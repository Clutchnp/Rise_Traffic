import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:latlong2/latlong.dart';

enum CongestionLevel {
  normal,
  moderate,
  high,
  critical;

  static CongestionLevel fromString(String? val) {
    if (val == null) return CongestionLevel.normal;
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'critical':
        return CongestionLevel.critical;
      case 'high':
        return CongestionLevel.high;
      case 'moderate':
        return CongestionLevel.moderate;
      default:
        return CongestionLevel.normal;
    }
  }
}

extension CongestionLevelExtension on CongestionLevel {
  String get displayName {
    switch (this) {
      case CongestionLevel.normal:
        return 'Normal';
      case CongestionLevel.moderate:
        return 'Moderate';
      case CongestionLevel.high:
        return 'High';
      case CongestionLevel.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case CongestionLevel.normal:
        return AppColors.trafficNormal;
      case CongestionLevel.moderate:
        return AppColors.trafficModerate;
      case CongestionLevel.high:
        return AppColors.trafficHigh;
      case CongestionLevel.critical:
        return AppColors.trafficCritical;
    }
  }
}

class CameraNode {
  final String id;
  final String name;
  final LatLng location;
  final bool isOnline;
  final int vehicleCount;
  final double averageSpeed;
  final double occupancy;
  final int queueLength;
  final double congestionScore;
  final CongestionLevel congestionLevel;
  final String lastUpdated;
  final String? description;
  final String signalPhase;
  final int greenTimeSec;
  final String signalMode;
  final bool isSurgeActive;

  const CameraNode({
    required this.id,
    required this.name,
    required this.location,
    required this.isOnline,
    required this.vehicleCount,
    required this.averageSpeed,
    required this.occupancy,
    required this.queueLength,
    this.congestionScore = 0.0,
    required this.congestionLevel,
    required this.lastUpdated,
    this.description,
    this.signalPhase = 'NORTH_SOUTH_GREEN',
    this.greenTimeSec = 45,
    this.signalMode = 'ADAPTIVE',
    this.isSurgeActive = false,
  });

  factory CameraNode.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble() ?? 12.9716;
    final lon = (json['longitude'] as num?)?.toDouble() ?? 77.5946;
    final rawLevel = json['congestion_level'] ?? json['status'];

