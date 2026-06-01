import 'dart:math';
import 'dart:typed_data';

class VadService {
  static const double _vadThreshold = 0.02;
  static const int _frameSize = 512;
  static const double _sampleRate = 16000.0;
  static const double _silenceDurationSeconds = 1.5;

  bool _isSpeaking = false;
  int _silenceFrameCount = 0;
  int _speechFrameCount = 0;
  final int _framesPerSilenceThreshold;
  final int _speechOnsetFrames = 5;

  final List<double> amplitudeHistory = [];
  static const int _maxHistorySize = 100;

  VadService() : _framesPerSilenceThreshold = ((_silenceDurationSeconds * _sampleRate) / _frameSize).round();

  bool get isSpeaking => _isSpeaking;
  double get currentAmplitude => amplitudeHistory.isNotEmpty ? amplitudeHistory.last : 0.0;

  bool processFrame(Uint8List pcmData) {
    final samples = _bytesToInt16List(pcmData);
    if (samples.isEmpty) return false;

    final rms = _calculateRMS(samples);
    final normalizedRms = rms / 32768.0;

    amplitudeHistory.add(normalizedRms);
    if (amplitudeHistory.length > _maxHistorySize) {
      amplitudeHistory.removeAt(0);
    }

    final isVoiceFrame = normalizedRms > _vadThreshold;

    if (isVoiceFrame) {
      _speechFrameCount++;
      _silenceFrameCount = 0;
      if (_speechFrameCount >= _speechOnsetFrames && !_isSpeaking) {
        _isSpeaking = true;
        return true;
      }
    } else {
      _silenceFrameCount++;
      _speechFrameCount = 0;
      if (_silenceFrameCount >= _framesPerSilenceThreshold && _isSpeaking) {
        _isSpeaking = false;
        return true;
      }
    }

    return false;
  }

  void reset() {
    _isSpeaking = false;
    _silenceFrameCount = 0;
    _speechFrameCount = 0;
    amplitudeHistory.clear();
  }

  double _calculateRMS(List<int> samples) {
    if (samples.isEmpty) return 0.0;
    double sum = 0;
    for (final s in samples) {
      sum += s.toDouble() * s.toDouble();
    }
    return sqrt(sum / samples.length);
  }

  List<int> _bytesToInt16List(Uint8List bytes) {
    final result = <int>[];
    for (int i = 0; i < bytes.length - 1; i += 2) {
      int value = (bytes[i + 1] << 8) | bytes[i];
      if (value > 32767) {
        value -= 65536;
      }
      result.add(value);
    }
    return result;
  }
}