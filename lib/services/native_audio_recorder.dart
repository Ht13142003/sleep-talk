import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 原生 Android AudioRecord 录音器，替代 record 包的 startStream
/// 仅用于 Android 平台
class NativeAudioRecorder {
  static const _methodChannel = MethodChannel('com.sleeptalk/audio_recorder');
  static const _eventChannel = EventChannel('com.sleeptalk/audio_recorder/stream');

  StreamSubscription<Uint8List>? _subscription;

  /// 开始录音，返回 PCM 16-bit 音频流
  Future<bool> start({int sampleRate = 16000}) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('start', {
        'sampleRate': sampleRate,
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('NativeAudioRecorder.start error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('NativeAudioRecorder.start unexpected error: $e');
      return false;
    }
  }

  /// 获取音频数据流
  Stream<Uint8List> get audioStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((data) => Uint8List.fromList(data as List<int>));
  }

  /// 是否正在录音
  Future<bool> isRecording() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isRecording');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// 停止录音
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _methodChannel.invokeMethod('stop');
    } catch (_) {}
  }
}