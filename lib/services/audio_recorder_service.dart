import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<String> _getRecordingsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(p.join(appDir.path, 'sleep_talk_recordings'));
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    return recordingsDir.path;
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    final dir = await _getRecordingsDirectory();
    final timestamp = DateTime.now();
    final fileName = 'dream_${timestamp.year}${_pad(timestamp.month)}${_pad(timestamp.day)}_'
        '${_pad(timestamp.hour)}${_pad(timestamp.minute)}${_pad(timestamp.second)}.m4a';
    _currentRecordingPath = p.join(dir, fileName);
    _recordingStartTime = timestamp;

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: 1,
    );

    await _recorder.start(config, path: _currentRecordingPath!);
    _isRecording = true;
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = _currentRecordingPath;
    final startTime = _recordingStartTime;

    _isRecording = false;
    _currentRecordingPath = null;
    _recordingStartTime = null;

    await _recorder.stop();

    if (path != null && startTime != null) {
      final file = File(path);
      if (await file.exists()) {
        return path;
      }
    }

    return path;
  }

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    _recorder.dispose();
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}