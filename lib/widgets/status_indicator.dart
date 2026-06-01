import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final bool isActive;
  final double amplitude;
  final String statusText;

  const StatusIndicator({
    super.key,
    required this.isActive,
    required this.amplitude,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPulseCircle(),
        const SizedBox(height: 24),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 16,
            color: isActive ? AppTheme.activeGreen : AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _buildAmplitudeBar(),
      ],
    );
  }

  Widget _buildPulseCircle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: isActive ? value : 1.0,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.activeGreen.withAlpha(30) : AppTheme.textSecondary.withAlpha(30),
              border: Border.all(
                color: isActive ? AppTheme.activeGreen : AppTheme.textSecondary,
                width: 3,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.activeGreen.withAlpha(60),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              isActive ? Icons.mic : Icons.mic_none,
              size: 48,
              color: isActive ? AppTheme.activeGreen : AppTheme.textSecondary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmplitudeBar() {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: AppTheme.cardDark,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (amplitude * 10).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [AppTheme.activeGreen, AppTheme.accentTeal],
            ),
          ),
        ),
      ),
    );
  }
}