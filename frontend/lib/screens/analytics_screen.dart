import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/data/traffic_state.dart';
import 'package:frontend/models/traffic_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/congestion_chart.dart';
import 'package:frontend/widgets/kpi_cards.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  VehicleComposition _composition = const VehicleComposition(
    carsAndCabs: 48,
    twoWheelers: 34,
    busesAndTransit: 12,
    commercialFreight: 6,
  );
  List<CorridorThroughput> _throughputs = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final comp = await apiService.fetchVehicleComposition();
    final tp = await apiService.fetchCorridorThroughput();
    if (mounted) {
      setState(() {
        _composition = comp;
        _throughputs = tp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: trafficState,
      builder: (context, _) {
        final kpis = trafficState.kpis;

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Traffic Intelligence & Analytics',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Corridor performance telemetry, volume throughput, and vehicle classification',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // KPI METRICS
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1100 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);
                    final cardWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: TrafficMetricCard(
                            label: 'DAILY VEHICLE VOLUME',
                            value: kpis.dailyVehicleVolume,
                            subtitle: '+8.4% vs monthly avg',
                            icon: Icons.directions_car_outlined,
                            accent: AppColors.accent,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: TrafficMetricCard(
                            label: 'PEAK FLOW RATE',
                            value: kpis.peakFlowRate,
                            subtitle: 'Observed at ${kpis.peakFlowTime}',
                            icon: Icons.speed_outlined,
                            accent: AppColors.trafficCritical,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: TrafficMetricCard(
                            label: 'AVG CORRIDOR SPEED',
                            value: kpis.avgCorridorSpeed,
                            subtitle: kpis.speedDelta,
                            icon: Icons.trending_up,
                            accent: AppColors.trafficNormal,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: TrafficMetricCard(
                            label: 'CARBON SAVINGS',
                            value: kpis.carbonSavingsTons,
                            subtitle: 'Reduced idle emissions today',
                            icon: Icons.eco_outlined,
                            accent: AppColors.trafficNormal,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 24H CONGESTION TREND
                const CongestionChart(),

                const SizedBox(height: 20),

                // VEHICLE CLASSIFICATION & CORRIDOR BREAKDOWN
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _VehicleCompositionCard(composition: _composition)),
                          const SizedBox(width: 16),
                          Expanded(flex: 5, child: _CorridorThroughputCard(throughputs: _throughputs)),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _VehicleCompositionCard(composition: _composition),
                        const SizedBox(height: 16),
                        _CorridorThroughputCard(throughputs: _throughputs),
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

class _VehicleCompositionCard extends StatelessWidget {
  final VehicleComposition composition;

  const _VehicleCompositionCard({required this.composition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Classification',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Distribution of monitored traffic modalities',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 18),
          _ModalityBar(label: 'Cars & Cabs', percentage: composition.carsAndCabs, color: AppColors.accent),
          const SizedBox(height: 12),
          _ModalityBar(label: 'Two-Wheelers & Bikes', percentage: composition.twoWheelers, color: AppColors.trafficNormal),
          const SizedBox(height: 12),
          _ModalityBar(label: 'Buses & Public Transit', percentage: composition.busesAndTransit, color: AppColors.trafficModerate),
          const SizedBox(height: 12),
          _ModalityBar(label: 'Commercial Freight & Trucks', percentage: composition.commercialFreight, color: AppColors.trafficHigh),
        ],
      ),
    );
  }
}

class _ModalityBar extends StatelessWidget {
  final String label;
  final int percentage;
  final Color color;

  const _ModalityBar({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text('$percentage%', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100.0,
            minHeight: 8,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _CorridorThroughputCard extends StatelessWidget {
  final List<CorridorThroughput> throughputs;

  const _CorridorThroughputCard({required this.throughputs});

  @override
  Widget build(BuildContext context) {
    final list = throughputs.isNotEmpty ? throughputs : const [
      CorridorThroughput(corridor: 'Silk Board Junction', volume: '54,200 veh', status: 'Near Capacity', congestionLevel: 'critical', averageSpeedKmh: 14.2),
      CorridorThroughput(corridor: 'Marathahalli Bridge', volume: '38,900 veh', status: 'Moderate Load', congestionLevel: 'high', averageSpeedKmh: 27.8),
      CorridorThroughput(corridor: 'Koramangala 80ft Road', volume: '31,400 veh', status: 'Stable Flow', congestionLevel: 'moderate', averageSpeedKmh: 19.4),
      CorridorThroughput(corridor: 'Hebbal Flyover Corridor', volume: '23,750 veh', status: 'Optimal Flow', congestionLevel: 'normal', averageSpeedKmh: 38.2),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Corridor Volume Throughput',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '24-hour total flow across major arteries',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 18),
          ...list.take(4).map((tp) {
            Color color = AppColors.trafficNormal;
            if (tp.congestionLevel == 'critical') {
              color = AppColors.trafficCritical;
            } else if (tp.congestionLevel == 'high') {
              color = AppColors.trafficHigh;
            } else if (tp.congestionLevel == 'moderate') {
              color = AppColors.trafficModerate;
            }

            return _ThroughputRow(
              corridor: tp.corridor,
              volume: tp.volume,
              status: tp.status,
              color: color,
            );
          }),
        ],
      ),
    );
  }
}

class _ThroughputRow extends StatelessWidget {
  final String corridor;
  final String volume;
  final String status;
  final Color color;

  const _ThroughputRow({
    required this.corridor,
    required this.volume,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(corridor, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(volume, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
