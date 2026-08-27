import random
from datetime import datetime
from typing import List, Dict, Optional, Any
from collections import deque

from backend.config import DEFAULT_CORRIDORS, CONGESTION_THRESHOLDS
from backend.models.traffic import (
    CameraNodeModel,
    CongestionLevel,
    TrafficSummaryModel,
    RawTelemetryEntry,
    IngestTelemetryRequest,
)


def get_temporal_multiplier(hour: int, corridor_id: str) -> float:
    """Computes realistic diurnal traffic flow multiplier."""
    # Morning rush
    if 8 <= hour <= 10:
        base = 1.6
    # Evening rush
    elif 17 <= hour <= 21:
        base = 1.75
    # Midday
    elif 11 <= hour <= 16:
        base = 1.05
    # Late night / early morning
    elif 22 <= hour or hour <= 5:
        base = 0.35
    else:
        base = 0.8

    # Specific corridor factors
    if corridor_id in ["CAM-001", "CAM-002", "CAM-007"]:
        base *= 1.15
    return base


import time
import random
from datetime import datetime
from typing import List, Dict, Optional, Any
from collections import deque

from backend.config import DEFAULT_CORRIDORS
from backend.models.traffic import (
    CameraNodeModel,
    CongestionLevel,
    TrafficSummaryModel,
    RawTelemetryEntry,
    IngestTelemetryRequest,
    SwitchSignalRequest,
)
from backend.traffic_processor import congestion_ml_engine


# Corridors order for the 30-second rotating congestion surge demo
SURGE_CYCLE_CORRIDORS = [
    "CAM-001",  # Silk Board Junction
    "CAM-002",  # Marathahalli Bridge
    "CAM-004",  # Hebbal Flyover
    "CAM-007",  # Whitefield ITPL Main Rd
    "CAM-008",  # Electronic City Toll Plaza
    "CAM-006",  # Indiranagar 100ft Rd
    "CAM-003",  # Koramangala 80ft Rd
    "CAM-005",  # MG Road Junction
]

SURGE_INTERVAL_SECONDS = 30.0


