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
try:
    from backend.signal_control.models import (
        ApproachState,
        IntersectionState,
        Phase,
    )
    from backend.signal_control.optimizer import AdaptiveSignalOptimizer
except ImportError:
    from src.models import (
        ApproachState,
        IntersectionState,
        Phase,
    )
    from src.optimizer import AdaptiveSignalOptimizer


class HotspotService:
    def __init__(self):
        self._tuning_history: List[Dict[str, Any]] = []
        self.optimizer = AdaptiveSignalOptimizer()

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

        # Convert current camera data into optimizer input.
        # Your current telemetry does not contain directional
        # North/South/East/West values, so we split the queue
        # between the two phases for now.

        ns_queue = cam.queue_length * 0.6
        ew_queue = cam.queue_length * 0.4

        ns_arrival = max(0.1, cam.vehicle_count * 0.01 * 0.6)
        ew_arrival = max(0.1, cam.vehicle_count * 0.01 * 0.4)

        state = IntersectionState(
            intersection_id=cam.id,
            north=ApproachState(
                name="north",
                queue=ns_queue / 2,
                arrival_rate=ns_arrival / 2,
                saturation_flow=1.5,
                speed_kph=cam.average_speed,
            ),
            south=ApproachState(
                name="south",
                queue=ns_queue / 2,
                arrival_rate=ns_arrival / 2,
                saturation_flow=1.5,
                speed_kph=cam.average_speed,
            ),
            east=ApproachState(
                name="east",
                queue=ew_queue / 2,
                arrival_rate=ew_arrival / 2,
                saturation_flow=1.5,
                speed_kph=cam.average_speed,
            ),
            west=ApproachState(
                name="west",
                queue=ew_queue / 2,
                arrival_rate=ew_arrival / 2,
                saturation_flow=1.5,
                speed_kph=cam.average_speed,
            ),
            current_phase=(
                Phase.NORTH_SOUTH
                if "NORTH_SOUTH" in cam.signal_phase
                else Phase.EAST_WEST
            ),
            prediction_horizon=15.0,
        )

        # Run the actual adaptive signal optimizer
        plan = self.optimizer.optimize(state)

        ns_green = plan.green_for(Phase.NORTH_SOUTH)
        ew_green = plan.green_for(Phase.EAST_WEST)

        current_green = ns_green if "NORTH_SOUTH" in cam.signal_phase else ew_green

        return SignalAdvisoryModel(
            corridor_id=cam.id,
            corridor_name=cam.name,
            current_congestion=cam.congestion_level,
            recommendation_title="Adaptive Signal Optimization",
            recommendation_text=(
                f"{plan.explanation} "
                f"Recommended timing: "
                f"North/South={ns_green}s, "
                f"East/West={ew_green}s."
            ),
            suggested_green_extension_sec=current_green,
            enable_vms_reroute=(cam.congestion_level == CongestionLevel.CRITICAL),
            enable_green_wave=(
                cam.congestion_level
                in [
                    CongestionLevel.CRITICAL,
                    CongestionLevel.HIGH,
                ]
            ),
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
