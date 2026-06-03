import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'utils/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/recordings_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeService();
  } catch (e) {
    debugPrint('Service initialization error: $e');
  }
  runApp(const SleepTalkApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  final androidConfig = AndroidConfiguration(
    onStart: onStart,
    autoStart: false,
    isForegroundMode: true,
    notificationChannelId: 'sleep_talk_channel',
    initialNotificationTitle: 'Sleep Talk Recorder',
    initialNotificationContent: 'Monitoring for dream talks...',
    foregroundServiceNotificationId: 888,
    foregroundServiceTypes: [AndroidForegroundType.microphone],
  );

  final iosConfig = IosConfiguration(
    autoStart: false,
    onForeground: onStart,
    onBackground: onStart,
  );

  await service.configure(
    androidConfiguration: androidConfig,
    iosConfiguration: iosConfig,
  );
}

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('startMonitoring').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Sleep Talk Recorder',
        content: 'Listening for dream talks...',
      );
    }
  });

  service.on('stopMonitoring').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Sleep Talk Recorder',
        content: 'Monitoring stopped',
      );
    }
    service.stopSelf();
  });

  service.on('updateStatus').listen((event) {
    if (service is AndroidServiceInstance) {
      final data = event as Map?;
      final state = data?['state'] as String? ?? 'listening';
      final content = state == 'recording'
          ? 'Recording dream talk...'
          : 'Listening for dream talks...';
      service.setForegroundNotificationInfo(
        title: 'Sleep Talk Recorder',
        content: content,
      );
    }
  });

  return true;
}

class SleepTalkApp extends StatelessWidget {
  const SleepTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Talk Recorder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    RecordingsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.textSecondary.withAlpha(30),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_none_rounded),
              activeIcon: Icon(Icons.mic),
              label: 'Recordings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}