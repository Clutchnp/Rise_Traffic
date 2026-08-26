import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/models/hotspot.dart';
import 'package:frontend/widgets/kpi_cards.dart';

class HotspotsScreen extends StatelessWidget {
  const HotspotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final critical = sampleHotspots
        .where((h) => h.severity == HotspotSeverity.critical)
        .length;
    final avgScore = sampleHotspots
            .map((h) => h.congestionScore)
            .reduce((a, b) => a + b) /
        sampleHotspots.length;
    final worst = sampleHotspots
        .reduce((a, b) => a.congestionScore > b.congestionScore ? a : b);

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Congestion Hotspots',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Zones ranked by real-time congestion intensity',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1200
                    ? 4
                    : constraints.maxWidth >= 700
                        ? 2
                        : 1;
                final cardWidth =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: TrafficMetricCard(
                        label: 'ZONES MONITORED',
                        value: '${sampleHotspots.length}',
                        subtitle: 'Across the network',
                        icon: Icons.location_city_outlined,
                        accent: AppColors.accent,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: TrafficMetricCard(
                        label: 'CRITICAL ZONES',
                        value: '$critical',
                        subtitle: 'Score above 85',
                        icon: Icons.local_fire_department_outlined,
                        accent: AppColors.trafficCritical,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: TrafficMetricCard(
                        label: 'AVG CONGESTION SCORE',
                        value: avgScore.toStringAsFixed(0),
                        subtitle: 'Out of 100',
                        icon: Icons.speed_outlined,
                        accent: AppColors.trafficModerate,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: TrafficMetricCard(
                        label: 'MOST CONGESTED',
                        value: worst.name,
                        subtitle: '${worst.congestionScore.toStringAsFixed(0)} score',
                        icon: Icons.priority_high,
                        accent: AppColors.trafficHigh,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Ranked Zones',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100 ? 2 : 1;
                final cardWidth = columns == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(sampleHotspots.length, (i) {
                    return SizedBox(
                      width: cardWidth,
                      child: _HotspotCard(rank: i + 1, hotspot: sampleHotspots[i]),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HotspotCard extends StatelessWidget {
  final int rank;
  final Hotspot hotspot;

  const _HotspotCard({required this.rank, required this.hotspot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotspot.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hotspot.road,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                hotspot.trendingUp ? Icons.trending_up : Icons.trending_down,
                size: 18,
                color: hotspot.trendingUp
                    ? AppColors.trafficCritical
                    : AppColors.trafficNormal,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hotspot.congestionScore.toStringAsFixed(0),
                style: TextStyle(
                  color: hotspot.severity.color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  '/ 100',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: hotspot.severity.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hotspot.severity.label,
                  style: TextStyle(
                    color: hotspot.severity.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (hotspot.congestionScore / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(hotspot.severity.color),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Avg Delay',
                  value: '${hotspot.avgDelayMinutes} min',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Vehicles/hr',
                  value: '${hotspot.vehicleCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
