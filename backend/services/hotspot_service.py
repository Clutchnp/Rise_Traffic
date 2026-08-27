from typing import List, Optional, Dict, Any
from datetime import datetime
from backend.models.traffic import CongestionLevel, CameraNodeModel, SwitchSignalRequest
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

    def get_hotspots(self) -> List[HotspotDetailModel]:
        cameras = traffic_service.get_cameras()
        surge_info = traffic_service.get_surge_status()
        hotspots = []

        for cam in cameras:
            is_surging = cam.id == surge_info["current_surge_id"]
            if is_surging:
                rec = f"Live 30s Congestion Surge Active. Recommend {cam.green_time_sec}s priority green phase."
            elif cam.congestion_level == CongestionLevel.CRITICAL:
                rec = f"High queue accumulation. Standard clearance cycle active ({cam.green_time_sec}s green)."
            elif cam.congestion_level == CongestionLevel.HIGH:
                rec = f"Moderate corridor delay. Flow steady under adaptive control."
            else:
                rec = f"Corridor free-flowing. Signal cycle balanced."

            hotspots.append(
                HotspotDetailModel(
                    camera_id=cam.id,
                    name=cam.name,
                    latitude=cam.latitude,
                    longitude=cam.longitude,
                    congestion_level=cam.congestion_level,
                    congestion_score=cam.congestion_score,
                    vehicle_count=cam.vehicle_count,
                    average_speed=cam.average_speed,
                    occupancy=cam.occupancy,
                    queue_length=cam.queue_length,
                    signal_phase=cam.signal_phase,
                    green_time_sec=cam.green_time_sec,
                    signal_mode=cam.signal_mode,
                    is_surge_active=is_surging,
                    recommendation=rec,
                    suggested_green_extension_sec=cam.green_time_sec,
                )
            )

        # Sort bottlenecks by congestion score descending (highest score first)
        hotspots.sort(key=lambda h: h.congestion_score, reverse=True)
        return hotspots

    def get_advisory_for_camera(self, camera_id: str) -> Optional[SignalAdvisoryModel]:
        cam = traffic_service.get_camera(camera_id)
        if not cam:
            return None
        return SignalAdvisoryModel(
            corridor_id=cam.id,
            corridor_name=cam.name,
            current_congestion=cam.congestion_level,
            recommendation_title=f"Signal State Controller: {cam.name}",
            recommendation_text=f"Phase: {cam.signal_phase} | Timer: {cam.green_time_sec}s | Mode: {cam.signal_mode}",
            suggested_green_extension_sec=cam.green_time_sec,
            enable_vms_reroute=(cam.congestion_level == CongestionLevel.CRITICAL),
            enable_green_wave=(cam.congestion_level in [CongestionLevel.CRITICAL, CongestionLevel.HIGH]),
        )

    def apply_signal_tuning(
        self, camera_id: str, req: SignalTuningRequest
    ) -> Optional[SignalTuningResponse]:
        cam = traffic_service.get_camera(camera_id)
        if not cam:
            return None

        phase = req.phase or "NORTH_SOUTH_GREEN"
        duration = req.green_extension_sec or 45
        mode = req.mode or "MANUAL"

        # Apply to live simulation service
        traffic_service.switch_signal(
            camera_id=camera_id,
            req=SwitchSignalRequest(
                phase=phase,
                green_duration_sec=duration,
                mode=mode,
            ),
        )

        applied_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        log_entry = {
            "camera_id": camera_id,
            "corridor_name": cam.name,
            "applied_phase": phase,
            "applied_green_extension_sec": duration,
            "signal_mode": mode,
            "vms_message": req.vms_message,
            "override_reason": req.override_reason,
            "applied_at": applied_at,
        }
        self._tuning_history.append(log_entry)

        return SignalTuningResponse(
            status="success",
            message=f"Signal switched to {phase} ({duration}s) on {cam.name}",
            camera_id=camera_id,
            corridor_name=cam.name,
            applied_phase=phase,
            applied_green_extension_sec=duration,
            applied_at=applied_at,
        )

    def get_tuning_history(self) -> List[Dict[str, Any]]:
        return list(reversed(self._tuning_history[-50:]))


hotspot_service = HotspotService()

