import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';

class CongestionChart extends StatelessWidget {
  const CongestionChart({super.key});

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

          AspectRatio(
            aspectRatio: 16 / 7,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'CONGESTION CHART',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
