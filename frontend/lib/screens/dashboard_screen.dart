import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/data/traffic_state.dart';
import 'package:frontend/models/traffic_model.dart';
import 'package:frontend/widgets/incident_panel.dart';
import 'package:frontend/widgets/kpi_cards.dart';
import 'package:frontend/widgets/map.dart';
import 'package:frontend/widgets/congestion_chart.dart';
import 'package:frontend/widgets/hotspot_panel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: trafficState,
      builder: (context, _) {
        final kpis = trafficState.kpis;
        final cameras = trafficState.cameras;
        final onlineCount = cameras.where((c) => c.isOnline).length;
        final critHotspotCount = cameras.where((c) => c.congestionLevel == CongestionLevel.critical).length;
        final highHotspotCount = cameras.where((c) => c.congestionLevel == CongestionLevel.high).length;
        final totalHotspots = critHotspotCount + highHotspotCount;

        Color statusColor = AppColors.trafficModerate;
        if (kpis.trafficStatus.toLowerCase() == 'critical') {
          statusColor = AppColors.trafficCritical;
        } else if (kpis.trafficStatus.toLowerCase() == 'high') {
          statusColor = AppColors.trafficHigh;
        } else if (kpis.trafficStatus.toLowerCase() == 'normal') {
          statusColor = AppColors.trafficNormal;
        }

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Summary Cards
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
                            label: 'TRAFFIC STATUS',
                            value: kpis.trafficStatus,
                            subtitle: 'Across $onlineCount monitored corridors',
                            icon: Icons.traffic_outlined,
                            accent: statusColor,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: TrafficMetricCard(
                            label: 'ACTIVE INCIDENTS',
                            value: '${trafficState.incidents.length}',
                            subtitle: '${kpis.criticalIncidents} critical priority',
                            icon: Icons.warning_amber_outlined,
                            accent: AppColors.trafficHigh,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: TrafficMetricCard(
                            label: 'CONGESTION HOTSPOTS',
                            value: '$totalHotspots',
                            subtitle: '$critHotspotCount critical junction(s)',
                            icon: Icons.local_fire_department_outlined,
                            accent: AppColors.trafficCritical,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: TrafficMetricCard(
                            label: 'RESPONSE STATUS',
                            value: kpis.responseStatus,
                            subtitle: 'Units responding normally',
                            icon: Icons.shield_outlined,
                            accent: AppColors.trafficNormal,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 30-SECOND SHIFTING CONGESTION LIVE BANNER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: AppColors.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Live ML Simulation: 30-second rolling congestion surge active. Peak load shifts across corridors automatically.',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '30s DEMO CYCLE',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ROW 2: Map + Incident Panel
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _DashboardMapCard(
                              height: 420,
                              cameras: cameras,
                              selectedCameraId: trafficState.selectedCamera.id,
                              onCameraSelected: (cam) => trafficState.selectCamera(cam),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            flex: 4,
                            child: IncidentPanel(),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _DashboardMapCard(
                          height: 320,
                          cameras: cameras,
                          selectedCameraId: trafficState.selectedCamera.id,
                          onCameraSelected: (cam) => trafficState.selectCamera(cam),
                        ),
                        const SizedBox(height: 16),
                        const IncidentPanel(),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ROW 3: Congestion Trend Chart + Hotspot Panel
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 900) {
                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: CongestionChart(),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: HotspotPanel(),
                          ),
                        ],
                      );
                    }

                    return const Column(
                      children: [
                        CongestionChart(),
                        SizedBox(height: 16),
                        HotspotPanel(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardMapCard extends StatelessWidget {
  final double height;
  final List<CameraNode> cameras;
  final String selectedCameraId;
  final ValueChanged<CameraNode> onCameraSelected;

  const _DashboardMapCard({
    required this.height,
    required this.cameras,
    required this.selectedCameraId,
    required this.onCameraSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Live Traffic Map',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.systemOnline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 6, color: AppColors.systemOnline),
                      const SizedBox(width: 5),
                      Text(
                        '${cameras.length} BLR CORRIDORS',
                        style: const TextStyle(
                          color: AppColors.systemOnline,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TrafficMapPanel(
              cameras: cameras,
              selectedCameraId: selectedCameraId,
              onCameraSelected: onCameraSelected,
            ),
          ),
        ],
      ),
    );
  }
}