    return CameraNode(
      id: (json['id'] ?? json['camera_id'] ?? 'CAM-000').toString(),
      name: (json['name'] ?? json['location'] ?? 'Monitored Corridor').toString(),
      location: LatLng(lat, lon),
      isOnline: json['is_online'] as bool? ?? true,
      vehicleCount: (json['vehicle_count'] as num?)?.toInt() ?? (json['vehicles'] as num?)?.toInt() ?? 0,
      averageSpeed: (json['average_speed'] as num?)?.toDouble() ?? (json['avg_speed'] as num?)?.toDouble() ?? 30.0,
      occupancy: (json['occupancy'] as num?)?.toDouble() ?? 0.5,
      queueLength: (json['queue_length'] as num?)?.toInt() ?? (json['queue'] as num?)?.toInt() ?? 0,
      congestionScore: (json['congestion_score'] as num?)?.toDouble() ?? 0.0,
      congestionLevel: CongestionLevel.fromString(rawLevel?.toString()),
      lastUpdated: (json['last_updated'] ?? json['timestamp'] ?? 'Just now').toString(),
      description: json['description'] as String?,
      signalPhase: (json['signal_phase'] ?? 'NORTH_SOUTH_GREEN').toString(),
      greenTimeSec: (json['green_time_sec'] as num?)?.toInt() ?? 45,
      signalMode: (json['signal_mode'] ?? 'ADAPTIVE').toString(),
      isSurgeActive: json['is_surge_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': location.latitude,
    'longitude': location.longitude,
    'is_online': isOnline,
    'vehicle_count': vehicleCount,
    'average_speed': averageSpeed,
    'occupancy': occupancy,
    'queue_length': queueLength,
    'congestion_score': congestionScore,
    'congestion_level': congestionLevel.displayName.toLowerCase(),
    'last_updated': lastUpdated,
    'description': description,
    'signal_phase': signalPhase,
    'green_time_sec': greenTimeSec,
    'signal_mode': signalMode,
    'is_surge_active': isSurgeActive,
  };

  CameraNode copyWith({
    String? id,
    String? name,
    LatLng? location,
    bool? isOnline,
    int? vehicleCount,
    double? averageSpeed,
    double? occupancy,
    int? queueLength,
    double? congestionScore,
    CongestionLevel? congestionLevel,
    String? lastUpdated,
    String? description,
    String? signalPhase,
    int? greenTimeSec,
    String? signalMode,
    bool? isSurgeActive,
  }) {
    return CameraNode(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      occupancy: occupancy ?? this.occupancy,
      queueLength: queueLength ?? this.queueLength,
      congestionScore: congestionScore ?? this.congestionScore,
      congestionLevel: congestionLevel ?? this.congestionLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      description: description ?? this.description,
      signalPhase: signalPhase ?? this.signalPhase,
      greenTimeSec: greenTimeSec ?? this.greenTimeSec,
      signalMode: signalMode ?? this.signalMode,
      isSurgeActive: isSurgeActive ?? this.isSurgeActive,
    );
  }

  static const List<CameraNode> defaultCameras = [
    CameraNode(
      id: 'CAM-001',
      name: 'Silk Board Junction',
      location: LatLng(12.9176, 77.6238),
      isOnline: true,
      vehicleCount: 182,
      averageSpeed: 14.2,
      occupancy: 0.92,
      queueLength: 47,
      congestionScore: 0.88,
      congestionLevel: CongestionLevel.critical,
      lastUpdated: '12:31:04',
    ),
    CameraNode(
      id: 'CAM-002',
      name: 'Marathahalli Bridge',
      location: LatLng(12.9591, 77.6974),
      isOnline: true,
      vehicleCount: 96,
      averageSpeed: 27.8,
      occupancy: 0.61,
      queueLength: 18,
      congestionScore: 0.62,
      congestionLevel: CongestionLevel.high,
      lastUpdated: '12:31:02',
    ),
    CameraNode(
      id: 'CAM-003',
      name: 'Koramangala 80ft Rd',
      location: LatLng(12.9352, 77.6245),
      isOnline: true,
      vehicleCount: 143,
      averageSpeed: 19.4,
      occupancy: 0.74,
      queueLength: 29,
      congestionScore: 0.45,
      congestionLevel: CongestionLevel.moderate,
      lastUpdated: '12:30:58',
    ),
    CameraNode(
      id: 'CAM-004',
      name: 'Hebbal Flyover',
      location: LatLng(13.0358, 77.5970),
      isOnline: true,
      vehicleCount: 51,
      averageSpeed: 38.2,
      occupancy: 0.42,
      queueLength: 8,
      congestionScore: 0.22,
      congestionLevel: CongestionLevel.normal,
      lastUpdated: '12:30:54',
    ),
    CameraNode(
      id: 'CAM-005',
      name: 'MG Road Junction',
      location: LatLng(12.9756, 77.6066),
      isOnline: true,
      vehicleCount: 82,
      averageSpeed: 26.5,
      occupancy: 0.58,
      queueLength: 15,
      congestionScore: 0.42,
      congestionLevel: CongestionLevel.moderate,
      lastUpdated: '12:30:50',
    ),
    CameraNode(
      id: 'CAM-006',
      name: 'Indiranagar 100ft Rd',
      location: LatLng(12.9784, 77.6408),
      isOnline: true,
      vehicleCount: 78,
      averageSpeed: 29.1,
      occupancy: 0.51,
      queueLength: 12,
      congestionScore: 0.38,
      congestionLevel: CongestionLevel.moderate,
      lastUpdated: '12:30:45',
    ),
    CameraNode(
      id: 'CAM-007',
      name: 'Whitefield ITPL Main Rd',
      location: LatLng(12.9866, 77.7381),
      isOnline: true,
      vehicleCount: 155,
      averageSpeed: 16.8,
      occupancy: 0.84,
      queueLength: 38,
      congestionScore: 0.72,
      congestionLevel: CongestionLevel.high,
      lastUpdated: '12:30:40',
    ),
    CameraNode(
      id: 'CAM-008',
      name: 'Electronic City Toll Plaza',
      location: LatLng(12.8452, 77.6602),
      isOnline: true,
      vehicleCount: 112,
      averageSpeed: 31.0,
      occupancy: 0.63,
      queueLength: 20,
      congestionScore: 0.48,
      congestionLevel: CongestionLevel.moderate,
      lastUpdated: '12:30:35',
    ),
  ];
}

enum IncidentType {
  congestion,
  obstruction,
  breakdown,
  accident,
  signalFailure;

