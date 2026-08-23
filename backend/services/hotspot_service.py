from typing import List, Optional, Dict, Any
from datetime import datetime
from backend.models.traffic import CongestionLevel, CameraNodeModel
from backend.models.hotspots import (
    HotspotDetailModel,
    SignalAdvisoryModel,
    SignalTuningRequest,
    SignalTuningResponse,
)
from backend.services.sim_service import traffic_service


class HotspotService:
    def __init__(self):
        self._tuning_history: List[Dict[str, Any]] = []

    def _generate_recommendation(self, node: CameraNodeModel) -> tuple[str, int]:
        if node.congestion_level == CongestionLevel.CRITICAL:
            rec = (
                f"Increase green phase timing by +25s on {node.name} inbound corridor. "
                f"Recommend activating dynamic variable message signs (VMS) for peripheral bypass."
            )
            ext_sec = 25
        elif node.congestion_level == CongestionLevel.HIGH:
            rec = (
                f"Enable dynamic green-wave progression towards downstream artery from {node.name}. "
                f"Disperse traffic flow at service lane merging points (+15s green phase)."
            )
            ext_sec = 15
        elif node.congestion_level == CongestionLevel.MODERATE:
            rec = (
                f"Standard adaptive cycle active for {node.name}. "
                f"Minor queue accumulation detected on secondary approaches (+5s adjustment)."
            )
            ext_sec = 5
        else:
            rec = f"Corridor {node.name} is free-flowing. Standard off-peak baseline signal timing maintained."
            ext_sec = 0
        return rec, ext_sec

    def get_hotspots(self) -> List[HotspotDetailModel]:
        cameras = traffic_service.get_cameras()
        hotspots = []
        for cam in cameras:
            rec_text, ext_sec = self._generate_recommendation(cam)
            hotspots.append(
                HotspotDetailModel(
                    camera_id=cam.id,
                    name=cam.name,
                    latitude=cam.latitude,
                    longitude=cam.longitude,
                    congestion_level=cam.congestion_level,
                    vehicle_count=cam.vehicle_count,
                    average_speed=cam.average_speed,
                    occupancy=cam.occupancy,
                    queue_length=cam.queue_length,
                    recommendation=rec_text,
                    suggested_green_extension_sec=ext_sec,
                )
            )
        # Sort bottlenecks by critical -> high -> moderate -> normal
        level_order = {
            CongestionLevel.CRITICAL: 0,
            CongestionLevel.HIGH: 1,
            CongestionLevel.MODERATE: 2,
            CongestionLevel.NORMAL: 3,
        }
        hotspots.sort(key=lambda h: level_order.get(h.congestion_level, 99))
        return hotspots

    def get_advisory_for_camera(self, camera_id: str) -> Optional[SignalAdvisoryModel]:
        cam = traffic_service.get_camera(camera_id)
        if not cam:
            return None
        rec_text, ext_sec = self._generate_recommendation(cam)
        return SignalAdvisoryModel(
            corridor_id=cam.id,
            corridor_name=cam.name,
            current_congestion=cam.congestion_level,
            recommendation_title=f"Adaptive Signal Optimization Advisory: {cam.name}",
            recommendation_text=rec_text,
            suggested_green_extension_sec=ext_sec,
            enable_vms_reroute=(cam.congestion_level == CongestionLevel.CRITICAL),
            enable_green_wave=(cam.congestion_level in [CongestionLevel.CRITICAL, CongestionLevel.HIGH]),
        )

    def apply_signal_tuning(
        self, camera_id: str, req: SignalTuningRequest
    ) -> Optional[SignalTuningResponse]:
        cam = traffic_service.get_camera(camera_id)
        if not cam:
            return None

        applied_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        ext = req.green_extension_sec or 20

        log_entry = {
            "camera_id": camera_id,
            "corridor_name": cam.name,
            "applied_green_extension_sec": ext,
            "enable_green_wave": req.enable_green_wave,
            "vms_message": req.vms_message,
            "override_reason": req.override_reason,
            "applied_at": applied_at,
        }
        self._tuning_history.append(log_entry)

        return SignalTuningResponse(
            status="success",
            message=f"Successfully applied dynamic signal timing adjustment for {cam.name}",
            camera_id=camera_id,
            corridor_name=cam.name,
            applied_green_extension_sec=ext,
            applied_at=applied_at,
        )

    def get_tuning_history(self) -> List[Dict[str, Any]]:
        return list(reversed(self._tuning_history[-50:]))


hotspot_service = HotspotService()
