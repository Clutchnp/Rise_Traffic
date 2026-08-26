import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';

class HotspotPanel extends StatelessWidget {
  const HotspotPanel({super.key});

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
            'Congestion Hotspots',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Zones requiring attention',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 18),

          const _Hotspot(
            name: 'Silk Board',
            status: 'Critical',
            color: AppColors.trafficCritical,
          ),

          const _Hotspot(
            name: 'Marathahalli',
            status: 'High',
            color: AppColors.trafficHigh,
          ),

          const _Hotspot(
            name: 'Koramangala',
            status: 'Moderate',
            color: AppColors.trafficModerate,
          ),

          const _Hotspot(
            name: 'Hebbal',
            status: 'Normal',
            color: AppColors.trafficNormal,
          ),
        ],
      ),
    );
  }
}

class _Hotspot extends StatelessWidget {
  final String name;
  final String status;
  final Color color;

  const _Hotspot({
    required this.name,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
