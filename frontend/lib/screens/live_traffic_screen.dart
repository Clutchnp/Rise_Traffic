import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/data/traffic_state.dart';
import 'package:frontend/models/traffic_model.dart';
import 'package:frontend/widgets/map.dart';

class LiveTrafficScreen extends StatefulWidget {
  const LiveTrafficScreen({super.key});

  @override
  State<LiveTrafficScreen> createState() => _LiveTrafficScreenState();
}

class _LiveTrafficScreenState extends State<LiveTrafficScreen> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: trafficState,
      builder: (context, _) {
        final allCameras = trafficState.cameras;
        final selectedCamera = trafficState.selectedCamera;
        final rawLogs = trafficState.rawLogs;
        final isConnected = trafficState.isBackendConnected;

        List<CameraNode> filteredCameras = allCameras;
        if (selectedFilter == 'Online') {
          filteredCameras = allCameras.where((c) => c.isOnline).toList();
        } else if (selectedFilter == 'Congested') {
          filteredCameras = allCameras
              .where((c) =>
                  c.congestionLevel == CongestionLevel.critical ||
                  c.congestionLevel == CongestionLevel.high)
              .toList();
        }

        final onlineCount = allCameras.where((c) => c.isOnline).length;
        final congestedCount = allCameras
            .where((c) =>
                c.congestionLevel == CongestionLevel.critical ||
                c.congestionLevel == CongestionLevel.high)
            .length;

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Traffic Feeds',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Real-time corridor view and camera telemetry stream',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // FILTERS
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FilterButton(
                      icon: Icons.videocam_outlined,
                      label: 'All Cameras (${allCameras.length})',
                      isSelected: selectedFilter == 'All',
                      onPressed: () => setState(() => selectedFilter = 'All'),
                    ),
                    _FilterButton(
                      icon: Icons.wifi,
                      label: 'Online Only ($onlineCount)',
                      isSelected: selectedFilter == 'Online',
                      onPressed: () => setState(() => selectedFilter = 'Online'),
                    ),
                    _FilterButton(
                      icon: Icons.warning_amber_rounded,
                      label: 'Congested Zones ($congestedCount)',
                      isSelected: selectedFilter == 'Congested',
                      onPressed: () => setState(() => selectedFilter = 'Congested'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: isConnected
                                ? AppColors.systemOnline
                                : AppColors.trafficModerate,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            isConnected ? 'TELEMETRY LIVE' : 'OFFLINE SYNC',
                            style: TextStyle(
                              color: isConnected
                                  ? AppColors.systemOnline
                                  : AppColors.trafficModerate,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // MAP + CAMERA NETWORK
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;

                    if (isDesktop) {
                      return SizedBox(
                        height: 420,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _TrafficMapCard(
                                cameras: filteredCameras,
                                selectedCameraId: selectedCamera.id,
                                onCameraSelected: (camera) {
                                  trafficState.selectCamera(camera);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _CameraNetworkCard(
                                cameras: filteredCameras,
                                selectedCameraId: selectedCamera.id,
                                onSelectCamera: (camera) {
                                  trafficState.selectCamera(camera);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 340,
                          child: _TrafficMapCard(
                            cameras: filteredCameras,
                            selectedCameraId: selectedCamera.id,
                            onCameraSelected: (camera) {
                              trafficState.selectCamera(camera);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _CameraNetworkCard(
                          cameras: filteredCameras,
                          selectedCameraId: selectedCamera.id,
                          onSelectCamera: (camera) {
                            trafficState.selectCamera(camera);
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // SELECTED CAMERA TELEMETRY
                _SelectedCameraCard(camera: selectedCamera),

                const SizedBox(height: 20),

                // RAW TELEMETRY DATA TABLE
                _RawTelemetryCard(
                  logs: rawLogs,
                  cameras: allCameras,
                  onSelectCamera: (cam) => trafficState.selectCamera(cam),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// MAP CARD
class _TrafficMapCard extends StatelessWidget {
  final List<CameraNode> cameras;
  final String selectedCameraId;
  final ValueChanged<CameraNode> onCameraSelected;

  const _TrafficMapCard({
    required this.cameras,
    required this.selectedCameraId,
    required this.onCameraSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Text(
                  'Live Corridor Map',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Text(
                  'CLICK MARKER TO INSPECT',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TrafficMapPanel(
              cameras: cameras,
              selectedCameraId: selectedCameraId,
              onCameraSelected: onCameraSelected,
            ),
          ),
        ],
      ),
    );
  }
}

// CAMERA NETWORK LIST CARD
class _CameraNetworkCard extends StatelessWidget {
  final List<CameraNode> cameras;
  final String selectedCameraId;
  final ValueChanged<CameraNode> onSelectCamera;

  const _CameraNetworkCard({
    required this.cameras,
    required this.selectedCameraId,
    required this.onSelectCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Camera Nodes',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a sensor to view telemetry',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: cameras.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                final cam = cameras[index];
                final isSelected = cam.id == selectedCameraId;
                return InkWell(
                  onTap: () => onSelectCamera(cam),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.surfaceElevated
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: cam.isOnline
                              ? AppColors.systemOnline
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cam.id,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cam.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cam.congestionLevel.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            cam.isOnline ? cam.congestionLevel.displayName : 'OFFLINE',
                            style: TextStyle(
                              color: cam.isOnline
                                  ? cam.congestionLevel.color
                                  : AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// SELECTED CAMERA DETAILS
class _SelectedCameraCard extends StatelessWidget {
  final CameraNode camera;

  const _SelectedCameraCard({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.videocam_outlined,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${camera.id} · ${camera.name}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Last updated at ${camera.lastUpdated} • Status: ${camera.congestionLevel.displayName} Congestion (Score: ${(camera.congestionScore * 100).toInt()}%)',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: camera.isOnline
                      ? AppColors.systemOnline.withValues(alpha: 0.1)
                      : AppColors.trafficCritical.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: camera.isOnline
                        ? AppColors.systemOnline.withValues(alpha: 0.3)
                        : AppColors.trafficCritical.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: camera.isOnline
                          ? AppColors.systemOnline
                          : AppColors.trafficCritical,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      camera.isOnline ? 'FEED ACTIVE' : 'FEED OFFLINE',
                      style: TextStyle(
                        color: camera.isOnline
                            ? AppColors.systemOnline
                            : AppColors.trafficCritical,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 4 : 2;

              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: columns == 4 ? 2.6 : 2.2,
                children: [
                  _TelemetryValue(
                    label: 'VEHICLES COUNT',
                    value: '${camera.vehicleCount}',
                    icon: Icons.directions_car_outlined,
                  ),
                  _TelemetryValue(
                    label: 'AVERAGE SPEED',
                    value: '${camera.averageSpeed} km/h',
                    icon: Icons.speed_outlined,
                  ),
                  _TelemetryValue(
                    label: 'LANE OCCUPANCY',
                    value: '${(camera.occupancy * 100).toInt()}%',
                    icon: Icons.pie_chart_outline,
                  ),
                  _TelemetryValue(
                    label: 'ESTIMATED QUEUE',
                    value: '${camera.queueLength} veh',
                    icon: Icons.linear_scale_outlined,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TelemetryValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TelemetryValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// RAW TELEMETRY TABLE
class _RawTelemetryCard extends StatelessWidget {
  final List<RawTelemetryLog> logs;
  final List<CameraNode> cameras;
  final ValueChanged<CameraNode> onSelectCamera;

  const _RawTelemetryCard({
    required this.logs,
    required this.cameras,
    required this.onSelectCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Raw Sensor Telemetry Log',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Unprocessed edge computing readings received from the camera network',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 28,
                headingTextStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                dataTextStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                columns: const [
                  DataColumn(label: Text('CAMERA ID')),
                  DataColumn(label: Text('CORRIDOR LOCATION')),
                  DataColumn(label: Text('VEHICLES')),
                  DataColumn(label: Text('AVG SPEED')),
                  DataColumn(label: Text('OCCUPANCY')),
                  DataColumn(label: Text('QUEUE')),
                  DataColumn(label: Text('TIMESTAMP')),
                  DataColumn(label: Text('ACTION')),
                ],
                rows: logs.map((log) {
                  return DataRow(
                    cells: [
                      DataCell(Text(log.cameraId, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                      DataCell(Text(log.corridorLocation)),
                      DataCell(Text('${log.vehicles}')),
                      DataCell(Text('${log.avgSpeed} km/h')),
                      DataCell(Text('${(log.occupancy * 100).toInt()}%')),
                      DataCell(Text('${log.queue} veh')),
                      DataCell(Text(log.timestamp)),
                      DataCell(
                        TextButton(
                          onPressed: () {
                            final match = cameras.firstWhere(
                              (c) => c.id == log.cameraId,
                              orElse: () => cameras.first,
                            );
                            onSelectCamera(match);
                          },
                          child: const Text('Inspect', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// FILTER BUTTON
class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 15,
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : AppColors.textSecondary,
        backgroundColor: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
        side: BorderSide(
          color: isSelected ? AppColors.accent : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
