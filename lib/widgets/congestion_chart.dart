import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/widgets/charts/simple_line_chart.dart';

class CongestionChart extends StatelessWidget {
  const CongestionChart({super.key});

  static const _hourLabels = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];
  static const _congestionValues = [22.0, 18.0, 64.0, 71.0, 68.0, 45.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Congestion Trend',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Traffic intensity over the last 24 hours',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 20),

          const SimpleLineChart(
            values: _congestionValues,
            labels: _hourLabels,
            color: AppColors.accent,
            height: 180,
          ),
        ],
      ),
    );
  }
}
