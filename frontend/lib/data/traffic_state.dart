import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/models/traffic_model.dart';
import 'package:frontend/services/api_service.dart';

class TrafficState extends ChangeNotifier {
  static final TrafficState _instance = TrafficState._internal();
  factory TrafficState() => _instance;
  TrafficState._internal();

  List<CameraNode> _cameras = CameraNode.defaultCameras;
  CameraNode? _selectedCamera;
  List<IncidentRecord> _incidents = List.from(IncidentRecord.defaultIncidents);
  List<HotspotDetail> _hotspots = [];
  KPIOverview _kpis = KPIOverview.defaultKPI;
  List<RawTelemetryLog> _rawLogs = [];
  bool _isBackendConnected = false;
  bool _isLoading = false;
  Timer? _pollingTimer;

  List<CameraNode> get cameras => _cameras;
  CameraNode get selectedCamera => _selectedCamera ?? (_cameras.isNotEmpty ? _cameras.first : CameraNode.defaultCameras.first);
  List<IncidentRecord> get incidents => _incidents;
  List<HotspotDetail> get hotspots => _hotspots.isNotEmpty ? _hotspots : _generateDefaultHotspots();
  KPIOverview get kpis => _kpis;
  List<RawTelemetryLog> get rawLogs => _rawLogs.isNotEmpty ? _rawLogs : _generateDefaultLogs();
  bool get isBackendConnected => _isBackendConnected;
  bool get isLoading => _isLoading;

