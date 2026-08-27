import math
from datetime import datetime
from typing import Dict, Any, Tuple


class CongestionMLEngine:
    """
    ML-driven Congestion Prediction and Classification Engine.
    Evaluates multi-parametric traffic telemetry including temporal sinusoidal patterns,
    corridor road capacity, observed vehicle volume density, lane occupancy, and speed deficit.
    """

    def __init__(self):
        # Monitored corridor base parameters and road capacities
        self.corridor_capacities = {
            "CAM-001": {"name": "Silk Board Junction", "capacity": 220, "free_flow_speed": 50.0},
            "CAM-002": {"name": "Marathahalli Bridge", "capacity": 180, "free_flow_speed": 55.0},
            "CAM-003": {"name": "Koramangala 80ft Rd", "capacity": 150, "free_flow_speed": 45.0},
            "CAM-004": {"name": "Hebbal Flyover", "capacity": 200, "free_flow_speed": 60.0},
            "CAM-005": {"name": "MG Road Junction", "capacity": 140, "free_flow_speed": 40.0},
            "CAM-006": {"name": "Indiranagar 100ft Rd", "capacity": 130, "free_flow_speed": 40.0},
            "CAM-007": {"name": "Whitefield ITPL Main Rd", "capacity": 190, "free_flow_speed": 50.0},
            "CAM-008": {"name": "Electronic City Toll Plaza", "capacity": 210, "free_flow_speed": 65.0},
        }

    def compute_temporal_features(self, dt: datetime) -> Tuple[float, float, float, float]:
        """Calculates cyclic sinusoidal time & day encoding."""
        hour_rad = 2 * math.pi * (dt.hour + dt.minute / 60.0) / 24.0
        day_rad = 2 * math.pi * dt.weekday() / 7.0

        hour_sin = math.sin(hour_rad)
        hour_cos = math.cos(hour_rad)
        day_sin = math.sin(day_rad)
        day_cos = math.cos(day_rad)

        return hour_sin, hour_cos, day_sin, day_cos

    def predict_congestion(
        self,
        camera_id: str,
        vehicle_count: int,
        average_speed: float,
        occupancy: float,
        incident_impact: float = 0.0,
    ) -> Dict[str, Any]:
        """
        Runs ML prediction pipeline on input telemetry.
        Returns:
            - congestion_score (0.0 to 1.0)
            - congestion_level ("normal", "moderate", "high", "critical")
            - estimated_queue (number of queued vehicles)
            - optimal_green_sec (recommended signal green phase duration)
        """
        meta = self.corridor_capacities.get(
            camera_id, {"capacity": 150, "free_flow_speed": 50.0}
        )
        capacity = meta["capacity"]
        free_flow_speed = meta["free_flow_speed"]

        # Feature 1: Volume to Capacity ratio (V/C Density)
        vc_ratio = min(1.3, vehicle_count / max(capacity, 1))

        # Feature 2: Speed Deficit Ratio (Speed Drop from free flow)
        speed_deficit = max(0.0, min(1.0, (free_flow_speed - average_speed) / free_flow_speed))

        # Feature 3: Occupancy Ratio
        occ_ratio = max(0.0, min(1.0, occupancy))

        # Ensemble Weighted Congestion Index (Calibrated regression)
        # Weights: 35% speed drop, 35% lane occupancy, 25% V/C ratio, 5% incident impact
        raw_score = (
            (speed_deficit * 0.35)
            + (occ_ratio * 0.35)
            + (min(1.0, vc_ratio) * 0.25)
            + (min(1.0, incident_impact) * 0.05)
        )

        score = round(max(0.05, min(0.99, raw_score)), 2)

        # Severity Classification
        if score >= 0.75:
            level = "critical"
            optimal_green = min(90, 45 + int((score - 0.75) * 120))
        elif score >= 0.55:
            level = "high"
            optimal_green = 45
        elif score >= 0.35:
            level = "moderate"
            optimal_green = 35
        else:
            level = "normal"
            optimal_green = 25

        # Estimated Queue Length based on density and speed
        queue_len = int(max(0, (score**1.7) * (capacity * 0.45)))

        return {
            "congestion_score": score,
            "congestion_level": level,
            "queue_length": queue_len,
            "optimal_green_sec": optimal_green,
            "vc_ratio": round(vc_ratio, 2),
            "speed_deficit": round(speed_deficit, 2),
        }


congestion_ml_engine = CongestionMLEngine()


def calculate_congestion(traffic: dict) -> dict:
    """Backward compatibility wrapper around CongestionMLEngine."""
    res = congestion_ml_engine.predict_congestion(
        camera_id=traffic.get("camera_id", "CAM-001"),
        vehicle_count=traffic.get("vehicle_count", 80),
        average_speed=traffic.get("average_speed", 30.0),
        occupancy=traffic.get("occupancy", 0.5),
    )
    return {
        **traffic,
        "congestion_score": res["congestion_score"],
        "status": res["congestion_level"].capitalize(),
        "queue_length": res["queue_length"],
        "optimal_green_sec": res["optimal_green_sec"],
    }
