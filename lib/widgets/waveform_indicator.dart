import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class WaveformIndicator extends StatelessWidget {
  final List<double> amplitudes;

  const WaveformIndicator({
    super.key,
    required this.amplitudes,
  });

  @override
  Widget build(BuildContext context) {
    if (amplitudes.isEmpty) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: Text('无波形数据', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          amplitudes.length.clamp(0, 50),
          (index) {
            final amp = amplitudes[index].clamp(0.0, 1.0);
            final height = (amp * 38) + 2;
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                color: AppTheme.waveColor.withAlpha((150 + (amp * 105)).round()),
              ),
            );
          },
        ),
      ),
    );
  }
}