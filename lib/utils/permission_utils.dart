import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestAlarmPermissions(BuildContext context) async {
    final permissions = [
      Permission.notification,
      Permission.scheduleExactAlarm,
    ];

    bool allGranted = true;
    for (final permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        allGranted = false;
      }
    }
    return allGranted;
  }

  static Future<bool> requestAudioPermissions(BuildContext context) async {
    final status = await Permission.audio.request();
    if (status.isGranted) return true;

    // Fallback for older Android versions
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  static Future<void> showPermissionRationale(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Future<bool> checkAndRequestAll(BuildContext context) async {
    final alarmOk = await requestAlarmPermissions(context);
    final audioOk = await requestAudioPermissions(context);
    return alarmOk && audioOk;
  }
}