  static IncidentType fromString(String? val) {
    if (val == null) return IncidentType.congestion;
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'obstruction':
        return IncidentType.obstruction;
      case 'breakdown':
        return IncidentType.breakdown;
      case 'accident':
        return IncidentType.accident;
      case 'signalfailure':
      case 'signal_failure':
        return IncidentType.signalFailure;
      default:
        return IncidentType.congestion;
    }
  }
}

class IncidentRecord {
  final String id;
  final String title;
  final String location;
  final String time;
  final IncidentType type;
  final CongestionLevel severity;
  final String description;
  final String assignedUnit;
  final String status;
  final double? latitude;
  final double? longitude;

  const IncidentRecord({
    required this.id,
    required this.title,
    required this.location,
    required this.time,
    required this.type,
    required this.severity,
    required this.description,
    required this.assignedUnit,
    required this.status,
    this.latitude,
    this.longitude,
  });

  factory IncidentRecord.fromJson(Map<String, dynamic> json) {
    return IncidentRecord(
      id: (json['id'] ?? 'INC-000').toString(),
      title: (json['title'] ?? 'Traffic Incident').toString(),
      location: (json['location'] ?? 'Monitored Location').toString(),
      time: (json['time'] ?? 'Just now').toString(),
      type: IncidentType.fromString(json['type']?.toString()),
      severity: CongestionLevel.fromString(json['severity']?.toString()),
      description: (json['description'] ?? '').toString(),
      assignedUnit: (json['assigned_unit'] ?? json['assignedUnit'] ?? 'Central Dispatch').toString(),
      status: (json['status'] ?? 'In Progress').toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'location': location,
    'type': type.name,
    'severity': severity.displayName.toLowerCase(),
    'description': description,
    'assigned_unit': assignedUnit,
    'status': status,
    'latitude': latitude,
    'longitude': longitude,
  };

  IncidentRecord copyWith({
    String? id,
    String? title,
    String? location,
    String? time,
    IncidentType? type,
    CongestionLevel? severity,
    String? description,
    String? assignedUnit,
    String? status,
    double? latitude,
    double? longitude,
  }) {
    return IncidentRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      time: time ?? this.time,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      assignedUnit: assignedUnit ?? this.assignedUnit,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  static const List<IncidentRecord> defaultIncidents = [
    IncidentRecord(
      id: 'INC-1049',
      title: 'Major Congestion Bottleneck',
      location: 'Silk Board Junction',
      time: '2 min ago',
      type: IncidentType.congestion,
      severity: CongestionLevel.critical,
      description: 'Severe traffic buildup due to heavy inflow from Hosur Road towards BTM.',
      assignedUnit: 'Patrol Alpha-4',
      status: 'In Progress',
    ),
    IncidentRecord(
      id: 'INC-1048',
      title: 'Traffic Lane Obstruction',
      location: 'Outer Ring Road (Marathahalli)',
      time: '6 min ago',
      type: IncidentType.obstruction,
      severity: CongestionLevel.high,
      description: 'Fallen tree branch blocking the left lane heading towards Bellandur.',
      assignedUnit: 'Quick Response Team 2',
      status: 'Dispatched',
    ),
    IncidentRecord(
      id: 'INC-1047',
      title: 'Slow Moving Traffic',
      location: 'Koramangala 80ft Road',
      time: '11 min ago',
      type: IncidentType.congestion,
      severity: CongestionLevel.moderate,
      description: 'Intermittent signal delays causing steady queue accumulation.',
      assignedUnit: 'Traffic Warden 09',
      status: 'Monitoring',
    ),
    IncidentRecord(
      id: 'INC-1046',
      title: 'Commercial Vehicle Breakdown',
      location: 'MG Road Junction',
      time: '18 min ago',
      type: IncidentType.breakdown,
      severity: CongestionLevel.moderate,
      description: 'Stalled delivery van on right turning lane, tow truck requested.',
      assignedUnit: 'Tow Unit 3',
      status: 'En Route',
    ),
    IncidentRecord(
      id: 'INC-1045',
      title: 'Traffic Signal Desync',
      location: 'Hebbal Interchange',
      time: '34 min ago',
      type: IncidentType.signalFailure,
      severity: CongestionLevel.normal,
      description: 'Signal timing reverted to fixed backup cycle; technician notified.',
      assignedUnit: 'Signals Dept Tech',
      status: 'Under Review',
    ),
  ];
}

// -------------------------------------------------------------
// Additional Frontend & API Models
// -------------------------------------------------------------

class HotspotDetail {
  final String cameraId;
  final String name;
  final double latitude;
  final double longitude;
  final CongestionLevel congestionLevel;
  final double congestionScore;
  final int vehicleCount;
  final double averageSpeed;
  final double occupancy;
  final int queueLength;
  final String signalPhase;
  final int greenTimeSec;
  final String signalMode;
  final bool isSurgeActive;
  final String recommendation;
  final int suggestedGreenExtensionSec;

  const HotspotDetail({
    required this.cameraId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.congestionLevel,
    this.congestionScore = 0.0,
    required this.vehicleCount,
    required this.averageSpeed,
    required this.occupancy,
    required this.queueLength,
    this.signalPhase = 'NORTH_SOUTH_GREEN',
    this.greenTimeSec = 45,
    this.signalMode = 'ADAPTIVE',
    this.isSurgeActive = false,
    required this.recommendation,
    required this.suggestedGreenExtensionSec,
  });

  factory HotspotDetail.fromJson(Map<String, dynamic> json) {
    return HotspotDetail(
      cameraId: (json['camera_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 12.9716,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.5946,
      congestionLevel: CongestionLevel.fromString(json['congestion_level']?.toString()),
      congestionScore: (json['congestion_score'] as num?)?.toDouble() ?? 0.0,
      vehicleCount: (json['vehicle_count'] as num?)?.toInt() ?? 0,
      averageSpeed: (json['average_speed'] as num?)?.toDouble() ?? 0.0,
      occupancy: (json['occupancy'] as num?)?.toDouble() ?? 0.0,
      queueLength: (json['queue_length'] as num?)?.toInt() ?? 0,
      signalPhase: (json['signal_phase'] ?? 'NORTH_SOUTH_GREEN').toString(),
      greenTimeSec: (json['green_time_sec'] as num?)?.toInt() ?? 45,
      signalMode: (json['signal_mode'] ?? 'ADAPTIVE').toString(),
      isSurgeActive: json['is_surge_active'] as bool? ?? false,
      recommendation: (json['recommendation'] ?? '').toString(),
      suggestedGreenExtensionSec: (json['suggested_green_extension_sec'] as num?)?.toInt() ?? 0,
    );
  }

  HotspotDetail copyWith({
    String? cameraId,
    String? name,
    double? latitude,
    double? longitude,
    CongestionLevel? congestionLevel,
    double? congestionScore,
    int? vehicleCount,
    double? averageSpeed,
    double? occupancy,
    int? queueLength,
    String? signalPhase,
    int? greenTimeSec,
    String? signalMode,
    bool? isSurgeActive,
    String? recommendation,
    int? suggestedGreenExtensionSec,
  }) {
    return HotspotDetail(
      cameraId: cameraId ?? this.cameraId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      congestionLevel: congestionLevel ?? this.congestionLevel,
      congestionScore: congestionScore ?? this.congestionScore,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      occupancy: occupancy ?? this.occupancy,
      queueLength: queueLength ?? this.queueLength,
      signalPhase: signalPhase ?? this.signalPhase,
      greenTimeSec: greenTimeSec ?? this.greenTimeSec,
      signalMode: signalMode ?? this.signalMode,
      isSurgeActive: isSurgeActive ?? this.isSurgeActive,
      recommendation: recommendation ?? this.recommendation,
      suggestedGreenExtensionSec: suggestedGreenExtensionSec ?? this.suggestedGreenExtensionSec,
    );
  }
}

class SignalAdvisory {
  final String corridorId;
  final String corridorName;
  final CongestionLevel currentCongestion;
  final String recommendationTitle;
  final String recommendationText;
  final int suggestedGreenExtensionSec;
  final bool enableVmsReroute;
  final bool enableGreenWave;

  const SignalAdvisory({
    required this.corridorId,
    required this.corridorName,
    required this.currentCongestion,
    required this.recommendationTitle,
    required this.recommendationText,
    required this.suggestedGreenExtensionSec,
    required this.enableVmsReroute,
    required this.enableGreenWave,
  });

  factory SignalAdvisory.fromJson(Map<String, dynamic> json) {
    return SignalAdvisory(
      corridorId: (json['corridor_id'] ?? '').toString(),
      corridorName: (json['corridor_name'] ?? '').toString(),
      currentCongestion: CongestionLevel.fromString(json['current_congestion']?.toString()),
      recommendationTitle: (json['recommendation_title'] ?? '').toString(),
      recommendationText: (json['recommendation_text'] ?? '').toString(),
      suggestedGreenExtensionSec: (json['suggested_green_extension_sec'] as num?)?.toInt() ?? 0,
      enableVmsReroute: json['enable_vms_reroute'] as bool? ?? false,
      enableGreenWave: json['enable_green_wave'] as bool? ?? false,
    );
  }
}

class KPIOverview {
  final String trafficStatus;
  final int activeIncidents;
  final int criticalIncidents;
  final int congestionHotspots;
  final int criticalHotspots;
  final String responseStatus;
  final String dailyVehicleVolume;
  final String peakFlowRate;
  final String peakFlowTime;
  final String avgCorridorSpeed;
  final String speedDelta;
  final String carbonSavingsTons;

  const KPIOverview({
    required this.trafficStatus,
    required this.activeIncidents,
    required this.criticalIncidents,
    required this.congestionHotspots,
    required this.criticalHotspots,
    required this.responseStatus,
    required this.dailyVehicleVolume,
    required this.peakFlowRate,
    required this.peakFlowTime,
    required this.avgCorridorSpeed,
    required this.speedDelta,
    required this.carbonSavingsTons,
  });

  factory KPIOverview.fromJson(Map<String, dynamic> json) {
    return KPIOverview(
      trafficStatus: (json['traffic_status'] ?? 'Moderate').toString(),
      activeIncidents: (json['active_incidents'] as num?)?.toInt() ?? 5,
      criticalIncidents: (json['critical_incidents'] as num?)?.toInt() ?? 2,
      congestionHotspots: (json['congestion_hotspots'] as num?)?.toInt() ?? 4,
      criticalHotspots: (json['critical_hotspots'] as num?)?.toInt() ?? 1,
      responseStatus: (json['response_status'] ?? '98.4%').toString(),
      dailyVehicleVolume: (json['daily_vehicle_volume'] ?? '148,250').toString(),
      peakFlowRate: (json['peak_flow_rate'] ?? '12,400 /hr').toString(),
      peakFlowTime: (json['peak_flow_time'] ?? '18:30 IST').toString(),
      avgCorridorSpeed: (json['avg_corridor_speed'] ?? '24.9 km/h').toString(),
      speedDelta: (json['speed_delta'] ?? '+3.1 km/h post AI tuning').toString(),
      carbonSavingsTons: (json['carbon_savings_tons'] ?? '1.42 Tons').toString(),
    );
  }

  static const defaultKPI = KPIOverview(
    trafficStatus: 'Moderate',
    activeIncidents: 5,
    criticalIncidents: 2,
    congestionHotspots: 4,
    criticalHotspots: 1,
    responseStatus: '98.4%',
    dailyVehicleVolume: '148,250',
    peakFlowRate: '12,400 /hr',
    peakFlowTime: '18:30 IST',
    avgCorridorSpeed: '24.9 km/h',
    speedDelta: '+3.1 km/h post AI tuning',
    carbonSavingsTons: '1.42 Tons',
  );
}

class CongestionTrendPoint {
  final int hour;
  final String timeLabel;
  final double congestionScore;
  final double averageSpeed;
  final int vehicleCount;

  const CongestionTrendPoint({
    required this.hour,
    required this.timeLabel,
    required this.congestionScore,
    required this.averageSpeed,
    required this.vehicleCount,
  });

  factory CongestionTrendPoint.fromJson(Map<String, dynamic> json) {
    return CongestionTrendPoint(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      timeLabel: (json['time_label'] ?? '').toString(),
      congestionScore: (json['congestion_score'] as num?)?.toDouble() ?? 0.0,
      averageSpeed: (json['average_speed'] as num?)?.toDouble() ?? 30.0,
      vehicleCount: (json['vehicle_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class VehicleComposition {
  final int carsAndCabs;
  final int twoWheelers;
  final int busesAndTransit;
  final int commercialFreight;

  const VehicleComposition({
    required this.carsAndCabs,
    required this.twoWheelers,
    required this.busesAndTransit,
    required this.commercialFreight,
  });

  factory VehicleComposition.fromJson(Map<String, dynamic> json) {
    return VehicleComposition(
      carsAndCabs: (json['cars_and_cabs'] as num?)?.toInt() ?? 48,
      twoWheelers: (json['two_wheelers'] as num?)?.toInt() ?? 34,
      busesAndTransit: (json['buses_and_transit'] as num?)?.toInt() ?? 12,
      commercialFreight: (json['commercial_freight'] as num?)?.toInt() ?? 6,
    );
  }
}

class CorridorThroughput {
  final String corridor;
  final String volume;
  final String status;
  final String congestionLevel;
  final double averageSpeedKmh;

  const CorridorThroughput({
    required this.corridor,
    required this.volume,
    required this.status,
    required this.congestionLevel,
    required this.averageSpeedKmh,
  });

  factory CorridorThroughput.fromJson(Map<String, dynamic> json) {
    return CorridorThroughput(
      corridor: (json['corridor'] ?? '').toString(),
      volume: (json['volume'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      congestionLevel: (json['congestion_level'] ?? 'normal').toString(),
      averageSpeedKmh: (json['average_speed_kmh'] as num?)?.toDouble() ?? 30.0,
    );
  }
}

class RawTelemetryLog {
  final String cameraId;
  final String corridorLocation;
  final int vehicles;
  final double avgSpeed;
  final double occupancy;
  final int queue;
  final String timestamp;
  final String status;

  const RawTelemetryLog({
    required this.cameraId,
    required this.corridorLocation,
    required this.vehicles,
    required this.avgSpeed,
    required this.occupancy,
    required this.queue,
    required this.timestamp,
    required this.status,
  });

  factory RawTelemetryLog.fromJson(Map<String, dynamic> json) {
    return RawTelemetryLog(
      cameraId: (json['camera_id'] ?? '').toString(),
      corridorLocation: (json['corridor_location'] ?? '').toString(),
      vehicles: (json['vehicles'] as num?)?.toInt() ?? 0,
      avgSpeed: (json['avg_speed'] as num?)?.toDouble() ?? 0.0,
      occupancy: (json['occupancy'] as num?)?.toDouble() ?? 0.0,
      queue: (json['queue'] as num?)?.toInt() ?? 0,
      timestamp: (json['timestamp'] ?? '').toString(),
      status: (json['status'] ?? 'NORMAL').toString(),
    );
  }
}
