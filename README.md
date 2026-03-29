# Cyclic Alarm Clock

A modern Android alarm clock built with Flutter and Material Design 3 (Material You). Its signature feature is a **Cyclic Playlist** — assign multiple music tracks to any alarm and the app automatically plays a different track each day, shuffled so you never hear the same song two mornings in a row.

---

## Features

| Feature | Details |
|---|---|
| **Material You Design** | Dynamic color theming, M3 components throughout |
| **CRUD Alarms** | Create, read, update, and delete multiple alarms |
| **Repeat Scheduling** | Per-weekday repeat (Mon–Sun), one-off, weekdays, weekends |
| **Cyclic Playlist** | Assign multiple audio files to an alarm; a new track is picked each day |
| **Daily Shuffle Engine** | Never repeats yesterday's track; shuffled once per day |
| **Track Management** | Add, remove, and reorder tracks; preview any track in-app |
| **Snooze** | Configurable snooze duration (1–30 min) per alarm |
| **Wake-Up Screen** | Full-screen overlay with pulsing animation, track name, Snooze & Dismiss |
| **Accessibility** | Semantic labels on all interactive elements, works with TalkBack |
| **Permissions** | `SCHEDULE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `READ_MEDIA_AUDIO`, `POST_NOTIFICATIONS` |
| **Boot Recovery** | Alarms are rescheduled after device reboot |

---

## Project Structure

```
lib/
├── main.dart                        # App entry point, providers, routes
├── models/
│   ├── alarm.dart                   # Alarm data model
│   └── cyclic_playlist.dart        # CyclicPlaylist + Track models
├── database/
│   └── database_helper.dart        # SQLite helper (sqflite)
├── providers/
│   ├── alarm_provider.dart          # Alarm state management
│   └── playlist_provider.dart      # Playlist state management
├── services/
│   ├── alarm_service.dart           # Alarm scheduling (android_alarm_manager_plus)
│   ├── audio_service.dart           # Audio playback (just_audio)
│   └── shuffle_service.dart        # Daily shuffle engine
├── screens/
│   ├── dashboard_screen.dart       # Alarm list
│   ├── alarm_editor_screen.dart    # Create / edit alarm
│   ├── music_selector_screen.dart  # Playlist track manager
│   └── wake_up_screen.dart         # Full-screen alarm overlay
├── widgets/
│   ├── alarm_card.dart              # Alarm list card
│   └── day_selector.dart           # Mon–Sun chip selector
└── utils/
    ├── time_utils.dart              # Time formatting helpers
    └── permission_utils.dart       # Runtime permission helpers

android/
├── app/src/main/
│   ├── AndroidManifest.xml         # All permissions + component declarations
│   └── kotlin/.../
│       ├── MainActivity.kt
│       └── BootReceiver.kt

test/
└── shuffle_service_test.dart       # Unit tests for the shuffle engine
```

---

## Tech Stack

| Concern | Package |
|---|---|
| State management | `provider` |
| Local database | `sqflite` |
| Alarm scheduling | `android_alarm_manager_plus` |
| Audio playback | `just_audio` + `just_audio_background` |
| File picker | `file_picker` |
| Permissions | `permission_handler` |
| Notifications | `flutter_local_notifications` |

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0
- Android SDK (API 21+, target API 34)

### Run

```bash
flutter pub get
flutter run
```

### Test

```bash
flutter test
```

---

## Shuffle Algorithm

The cyclic shuffle engine (`lib/services/shuffle_service.dart`) works as follows:

1. Each `CyclicPlaylist` stores a `currentIndex` (today's track) and `lastShuffledDate`.
2. When an alarm fires, `ShuffleService.refreshIfNewDay()` is called:
   - If `lastShuffledDate == today` → return the existing `currentIndex` (no change).
   - If `lastShuffledDate < today` → pick a new random index **different from** the previous one (when the playlist has > 1 track), persist it, and return it.
3. The track at `currentIndex` is played.

This guarantees you hear a **different song every morning** without repeating yesterday's track.

---

## Android Permissions

| Permission | API Level | Purpose |
|---|---|---|
| `SCHEDULE_EXACT_ALARM` | 31–32 | Precise alarm scheduling |
| `USE_EXACT_ALARM` | 33+ | Precise alarm scheduling (auto-granted for alarm apps) |
| `USE_FULL_SCREEN_INTENT` | all | Wake-up overlay over the lock screen |
| `POST_NOTIFICATIONS` | 33+ | Alarm notification |
| `READ_MEDIA_AUDIO` | 33+ | Access local audio files |
| `READ_EXTERNAL_STORAGE` | ≤32 | Access local audio files |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | all | Background audio |
| `RECEIVE_BOOT_COMPLETED` | all | Reschedule alarms after reboot |
