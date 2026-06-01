import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../utils/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _vadThreshold = 0.02;
  double _silenceDuration = 1.5;
  int _sampleRate = 44100;
  int _bitRate = 128;
  bool _autoDeleteOld = false;
  int _autoDeleteDays = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader('Audio Settings'),
          _buildSliderTile(
            'VAD Sensitivity',
            'Lower = more sensitive to voice',
            _vadThreshold,
            0.005,
            0.1,
            (value) => setState(() => _vadThreshold = value),
            valueDisplay: (v) => v.toStringAsFixed(3),
          ),
          _buildSliderTile(
            'Silence Duration',
            'Seconds of silence before stopping recording',
            _silenceDuration,
            0.5,
            5.0,
            (value) => setState(() => _silenceDuration = value),
            valueDisplay: (v) => '${v.toStringAsFixed(1)}s',
          ),
          _buildSliderTile(
            'Sample Rate',
            'Recording quality',
            _sampleRate.toDouble(),
            22050,
            48000,
            (value) => setState(() => _sampleRate = value.round()),
            valueDisplay: (v) => '${(v / 1000).toStringAsFixed(1)}kHz',
          ),
          _buildSliderTile(
            'Bit Rate',
            'Audio encoding quality',
            _bitRate.toDouble(),
            64,
            256,
            (value) => setState(() => _bitRate = value.round()),
            valueDisplay: (v) => '${v.round()}kbps',
          ),
          _buildSectionHeader('Storage'),
          _buildSwitchTile(
            'Auto-delete old recordings',
            'Remove recordings older than $_autoDeleteDays days',
            _autoDeleteOld,
            (value) => setState(() => _autoDeleteOld = value),
          ),
          if (_autoDeleteOld)
            _buildSliderTile(
              'Keep recordings for',
              'Days before auto-deletion',
              _autoDeleteDays.toDouble(),
              7,
              90,
              (value) => setState(() => _autoDeleteDays = value.round()),
              valueDisplay: (v) => '${v.round()} days',
            ),
          const SizedBox(height: 8),
          _buildActionTile(
            Icons.backup,
            'Backup All Recordings',
            'Export all recordings to device storage',
            _backupRecordings,
          ),
          _buildActionTile(
            Icons.folder_open,
            'Open Recordings Folder',
            'Browse recording files',
            _openRecordingsFolder,
          ),
          _buildSectionHeader('About'),
          _buildInfoTile('Version', '1.0.0'),
          _buildInfoTile('Database', 'SQLite (Local)'),
          _buildInfoTile('Storage', 'On-device only'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.accentBlue,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String Function(double)? valueDisplay,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                ),
                Text(
                  valueDisplay != null ? valueDisplay(value) : value.toStringAsFixed(1),
                  style: const TextStyle(color: AppTheme.accentBlue, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                activeTrackColor: AppTheme.accentBlue,
                inactiveTrackColor: AppTheme.textSecondary.withAlpha(50),
                thumbColor: AppTheme.accentBlue,
              ),
              child: Slider(value: value, min: min, max: max, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))
            : null,
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.accentBlue,
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accentBlue),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
        tileColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            Text(value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _backupRecordings() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(p.join(appDir.path, 'sleep_talk_recordings'));
      final dbPath = p.join(appDir.path, 'databases', 'sleep_talk.db');

      if (!await recordingsDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No recordings to backup')),
          );
        }
        return;
      }

      final files = await recordingsDir.list().toList();
      final xFiles = files
          .whereType<File>()
          .map((f) => XFile(f.path))
          .toList();

      if (await File(dbPath).exists()) {
        xFiles.add(XFile(dbPath));
      }

      if (xFiles.isNotEmpty) {
        await Share.shareXFiles(xFiles, subject: 'Sleep Talk Backup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  Future<void> _openRecordingsFolder() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(p.join(appDir.path, 'sleep_talk_recordings'));

      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recordings: ${recordingsDir.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {}
  }
}