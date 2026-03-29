import 'package:flutter_test/flutter_test.dart';
import 'package:cyclic_alarm_clock/models/cyclic_playlist.dart';
import 'package:cyclic_alarm_clock/services/shuffle_service.dart';

void main() {
  group('ShuffleService', () {
    final yesterday =
        DateTime.now().subtract(const Duration(days: 1));
    final today = DateTime.now();

    CyclicPlaylist makePlaylist({
      required List<String> paths,
      required int currentIndex,
      required DateTime lastShuffledDate,
    }) {
      return CyclicPlaylist(
        id: 'test-id',
        name: 'Test Playlist',
        trackPaths: paths,
        currentIndex: currentIndex,
        lastShuffledDate: lastShuffledDate,
      );
    }

    test('returns 0 for empty playlist', () async {
      final playlist = makePlaylist(
          paths: [], currentIndex: 0, lastShuffledDate: yesterday);
      final index = await ShuffleService.getTodaysTrackIndex(playlist);
      expect(index, 0);
    });

    test('returns same index when shuffled today', () async {
      final playlist = makePlaylist(
        paths: ['/track1.mp3', '/track2.mp3', '/track3.mp3'],
        currentIndex: 1,
        lastShuffledDate: today,
      );
      final index = await ShuffleService.getTodaysTrackIndex(playlist);
      expect(index, 1);
    });

    test('returns valid index when shuffled yesterday', () async {
      final playlist = makePlaylist(
        paths: ['/track1.mp3', '/track2.mp3', '/track3.mp3'],
        currentIndex: 0,
        lastShuffledDate: yesterday,
      );
      final index = await ShuffleService.getTodaysTrackIndex(playlist);
      expect(index, greaterThanOrEqualTo(0));
      expect(index, lessThan(playlist.trackPaths.length));
    });

    test('picks different index when playlist has multiple tracks',
        () async {
      // Run many times to verify the shuffle avoids the previous index.
      final results = <int>{};
      for (int i = 0; i < 50; i++) {
        final playlist = makePlaylist(
          paths: ['/track1.mp3', '/track2.mp3', '/track3.mp3'],
          currentIndex: 0,
          lastShuffledDate: yesterday,
        );
        final index =
            await ShuffleService.getTodaysTrackIndex(playlist);
        results.add(index);
      }
      // Should never return the previous index (0).
      expect(results.contains(0), isFalse);
    });

    test('returns 0 for single-track playlist', () async {
      final playlist = makePlaylist(
        paths: ['/track1.mp3'],
        currentIndex: 0,
        lastShuffledDate: yesterday,
      );
      final index = await ShuffleService.getTodaysTrackIndex(playlist);
      expect(index, 0);
    });
  });
}
