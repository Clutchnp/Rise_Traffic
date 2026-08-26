import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/widgets/kpi_cards.dart';
import 'package:frontend/widgets/charts/simple_line_chart.dart';
import 'package:frontend/widgets/charts/simple_bar_chart.dart';
import 'package:frontend/widgets/charts/simple_donut_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const _hourLabels = ['6am', '9am', '12pm', '3pm', '6pm', '9pm'];
  static const _congestionTrend = [28.0, 52.0, 61.0, 58.0, 82.0, 46.0];

  static const _zoneIncidents = [
    BarDatum(label: 'Silk Board', value: 14, color: AppColors.trafficCritical),
    BarDatum(label: 'ORR', value: 11, color: AppColors.trafficHigh),
    BarDatum(label: 'Koramangala', value: 8, color: AppColors.trafficModerate),
    BarDatum(label: 'Hebbal', value: 6, color: AppColors.trafficModerate),
    BarDatum(label: 'Whitefield', value: 4, color: AppColors.trafficNormal),
  ];

  static const _incidentTypes = [
    DonutDatum(label: 'Congestion', value: 38, color: AppColors.trafficHigh),
    DonutDatum(label: 'Accidents', value: 22, color: AppColors.trafficCritical),
    DonutDatum(label: 'Breakdowns', value: 18, color: AppColors.trafficModerate),
    DonutDatum(label: 'Infrastructure', value: 12, color: AppColors.accent),
    DonutDatum(label: 'Violations', value: 10, color: AppColors.trafficNormal),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics & Insights',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Traffic trends and predictive performance across the network',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            _buildKpiRow(),
            const SizedBox(height: 20),
            _buildPanel(
              title: 'Congestion Trend',
              subtitle: 'Average congestion intensity by time of day',
              child: const SimpleLineChart(
                values: _congestionTrend,
                labels: _hourLabels,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildPanel(
                            title: 'Incidents by Zone',
                            subtitle: 'Last 7 days',
                            child: const SimpleBarChart(data: _zoneIncidents),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: _buildPanel(
                            title: 'Incident Breakdown',
                            subtitle: 'By category',
                            child: const SimpleDonutChart(data: _incidentTypes),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    _buildPanel(
                      title: 'Incidents by Zone',
                      subtitle: 'Last 7 days',
                      child: const SimpleBarChart(data: _zoneIncidents),
                    ),
                    const SizedBox(height: 16),
                    _buildPanel(
                      title: 'Incident Breakdown',
                      subtitle: 'By category',
                      child: const SimpleDonutChart(data: _incidentTypes),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(
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
              child: const TrafficMetricCard(
                label: 'INCIDENTS (7D)',
                value: '86',
                subtitle: '12% fewer than last week',
                icon: Icons.insights_outlined,
                accent: AppColors.accent,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const TrafficMetricCard(
                label: 'AVG CONGESTION REDUCTION',
                value: '17%',
                subtitle: 'After signal optimization',
                icon: Icons.trending_down,
                accent: AppColors.trafficNormal,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const TrafficMetricCard(
                label: 'PEAK HOUR',
                value: '6 – 7 PM',
                subtitle: 'Highest average intensity',
                icon: Icons.schedule_outlined,
                accent: AppColors.trafficModerate,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const TrafficMetricCard(
                label: 'PREDICTION ACCURACY',
                value: '91.2%',
                subtitle: 'CatBoost congestion model',
                icon: Icons.model_training_outlined,
                accent: AppColors.trafficCritical,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
