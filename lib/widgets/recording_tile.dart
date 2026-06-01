import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recording_model.dart';
import '../utils/app_theme.dart';
import 'waveform_indicator.dart';

class RecordingTile extends StatelessWidget {
  final RecordingModel recording;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onDelete;
  final bool selectionMode;

  const RecordingTile({
    super.key,
    required this.recording,
    required this.isPlaying,
    required this.isSelected,
    required this.onTap,
    required this.onPlayPause,
    required this.onDelete,
    this.selectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('recording_${recording.id}'),
      direction: selectionMode ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Recording'),
            content: const Text('Are you sure you want to delete this recording?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: AppTheme.dangerRed)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.dangerRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: selectionMode ? null : onTap,
        onLongPress: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentBlue.withAlpha(40) : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppTheme.accentBlue, width: 1.5)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                    ),
                  ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentBlue.withAlpha(30),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: AppTheme.accentBlue,
                      size: 24,
                    ),
                    onPressed: onPlayPause,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateTime(recording.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(recording.durationMs),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      WaveformIndicator(
                        amplitudes: _generateDummyAmplitudes(),
                      ),
                    ],
                  ),
                ),
                if (!selectionMode)
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => _showOptionsMenu(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _menuItem(Icons.info_outline, 'Details', () {
              Navigator.pop(ctx);
              _showDetailsDialog(context);
            }),
            _menuItem(Icons.delete_outline, 'Delete', () {
              Navigator.pop(ctx);
              onDelete();
            }, isDestructive: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.dangerRed : AppTheme.textPrimary),
      title: Text(label, style: TextStyle(color: isDestructive ? AppTheme.dangerRed : AppTheme.textPrimary)),
      onTap: onTap,
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recording Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('File', recording.fileName),
            _detailRow('Date', _formatDateTime(recording.createdAt)),
            _detailRow('Duration', _formatDuration(recording.durationMs)),
            _detailRow('Size', _formatFileSize(recording.fileSizeBytes)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy/MM/dd HH:mm:ss').format(dt);
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  List<double> _generateDummyAmplitudes() {
    return List.generate(30, (i) => (0.3 + (i % 7) * 0.1).clamp(0.0, 1.0));
  }
}