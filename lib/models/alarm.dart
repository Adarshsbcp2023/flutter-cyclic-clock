class Alarm {
  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool isEnabled;
  final List<bool> repeatDays; // index 0=Mon, 6=Sun
  final bool isCyclicEnabled;
  final String? playlistId;
  final int snoozeMinutes;
  final DateTime? nextAlarmTime;

  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.isEnabled = true,
    required this.repeatDays,
    this.isCyclicEnabled = false,
    this.playlistId,
    this.snoozeMinutes = 5,
    this.nextAlarmTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'isEnabled': isEnabled ? 1 : 0,
      'repeatDays': repeatDays.map((d) => d ? '1' : '0').join(','),
      'isCyclicEnabled': isCyclicEnabled ? 1 : 0,
      'playlistId': playlistId,
      'snoozeMinutes': snoozeMinutes,
      'nextAlarmTime': nextAlarmTime?.toIso8601String(),
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] as String,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      label: map['label'] as String? ?? '',
      isEnabled: (map['isEnabled'] as int) == 1,
      repeatDays: (map['repeatDays'] as String)
          .split(',')
          .map((d) => d == '1')
          .toList(),
      isCyclicEnabled: (map['isCyclicEnabled'] as int) == 1,
      playlistId: map['playlistId'] as String?,
      snoozeMinutes: map['snoozeMinutes'] as int? ?? 5,
      nextAlarmTime: map['nextAlarmTime'] != null
          ? DateTime.tryParse(map['nextAlarmTime'] as String)
          : null,
    );
  }

  Alarm copyWith({
    String? id,
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    List<bool>? repeatDays,
    bool? isCyclicEnabled,
    String? playlistId,
    int? snoozeMinutes,
    DateTime? nextAlarmTime,
    bool clearPlaylistId = false,
    bool clearNextAlarmTime = false,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      isCyclicEnabled: isCyclicEnabled ?? this.isCyclicEnabled,
      playlistId: clearPlaylistId ? null : (playlistId ?? this.playlistId),
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      nextAlarmTime:
          clearNextAlarmTime ? null : (nextAlarmTime ?? this.nextAlarmTime),
    );
  }
}
