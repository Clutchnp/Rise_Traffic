import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/data/traffic_state.dart';
import 'package:frontend/models/traffic_model.dart';

class HotspotsScreen extends StatelessWidget {
  const HotspotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: trafficState,
      builder: (context, _) {
        final hotspots = trafficState.hotspots;
        final critCount = hotspots
            .where((h) => h.congestionLevel == CongestionLevel.critical)
            .length;

        final double avgScore = hotspots.isNotEmpty
            ? (hotspots.fold<double>(0.0, (sum, h) => sum + (h.congestionScore > 0 ? h.congestionScore : (h.occupancy * 0.5 + 0.3))) /
                    hotspots.length) *
                100
            : 0.0;

        final worst = hotspots.isNotEmpty ? hotspots.first : null;
        final surgeHotspot = hotspots.firstWhere(
          (h) => h.isSurgeActive,
          orElse: () => hotspots.isNotEmpty ? hotspots.first : hotspots.first,
        );

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Congestion Hotspots & Signal Control',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Real-time bottleneck classification, direct signal phase switching, and dynamic corridor balancing',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.trafficNormal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.trafficNormal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.trafficNormal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Adaptive Control Active',
                            style: TextStyle(
                              color: AppColors.trafficNormal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 30-SECOND SHIFTING CONGESTION LIVE BANNER
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.trafficCritical.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.trafficCritical.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync_alt,
                        color: AppColors.trafficCritical,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dynamic Load Simulation: Peak volume currently on ${surgeHotspot.name}. Rotates across corridors every 30 seconds.',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.trafficCritical,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '30s CYCLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // SUMMARY METRICS STRIP
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 4
                        : (constraints.maxWidth >= 600 ? 2 : 1);
                    final cardWidth =
                        (constraints.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _MetricCard(
                            label: 'MONITORED BOTTLENECKS',
                            value: '${hotspots.length}',
                            color: AppColors.accent,
                            icon: Icons.traffic,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _MetricCard(
                            label: 'CRITICAL PRIORITY',
                            value: '$critCount',
                            color: AppColors.trafficCritical,
                            icon: Icons.warning_amber_rounded,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _MetricCard(
                            label: 'AVG CONGESTION SCORE',
                            value: '${avgScore.toStringAsFixed(0)} / 100',
                            color: AppColors.trafficModerate,
                            icon: Icons.speed,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _MetricCard(
                            label: 'WORST BOTTLENECK',
                            value: worst != null ? worst.name.split(' ').first : 'N/A',
                            color: AppColors.trafficHigh,
                            icon: Icons.priority_high,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text(
                  'Ranked Bottlenecks & Signal Controllers',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),

                // HOTSPOT CARDS
                if (hotspots.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Text(
                        'No active bottlenecks detected.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: hotspots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final node = hotspots[index];
                      return _HotspotDetailCard(
                        rank: index + 1,
                        node: node,
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HotspotDetailCard extends StatefulWidget {
  final int rank;
  final HotspotDetail node;

  const _HotspotDetailCard({
    required this.rank,
    required this.node,
  });

  @override
  State<_HotspotDetailCard> createState() => _HotspotDetailCardState();
}

class _HotspotDetailCardState extends State<_HotspotDetailCard> {
  bool _isSwitching = false;

  Future<void> _handleSignalSwitch(String phase, int duration) async {
    setState(() => _isSwitching = true);
    final success = await trafficState.switchSignal(
      widget.node.cameraId,
      phase: phase,
      greenDurationSec: duration,
      mode: 'MANUAL',
    );
    if (mounted) {
      setState(() => _isSwitching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.surfaceElevated : AppColors.trafficCritical,
          content: Text(
            success
                ? 'Signal on ${widget.node.name} switched to $phase (${duration}s)'
                : 'Failed to switch signal on ${widget.node.name}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openCustomSwitchDialog() {
    String selectedPhase = widget.node.signalPhase;
    int duration = widget.node.greenTimeSec;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Row(
            children: [
              const Icon(Icons.traffic, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Signal Switcher — ${widget.node.name}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Target Signal Phase:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PhaseChoiceChip(
                      label: 'North-South Green',
                      phaseKey: 'NORTH_SOUTH_GREEN',
                      selected: selectedPhase == 'NORTH_SOUTH_GREEN',
                      onSelected: () => setDialogState(() => selectedPhase = 'NORTH_SOUTH_GREEN'),
                    ),
                    _PhaseChoiceChip(
                      label: 'East-West Green',
                      phaseKey: 'EAST_WEST_GREEN',
                      selected: selectedPhase == 'EAST_WEST_GREEN',
                      onSelected: () => setDialogState(() => selectedPhase = 'EAST_WEST_GREEN'),
                    ),
                    _PhaseChoiceChip(
                      label: 'Priority Clearance',
                      phaseKey: 'PRIORITY_CLEARANCE',
                      selected: selectedPhase == 'PRIORITY_CLEARANCE',
                      onSelected: () => setDialogState(() => selectedPhase = 'PRIORITY_CLEARANCE'),
                    ),
                    _PhaseChoiceChip(
                      label: 'All-Red Emergency',
                      phaseKey: 'ALL_RED_EMERGENCY',
                      selected: selectedPhase == 'ALL_RED_EMERGENCY',
                      onSelected: () => setDialogState(() => selectedPhase = 'ALL_RED_EMERGENCY'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Green Phase Timer:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${duration}s',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: duration.toDouble(),
                  min: 15,
                  max: 90,
                  divisions: 15,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.border,
                  label: '${duration}s',
                  onChanged: (val) => setDialogState(() => duration = val.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _handleSignalSwitch(selectedPhase, duration);
              },
              child: const Text('Apply Signal Switch'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final int scoreInt = (node.congestionScore > 0
            ? (node.congestionScore * 100).round()
            : (node.occupancy * 70 + 20).round())
        .clamp(5, 100);

    final isSurging = node.isSurgeActive;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSurging
              ? AppColors.trafficCritical
              : AppColors.border,
          width: isSurging ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW: RANK, NAME, SEVERITY BADGE, SURGE INDICATOR
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${widget.rank}',
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            node.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isSurging) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.trafficCritical,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '⚡ 30s SURGE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.cameraId,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: node.congestionLevel.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  node.congestionLevel.displayName.toUpperCase(),
                  style: TextStyle(
                    color: node.congestionLevel.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // CONGESTION SCORE BAR
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$scoreInt',
                style: TextStyle(
                  color: node.congestionLevel.color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  '/ 100 Score',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
              const Spacer(),
              Text(
                'Queue: ${node.queueLength} vehicles',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (scoreInt / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(node.congestionLevel.color),
            ),
          ),
          const SizedBox(height: 14),

          // TELEMETRY STATS GRID
          Row(
            children: [
              Expanded(
                child: _DataPill(
                  label: 'VEHICLE COUNT',
                  value: '${node.vehicleCount} veh',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DataPill(
                  label: 'AVG SPEED',
                  value: '${node.averageSpeed.toStringAsFixed(1)} km/h',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DataPill(
                  label: 'LANE OCCUPANCY',
                  value: '${(node.occupancy * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // SIGNAL SWITCHER CONTROL BAR
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.traffic,
                      color: AppColors.trafficNormal,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${node.signalPhase.replaceAll('_', ' ')} (${node.greenTimeSec}s)',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_isSwitching)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                )
              else ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 16, color: AppColors.accent),
                  label: const Text(
                    'Quick Switch Phase',
                    style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    final nextPhase = node.signalPhase == 'NORTH_SOUTH_GREEN'
                        ? 'EAST_WEST_GREEN'
                        : 'NORTH_SOUTH_GREEN';
                    _handleSignalSwitch(nextPhase, node.greenTimeSec);
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text(
                    'Signal Switcher',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _openCustomSwitchDialog,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PhaseChoiceChip extends StatelessWidget {
  final String label;
  final String phaseKey;
  final bool selected;
  final VoidCallback onSelected;

  const _PhaseChoiceChip({
    required this.label,
    required this.phaseKey,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: selected ? AppColors.accent : AppColors.textSecondary,
        fontSize: 11,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.border,
        ),
      ),
    );
  }
}

class _DataPill extends StatelessWidget {
  final String label;
  final String value;

  const _DataPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
