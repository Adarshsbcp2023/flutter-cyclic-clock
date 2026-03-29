import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/cyclic_playlist.dart';
import '../database/database_helper.dart';
import '../services/shuffle_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<CyclicPlaylist> _playlists = [];
  bool _isLoading = false;

  List<CyclicPlaylist> get playlists => List.unmodifiable(_playlists);
  bool get isLoading => _isLoading;

  Future<void> loadPlaylists() async {
    _isLoading = true;
    notifyListeners();
    _playlists = await _db.getAllPlaylists();
    _isLoading = false;
    notifyListeners();
  }

  Future<CyclicPlaylist> createPlaylist(String name) async {
    final playlist = CyclicPlaylist(
      id: const Uuid().v4(),
      name: name,
      trackPaths: [],
      currentIndex: 0,
      lastShuffledDate: DateTime(2000),
    );
    await _db.insertPlaylist(playlist);
    _playlists.add(playlist);
    notifyListeners();
    return playlist;
  }

  Future<void> updatePlaylist(CyclicPlaylist playlist) async {
    await _db.updatePlaylist(playlist);
    final index = _playlists.indexWhere((p) => p.id == playlist.id);
    if (index >= 0) {
      _playlists[index] = playlist;
    }
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    await _db.deletePlaylist(id);
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> addTrack(String playlistId, String trackPath) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;
    final playlist = _playlists[index];
    if (playlist.trackPaths.contains(trackPath)) return;
    final updated = playlist.copyWith(
      trackPaths: [...playlist.trackPaths, trackPath],
    );
    await updatePlaylist(updated);
  }

  Future<void> removeTrack(String playlistId, int trackIndex) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;
    final playlist = _playlists[index];
    final paths = List<String>.from(playlist.trackPaths)..removeAt(trackIndex);
    int newCurrentIndex = playlist.currentIndex;
    if (paths.isNotEmpty) {
      newCurrentIndex = newCurrentIndex % paths.length;
    } else {
      newCurrentIndex = 0;
    }
    final updated =
        playlist.copyWith(trackPaths: paths, currentIndex: newCurrentIndex);
    await updatePlaylist(updated);
  }

  Future<void> reorderTracks(
      String playlistId, int oldIndex, int newIndex) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;
    final playlist = _playlists[index];
    final paths = List<String>.from(playlist.trackPaths);
    final item = paths.removeAt(oldIndex);
    paths.insert(newIndex, item);
    final updated = playlist.copyWith(trackPaths: paths);
    await updatePlaylist(updated);
  }

  Future<Track?> getTodaysTrack(String playlistId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return null;
    final playlist = _playlists[index];
    if (playlist.trackPaths.isEmpty) return null;
    final refreshed = await ShuffleService.refreshIfNewDay(playlist, _db);
    if (refreshed.currentIndex != playlist.currentIndex ||
        refreshed.lastShuffledDate != playlist.lastShuffledDate) {
      _playlists[index] = refreshed;
      notifyListeners();
    }
    return refreshed.currentTrack;
  }

  CyclicPlaylist? getPlaylistById(String id) {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
