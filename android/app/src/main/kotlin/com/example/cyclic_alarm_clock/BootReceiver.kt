package com.example.cyclic_alarm_clock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives BOOT_COMPLETED broadcast and launches the app in the background
 * so that android_alarm_manager_plus can reschedule all alarms via its own
 * ScheduledNotificationBootReceiver. The actual rescheduling logic lives in
 * the Flutter layer (AlarmService.rescheduleAll) which is triggered when the
 * app initialises after boot.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            // android_alarm_manager_plus handles its own rescheduling via
            // AlarmBroadcastReceiver; nothing extra needed here.
        }
    }
}
