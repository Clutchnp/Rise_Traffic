import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/data/traffic_state.dart';
import 'package:frontend/models/traffic_model.dart';
import 'package:frontend/widgets/kpi_cards.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: trafficState,
      builder: (context, _) {
        final allIncidents = trafficState.incidents;
        final kpis = trafficState.kpis;

        List<IncidentRecord> filteredIncidents = allIncidents;
        if (selectedFilter == 'Critical') {
          filteredIncidents = allIncidents
              .where((i) => i.severity == CongestionLevel.critical)
              .toList();
        } else if (selectedFilter == 'High') {
          filteredIncidents = allIncidents
              .where((i) => i.severity == CongestionLevel.high)
              .toList();
        } else if (selectedFilter == 'Moderate') {
          filteredIncidents = allIncidents
              .where((i) => i.severity == CongestionLevel.moderate)
              .toList();
        }

        final critCount = allIncidents.where((i) => i.severity == CongestionLevel.critical).length;
        final highCount = allIncidents.where((i) => i.severity == CongestionLevel.high).length;
        final modCount = allIncidents.where((i) => i.severity == CongestionLevel.moderate).length;

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incident Management',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Live traffic bottlenecks, vehicle stalls, and emergency dispatches',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateIncidentDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Log New Incident'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SUMMARY CARDS
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
                            label: 'TOTAL ACTIVE',
                            value: '${allIncidents.length}',
                            subtitle: '$critCount critical priority',
                            icon: Icons.warning_amber_rounded,
                            accent: AppColors.trafficCritical,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: const TrafficMetricCard(
                            label: 'AVG DISPATCH TIME',
                            value: '3.8 min',
                            subtitle: '-45s vs last week',
                            icon: Icons.timer_outlined,
                            accent: AppColors.trafficNormal,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: const TrafficMetricCard(
                            label: 'UNITS DEPLOYED',
                            value: '8 Patrols',
                            subtitle: 'Across 4 zones',
                            icon: Icons.local_police_outlined,
                            accent: AppColors.accent,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: TrafficMetricCard(
                            label: 'RESPONSE RATE',
                            value: kpis.responseStatus,
                            subtitle: 'Clearance efficiency',
                            icon: Icons.check_circle_outline,
                            accent: AppColors.trafficNormal,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // FILTER BUTTONS
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FilterChip(
                      label: 'All Incidents (${allIncidents.length})',
                      isSelected: selectedFilter == 'All',
                      onTap: () => setState(() => selectedFilter = 'All'),
                    ),
                    _FilterChip(
                      label: 'Critical ($critCount)',
                      isSelected: selectedFilter == 'Critical',
                      color: AppColors.trafficCritical,
                      onTap: () => setState(() => selectedFilter = 'Critical'),
                    ),
                    _FilterChip(
                      label: 'High ($highCount)',
                      isSelected: selectedFilter == 'High',
                      color: AppColors.trafficHigh,
                      onTap: () => setState(() => selectedFilter = 'High'),
                    ),
                    _FilterChip(
                      label: 'Moderate ($modCount)',
                      isSelected: selectedFilter == 'Moderate',
                      color: AppColors.trafficModerate,
                      onTap: () => setState(() => selectedFilter = 'Moderate'),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // INCIDENT FEED
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredIncidents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final incident = filteredIncidents[index];
                    return _IncidentCard(
                      incident: incident,
                      onDispatch: () => _showDispatchDialog(incident),
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

  void _showDispatchDialog(IncidentRecord incident) {
    String selectedUnit = 'Patrol Alpha-4';
    final notesController = TextEditingController(
      text: 'Immediate dispatch to resolve ${incident.title.toLowerCase()} and divert traffic.',
    );
    bool isDispatching = false;

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
              const Icon(Icons.local_police_outlined, color: AppColors.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dispatch Unit — ${incident.id}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
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
                  // Incident info pill
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: incident.severity.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: incident.severity.color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: incident.severity.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                incident.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Location: ${incident.location} • Currently Assigned: ${incident.assignedUnit}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Select Response Unit',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    dropdownColor: AppColors.surfaceElevated,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
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
                    items: const [
                      DropdownMenuItem(value: 'Patrol Alpha-4', child: Text('Patrol Alpha-4 (Rapid Intercept)')),
                      DropdownMenuItem(value: 'Quick Response Team 2', child: Text('Quick Response Team 2 (Heavy Incident)')),
                      DropdownMenuItem(value: 'Traffic Warden Unit 09', child: Text('Traffic Warden Unit 09 (Intersection Control)')),
                      DropdownMenuItem(value: 'Emergency Tow Unit 3', child: Text('Emergency Tow Unit 3 (Breakdown Clearance)')),
                      DropdownMenuItem(value: 'Highway Patrol Taskforce', child: Text('Highway Patrol Taskforce (Corridor Sweeper)')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedUnit = val ?? 'Patrol Alpha-4'),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Dispatch Orders / Mission Notes',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter dispatch mission directive...',
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
              onPressed: isDispatching ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isDispatching
                  ? null
                  : () async {
                      setDialogState(() => isDispatching = true);
                      final success = await trafficState.dispatchBackup(
                        incident.id,
                        unitName: selectedUnit,
                        notes: notesController.text.trim(),
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: success
                                ? AppColors.trafficNormal.withValues(alpha: 0.9)
                                : AppColors.surfaceElevated,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dispatched $selectedUnit to ${incident.location}',
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
              icon: isDispatching
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(isDispatching ? 'Dispatching...' : 'Confirm & Dispatch'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateIncidentDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'congestion';
    String selectedSeverity = 'critical';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text('Log New Traffic Incident', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Incident Title',
                    hintText: 'e.g. Major Vehicle Breakdown',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Corridor / Landmark',
                    hintText: 'e.g. Silk Board Junction',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSeverity,
                  dropdownColor: AppColors.surfaceElevated,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Severity Level',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'critical', child: Text('Critical Priority')),
                    DropdownMenuItem(value: 'high', child: Text('High Priority')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate Priority')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal Flow')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedSeverity = val ?? 'moderate'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Situation Description',
                    hintText: 'Provide situational details for responding units...',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () async {
                if (titleController.text.trim().isEmpty || locationController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(ctx).pop();
                await trafficState.createIncident(
                  title: titleController.text.trim(),
                  location: locationController.text.trim(),
                  type: selectedType,
                  severity: selectedSeverity,
                  description: descriptionController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incident logged to central dispatch!')),
                  );
                }
              },
              child: const Text('Log Incident'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final IncidentRecord incident;
  final VoidCallback onDispatch;

  const _IncidentCard({
    required this.incident,
    required this.onDispatch,
  });

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
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: incident.severity.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: incident.severity.color.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                incident.id,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: incident.severity.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  incident.severity.displayName.toUpperCase(),
                  style: TextStyle(
                    color: incident.severity.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (incident.status.toLowerCase() == 'dispatched') ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.trafficNormal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.trafficNormal.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 10, color: AppColors.trafficNormal),
                      SizedBox(width: 3),
                      Text(
                        'DISPATCHED',
                        style: TextStyle(
                          color: AppColors.trafficNormal,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                incident.time,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            incident.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                incident.location,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            incident.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Assigned: ${incident.assignedUnit}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: incident.status.toLowerCase() == 'dispatched'
                        ? AppColors.trafficNormal
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: incident.status.toLowerCase() == 'dispatched'
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onDispatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: incident.status.toLowerCase() == 'dispatched'
                      ? AppColors.surfaceElevated
                      : AppColors.accent,
                  foregroundColor: incident.status.toLowerCase() == 'dispatched'
                      ? AppColors.textPrimary
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(
                      color: incident.status.toLowerCase() == 'dispatched'
                          ? AppColors.border
                          : Colors.transparent,
                    ),
                  ),
                ),
                icon: Icon(
                  incident.status.toLowerCase() == 'dispatched'
                      ? Icons.add_moderator_outlined
                      : Icons.send_rounded,
                  size: 13,
                ),
                label: Text(
                  incident.status.toLowerCase() == 'dispatched'
                      ? 'Dispatch Reinforcement'
                      : 'Dispatch Backup',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
