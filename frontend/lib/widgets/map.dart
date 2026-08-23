import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/models/traffic_model.dart';
import 'package:latlong2/latlong.dart';

class TrafficMapPanel extends StatelessWidget {
  final List<CameraNode>? cameras;
  final String? selectedCameraId;
  final ValueChanged<CameraNode>? onCameraSelected;
  final bool showControls;

  const TrafficMapPanel({
    super.key,
    this.cameras,
    this.selectedCameraId,
    this.onCameraSelected,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayCameras = cameras ?? CameraNode.defaultCameras;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(12.9716, 77.6412),
              initialZoom: 11.8,
              minZoom: 9.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rise.traffic.frontend',
              ),
              MarkerLayer(
                markers: displayCameras.map((camera) {
                  final isSelected = camera.id == selectedCameraId;
                  return Marker(
                    point: camera.location,
                    width: isSelected ? 120 : 90,
                    height: isSelected ? 65 : 55,
                    child: GestureDetector(
                      onTap: () {
                        if (onCameraSelected != null) {
                          onCameraSelected!(camera);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : camera.congestionLevel.color,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              camera.name.split(' ').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: isSelected ? 24 : 18,
                            height: isSelected ? 24 : 18,
                            decoration: BoxDecoration(
                              color: camera.congestionLevel.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: camera.congestionLevel.color.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.videocam,
                                size: isSelected ? 12 : 9,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap',
                  ),
                ],
              ),
            ],
          ),

          // Map legend / Overlay tag
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendItem(color: AppColors.trafficCritical, label: 'Critical'),
                  const SizedBox(width: 8),
                  _LegendItem(color: AppColors.trafficHigh, label: 'High'),
                  const SizedBox(width: 8),
                  _LegendItem(color: AppColors.trafficModerate, label: 'Moderate'),
                  const SizedBox(width: 8),
                  _LegendItem(color: AppColors.trafficNormal, label: 'Normal'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
