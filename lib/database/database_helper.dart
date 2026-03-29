import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alarm.dart';
import '../models/cyclic_playlist.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cyclic_alarm.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alarms (
        id TEXT PRIMARY KEY,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        label TEXT DEFAULT '',
        isEnabled INTEGER DEFAULT 1,
        repeatDays TEXT NOT NULL,
        isCyclicEnabled INTEGER DEFAULT 0,
        playlistId TEXT,
        snoozeMinutes INTEGER DEFAULT 5,
        nextAlarmTime TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        currentIndex INTEGER DEFAULT 0,
        lastShuffledDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlistId TEXT NOT NULL,
        path TEXT NOT NULL,
        name TEXT NOT NULL,
        position INTEGER NOT NULL,
        FOREIGN KEY (playlistId) REFERENCES playlists(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Alarm CRUD ──────────────────────────────────────────────────────────────

  Future<void> insertAlarm(Alarm alarm) async {
    final db = await database;
    await db.insert('alarms', alarm.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final db = await database;
    await db
        .update('alarms', alarm.toMap(), where: 'id = ?', whereArgs: [alarm.id]);
  }

  Future<void> deleteAlarm(String id) async {
    final db = await database;
    await db.delete('alarms', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Alarm>> getAllAlarms() async {
    final db = await database;
    final maps = await db.query('alarms', orderBy: 'hour ASC, minute ASC');
    return maps.map(Alarm.fromMap).toList();
  }

  Future<Alarm?> getAlarm(String id) async {
    final db = await database;
    final maps = await db.query('alarms', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Alarm.fromMap(maps.first);
  }

  // ── Playlist CRUD ────────────────────────────────────────────────────────────

  Future<void> insertPlaylist(CyclicPlaylist playlist) async {
    final db = await database;
    await db.insert('playlists', playlist.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await _insertTracks(db, playlist);
  }

  Future<void> updatePlaylist(CyclicPlaylist playlist) async {
    final db = await database;
    await db.update('playlists', playlist.toMap(),
        where: 'id = ?', whereArgs: [playlist.id]);
    await db.delete('playlist_tracks',
        where: 'playlistId = ?', whereArgs: [playlist.id]);
    await _insertTracks(db, playlist);
  }

  Future<void> _insertTracks(Database db, CyclicPlaylist playlist) async {
    for (int i = 0; i < playlist.trackPaths.length; i++) {
      final track = Track.fromPath(playlist.trackPaths[i]);
      await db.insert('playlist_tracks', track.toMap(playlist.id, i));
    }
  }

  Future<void> deletePlaylist(String id) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
    await db.delete('playlist_tracks',
        where: 'playlistId = ?', whereArgs: [id]);
  }

  Future<List<CyclicPlaylist>> getAllPlaylists() async {
    final db = await database;
    final playlistMaps = await db.query('playlists');
    final playlists = <CyclicPlaylist>[];
    for (final map in playlistMaps) {
      final id = map['id'] as String;
      final trackMaps = await db.query(
        'playlist_tracks',
        where: 'playlistId = ?',
        whereArgs: [id],
        orderBy: 'position ASC',
      );
      final paths = trackMaps.map((t) => t['path'] as String).toList();
      playlists.add(CyclicPlaylist.fromMap(map, paths));
    }
    return playlists;
  }

  Future<CyclicPlaylist?> getPlaylist(String id) async {
    final db = await database;
    final maps =
        await db.query('playlists', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final trackMaps = await db.query(
      'playlist_tracks',
      where: 'playlistId = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );
    final paths = trackMaps.map((t) => t['path'] as String).toList();
    return CyclicPlaylist.fromMap(maps.first, paths);
  }

  Future<void> updatePlaylistIndex(
      String id, int currentIndex, DateTime lastShuffledDate) async {
    final db = await database;
    await db.update(
      'playlists',
      {
        'currentIndex': currentIndex,
        'lastShuffledDate': lastShuffledDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
