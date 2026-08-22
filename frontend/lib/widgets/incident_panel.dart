import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';

class IncidentPanel extends StatelessWidget {
  const IncidentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Incidents',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Requires operator attention',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.trafficCritical.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '12 ACTIVE',
                    style: TextStyle(
                      color: AppColors.trafficCritical,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            color: AppColors.border,
          ),

          // Incident list
          Expanded(
            child: SingleChildScrollView(
              child: const Column(
                children: [
                  _IncidentItem(
                    severity: IncidentSeverity.critical,
                    title: 'Major congestion',
                    location: 'Silk Board Junction',
                    time: '2 min ago',
                  ),
              
                  _IncidentItem(
                    severity: IncidentSeverity.high,
                    title: 'Traffic obstruction',
                    location: 'Outer Ring Road',
                    time: '6 min ago',
                  ),
              
                  _IncidentItem(
                    severity: IncidentSeverity.moderate,
                    title: 'Slow moving traffic',
                    location: 'Koramangala',
                    time: '11 min ago',
                  ),
              
                  _IncidentItem(
                    severity: IncidentSeverity.moderate,
                    title: 'Vehicle breakdown',
                    location: 'MG Road',
                    time: '18 min ago',
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('View All Incidents'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum IncidentSeverity {
  critical,
  high,
  moderate,
}

class _IncidentItem extends StatelessWidget {
  final IncidentSeverity severity;
  final String title;
  final String location;
  final String time;

  const _IncidentItem({
    required this.severity,
    required this.title,
    required this.location,
    required this.time,
  });

  Color get severityColor {
    switch (severity) {
      case IncidentSeverity.critical:
        return AppColors.trafficCritical;

      case IncidentSeverity.high:
        return AppColors.trafficHigh;

      case IncidentSeverity.moderate:
        return AppColors.trafficModerate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: severityColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  location,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            time,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
