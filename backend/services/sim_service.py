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


class TrafficSimulationService:
    def __init__(self):
        self._corridors: Dict[str, Dict[str, Any]] = {
            c["camera_id"]: dict(c) for c in DEFAULT_CORRIDORS
        }
        self._live_nodes: Dict[str, CameraNodeModel] = {}
        self._raw_logs: deque = deque(maxlen=100)
        self.update_all()

    def _compute_node(self, corridor: Dict[str, Any]) -> CameraNodeModel:
        now = datetime.now()
        hour = now.hour
        cam_id = corridor["camera_id"]
        base_traffic = corridor.get("base_traffic", 100)
        is_online = corridor.get("is_online", True)

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
            )

        time_factor = get_temporal_multiplier(hour, cam_id)
        expected_vehicles = base_traffic * time_factor

        # Gaussian sampling for vehicle counts
        vehicle_count = max(5, int(random.gauss(expected_vehicles, expected_vehicles * 0.08)))

        # Congestion ratio
        congestion_ratio = min(1.0, vehicle_count / (base_traffic * 1.65))

        # Speed deceleration curve
        average_speed = 48.0 - (congestion_ratio * 34.0) + random.uniform(-2.5, 2.5)
        average_speed = round(max(5.0, min(65.0, average_speed)), 1)

        # Occupancy
        occupancy = 0.12 + (congestion_ratio * 0.82) + random.uniform(-0.02, 0.02)
        occupancy = round(max(0.05, min(0.99, occupancy)), 2)

        # Queue estimation
        queue_length = int((congestion_ratio ** 1.8) * 52 + random.randint(-2, 3))
        queue_length = max(0, queue_length)

        # Congestion score calculation
        speed_score = max(0.0, min(1.0, (50.0 - average_speed) / 45.0))
        occupancy_score = occupancy
        vehicle_score = min(1.0, vehicle_count / 200.0)

        score = round((speed_score * 0.4) + (occupancy_score * 0.4) + (vehicle_score * 0.2), 2)

        # Level assignment
        if score >= CONGESTION_THRESHOLDS["critical"]:
            level = CongestionLevel.CRITICAL
        elif score >= CONGESTION_THRESHOLDS["high"]:
            level = CongestionLevel.HIGH
        elif score >= CONGESTION_THRESHOLDS["moderate"]:
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
            queue_length=queue_length,
            congestion_score=score,
            congestion_level=level,
            last_updated=formatted_time,
            description=corridor.get("description", ""),
        )

        # Append to raw telemetry buffer
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
        """Runs a simulation tick across all corridors."""
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

    def ingest_telemetry(self, req: IngestTelemetryRequest) -> CameraNodeModel:
        now = datetime.now()
        formatted_time = now.strftime("%H:%M:%S")

        corridor_info = self._corridors.get(req.camera_id, {})
        name = req.location or corridor_info.get("name", f"Sensor Node {req.camera_id}")
        lat = req.latitude or corridor_info.get("latitude", 12.9716)
        lon = req.longitude or corridor_info.get("longitude", 77.5946)

        speed_score = max(0.0, min(1.0, (50.0 - req.average_speed) / 45.0))
        occupancy_score = min(1.0, max(0.0, req.occupancy))
        vehicle_score = min(1.0, req.vehicle_count / 200.0)
        score = round((speed_score * 0.4) + (occupancy_score * 0.4) + (vehicle_score * 0.2), 2)

        if score >= CONGESTION_THRESHOLDS["critical"]:
            level = CongestionLevel.CRITICAL
        elif score >= CONGESTION_THRESHOLDS["high"]:
            level = CongestionLevel.HIGH
        elif score >= CONGESTION_THRESHOLDS["moderate"]:
            level = CongestionLevel.MODERATE
        else:
            level = CongestionLevel.NORMAL

        queue = req.queue_length if req.queue_length is not None else int((score ** 1.8) * 50)

        node = CameraNodeModel(
            id=req.camera_id,
            name=name,
            latitude=lat,
            longitude=lon,
            is_online=True,
            vehicle_count=req.vehicle_count,
            average_speed=req.average_speed,
            occupancy=req.occupancy,
            queue_length=queue,
            congestion_score=score,
            congestion_level=level,
            last_updated=formatted_time,
            description="Manually ingested telemetry reading",
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

        return TrafficSummaryModel(
            status="success",
            active_corridors=active_count,
            overall_status=overall,
            average_speed=avg_speed,
            total_vehicles=total_vehicles,
            cameras=cameras,
        )


traffic_service = TrafficSimulationService()
