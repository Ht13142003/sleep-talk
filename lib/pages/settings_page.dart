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
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader('音频设置'),
          _buildSliderTile(
            'VAD 灵敏度',
            '值越低对声音越敏感',
            _vadThreshold,
            0.005,
            0.1,
            (value) => setState(() => _vadThreshold = value),
            valueDisplay: (v) => v.toStringAsFixed(3),
          ),
          _buildSliderTile(
            '静音时长',
            '停止录音前的静音等待时间',
            _silenceDuration,
            0.5,
            5.0,
            (value) => setState(() => _silenceDuration = value),
            valueDisplay: (v) => '${v.toStringAsFixed(1)}秒',
          ),
          _buildSliderTile(
            '采样率',
            '录音质量',
            _sampleRate.toDouble(),
            22050,
            48000,
            (value) => setState(() => _sampleRate = value.round()),
            valueDisplay: (v) => '${(v / 1000).toStringAsFixed(1)}kHz',
          ),
          _buildSliderTile(
            '比特率',
            '音频编码质量',
            _bitRate.toDouble(),
            64,
            256,
            (value) => setState(() => _bitRate = value.round()),
            valueDisplay: (v) => '${v.round()}kbps',
          ),
          _buildSectionHeader('存储'),
          _buildSwitchTile(
            '自动删除旧录音',
            '删除超过 $_autoDeleteDays 天的录音',
            _autoDeleteOld,
            (value) => setState(() => _autoDeleteOld = value),
          ),
          if (_autoDeleteOld)
            _buildSliderTile(
              '保留天数',
              '自动删除前的保留天数',
              _autoDeleteDays.toDouble(),
              7,
              90,
              (value) => setState(() => _autoDeleteDays = value.round()),
              valueDisplay: (v) => '${v.round()} 天',
            ),
          const SizedBox(height: 8),
          _buildActionTile(
            Icons.backup,
            '备份所有录音',
            '导出录音到设备存储',
            _backupRecordings,
          ),
          _buildActionTile(
            Icons.folder_open,
            '打开录音文件夹',
            '浏览录音文件',
            _openRecordingsFolder,
          ),
          _buildSectionHeader('关于'),
          _buildInfoTile('版本', '1.0.0'),
          _buildInfoTile('数据库', 'SQLite（本地）'),
          _buildInfoTile('存储', '仅设备本地'),
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
            const SnackBar(content: Text('没有可备份的录音')),
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
        await Share.shareXFiles(xFiles, subject: '梦话录音备份');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败: $e')),
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
              content: Text('录音目录: ${recordingsDir.path}'),
              duration: const Duration(seconds: 4),
            ),
          );
      }
    } catch (_) {}
  }
}