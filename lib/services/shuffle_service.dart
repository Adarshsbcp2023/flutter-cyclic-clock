import 'dart:math';
import '../models/cyclic_playlist.dart';
import '../database/database_helper.dart';

class ShuffleService {
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Future<int> getTodaysTrackIndex(CyclicPlaylist playlist) async {
    if (playlist.trackPaths.isEmpty) return 0;
    final today = DateTime.now();
    if (_isSameDay(today, playlist.lastShuffledDate)) {
      return playlist.currentIndex % playlist.trackPaths.length;
    }
    return _pickNewIndex(playlist);
  }

  static int _pickNewIndex(CyclicPlaylist playlist) {
    if (playlist.trackPaths.length <= 1) return 0;
    final rng = Random();
    int newIndex;
    do {
      newIndex = rng.nextInt(playlist.trackPaths.length);
    } while (newIndex == playlist.currentIndex);
    return newIndex;
  }

  static Future<CyclicPlaylist> refreshIfNewDay(
    CyclicPlaylist playlist,
    DatabaseHelper db,
  ) async {
    if (playlist.trackPaths.isEmpty) return playlist;
    final today = DateTime.now();
    if (_isSameDay(today, playlist.lastShuffledDate)) {
      return playlist;
    }
    final newIndex = _pickNewIndex(playlist);
    await db.updatePlaylistIndex(playlist.id, newIndex, today);
    return playlist.copyWith(currentIndex: newIndex, lastShuffledDate: today);
  }
}