  void initialize() {
    refreshAll();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollLiveTelemetry();
    });
  }

  Future<void> _pollLiveTelemetry() async {
    try {
      final updatedCams = await apiService.fetchCameraNodes();
      if (updatedCams.isNotEmpty) {
        _cameras = updatedCams;
        if (_selectedCamera != null) {
          _selectedCamera = _cameras.firstWhere(
            (c) => c.id == _selectedCamera!.id,
            orElse: () => _cameras.first,
          );
        }
        _isBackendConnected = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isBackendConnected = await apiService.checkHealth();

      final results = await Future.wait([
        apiService.fetchCameraNodes(),
        apiService.fetchIncidents(),
        apiService.fetchHotspots(),
        apiService.fetchKPIOverview(),
        apiService.fetchRawTelemetryLogs(limit: 20),
      ]);

      if (results[0] is List<CameraNode> && (results[0] as List<CameraNode>).isNotEmpty) {
        _cameras = results[0] as List<CameraNode>;
      }
      if (results[1] is List<IncidentRecord> && (results[1] as List<IncidentRecord>).isNotEmpty) {
        _incidents = results[1] as List<IncidentRecord>;
      }
      if (results[2] is List<HotspotDetail> && (results[2] as List<HotspotDetail>).isNotEmpty) {
        _hotspots = results[2] as List<HotspotDetail>;
      }
      if (results[3] is KPIOverview) {
        _kpis = results[3] as KPIOverview;
      }
      if (results[4] is List<RawTelemetryLog> && (results[4] as List<RawTelemetryLog>).isNotEmpty) {
        _rawLogs = results[4] as List<RawTelemetryLog>;
      }

      if (_selectedCamera == null && _cameras.isNotEmpty) {
        _selectedCamera = _cameras.first;
      } else if (_selectedCamera != null) {
        _selectedCamera = _cameras.firstWhere(
          (c) => c.id == _selectedCamera!.id,
          orElse: () => _cameras.first,
        );
      }
    } catch (e) {
      debugPrint('TrafficState.refreshAll error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCamera(CameraNode camera) {
    _selectedCamera = camera;
    notifyListeners();
  }

  Future<bool> createIncident({
    required String title,
    required String location,
    required String type,
    required String severity,
    required String description,
    String? assignedUnit,
  }) async {
    final created = await apiService.createIncident(
      title: title,
      location: location,
      type: type,
      severity: severity,
      description: description,
      assignedUnit: assignedUnit,
    );

    if (created != null) {
      _incidents.insert(0, created);
      notifyListeners();
      return true;
    } else {
      // Local fallback
      final fallbackInc = IncidentRecord(
        id: 'INC-${_incidents.length + 1050}',
        title: title,
        location: location,
        time: 'Just now',
        type: IncidentType.fromString(type),
        severity: CongestionLevel.fromString(severity),
        description: description,
        assignedUnit: assignedUnit ?? 'Local Dispatch',
        status: 'In Progress',
      );
      _incidents.insert(0, fallbackInc);
      notifyListeners();
      return true;
    }
  }

  final Set<String> _tunedCameraIds = {};
  Set<String> get tunedCameraIds => _tunedCameraIds;
  bool isCameraTuned(String id) => _tunedCameraIds.contains(id);

  Future<bool> dispatchBackup(String incidentId, {String? unitName, String? notes}) async {
    final effectiveUnit = unitName ?? 'Patrol Response Unit';
    final updated = await apiService.dispatchBackup(incidentId, unitName: effectiveUnit, notes: notes);
    
    final index = _incidents.indexWhere((i) => i.id == incidentId);
    if (index != -1) {
      if (updated != null) {
        _incidents[index] = updated;
      } else {
        final existing = _incidents[index];
        _incidents[index] = existing.copyWith(
          assignedUnit: existing.assignedUnit.contains(effectiveUnit)
              ? existing.assignedUnit
              : '${existing.assignedUnit} + $effectiveUnit',
          status: 'Dispatched',
        );
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> tuneSignal(
    String cameraId, {
    int greenExtensionSec = 25,
    bool enableGreenWave = true,
    String? vmsMessage,
  }) async {
    _tunedCameraIds.add(cameraId);

    // Reactively optimize local camera telemetry
    final camIndex = _cameras.indexWhere((c) => c.id == cameraId);
    if (camIndex != -1) {
      final cam = _cameras[camIndex];
      final newQueue = (cam.queueLength * 0.6).round();
      final newSpeed = (cam.averageSpeed + 4.8).clamp(10.0, 60.0);
      final newOccupancy = (cam.occupancy - 0.18).clamp(0.15, 0.99);
      final newScore = (cam.congestionScore - 0.25).clamp(0.05, 1.0);
      
      CongestionLevel newLevel = cam.congestionLevel;
      if (cam.congestionLevel == CongestionLevel.critical) {
        newLevel = CongestionLevel.high;
      } else if (cam.congestionLevel == CongestionLevel.high) {
        newLevel = CongestionLevel.moderate;
      } else if (cam.congestionLevel == CongestionLevel.moderate) {
        newLevel = CongestionLevel.normal;
      }

      _cameras[camIndex] = cam.copyWith(
        queueLength: newQueue,
        averageSpeed: newSpeed,
        occupancy: newOccupancy,
        congestionScore: newScore,
        congestionLevel: newLevel,
        lastUpdated: 'Just now (AI Tuned)',
      );
    }

    // Reactively optimize hotspot recommendation
    final hotIndex = _hotspots.indexWhere((h) => h.cameraId == cameraId);
    if (hotIndex != -1) {
      final h = _hotspots[hotIndex];
      _hotspots[hotIndex] = h.copyWith(
        recommendation: 'AI Signal Tuning Active (+${greenExtensionSec}s green phase, Green Wave Synchronized). Congestion dissipating.',
        suggestedGreenExtensionSec: greenExtensionSec,
      );
    }

    notifyListeners();

    final success = await apiService.applySignalTuning(
      cameraId,
      greenExtensionSec: greenExtensionSec,
      enableGreenWave: enableGreenWave,
      vmsMessage: vmsMessage,
    );

    if (_isBackendConnected) {
      _pollLiveTelemetry();
    }
    return success;
  }

  List<HotspotDetail> _generateDefaultHotspots() {
    return _cameras.map((c) => HotspotDetail(
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

  List<RawTelemetryLog> _generateDefaultLogs() {
    return _cameras.map((c) => RawTelemetryLog(
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

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final trafficState = TrafficState();
