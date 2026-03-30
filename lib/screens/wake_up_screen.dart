import 'dart:async';
import 'dart:convert';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/alarm_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/audio_service.dart';
import '../services/alarm_service.dart';
import '../models/alarm.dart';
import '../utils/time_utils.dart';

class WakeUpScreen extends StatefulWidget {
  const WakeUpScreen({super.key});

  @override
  State<WakeUpScreen> createState() => _WakeUpScreenState();
}

class _WakeUpScreenState extends State<WakeUpScreen>
    with SingleTickerProviderStateMixin {
  final AudioService _audio = AudioService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  String? _trackName;
  Alarm? _alarm;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAlarm());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _startAlarm() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? alarmId;
    if (args is String) alarmId = args;
    if (args is Map) alarmId = args['alarmId'] as String?;

    if (alarmId != null) {
      _alarm = context.read<AlarmProvider>().getAlarmById(alarmId);
    }

    if (_alarm != null &&
        _alarm!.isCyclicEnabled &&
        _alarm!.playlistId != null) {
      final track = await context
          .read<PlaylistProvider>()
          .getTodaysTrack(_alarm!.playlistId!);
      if (track != null) {
        setState(() => _trackName = track.name);
        await _audio.playTrack(track.path, trackName: track.name);
      }
    }

    if (mounted && _alarm != null) {
      final alarmIntId = _alarm!.id.hashCode.abs() % 2147483647;
      await AlarmService.cancelNotification(alarmIntId);
    }
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    setState(() => _dismissed = true);
    await _audio.stop();
    _pulseController.stop();
    _clockTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    if (_dismissed) return;
    setState(() => _dismissed = true);
    await _audio.stop();
    _pulseController.stop();
    _clockTimer?.cancel();

    // Schedule a one-off snooze alarm using a separate ID so the original
    // recurring alarm (if any) remains unaffected.
    if (_alarm != null) {
      final snoozeMinutes = _alarm!.snoozeMinutes;
      final snoozeTime =
          DateTime.now().add(Duration(minutes: snoozeMinutes));
      // Derive a stable snooze-alarm ID from the original, guaranteed different.
      final snoozeId =
          ('${_alarm!.id}_snooze').hashCode.abs() % 2147483647;
      final prefs = await SharedPreferences.getInstance();
      // Store with the same key format that alarmCallback reads: 'alarm_data_${id}'
      await prefs.setString(
          'alarm_data_$snoozeId', jsonEncode(_alarm!.toMap()));
      await AndroidAlarmManager.oneShotAt(
        snoozeTime,
        snoozeId,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: false,
        allowWhileIdle: true,
      );
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Snoozed for ${_alarm?.snoozeMinutes ?? 5} minutes'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _clockTimer?.cancel();
    _audio.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final dateStr = TimeUtils.formatDate(_now);

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pulsing time display
            ScaleTransition(
              scale: _pulseAnimation,
              child: Column(
                children: [
                  Text(
                    timeStr,
                    style:
                        Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 80,
                              fontWeight: FontWeight.w200,
                              color: colorScheme.onPrimaryContainer,
                            ),
                  ),
                  Text(
                    dateStr,
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withOpacity(0.7),
                            ),
                  ),
                ],
              ),
            ),

            // Alarm label
            if (_alarm?.label.isNotEmpty == true)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _alarm!.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
              ),

            // Now-playing track info
            if (_trackName != null)
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_note,
                        color: colorScheme.onPrimaryContainer,
                        size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _trackName!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Animated waveform bars
            SizedBox(
              height: 60,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final height = 10.0 +
                          (30.0 *
                              ((i % 2 == 0)
                                  ? _pulseController.value
                                  : (1 - _pulseController.value)));
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3),
                        child: Container(
                          width: 6,
                          height: height,
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimaryContainer
                                .withOpacity(0.6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            // Action buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Semantics(
                    label: 'Snooze alarm',
                    child: OutlinedButton.icon(
                      onPressed: _snooze,
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 56),
                        side: BorderSide(
                            color: colorScheme.onPrimaryContainer),
                        foregroundColor:
                            colorScheme.onPrimaryContainer,
                      ),
                      icon: const Icon(Icons.snooze),
                      label: Text(
                          'Snooze ${_alarm?.snoozeMinutes ?? 5} min'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    autofocus: true,
                    label: 'Dismiss alarm',
                    child: FilledButton.icon(
                      onPressed: _dismiss,
                      style: FilledButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 56),
                        backgroundColor:
                            colorScheme.onPrimaryContainer,
                        foregroundColor:
                            colorScheme.primaryContainer,
                      ),
                      icon: const Icon(Icons.alarm_off),
                      label: const Text('Dismiss'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
