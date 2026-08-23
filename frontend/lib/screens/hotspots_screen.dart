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
        final critCount = hotspots.where((h) => h.congestionLevel == CongestionLevel.critical).length;
        final highCount = hotspots.where((h) => h.congestionLevel == CongestionLevel.high).length;
        final modCount = hotspots.where((h) => h.congestionLevel == CongestionLevel.moderate).length;

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
                            'Congestion Hotspots & Bottlenecks',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'AI-detected recurring bottlenecks with adaptive signal optimization recommendations',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (trafficState.isBackendConnected
                                ? AppColors.trafficNormal
                                : AppColors.accent)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (trafficState.isBackendConnected
                                  ? AppColors.trafficNormal
                                  : AppColors.accent)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: trafficState.isBackendConnected
                                  ? AppColors.trafficNormal
                                  : AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            trafficState.isBackendConnected ? 'Backend Connected' : 'Adaptive Engine Active',
                            style: TextStyle(
                              color: trafficState.isBackendConnected
                                  ? AppColors.trafficNormal
                                  : AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SUMMARY METRIC STRIP
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);
                    final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _MetricCard(
                            label: 'TOTAL HOTSPOTS',
                            value: '${hotspots.length}',
                            color: AppColors.accent,
                            icon: Icons.location_on_outlined,
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
                            label: 'HIGH CONGESTION',
                            value: '$highCount',
                            color: AppColors.trafficHigh,
                            icon: Icons.traffic_outlined,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _MetricCard(
                            label: 'MODERATE LOAD',
                            value: '$modCount',
                            color: AppColors.trafficModerate,
                            icon: Icons.speed_outlined,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

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
                      return _HotspotDetailCard(node: node);
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
                  fontSize: 20,
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
  final HotspotDetail node;

  const _HotspotDetailCard({required this.node});

  @override
  State<_HotspotDetailCard> createState() => _HotspotDetailCardState();
}

class _HotspotDetailCardState extends State<_HotspotDetailCard> {
  bool _isApplying = false;

  void _openTuningDialog() {
    int greenExtension = widget.node.suggestedGreenExtensionSec > 0
        ? widget.node.suggestedGreenExtensionSec
        : 25;
    bool enableGreenWave = true;
    final vmsController = TextEditingController(
      text: 'Heavy congestion on ${widget.node.name}. Green wave route priority active.',
    );

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
              const Icon(Icons.tune, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Signal Tuning — ${widget.node.name}',
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
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Suggestion Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI OPTIMIZATION ADVISORY',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.node.recommendation,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Green Phase Extension Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Green Phase Extension',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${greenExtension}s',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.accent,
                    ),
                    child: Slider(
                      min: 5,
                      max: 60,
                      divisions: 11,
                      value: greenExtension.toDouble(),
                      onChanged: (v) => setDialogState(() => greenExtension = v.round()),
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('5s (Minor)', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      Text('60s (Heavy Surge)', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Green Wave Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Green Wave Corridor Sync',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Synchronize downstream junction offsets',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                      Switch(
                        value: enableGreenWave,
                        activeColor: AppColors.accent,
                        onChanged: (val) => setDialogState(() => enableGreenWave = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // VMS Advisory Broadcast
                  const Text(
                    'Variable Message Sign (VMS) Broadcast',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: vmsController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Display message for electronic corridor signs...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() => _isApplying = true);

                final success = await trafficState.tuneSignal(
                  widget.node.cameraId,
                  greenExtensionSec: greenExtension,
                  enableGreenWave: enableGreenWave,
                  vmsMessage: vmsController.text.trim(),
                );

                if (mounted) {
                  setState(() => _isApplying = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: success ? AppColors.trafficNormal : AppColors.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Applied +${greenExtension}s green phase with Green Wave to ${widget.node.name}',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Apply Tuning'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final isTuned = trafficState.isCameraTuned(node.cameraId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTuned
              ? AppColors.trafficNormal.withValues(alpha: 0.5)
              : AppColors.border,
          width: isTuned ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE ROW
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isTuned ? AppColors.trafficNormal : node.congestionLevel.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isTuned ? AppColors.trafficNormal : node.congestionLevel.color)
                          .withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  node.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isTuned) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.trafficNormal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.trafficNormal, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'AI TUNED',
                        style: TextStyle(
                          color: AppColors.trafficNormal,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isTuned ? AppColors.trafficNormal : node.congestionLevel.color)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (isTuned ? AppColors.trafficNormal : node.congestionLevel.color)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isTuned
                      ? 'ADAPTIVE CLEARANCE'
                      : '${node.congestionLevel.displayName.toUpperCase()} BOTTLENECK',
                  style: TextStyle(
                    color: isTuned ? AppColors.trafficNormal : node.congestionLevel.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // STATS GRID
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: columns == 4 ? 2.8 : 2.4,
                children: [
                  _StatBox(label: 'VEHICLE COUNT', value: '${node.vehicleCount}'),
                  _StatBox(label: 'AVG SPEED', value: '${node.averageSpeed.toStringAsFixed(1)} km/h'),
                  _StatBox(label: 'LANE OCCUPANCY', value: '${(node.occupancy * 100).toInt()}%'),
                  _StatBox(label: 'QUEUE LENGTH', value: '${node.queueLength} veh'),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // AI SUGGESTION BOX
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isTuned
                    ? AppColors.trafficNormal.withValues(alpha: 0.3)
                    : AppColors.accent.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: isTuned ? AppColors.trafficNormal : AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI TRAFFIC OPTIMIZATION ADVISORY',
                      style: TextStyle(
                        color: isTuned ? AppColors.trafficNormal : AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (node.suggestedGreenExtensionSec > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isTuned ? AppColors.trafficNormal : AppColors.accent)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isTuned
                              ? '+${node.suggestedGreenExtensionSec}s Active'
                              : 'Suggested +${node.suggestedGreenExtensionSec}s',
                          style: TextStyle(
                            color: isTuned ? AppColors.trafficNormal : AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  node.recommendation,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FeatureChip(
                      icon: Icons.timer_outlined,
                      label: node.suggestedGreenExtensionSec > 0
                          ? '+${node.suggestedGreenExtensionSec}s Green Phase'
                          : 'Adaptive Phase',
                      color: AppColors.accent,
                    ),
                    const _FeatureChip(
                      icon: Icons.waves_outlined,
                      label: 'Green Wave Sync',
                      color: AppColors.trafficNormal,
                    ),
                    const _FeatureChip(
                      icon: Icons.campaign_outlined,
                      label: 'VMS Advisory',
                      color: AppColors.trafficModerate,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isApplying ? null : _openTuningDialog,
                    icon: _isApplying
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isTuned ? Icons.refresh : Icons.tune,
                            size: 15,
                          ),
                    label: Text(
                      _isApplying
                          ? 'Applying Tuning...'
                          : isTuned
                              ? 'Re-tune Signal Timing'
                              : 'Apply AI Signal Tuning',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTuned ? AppColors.trafficNormal : AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
