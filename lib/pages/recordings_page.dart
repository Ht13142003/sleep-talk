import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/recording_model.dart';
import '../services/audio_player_service.dart';
import '../widgets/recording_tile.dart';
import '../utils/app_theme.dart';

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  List<RecordingModel> _recordings = [];
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  String? _playingFile;

  double _playbackRate = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _nowPlayingFile;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
    _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed && mounted) {
        setState(() {
          _playingFile = null;
          _nowPlayingFile = null;
        });
      }
    });
  }

  Future<void> _loadRecordings() async {
    final recordings = await _dbHelper.getAllRecordings();
    if (mounted) setState(() => _recordings = recordings);
  }

  Future<void> _togglePlayPause(RecordingModel recording) async {
    if (_playingFile == recording.filePath) {
      await _audioPlayer.pause();
      setState(() => _playingFile = null);
      return;
    }
    await _audioPlayer.play(recording.filePath);
    setState(() {
      _playingFile = recording.filePath;
      _nowPlayingFile = recording.filePath;
    });
  }

  Future<void> _deleteRecording(RecordingModel recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除录音'),
        content: Text('删除"${recording.fileName}"？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await File(recording.filePath).delete();
      } catch (_) {}
      await _dbHelper.deleteRecording(recording.id!);
      if (_playingFile == recording.filePath) {
        await _audioPlayer.stop();
        setState(() => _playingFile = null);
      }
      _loadRecordings();
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('删除选中的 ${_selectedIds.length} 条录音？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final recording in _recordings) {
        if (_selectedIds.contains(recording.id)) {
          try {
            await File(recording.filePath).delete();
          } catch (_) {}
        }
      }
      await _dbHelper.deleteMultipleRecordings(_selectedIds.toList());
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
      _loadRecordings();
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(int id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  Future<void> _seekAudio(double value) async {
    final position = Duration(milliseconds: value.round());
    await _audioPlayer.seek(position);
  }

  void _changePlaybackRate(double rate) {
    _playbackRate = rate;
    _audioPlayer.setPlaybackRate(rate);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '已选 ${_selectedIds.length} 项' : '录音'),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectionMode = false;
                  _selectedIds.clear();
                }),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.dangerRed),
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_nowPlayingFile != null) _buildNowPlayingBar(),
          Expanded(
            child: _recordings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_none, size: 64, color: AppTheme.textSecondary.withAlpha(80)),
                        const SizedBox(height: 16),
                        const Text(
                          '暂无录音',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '录制的梦话将显示在这里',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: _recordings.length,
                    itemBuilder: (context, index) {
                      final recording = _recordings[index];
                      return RecordingTile(
                        recording: recording,
                        isPlaying: _playingFile == recording.filePath,
                        isSelected: _selectedIds.contains(recording.id),
                        selectionMode: _selectionMode,
                        onTap: () => _selectionMode
                            ? _toggleSelection(recording.id!)
                            : _enterSelectionMode(recording.id!),
                        onPlayPause: () => _togglePlayPause(recording),
                        onDelete: () => _deleteRecording(recording),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingBar() {
    final positionText = DateFormat('mm:ss').format(
      DateTime(0).add(_currentPosition),
    );
    final durationText = DateFormat('mm:ss').format(
      DateTime(0).add(_totalDuration),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: AppTheme.accentBlue.withAlpha(60))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                positionText,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: AppTheme.accentBlue,
                    inactiveTrackColor: AppTheme.textSecondary.withAlpha(50),
                    thumbColor: AppTheme.accentBlue,
                  ),
                  child: Slider(
                    value: _currentPosition.inMilliseconds.toDouble(),
                    max: _totalDuration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                    onChanged: _seekAudio,
                  ),
                ),
              ),
              Text(
                durationText,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _rateButton(0.5),
              _rateButton(0.75),
              _rateButton(1.0),
              _rateButton(1.5),
              _rateButton(2.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateButton(double rate) {
    final isSelected = _playbackRate == rate;
    return GestureDetector(
      onTap: () => _changePlaybackRate(rate),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentBlue.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary.withAlpha(60),
          ),
        ),
        child: Text(
          '${rate}x',
          style: TextStyle(
            color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}