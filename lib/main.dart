import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'providers/alarm_provider.dart';
import 'providers/playlist_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alarm_editor_screen.dart';
import 'screens/music_selector_screen.dart';
import 'screens/wake_up_screen.dart';
import 'models/cyclic_playlist.dart';
import 'services/alarm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.cyclic_alarm_clock.audio',
    androidNotificationChannelName: 'Cyclic Alarm Clock Audio',
    androidNotificationOngoing: true,
  );

  await AndroidAlarmManager.initialize();
  await AlarmService.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlarmProvider()..loadAlarms()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()..loadPlaylists()),
      ],
      child: const CyclicAlarmApp(),
    ),
  );
}

class CyclicAlarmApp extends StatelessWidget {
  const CyclicAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyclic Alarm Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/alarm-editor': (context) => const AlarmEditorScreen(),
        '/music-selector': (context) {
          final playlist =
              ModalRoute.of(context)!.settings.arguments as CyclicPlaylist;
          return MusicSelectorScreen(playlist: playlist);
        },
        '/wake-up': (context) => const WakeUpScreen(),
      },
    );
  }
}
