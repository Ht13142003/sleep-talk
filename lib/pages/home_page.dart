import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/monitoring_service.dart';
import '../services/audio_player_service.dart';
import '../database/database_helper.dart';
import '../models/recording_model.dart';
import '../widgets/status_indicator.dart';
import '../widgets/recording_tile.dart';
import '../utils/app_theme.dart';
import 'recordings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MonitoringService _monitoringService = MonitoringService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioPlayerService _audioPlayer = AudioPlayerService();

  bool _isMonitoring = false;
  double _amplitude = 0.0;
  String _statusText = 'Monitoring Off';
  MonitoringState _currentState = MonitoringState.idle;
  List<RecordingModel> _recentRecordings = [];
  StreamSubscription<MonitoringState>? _stateSub;
  StreamSubscription<double>? _amplitudeSub;
  String? _playingFile;

  @override
  void initState() {
    super.initState();
    _loadRecentRecordings();
    _stateSub = _monitoringService.onStateChanged.listen((state) {
      setState(() {
        _currentState = state;
        _updateStatusText();
      });
    });
    _amplitudeSub = _monitoringService.onAmplitudeChanged.listen((amp) {
      if (mounted) setState(() => _amplitude = amp);
    });
  }

  void _updateStatusText() {
    switch (_currentState) {
      case MonitoringState.idle:
        _statusText = 'Monitoring Off';
        break;
      case MonitoringState.listening:
        _statusText = 'Listening...';
        break;
      case MonitoringState.recording:
        _statusText = 'Recording...';
        break;
    }
  }

  Future<void> _loadRecentRecordings() async {
    final recordings = await _dbHelper.getAllRecordings();
    if (mounted) {
      setState(() => _recentRecordings = recordings.take(3).toList());
    }
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoring) {
      // 停止监听
      _stopAndroidService();
      await _monitoringService.stopMonitoring();
      setState(() => _isMonitoring = false);
    } else {
      // 开始监听
      final success = await _monitoringService.startMonitoring();
      if (success) {
        _startAndroidService();
        setState(() => _isMonitoring = true);
      }
    }
  }

  void _startAndroidService() {
    if (!Platform.isAndroid) return;
    final service = FlutterBackgroundService();
    service.startService().then((started) {
      if (started) {
        service.invoke('startMonitoring');
      }
    });
  }

  void _stopAndroidService() {
    if (!Platform.isAndroid) return;
    final service = FlutterBackgroundService();
    service.invoke('stopMonitoring');
  }

  Future<void> _playRecording(RecordingModel recording) async {
    if (_playingFile == recording.filePath) {
      await _audioPlayer.pause();
      setState(() => _playingFile = null);
      return;
    }
    await _audioPlayer.play(recording.filePath);
    setState(() => _playingFile = recording.filePath);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _amplitudeSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Talk Recorder')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              StatusIndicator(
                isActive: _isMonitoring,
                amplitude: _amplitude,
                statusText: _statusText,
              ),
              const SizedBox(height: 32),
              _buildToggleButton(),
              const SizedBox(height: 40),
              _buildInfoCard(),
              const SizedBox(height: 32),
              _buildRecentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: _toggleMonitoring,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 220,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: _isMonitoring
                ? [AppTheme.dangerRed, AppTheme.warningOrange]
                : [AppTheme.accentBlue, AppTheme.accentTeal],
          ),
          boxShadow: [
            BoxShadow(
              color: (_isMonitoring ? AppTheme.dangerRed : AppTheme.accentBlue).withAlpha(80),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isMonitoring ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                _isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentTeal.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.accentTeal, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How It Works',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isMonitoring
                      ? 'VAD active — only saves audio when voice detected'
                      : 'Press Start to begin monitoring. The app works in background and when device is locked.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Recordings',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecordingsPage()),
                  ).then((_) => _loadRecentRecordings());
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_recentRecordings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.nights_stay, size: 48, color: AppTheme.textSecondary.withAlpha(100)),
                  const SizedBox(height: 12),
                  const Text(
                    'No recordings yet',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Start monitoring to capture dream talks',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentRecordings.map((recording) => RecordingTile(
                recording: recording,
                isPlaying: _playingFile == recording.filePath,
                isSelected: false,
                selectionMode: false,
                onTap: () {},
                onPlayPause: () => _playRecording(recording),
                onDelete: () async {
                  await _dbHelper.deleteRecording(recording.id!);
                  _loadRecentRecordings();
                },
              )),
      ],
    );
  }
}