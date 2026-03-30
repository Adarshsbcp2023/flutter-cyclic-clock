import 'package:intl/intl.dart';

class TimeUtils {
  static String formatTime(int hour, int minute) {
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat.jm().format(dt);
  }

  static String formatDate(DateTime dt) {
    return DateFormat('EEEE, MMMM d').format(dt);
  }

  static String formatRepeatDays(List<bool> days) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selected = <int>[];
    for (int i = 0; i < days.length; i++) {
      if (days[i]) selected.add(i);
    }
    if (selected.isEmpty) return 'Once';
    if (selected.length == 7) return 'Every day';
    if (selected.length == 5 &&
        selected.contains(0) &&
        selected.contains(1) &&
        selected.contains(2) &&
        selected.contains(3) &&
        selected.contains(4)) {
      return 'Weekdays';
    }
    if (selected.length == 2 &&
        selected.contains(5) &&
        selected.contains(6)) {
      return 'Weekends';
    }
    return selected.map((i) => names[i]).join(', ');
  }

  static DateTime? getNextAlarmTime(
      int hour, int minute, List<bool> repeatDays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, hour, minute);

    final anyRepeat = repeatDays.any((d) => d);

    if (!anyRepeat) {
      if (today.isAfter(now)) return today;
      return today.add(const Duration(days: 1));
    }

    // Find next matching weekday (0=Mon in our list, DateTime.weekday: 1=Mon, 7=Sun).
    // Check up to 14 days ahead so we always find the next repeat occurrence even
    // if the matching day has already passed today.
    for (int offset = 0; offset <= 13; offset++) {
      final candidate =
          DateTime(now.year, now.month, now.day + offset, hour, minute);
      final weekdayIndex = candidate.weekday - 1; // 0=Mon
      if (repeatDays[weekdayIndex] && candidate.isAfter(now)) {
        return candidate;
      }
    }
    return null;
  }
}
