import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/models/incident.dart';
import 'package:frontend/widgets/kpi_cards.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  IncidentSeverity? _filter;

  @override
  Widget build(BuildContext context) {
    final activeCount = sampleIncidents
        .where((i) => i.status != IncidentStatus.resolved)
        .length;
    final criticalCount = sampleIncidents
        .where((i) => i.severity == IncidentSeverity.critical)
        .length;
    final resolvedToday = sampleIncidents
        .where((i) => i.status == IncidentStatus.resolved)
        .length;

    final filtered = _filter == null
        ? sampleIncidents
        : sampleIncidents.where((i) => i.severity == _filter).toList();

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildKpiRow(activeCount, criticalCount, resolvedToday),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 16),
            ...filtered.map(
              (incident) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IncidentCard(incident: incident),
              ),
            ),
            if (filtered.isEmpty) _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Incident Management',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Track, triage and respond to active traffic incidents',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Report Incident'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow(int active, int critical, int resolvedToday) {
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
              child: TrafficMetricCard(
                label: 'ACTIVE INCIDENTS',
                value: '$active',
                subtitle: 'Currently unresolved',
                icon: Icons.warning_amber_outlined,
                accent: AppColors.trafficHigh,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: TrafficMetricCard(
                label: 'CRITICAL',
                value: '$critical',
                subtitle: 'Require immediate response',
                icon: Icons.priority_high,
                accent: AppColors.trafficCritical,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: TrafficMetricCard(
                label: 'RESOLVED TODAY',
                value: '$resolvedToday',
                subtitle: 'Closed within SLA',
                icon: Icons.check_circle_outline,
                accent: AppColors.trafficNormal,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const TrafficMetricCard(
                label: 'AVG RESPONSE TIME',
                value: '6.4 min',
                subtitle: 'Across all units',
                icon: Icons.timer_outlined,
                accent: AppColors.accent,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChip(
          label: 'All',
          selected: _filter == null,
          onTap: () => setState(() => _filter = null),
        ),
        _FilterChip(
          label: 'Critical',
          color: AppColors.trafficCritical,
          selected: _filter == IncidentSeverity.critical,
          onTap: () => setState(() => _filter = IncidentSeverity.critical),
        ),
        _FilterChip(
          label: 'High',
          color: AppColors.trafficHigh,
          selected: _filter == IncidentSeverity.high,
          onTap: () => setState(() => _filter = IncidentSeverity.high),
        ),
        _FilterChip(
          label: 'Moderate',
          color: AppColors.trafficModerate,
          selected: _filter == IncidentSeverity.moderate,
          onTap: () => setState(() => _filter = IncidentSeverity.moderate),
        ),
        _FilterChip(
          label: 'Low',
          color: AppColors.trafficNormal,
          selected: _filter == IncidentSeverity.low,
          onTap: () => setState(() => _filter = IncidentSeverity.low),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'No incidents match this filter',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.14)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: chipColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? chipColor : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Incident incident;

  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: incident.severity.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 640;
                      final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                incident.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: incident.severity.color
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  incident.severity.label.toUpperCase(),
                                  style: TextStyle(
                                    color: incident.severity.color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 14,
                            runSpacing: 4,
                            children: [
                              _MetaTag(
                                icon: Icons.location_on_outlined,
                                label: incident.location,
                              ),
                              _MetaTag(
                                icon: Icons.category_outlined,
                                label: incident.type,
                              ),
                            ],
                          ),
                        ],
                      );

                      final status = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            incident.status.label,
                            style: TextStyle(
                              color: incident.status.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            incident.unit,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );

                      final time = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            incident.time,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ],
                      );

                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            details,
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [status, time],
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(flex: 3, child: details),
                          Expanded(flex: 2, child: status),
                          time,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
