import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/traffic_model.dart';

class ApiService {
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';
  final String baseUrl;

  ApiService({this.baseUrl = defaultBaseUrl});

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Fetch Camera Nodes with optional filter (Online / Congested)
  Future<List<CameraNode>> fetchCameraNodes({String? filter}) async {
    try {
      final queryParam = filter != null && filter != 'All' ? '?filter_by=$filter' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/traffic/nodes$queryParam'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => CameraNode.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchCameraNodes error: $e. Falling back to default.');
    }
    // Fallback if backend is offline
    if (filter == 'Online') {
      return CameraNode.defaultCameras.where((c) => c.isOnline).toList();
    } else if (filter == 'Congested') {
      return CameraNode.defaultCameras
          .where((c) =>
              c.congestionLevel == CongestionLevel.critical ||
              c.congestionLevel == CongestionLevel.high)
          .toList();
    }
    return CameraNode.defaultCameras;
  }

  // Fetch Single Camera Telemetry
  Future<CameraNode?> fetchCameraNode(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/traffic/nodes/$id'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return CameraNode.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('ApiService.fetchCameraNode error: $e');
    }
    return CameraNode.defaultCameras.firstWhere((c) => c.id == id, orElse: () => CameraNode.defaultCameras.first);
  }

  // Fetch Raw Telemetry Log Table Entries
  Future<List<RawTelemetryLog>> fetchRawTelemetryLogs({int limit = 50}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/traffic/logs?limit=$limit'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => RawTelemetryLog.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchRawTelemetryLogs error: $e');
    }
    return CameraNode.defaultCameras.map((c) => RawTelemetryLog(
      cameraId: c.id,
      corridorLocation: c.name,
      vehicles: c.vehicleCount,
      avgSpeed: c.averageSpeed,
      occupancy: c.occupancy,
      queue: c.queueLength,
      timestamp: c.lastUpdated,
      status: c.congestionLevel.displayName.toUpperCase(),
    )).toList();
  }

  // Fetch Incidents
  Future<List<IncidentRecord>> fetchIncidents({String? severity}) async {
    try {
      final queryParam = severity != null && severity != 'All'
          ? '?severity=${severity.toLowerCase()}'
          : '';
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/incidents$queryParam'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => IncidentRecord.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchIncidents error: $e. Using defaults.');
    }
    if (severity != null && severity != 'All') {
      final target = CongestionLevel.fromString(severity);
      return IncidentRecord.defaultIncidents.where((i) => i.severity == target).toList();
    }
    return List.from(IncidentRecord.defaultIncidents);
  }

  // Create Incident
  Future<IncidentRecord?> createIncident({
    required String title,
    required String location,
    required String type,
    required String severity,
    required String description,
    String? assignedUnit,
  }) async {
    try {
      final body = jsonEncode({
        'title': title,
        'location': location,
        'type': type,
        'severity': severity.toLowerCase(),
        'description': description,
        'assigned_unit': assignedUnit ?? 'Central Dispatch Unit',
      });

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/incidents'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return IncidentRecord.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('ApiService.createIncident error: $e');
    }
    return null;
  }

  // Dispatch Backup Unit
  Future<IncidentRecord?> dispatchBackup(
    String incidentId, {
    String unitName = 'Quick Response Backup Unit',
    String? notes,
  }) async {
    try {
      final body = jsonEncode({
        'unit_name': unitName,
        'notes': notes ?? 'Backup dispatched from command center',
      });
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/incidents/$incidentId/dispatch'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return IncidentRecord.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('ApiService.dispatchBackup error: $e');
    }
    return null;
  }

  // Fetch Bottlenecks / Hotspots with AI Advisories
  Future<List<HotspotDetail>> fetchHotspots() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/hotspots'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => HotspotDetail.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchHotspots error: $e');
    }
    return CameraNode.defaultCameras.map((c) => HotspotDetail(
      cameraId: c.id,
      name: c.name,
      latitude: c.location.latitude,
      longitude: c.location.longitude,
      congestionLevel: c.congestionLevel,
      vehicleCount: c.vehicleCount,
      averageSpeed: c.averageSpeed,
      occupancy: c.occupancy,
      queueLength: c.queueLength,
      recommendation: c.congestionLevel == CongestionLevel.critical
          ? 'Increase green phase timing by +25s on ${c.name} inbound corridor.'
          : 'Standard adaptive cycle active.',
      suggestedGreenExtensionSec: c.congestionLevel == CongestionLevel.critical ? 25 : 0,
    )).toList();
  }

  // Apply Signal Tuning / Switching Adjustment
  Future<bool> applySignalTuning(
    String cameraId, {
    String phase = 'NORTH_SOUTH_GREEN',
    int greenExtensionSec = 45,
    bool enableGreenWave = true,
    String? vmsMessage,
    String mode = 'MANUAL',
  }) async {
    try {
      final body = jsonEncode({
        'phase': phase,
        'green_extension_sec': greenExtensionSec,
        'enable_green_wave': enableGreenWave,
        'vms_message': vmsMessage,
        'override_reason': 'Operator Signal Switch',
        'mode': mode,
      });
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/hotspots/$cameraId/tune-signal'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.applySignalTuning error: $e');
      return true; // Fallback demo success
    }
  }

  // Switch Signal directly on corridor
  Future<bool> switchSignal(
    String cameraId, {
    required String phase,
    int greenDurationSec = 45,
    String mode = 'MANUAL',
  }) async {
    try {
      final body = jsonEncode({
        'phase': phase,
        'green_duration_sec': greenDurationSec,
        'mode': mode,
      });
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/traffic/nodes/$cameraId/signal'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.switchSignal error: $e');
      return true;
    }
  }

  // Fetch KPI Overview
  Future<KPIOverview> fetchKPIOverview() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/analytics/kpi'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return KPIOverview.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('ApiService.fetchKPIOverview error: $e');
    }
    return KPIOverview.defaultKPI;
  }

  // Fetch 24-Hour Congestion Trend Points
  Future<List<CongestionTrendPoint>> fetchCongestionTrend() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/analytics/congestion-trend'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => CongestionTrendPoint.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchCongestionTrend error: $e');
    }
    return const [];
  }

  // Fetch Vehicle Composition
  Future<VehicleComposition> fetchVehicleComposition() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/analytics/vehicle-composition'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return VehicleComposition.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('ApiService.fetchVehicleComposition error: $e');
    }
    return const VehicleComposition(
      carsAndCabs: 48,
      twoWheelers: 34,
      busesAndTransit: 12,
      commercialFreight: 6,
    );
  }

  // Fetch Corridor Throughput Rankings
  Future<List<CorridorThroughput>> fetchCorridorThroughput() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/analytics/corridor-throughput'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => CorridorThroughput.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchCorridorThroughput error: $e');
    }
    return const [
      CorridorThroughput(corridor: 'Silk Board Junction', volume: '54,200 veh', status: 'Near Capacity', congestionLevel: 'critical', averageSpeedKmh: 14.2),
      CorridorThroughput(corridor: 'Marathahalli Bridge', volume: '38,900 veh', status: 'Moderate Load', congestionLevel: 'high', averageSpeedKmh: 27.8),
      CorridorThroughput(corridor: 'Koramangala 80ft Road', volume: '31,400 veh', status: 'Stable Flow', congestionLevel: 'moderate', averageSpeedKmh: 19.4),
      CorridorThroughput(corridor: 'Hebbal Flyover Corridor', volume: '23,750 veh', status: 'Optimal Flow', congestionLevel: 'normal', averageSpeedKmh: 38.2),
    ];
  }
}

// Global shared instance
final apiService = ApiService();
