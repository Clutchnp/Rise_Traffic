import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';

enum IncidentSeverity { critical, high, moderate, low }

enum IncidentStatus { active, responding, resolved }

extension IncidentSeverityX on IncidentSeverity {
  String get label {
    switch (this) {
      case IncidentSeverity.critical:
        return 'Critical';
      case IncidentSeverity.high:
        return 'High';
      case IncidentSeverity.moderate:
        return 'Moderate';
      case IncidentSeverity.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case IncidentSeverity.critical:
        return AppColors.trafficCritical;
      case IncidentSeverity.high:
        return AppColors.trafficHigh;
      case IncidentSeverity.moderate:
        return AppColors.trafficModerate;
      case IncidentSeverity.low:
        return AppColors.trafficNormal;
    }
  }
}

extension IncidentStatusX on IncidentStatus {
  String get label {
    switch (this) {
      case IncidentStatus.active:
        return 'Active';
      case IncidentStatus.responding:
        return 'Responding';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }

  Color get color {
    switch (this) {
      case IncidentStatus.active:
        return AppColors.trafficCritical;
      case IncidentStatus.responding:
        return AppColors.trafficModerate;
      case IncidentStatus.resolved:
        return AppColors.trafficNormal;
    }
  }
}

class Incident {
  final String title;
  final String location;
  final String type;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String time;
  final String unit;

  const Incident({
    required this.title,
    required this.location,
    required this.type,
    required this.severity,
    required this.status,
    required this.time,
    required this.unit,
  });
}

/// Placeholder data until this is wired up to the backend (src/app.py).
const List<Incident> sampleIncidents = [
  Incident(
    title: 'Major congestion',
    location: 'Silk Board Junction',
    type: 'Congestion',
    severity: IncidentSeverity.critical,
    status: IncidentStatus.active,
    time: '2 min ago',
    unit: 'Unit 14',
  ),
  Incident(
    title: 'Multi-vehicle collision',
    location: 'Outer Ring Road',
    type: 'Accident',
    severity: IncidentSeverity.critical,
    status: IncidentStatus.responding,
    time: '6 min ago',
    unit: 'Unit 07',
  ),
  Incident(
    title: 'Traffic obstruction',
    location: 'Marathahalli Bridge',
    type: 'Obstruction',
    severity: IncidentSeverity.high,
    status: IncidentStatus.responding,
    time: '9 min ago',
    unit: 'Unit 22',
  ),
  Incident(
    title: 'Signal malfunction',
    location: 'Koramangala 80ft Rd',
    type: 'Infrastructure',
    severity: IncidentSeverity.high,
    status: IncidentStatus.active,
    time: '14 min ago',
    unit: 'Unassigned',
  ),
  Incident(
    title: 'Slow moving traffic',
    location: 'Hebbal Flyover',
    type: 'Congestion',
    severity: IncidentSeverity.moderate,
    status: IncidentStatus.active,
    time: '18 min ago',
    unit: 'Unassigned',
  ),
  Incident(
    title: 'Vehicle breakdown',
    location: 'MG Road',
    type: 'Breakdown',
    severity: IncidentSeverity.moderate,
    status: IncidentStatus.resolved,
    time: '31 min ago',
    unit: 'Unit 03',
  ),
  Incident(
    title: 'Illegal parking',
    location: 'Indiranagar 100ft Rd',
    type: 'Violation',
    severity: IncidentSeverity.low,
    status: IncidentStatus.resolved,
    time: '45 min ago',
    unit: 'Unit 11',
  ),
  Incident(
    title: 'Minor fender bender',
    location: 'Whitefield Main Rd',
    type: 'Accident',
    severity: IncidentSeverity.low,
    status: IncidentStatus.resolved,
    time: '1 hr ago',
    unit: 'Unit 09',
  ),
];
