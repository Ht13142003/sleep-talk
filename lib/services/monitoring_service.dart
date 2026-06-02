import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'vad_service.dart';
import '../database/database_helper.dart';
import '../models/recording_model.dart';

enum MonitoringState { idle, listening, recording }

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final VadService _vadService = VadService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioRecorder _audioRecorder = AudioRecorder();

  MonitoringState _state = MonitoringState.idle;
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  // 预初始化的录音目录路径（在 startMonitoring 中设置）
  String? _recordingsPath;

  // 当前录音段状态
  IOSink? _waveFileSink;
  File? _currentOutputFile;
  DateTime? _segmentStartTime;
  int _segmentSampleCount = 0;
  bool _finalizing = false; // 防止并发 finalize
  static const int _sampleRate = 16000;

  MonitoringState get state => _state;
  bool get isActive => _state != MonitoringState.idle;
  double get currentAmplitude => _vadService.currentAmplitude;

  final _stateController = StreamController<MonitoringState>.broadcast();
  Stream<MonitoringState> get onStateChanged => _stateController.stream;

  final _amplitudeController = StreamController<double>.broadcast();
  Stream<double> get onAmplitudeChanged => _amplitudeController.stream;

  Future<bool> startMonitoring() async {
    if (_state != MonitoringState.idle) return true;

    final granted = await _audioRecorder.hasPermission();
    if (!granted) return false;

    // 预创建录音目录
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/sleep_talk_recordings');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _recordingsPath = dir.path;
    } catch (_) {
      return false;
    }

    _state = MonitoringState.listening;
    _stateController.add(_state);
    _vadService.reset();
    _finalizing = false;

    await _startAudioStream();
    return true;
  }

  Future<void> _startAudioStream() async {
    try {
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );

      _audioStreamSubscription = stream.listen(
        _processAudioFrame,
        onError: (_) => _handleStreamError(),
      );
    } catch (_) {
      _handleStreamError();
    }
  }

  void _processAudioFrame(Uint8List data) {
    final stateChanged = _vadService.processFrame(data);
    _amplitudeController.add(_vadService.currentAmplitude);

    if (_vadService.isSpeaking) {
      if (_waveFileSink == null && !_finalizing) {
        _beginSegment();
      }
      _writePcmToFile(data);
    } else if (_waveFileSink != null && !_finalizing) {
      // 异步 finalize，不阻塞音频流
      unawaited(_finalizeSegment());
    }

    if (stateChanged) {
      _state = _vadService.isSpeaking ? MonitoringState.recording : MonitoringState.listening;
      _stateController.add(_state);
    }
  }

  void _beginSegment() {
    if (_recordingsPath == null) return;

    _segmentStartTime = DateTime.now();
    _segmentSampleCount = 0;

    final timestamp = _segmentStartTime!;
    final fileName = 'dream_${_pad(timestamp.year)}${_pad(timestamp.month)}${_pad(timestamp.day)}_'
        '${_pad(timestamp.hour)}${_pad(timestamp.minute)}${_pad(timestamp.second)}.wav';

    final filePath = '$_recordingsPath/$fileName';
    _currentOutputFile = File(filePath);
    _waveFileSink = _currentOutputFile!.openWrite();

    _writeWavHeader(_waveFileSink!, 0);
  }

  void _writePcmToFile(Uint8List data) {
    if (_waveFileSink == null) return;
    _waveFileSink!.add(data);
    _segmentSampleCount += data.length ~/ 2;
  }

  Future<void> _finalizeSegment() async {
    _finalizing = true;

    try {
      if (_waveFileSink != null) {
        await _waveFileSink!.flush();
        await _waveFileSink!.close();
        _waveFileSink = null;
      }

      if (_currentOutputFile != null) {
        await _updateWavHeader(_currentOutputFile!, _segmentSampleCount);
        final fileSize = await _currentOutputFile!.length();
        final durationMs = ((_segmentSampleCount / _sampleRate) * 1000).round();

        await _dbHelper.insertRecording(RecordingModel(
          filePath: _currentOutputFile!.path,
          fileName: _currentOutputFile!.path.split(Platform.pathSeparator).last,
          createdAt: _segmentStartTime ?? DateTime.now(),
          durationMs: durationMs,
          fileSizeBytes: fileSize,
        ));
      }
    } catch (_) {} finally {
      _currentOutputFile = null;
      _segmentStartTime = null;
      _segmentSampleCount = 0;
      _finalizing = false;

      if (_state != MonitoringState.idle) {
        _state = MonitoringState.listening;
        _stateController.add(_state);
      }
    }
  }

  Future<void> stopMonitoring() async {
    if (_state == MonitoringState.idle) return;

    if (_waveFileSink != null) {
      await _finalizeSegment();
    }

    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    try {
      await _audioRecorder.stop();
    } catch (_) {}

    _state = MonitoringState.idle;
    _stateController.add(_state);
    _vadService.reset();
    _recordingsPath = null;
  }

  void _handleStreamError() {
    if (_waveFileSink != null) {
      try { _waveFileSink!.close(); } catch (_) {}
      _waveFileSink = null;
    }
    _finalizing = false;

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
    _audioRecorder.dispose();
    _stateController.close();
    _amplitudeController.close();
  }

  // --- WAV 头写入工具 ---

  void _writeWavHeader(IOSink sink, int dataSize) {
    const byteRate = _sampleRate * 2;
    final header = BytesBuilder();
    header.add('RIFF'.codeUnits);
    header.add(_int32ToBytes(36 + dataSize));
    header.add('WAVE'.codeUnits);
    header.add('fmt '.codeUnits);
    header.add(_int32ToBytes(16));
    header.add(_int16ToBytes(1)); // PCM
    header.add(_int16ToBytes(1)); // mono
    header.add(_int32ToBytes(_sampleRate));
    header.add(_int32ToBytes(byteRate));
    header.add(_int16ToBytes(2)); // block align
    header.add(_int16ToBytes(16)); // bits per sample
    header.add('data'.codeUnits);
    header.add(_int32ToBytes(dataSize));
    sink.add(header.toBytes());
  }

  Future<void> _updateWavHeader(File file, int sampleCount) async {
    try {
      final dataSize = sampleCount * 2;
      final raf = await file.open(mode: FileMode.write);
      raf.setPositionSync(4);
      raf.writeFromSync(_int32ToBytes(36 + dataSize));
      raf.setPositionSync(40);
      raf.writeFromSync(_int32ToBytes(dataSize));
      await raf.close();
    } catch (_) {}
  }

  Uint8List _int32ToBytes(int value) {
    final bytes = Uint8List(4);
    bytes[0] = value & 0xFF;
    bytes[1] = (value >> 8) & 0xFF;
    bytes[2] = (value >> 16) & 0xFF;
    bytes[3] = (value >> 24) & 0xFF;
    return bytes;
  }

  Uint8List _int16ToBytes(int value) {
    final bytes = Uint8List(2);
    bytes[0] = value & 0xFF;
    bytes[1] = (value >> 8) & 0xFF;
    return bytes;
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}