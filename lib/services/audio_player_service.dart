import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _currentFile;

  bool get isPlaying => _isPlaying;
  String? get currentFile => _currentFile;

  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  Future<void> play(String filePath) async {
    if (_isPlaying && _currentFile == filePath) {
      await pause();
      return;
    }

    if (_isPlaying) {
      await stop();
    }

    _currentFile = filePath;
    await _player.play(DeviceFileSource(filePath));
    _isPlaying = true;
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  Future<void> resume() async {
    await _player.resume();
    _isPlaying = true;
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentFile = null;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<Duration?> getDuration() async {
    return await _player.getDuration();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}