class TrafficSimulationService:
    """
    Simulates a live multi-corridor traffic grid with a dynamic 30-second rotating
    congestion surge and ML-driven score calculation, plus real-time signal phase switching.
    """

    def __init__(self):
        self._corridors: Dict[str, Dict[str, Any]] = {
            c["camera_id"]: dict(c) for c in DEFAULT_CORRIDORS
        }
        self._live_nodes: Dict[str, CameraNodeModel] = {}
        self._raw_logs: deque = deque(maxlen=100)

        # Dynamic signal state per corridor
        self._signal_states: Dict[str, Dict[str, Any]] = {
            c["camera_id"]: {
                "signal_phase": "NORTH_SOUTH_GREEN",
                "green_time_sec": 45,
                "signal_mode": "ADAPTIVE",
                "manual_clearance_bonus": 0.0,
            }
            for c in DEFAULT_CORRIDORS
        }

        # Simulation clock for 30s surge cycles
        self._start_time = time.time()
        self.update_all()

    def get_surge_status(self) -> Dict[str, Any]:
        """Returns the current active 30s congestion surge junction and countdown."""
        elapsed = time.time() - self._start_time
        cycle_idx = int(elapsed // SURGE_INTERVAL_SECONDS) % len(SURGE_CYCLE_CORRIDORS)
        current_surge_id = SURGE_CYCLE_CORRIDORS[cycle_idx]
        next_surge_id = SURGE_CYCLE_CORRIDORS[(cycle_idx + 1) % len(SURGE_CYCLE_CORRIDORS)]
        seconds_remaining = int(SURGE_INTERVAL_SECONDS - (elapsed % SURGE_INTERVAL_SECONDS))

        current_name = self._corridors.get(current_surge_id, {}).get("name", current_surge_id)
        next_name = self._corridors.get(next_surge_id, {}).get("name", next_surge_id)

        return {
            "current_surge_id": current_surge_id,
            "current_surge_name": current_name,
            "next_surge_id": next_surge_id,
            "next_surge_name": next_name,
            "seconds_remaining": max(1, seconds_remaining),
            "cycle_interval_sec": int(SURGE_INTERVAL_SECONDS),
        }

    def _compute_node(self, corridor: Dict[str, Any]) -> CameraNodeModel:
        now = datetime.now()
        cam_id = corridor["camera_id"]
        base_traffic = corridor.get("base_traffic", 100)
        is_online = corridor.get("is_online", True)

        signal_info = self._signal_states.get(
            cam_id,
            {
                "signal_phase": "NORTH_SOUTH_GREEN",
                "green_time_sec": 45,
                "signal_mode": "ADAPTIVE",
                "manual_clearance_bonus": 0.0,
            },
        )

        if not is_online:
            return CameraNodeModel(
                id=cam_id,
                name=corridor["name"],
                latitude=corridor["latitude"],
                longitude=corridor["longitude"],
                is_online=False,
                vehicle_count=0,
                average_speed=0.0,
                occupancy=0.0,
                queue_length=0,
                congestion_score=0.0,
                congestion_level=CongestionLevel.NORMAL,
                last_updated=now.strftime("%H:%M:%S"),
                description=corridor.get("description", ""),
                signal_phase=signal_info["signal_phase"],
                green_time_sec=signal_info["green_time_sec"],
                signal_mode=signal_info["signal_mode"],
                is_surge_active=False,
            )

        surge_info = self.get_surge_status()
        is_surging = cam_id == surge_info["current_surge_id"]

        # Decay manual clearance bonus gradually
        bonus = signal_info.get("manual_clearance_bonus", 0.0)
        if bonus > 0:
            signal_info["manual_clearance_bonus"] = max(0.0, bonus - 0.08)

        # Influx logic: Surging junction experiences heavy volume surge
        if is_surging:
            surge_mult = random.uniform(1.65, 2.15)
            speed_penalty = random.uniform(28.0, 36.0)
            occ_boost = random.uniform(0.72, 0.92)
        else:
            surge_mult = random.uniform(0.65, 1.05)
            speed_penalty = random.uniform(4.0, 14.0)
            occ_boost = random.uniform(0.18, 0.45)

        # Apply signal clearance relief if green phase or priority is active
        clearance_relief = (bonus * 0.3) + (0.1 if signal_info["signal_phase"] in ["NORTH_SOUTH_GREEN", "PRIORITY_CLEARANCE"] else 0.0)

        vehicle_count = max(
            8,
            int(base_traffic * surge_mult * (1.0 - clearance_relief * 0.4) + random.gauss(0, 5)),
        )
        average_speed = round(
            max(7.0, min(58.0, 48.0 - speed_penalty + (clearance_relief * 14.0) + random.uniform(-1.5, 1.5))),
            1,
        )
        occupancy = round(
            max(0.08, min(0.98, occ_boost - (clearance_relief * 0.25) + random.uniform(-0.02, 0.02))),
            2,
        )

        # Run inference through ML Congestion Engine
        ml_result = congestion_ml_engine.predict_congestion(
            camera_id=cam_id,
            vehicle_count=vehicle_count,
            average_speed=average_speed,
            occupancy=occupancy,
            incident_impact=0.4 if is_surging else 0.0,
        )

        score = ml_result["congestion_score"]
        level_str = ml_result["congestion_level"]
        queue_len = ml_result["queue_length"]

        # Map to enum
        if level_str == "critical":
            level = CongestionLevel.CRITICAL
        elif level_str == "high":
            level = CongestionLevel.HIGH
        elif level_str == "moderate":
            level = CongestionLevel.MODERATE
        else:
            level = CongestionLevel.NORMAL

        formatted_time = now.strftime("%H:%M:%S")

        node = CameraNodeModel(
            id=cam_id,
            name=corridor["name"],
            latitude=corridor["latitude"],
            longitude=corridor["longitude"],
            is_online=is_online,
            vehicle_count=vehicle_count,
            average_speed=average_speed,
            occupancy=occupancy,
            queue_length=queue_len,
            congestion_score=score,
            congestion_level=level,
            last_updated=formatted_time,
            description=corridor.get("description", ""),
            signal_phase=signal_info["signal_phase"],
            green_time_sec=signal_info["green_time_sec"],
            signal_mode=signal_info["signal_mode"],
            is_surge_active=is_surging,
        )

        self._raw_logs.appendleft(
            RawTelemetryEntry(
                camera_id=node.id,
                corridor_location=node.name,
                vehicles=node.vehicle_count,
                avg_speed=node.average_speed,
                occupancy=node.occupancy,
                queue=node.queue_length,
                timestamp=node.last_updated,
                status=node.congestion_level.value.upper(),
            )
        )

        return node

    def update_all(self) -> List[CameraNodeModel]:
        """Executes simulation cycle tick across all corridors with current surge state."""
        nodes = []
        for cam_id, corridor in self._corridors.items():
            node = self._compute_node(corridor)
            self._live_nodes[cam_id] = node
            nodes.append(node)
        return nodes

    def get_cameras(self) -> List[CameraNodeModel]:
        return list(self._live_nodes.values())

    def get_camera(self, camera_id: str) -> Optional[CameraNodeModel]:
        return self._live_nodes.get(camera_id)

    def get_raw_logs(self, limit: int = 50) -> List[RawTelemetryEntry]:
        return list(self._raw_logs)[:limit]

    def switch_signal(self, camera_id: str, req: SwitchSignalRequest) -> Optional[CameraNodeModel]:
        """Manually switches the traffic signal phase and timer for a corridor."""
        if camera_id not in self._corridors:
            return None

        state = self._signal_states.setdefault(
            camera_id,
            {
                "signal_phase": "NORTH_SOUTH_GREEN",
                "green_time_sec": 45,
                "signal_mode": "MANUAL",
                "manual_clearance_bonus": 0.0,
            },
        )

        state["signal_phase"] = req.phase
        state["green_time_sec"] = req.green_duration_sec or 45
        state["signal_mode"] = req.mode or "MANUAL"
        state["manual_clearance_bonus"] = 1.0  # Immediate queue clearance bonus

        # Recompute node immediately
        node = self._compute_node(self._corridors[camera_id])
        self._live_nodes[camera_id] = node
        return node

    def ingest_telemetry(self, req: IngestTelemetryRequest) -> CameraNodeModel:
        now = datetime.now()
        formatted_time = now.strftime("%H:%M:%S")

        corridor_info = self._corridors.get(req.camera_id, {})
        name = req.location or corridor_info.get("name", f"Sensor Node {req.camera_id}")
        lat = req.latitude or corridor_info.get("latitude", 12.9716)
        lon = req.longitude or corridor_info.get("longitude", 77.5946)

        ml_result = congestion_ml_engine.predict_congestion(
            camera_id=req.camera_id,
            vehicle_count=req.vehicle_count,
            average_speed=req.average_speed,
            occupancy=req.occupancy,
        )

        level_str = ml_result["congestion_level"]
        level = (
            CongestionLevel.CRITICAL
            if level_str == "critical"
            else (
                CongestionLevel.HIGH
                if level_str == "high"
                else (
                    CongestionLevel.MODERATE
                    if level_str == "moderate"
                    else CongestionLevel.NORMAL
                )
            )
        )

        node = CameraNodeModel(
            id=req.camera_id,
            name=name,
            latitude=lat,
            longitude=lon,
            is_online=True,
            vehicle_count=req.vehicle_count,
            average_speed=req.average_speed,
            occupancy=req.occupancy,
            queue_length=req.queue_length or ml_result["queue_length"],
            congestion_score=ml_result["congestion_score"],
            congestion_level=level,
            last_updated=formatted_time,
            description="Manually ingested telemetry reading",
            signal_phase="NORTH_SOUTH_GREEN",
            green_time_sec=45,
            signal_mode="MANUAL",
            is_surge_active=False,
        )

        self._live_nodes[req.camera_id] = node
        self._raw_logs.appendleft(
            RawTelemetryEntry(
                camera_id=node.id,
                corridor_location=node.name,
                vehicles=node.vehicle_count,
                avg_speed=node.average_speed,
                occupancy=node.occupancy,
                queue=node.queue_length,
                timestamp=node.last_updated,
                status=node.congestion_level.value.upper(),
            )
        )
        return node

    def get_summary(self) -> TrafficSummaryModel:
        cameras = self.get_cameras()
        online_cams = [c for c in cameras if c.is_online]
        active_count = len(online_cams)
        total_vehicles = sum(c.vehicle_count for c in online_cams)
        avg_speed = round(
            sum(c.average_speed for c in online_cams) / active_count if active_count > 0 else 0.0,
            1,
        )

        critical_count = sum(1 for c in online_cams if c.congestion_level == CongestionLevel.CRITICAL)
        high_count = sum(1 for c in online_cams if c.congestion_level == CongestionLevel.HIGH)

        if critical_count > 0:
            overall = "Critical"
        elif high_count > 0:
            overall = "High"
        else:
            overall = "Moderate"

        surge_info = self.get_surge_status()

        return TrafficSummaryModel(
            status="success",
            active_corridors=active_count,
            overall_status=overall,
            average_speed=avg_speed,
            total_vehicles=total_vehicles,
            cameras=cameras,
            active_surge_corridor=surge_info["current_surge_name"],
            seconds_to_next_surge=surge_info["seconds_remaining"],
        )


traffic_service = TrafficSimulationService()

