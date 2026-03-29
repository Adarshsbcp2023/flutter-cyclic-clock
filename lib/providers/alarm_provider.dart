import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../database/database_helper.dart';
import '../services/alarm_service.dart';

class AlarmProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Alarm> _alarms = [];
  bool _isLoading = false;

  List<Alarm> get alarms => List.unmodifiable(_alarms);
  bool get isLoading => _isLoading;

  Future<void> loadAlarms() async {
    _isLoading = true;
    notifyListeners();
    _alarms = await _db.getAllAlarms();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAlarm(Alarm alarm) async {
    final newAlarm = alarm.copyWith(id: const Uuid().v4());
    await _db.insertAlarm(newAlarm);
    _alarms.add(newAlarm);
    await AlarmService.scheduleAlarm(newAlarm);
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _db.updateAlarm(alarm);
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index >= 0) {
      _alarms[index] = alarm;
    }
    await AlarmService.cancelAlarm(alarm.id);
    if (alarm.isEnabled) {
      await AlarmService.scheduleAlarm(alarm);
    }
    notifyListeners();
  }

  Future<void> deleteAlarm(String id) async {
    await _db.deleteAlarm(id);
    await AlarmService.cancelAlarm(id);
    _alarms.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index < 0) return;
    final alarm = _alarms[index];
    final updated = alarm.copyWith(isEnabled: !alarm.isEnabled);
    await updateAlarm(updated);
  }

  Alarm? getAlarmById(String id) {
    try {
      return _alarms.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
