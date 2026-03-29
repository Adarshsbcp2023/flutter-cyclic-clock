class Track {
  final String path;
  final String name;

  const Track({required this.path, required this.name});

  factory Track.fromPath(String path) {
    final parts = path.replaceAll('\\', '/').split('/');
    final filename = parts.last;
    final dotIndex = filename.lastIndexOf('.');
    final name = dotIndex > 0 ? filename.substring(0, dotIndex) : filename;
    return Track(path: path, name: name);
  }

  Map<String, dynamic> toMap(String playlistId, int position) {
    return {
      'playlistId': playlistId,
      'path': path,
      'name': name,
      'position': position,
    };
  }
}

class CyclicPlaylist {
  final String id;
  final String name;
  final List<String> trackPaths;
  final int currentIndex;
  final DateTime lastShuffledDate;

  const CyclicPlaylist({
    required this.id,
    required this.name,
    required this.trackPaths,
    this.currentIndex = 0,
    required this.lastShuffledDate,
  });

  List<Track> get tracks => trackPaths.map(Track.fromPath).toList();

  Track? get currentTrack => trackPaths.isEmpty
      ? null
      : Track.fromPath(trackPaths[currentIndex % trackPaths.length]);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currentIndex': currentIndex,
      'lastShuffledDate': lastShuffledDate.toIso8601String(),
    };
  }

  factory CyclicPlaylist.fromMap(Map<String, dynamic> map, List<String> paths) {
    return CyclicPlaylist(
      id: map['id'] as String,
      name: map['name'] as String,
      trackPaths: paths,
      currentIndex: map['currentIndex'] as int? ?? 0,
      lastShuffledDate:
          DateTime.tryParse(map['lastShuffledDate'] as String? ?? '') ??
              DateTime(2000),
    );
  }

  CyclicPlaylist copyWith({
    String? id,
    String? name,
    List<String>? trackPaths,
    int? currentIndex,
    DateTime? lastShuffledDate,
  }) {
    return CyclicPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      trackPaths: trackPaths ?? this.trackPaths,
      currentIndex: currentIndex ?? this.currentIndex,
      lastShuffledDate: lastShuffledDate ?? this.lastShuffledDate,
    );
  }
}
