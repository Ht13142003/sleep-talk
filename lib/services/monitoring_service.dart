import 'dart:typed_data';
import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:record/record.dart';
import 'vad_service.dart';
import 'audio_recorder_service.dart';
import '../database/database_helper.dart';
import '../models/recording_model.dart';

enum MonitoringState { idle, listening, recording }

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final VadService _vadService = VadService();
  final AudioRecorderService _recorderService = AudioRecorderService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioRecorder _streamRecorder = AudioRecorder();

  MonitoringState _state = MonitoringState.idle;
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  MonitoringState get state => _state;
  bool get isActive => _state != MonitoringState.idle;
  double get currentAmplitude => _vadService.currentAmplitude;

  final _stateController = StreamController<MonitoringState>.broadcast();
  Stream<MonitoringState> get onStateChanged => _stateController.stream;

  final _amplitudeController = StreamController<double>.broadcast();
  Stream<double> get onAmplitudeChanged => _amplitudeController.stream;

  Future<bool> startMonitoring() async {
    if (_state != MonitoringState.idle) return true;

    final hasPermission = await _recorderService.hasPermission();
    if (!hasPermission) return false;

    _state = MonitoringState.listening;
    _stateController.add(_state);
    _vadService.reset();

    await _startVadStream();
    return true;
  }

  Future<void> _startVadStream() async {
    try {
      final stream = await _streamRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _audioStreamSubscription = stream.listen(
        (data) {
          _processAudioFrame(data);
        },
        onError: (error) {
          _handleStreamError();
        },
      );
    } catch (e) {
      _handleStreamError();
    }
  }

  void _processAudioFrame(Uint8List data) {
    final stateChanged = _vadService.processFrame(data);
    _amplitudeController.add(_vadService.currentAmplitude);

    if (stateChanged) {
      if (_vadService.isSpeaking) {
        _startHighQualityRecording();
      } else {
        _stopHighQualityRecording();
      }
    }
  }

  Future<void> _startHighQualityRecording() async {
    _state = MonitoringState.recording;
    _stateController.add(_state);

    await _streamRecorder.stop();
    await _audioStreamSubscription?.cancel();

    await _recorderService.startRecording();
  }

  Future<void> _stopHighQualityRecording() async {
    final filePath = await _recorderService.stopRecording();

    _state = MonitoringState.listening;
    _stateController.add(_state);

    if (filePath != null) {
      await _saveRecordingMetadata(filePath);
    }

    _vadService.reset();

    final service = FlutterBackgroundService();
    service.invoke('updateStatus', {
      'state': 'listening',
      'amplitude': 0.0,
    });

    await _startVadStream();
  }

  Future<void> _saveRecordingMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      final fileSize = await file.length();
      final fileName = filePath.split(Platform.pathSeparator).last;

      final recording = RecordingModel(
        filePath: filePath,
        fileName: fileName,
        createdAt: DateTime.now(),
        durationMs: 0,
        fileSizeBytes: fileSize,
      );

      await _dbHelper.insertRecording(recording);
    } catch (_) {}
  }

  Future<void> stopMonitoring() async {
    if (_state == MonitoringState.idle) return;

    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    try {
      await _streamRecorder.stop();
    } catch (_) {}

    if (_state == MonitoringState.recording) {
      final filePath = await _recorderService.stopRecording();
      if (filePath != null) {
        await _saveRecordingMetadata(filePath);
      }
    }

    _state = MonitoringState.idle;
    _stateController.add(_state);
    _vadService.reset();
  }

  void _handleStreamError() {
    _state = MonitoringState.idle;
    _stateController.add(_state);

    Timer(const Duration(seconds: 3), () {
      if (_state == MonitoringState.idle) {
        startMonitoring();
      }
    });
  }

  Future<void> dispose() async {
    await stopMonitoring();
    await _recorderService.dispose();
    _streamRecorder.dispose();
    _stateController.close();
    _amplitudeController.close();
  }
}