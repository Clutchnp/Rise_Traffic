import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/widgets/incident_panel.dart';
import 'package:frontend/widgets/kpi_cards.dart';
import 'package:frontend/widgets/map.dart';
import 'package:frontend/widgets/congestion_chart.dart';
import 'package:frontend/widgets/hotspot_panel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────
            // ROW 1 — KPI CARDS
            // ─────────────────────────────────────────

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
                      child: const TrafficMetricCard(
                        label: 'TRAFFIC STATUS',
                        value: 'Moderate',
                        subtitle: 'Across monitored zones',
                        icon: Icons.traffic_outlined,
                        accent: AppColors.trafficModerate,
                      ),
                    ),

                    SizedBox(
                      width: cardWidth,
                      child: const TrafficMetricCard(
                        label: 'ACTIVE INCIDENTS',
                        value: '12',
                        subtitle: '3 require immediate attention',
                        icon: Icons.warning_amber_outlined,
                        accent: AppColors.trafficHigh,
                      ),
                    ),

                    SizedBox(
                      width: cardWidth,
                      child: const TrafficMetricCard(
                        label: 'CONGESTION HOTSPOTS',
                        value: '8',
                        subtitle: '2 critical zones',
                        icon: Icons.local_fire_department_outlined,
                        accent: AppColors.trafficCritical,
                      ),
                    ),

                    SizedBox(
                      width: cardWidth,
                      child: const TrafficMetricCard(
                        label: 'RESPONSE STATUS',
                        value: '98.4%',
                        subtitle: 'Units responding normally',
                        icon: Icons.shield_outlined,
                        accent: AppColors.trafficNormal,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────
            // ROW 2 — LIVE MAP + INCIDENTS
            // ─────────────────────────────────────────

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(
                          flex: 7,
                          child: TrafficMapPanel(),
                        ),
                    
                        const SizedBox(width: 16),
                    
                        const Expanded(
                          flex: 3,
                          child: IncidentPanel(),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    const TrafficMapPanel(),

                    const SizedBox(height: 16),

                    const IncidentPanel(),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────
            // ROW 3 — CONGESTION + HOTSPOTS
            // ─────────────────────────────────────────

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 7,
                        child: CongestionChart(),
                      ),

                      const SizedBox(width: 16),

                      const Expanded(
                        flex: 3,
                        child: HotspotPanel(),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    const CongestionChart(),

                    const SizedBox(height: 16),

                    const HotspotPanel(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
