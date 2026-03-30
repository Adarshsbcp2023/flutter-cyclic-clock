import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playTrack(String filePath, {String? trackName}) async {
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.file(filePath),
          tag: MediaItem(
            id: filePath,
            title: trackName ?? _nameFromPath(filePath),
            album: 'Cyclic Alarm',
          ),
        ),
      );
      await _player.setLooping(true);
      await _player.play();
      _isPlaying = true;
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  Future<void> resume() async {
    await _player.play();
    _isPlaying = true;
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  String _nameFromPath(String path) {
    final parts = path.replaceAll('\\', '/').split('/');
    final filename = parts.last;
    final dotIndex = filename.lastIndexOf('.');
    return dotIndex > 0 ? filename.substring(0, dotIndex) : filename;
  }
}
