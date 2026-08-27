import os
import joblib
import pandas as pd
from datetime import datetime
from typing import Dict, Any, Optional

try:
    from src.models import IntersectionState, Phase, ApproachState, SignalConfig
    from src.optimizer import AdaptiveSignalOptimizer
    SIGNAL_OPTIMIZER_AVAILABLE = True
except ImportError:
    SIGNAL_OPTIMIZER_AVAILABLE = False


class CongestionMLEngine:
    def __init__(self):
        self.corridor_metadata = {
            "CAM-001": {"name": "Silk Board Junction", "area": "Silk Board", "capacity": 220},
            "CAM-002": {"name": "Marathahalli Bridge", "area": "Marathahalli", "capacity": 180},
            "CAM-003": {"name": "Koramangala 80ft Rd", "area": "Koramangala", "capacity": 150},
            "CAM-004": {"name": "Hebbal Flyover", "area": "Hebbal", "capacity": 200},
            "CAM-005": {"name": "MG Road Junction", "area": "MG Road", "capacity": 140},
            "CAM-006": {"name": "Indiranagar 100ft Rd", "area": "Indiranagar", "capacity": 130},
            "CAM-007": {"name": "Whitefield ITPL Main Rd", "area": "Whitefield", "capacity": 190},
            "CAM-008": {"name": "Electronic City Toll Plaza", "area": "Electronic City", "capacity": 210},
        }

        # Load the Random Forest Pipeline
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        model_path = os.path.join(base_dir, "assets", "rf_congestion_pipeline.pkl")
        
        self.pipeline = None
        if os.path.exists(model_path):
            try:
                self.pipeline = joblib.load(model_path)
                print(f"[ML Engine] Loaded Random Forest Pipeline from {model_path}")
            except Exception as e:
                print(f"[ML Engine] Failed to load RF pipeline: {e}")

        # Initialize Signal Optimizer
        self.optimizer = None
        if SIGNAL_OPTIMIZER_AVAILABLE:
            try:
                self.optimizer = AdaptiveSignalOptimizer(SignalConfig(cycle_length=90, min_green=15, max_green=55))
                print("[ML Engine] Adaptive Signal Optimizer initialized.")
            except Exception as e:
                print(f"[ML Engine] Signal Optimizer initialization error: {e}")

    def optimize_signal_timing(self, queue_len: float, vehicle_count: int, capacity: int) -> int:
        if self.optimizer is not None:
            try:
                arrival_rate = max(0.1, (vehicle_count / max(capacity, 1)) * 1.5)
                state = IntersectionState(
                    intersection_id="CURRENT_NODE",
                    north=ApproachState(name="North Approach", queue=float(queue_len), arrival_rate=arrival_rate, saturation_flow=1.8),
                    south=ApproachState(name="South Approach", queue=float(queue_len * 0.9), arrival_rate=arrival_rate, saturation_flow=1.8),
                    east=ApproachState(name="East Approach", queue=max(2.0, queue_len * 0.4), arrival_rate=0.4, saturation_flow=1.6),
                    west=ApproachState(name="West Approach", queue=max(2.0, queue_len * 0.4), arrival_rate=0.4, saturation_flow=1.6),
                )
                plan = self.optimizer.optimize(state)
                green = plan.allocations[Phase.NORTH_SOUTH].green_time
                return int(green)
            except Exception:
                pass
        return min(90, max(25, int(30 + (queue_len * 0.8))))

    def predict_congestion(
        self,
        camera_id: str,
        vehicle_count: int,
        average_speed: float,
        occupancy: float,
        incident_impact: float = 0.0,
        weather: str = "Clear",
        roadwork: str = "No",
        pedestrian_count: int = 15,
        dt: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """
        Runs the Random Forest Pipeline with the 16 engineered features.
        """
        dt = dt or datetime.now()
        meta = self.corridor_metadata.get(camera_id, {
            "name": camera_id, "area": "Bangalore Central", "capacity": 150
        })

        # Temporal features
        hour = dt.hour
        day_of_week = dt.weekday()
        month = dt.month
        is_weekend = 1 if day_of_week >= 5 else 0
        peak_hour = 1 if (7 <= hour <= 10 or 17 <= hour <= 22) else 0

        # Construct single row dataframe matching the trained pipeline schema
        row = {
            "Traffic Volume": vehicle_count,
            "Average Speed": average_speed,
            "Incident Reports": int(incident_impact > 0),
            "Public Transport Usage": int(vehicle_count * 0.15),
            "Traffic Signal Compliance": 85.0,  # Defaulted baseline
            "Parking Usage": int(occupancy * 100),
            "Pedestrian and Cyclist Count": pedestrian_count,
            "hour": hour,
            "day_of_week": day_of_week,
            "month": month,
            "is_weekend": is_weekend,
            "peak_hour": peak_hour,
            "Area Name": meta.get("area", "Bangalore Central"),
            "Road/Intersection Name": meta.get("name", camera_id),
            "Weather Conditions": weather,
            "Roadwork and Construction Activity": roadwork,
        }

        df_in = pd.DataFrame([row])

        if self.pipeline:
            try:
                # Get direct prediction score
                pred_score = float(self.pipeline.predict(df_in)[0])
                # Normalize if your dataset score was e.g. 0-100 or something else.
                # Assuming it predicts a relative congestion index:
                score = round(max(0.0, min(1.0, pred_score / 100.0 if pred_score > 1.0 else pred_score)), 2)
            except Exception as e:
                print(f"[ML Engine] Prediction error, using fallback: {e}")
                score = round(min(0.99, (vehicle_count / meta["capacity"]) * 0.7 + occupancy * 0.3), 2)
        else:
            # Fallback heuristic if model file isn't found
            score = round(min(0.99, (vehicle_count / meta["capacity"]) * 0.7 + occupancy * 0.3), 2)

        # Map to severity level
        if score >= 0.75:
            level = "critical"
        elif score >= 0.55:
            level = "high"
        elif score >= 0.35:
            level = "moderate"
        else:
            level = "normal"

        queue_len = int(max(0, (score ** 1.6) * (meta["capacity"] * 0.45)))
        optimal_green = self.optimize_signal_timing(queue_len, vehicle_count, meta["capacity"])

        return {
            "congestion_score": score,
            "congestion_level": level,
            "queue_length": queue_len,
            "optimal_green_sec": optimal_green,
        }

congestion_ml_engine = CongestionMLEngine()
