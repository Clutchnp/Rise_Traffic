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
  List<IncidentRecord> _incidents = IncidentRecord.defaultIncidents;
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

  Future<bool> dispatchBackup(String incidentId, {String? unitName, String? notes}) async {
    final updated = await apiService.dispatchBackup(incidentId, unitName: unitName ?? 'Patrol Response', notes: notes);
    if (updated != null) {
      final index = _incidents.indexWhere((i) => i.id == incidentId);
      if (index != -1) {
        _incidents[index] = updated;
        notifyListeners();
      }
      return true;
    } else {
      final index = _incidents.indexWhere((i) => i.id == incidentId);
      if (index != -1) {
        final existing = _incidents[index];
        _incidents[index] = existing.copyWith(
          assignedUnit: '${existing.assignedUnit} + ${unitName ?? "Backup Patrol"}',
          status: 'Dispatched',
        );
        notifyListeners();
      }
      return true;
    }
  }

  Future<bool> tuneSignal(String cameraId, {int greenExtensionSec = 25, bool enableGreenWave = true, String? vmsMessage}) async {
    final success = await apiService.applySignalTuning(
      cameraId,
      greenExtensionSec: greenExtensionSec,
      enableGreenWave: enableGreenWave,
      vmsMessage: vmsMessage,
    );
    if (success) {
      // Trigger instant telemetry update
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
