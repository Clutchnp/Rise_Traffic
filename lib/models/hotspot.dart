import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';

enum HotspotSeverity { critical, high, moderate, normal }

extension HotspotSeverityX on HotspotSeverity {
  String get label {
    switch (this) {
      case HotspotSeverity.critical:
        return 'Critical';
      case HotspotSeverity.high:
        return 'High';
      case HotspotSeverity.moderate:
        return 'Moderate';
      case HotspotSeverity.normal:
        return 'Normal';
    }
  }

  Color get color {
    switch (this) {
      case HotspotSeverity.critical:
        return AppColors.trafficCritical;
      case HotspotSeverity.high:
        return AppColors.trafficHigh;
      case HotspotSeverity.moderate:
        return AppColors.trafficModerate;
      case HotspotSeverity.normal:
        return AppColors.trafficNormal;
    }
  }
}

class Hotspot {
  final String name;
  final String road;
  final HotspotSeverity severity;
  final double congestionScore; // 0-100
  final int avgDelayMinutes;
  final int vehicleCount;
  final bool trendingUp;

  const Hotspot({
    required this.name,
    required this.road,
    required this.severity,
    required this.congestionScore,
    required this.avgDelayMinutes,
    required this.vehicleCount,
    required this.trendingUp,
  });
}

/// Placeholder data until this is wired up to the backend (src/app.py).
const List<Hotspot> sampleHotspots = [
  Hotspot(
    name: 'Silk Board',
    road: 'Hosur Road',
    severity: HotspotSeverity.critical,
    congestionScore: 92,
    avgDelayMinutes: 24,
    vehicleCount: 4200,
    trendingUp: true,
  ),
  Hotspot(
    name: 'Marathahalli Bridge',
    road: 'Outer Ring Road',
    severity: HotspotSeverity.high,
    congestionScore: 78,
    avgDelayMinutes: 17,
    vehicleCount: 3600,
    trendingUp: true,
  ),
  Hotspot(
    name: 'KR Puram',
    road: 'Old Madras Road',
    severity: HotspotSeverity.high,
    congestionScore: 74,
    avgDelayMinutes: 15,
    vehicleCount: 3100,
    trendingUp: false,
  ),
  Hotspot(
    name: 'Koramangala',
    road: '80ft Road',
    severity: HotspotSeverity.moderate,
    congestionScore: 58,
    avgDelayMinutes: 10,
    vehicleCount: 2400,
    trendingUp: false,
  ),
  Hotspot(
    name: 'Hebbal',
    road: 'Bellary Road',
    severity: HotspotSeverity.moderate,
    congestionScore: 51,
    avgDelayMinutes: 8,
    vehicleCount: 2100,
    trendingUp: true,
  ),
  Hotspot(
    name: 'Whitefield',
    road: 'ITPL Main Road',
    severity: HotspotSeverity.normal,
    congestionScore: 34,
    avgDelayMinutes: 4,
    vehicleCount: 1500,
    trendingUp: false,
  ),
];
