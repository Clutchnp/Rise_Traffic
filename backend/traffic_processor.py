import os
import math
import pickle
import numpy as np
import pandas as pd
from datetime import datetime
from typing import Dict, Any, Tuple, Optional

# Try importing CatBoost and Spatial Tree
try:
    import catboost
    CATBOOST_AVAILABLE = True
except ImportError:
    CATBOOST_AVAILABLE = False

# Try importing Signal Optimizer from src
try:
    from src.models import IntersectionState, Phase, ApproachState, SignalConfig
    from src.optimizer import AdaptiveSignalOptimizer
    SIGNAL_OPTIMIZER_AVAILABLE = True
except ImportError:
    SIGNAL_OPTIMIZER_AVAILABLE = False


class CongestionMLEngine:
    """
    ML-driven Congestion Prediction and Adaptive Signal Management Engine.
    Integrates trained CatBoost Classifier (traffic_management_model.cbm),
    spatial clustering BallTree (spatial_tree.pkl), and the Adaptive Signal Optimizer.
    """

    def __init__(self):
        self.corridor_metadata = {
            "CAM-001": {"name": "Silk Board Junction", "capacity": 220, "free_flow_speed": 50.0, "lat": 12.9176, "lon": 77.6238, "police_station": "Madiwala Traffic BCP"},
            "CAM-002": {"name": "Marathahalli Bridge", "capacity": 180, "free_flow_speed": 55.0, "lat": 12.9591, "lon": 77.6974, "police_station": "HAL Traffic BCP"},
            "CAM-003": {"name": "Koramangala 80ft Rd", "capacity": 150, "free_flow_speed": 45.0, "lat": 12.9352, "lon": 77.6245, "police_station": "Adugodi Traffic BCP"},
            "CAM-004": {"name": "Hebbal Flyover", "capacity": 200, "free_flow_speed": 60.0, "lat": 13.0358, "lon": 77.5970, "police_station": "Hebbal Traffic BCP"},
            "CAM-005": {"name": "MG Road Junction", "capacity": 140, "free_flow_speed": 40.0, "lat": 12.9756, "lon": 77.6066, "police_station": "Cubbon Park Traffic BCP"},
            "CAM-006": {"name": "Indiranagar 100ft Rd", "capacity": 130, "free_flow_speed": 40.0, "lat": 12.9784, "lon": 77.6408, "police_station": "Indiranagar Traffic BCP"},
            "CAM-007": {"name": "Whitefield ITPL Main Rd", "capacity": 190, "free_flow_speed": 50.0, "lat": 12.9863, "lon": 77.7340, "police_station": "Whitefield Traffic BCP"},
            "CAM-008": {"name": "Electronic City Toll Plaza", "capacity": 210, "free_flow_speed": 65.0, "lat": 12.8452, "lon": 77.6602, "police_station": "Electronic City Traffic BCP"},
        }

        # Locate assets directory
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        assets_dir = os.path.join(base_dir, "assets")

        self.cb_model = None
        self.spatial_tree = None
        self.cluster_labels = None
        self.optimizer = None

        # Load CatBoost Model
        cbm_path = os.path.join(assets_dir, "traffic_management_model.cbm")
        if CATBOOST_AVAILABLE and os.path.exists(cbm_path):
            try:
                self.cb_model = catboost.CatBoostClassifier()
                self.cb_model.load_model(cbm_path)
                print(f"[ML Engine] Loaded CatBoost Model from {cbm_path} ({len(self.cb_model.feature_names_)} features)")
            except Exception as e:
                print(f"[ML Engine] Failed to load CatBoost model: {e}")

        # Load Spatial Tree
        spatial_path = os.path.join(assets_dir, "spatial_tree.pkl")
        if os.path.exists(spatial_path):
            try:
                with open(spatial_path, "rb") as f:
                    data = pickle.load(f)
                    self.spatial_tree = data.get("tree")
                    self.cluster_labels = data.get("cluster_labels")
                print(f"[ML Engine] Loaded Spatial BallTree ({len(self.cluster_labels)} spatial clusters)")
            except Exception as e:
                print(f"[ML Engine] Failed to load spatial tree: {e}")

        # Initialize Signal Optimizer
        if SIGNAL_OPTIMIZER_AVAILABLE:
            try:
                self.optimizer = AdaptiveSignalOptimizer(SignalConfig(cycle_length=90, min_green=15, max_green=55))
                print("[ML Engine] Adaptive Signal Optimizer initialized.")
            except Exception as e:
                print(f"[ML Engine] Signal Optimizer initialization error: {e}")

    def get_spatial_cluster(self, lat: float, lon: float) -> str:
        """Finds nearest spatial DBSCAN cluster from BallTree."""
        if self.spatial_tree is not None and self.cluster_labels is not None:
            try:
                rad = np.radians([[lat, lon]])
                _, ind = self.spatial_tree.query(rad, k=1)
                return str(self.cluster_labels[ind[0][0]])
            except Exception:
                pass
        return "Cluster_0"

    def compute_temporal_features(self, dt: datetime) -> Tuple[float, float, float, float]:
        """Calculates cyclic sinusoidal time & day encoding."""
        hour_rad = 2 * math.pi * (dt.hour + dt.minute / 60.0) / 24.0
        day_rad = 2 * math.pi * dt.weekday() / 7.0

        hour_sin = math.sin(hour_rad)
        hour_cos = math.cos(hour_rad)
        day_sin = math.sin(day_rad)
        day_cos = math.cos(day_rad)

        return hour_sin, hour_cos, day_sin, day_cos

    def predict_catboost_friction(self, camera_id: str, dt: Optional[datetime] = None) -> float:
        """Runs inference with trained CatBoost model to predict traffic bottleneck / friction risk."""
        if self.cb_model is None:
            return 0.5

        if dt is None:
            dt = datetime.now()

        meta = self.corridor_metadata.get(camera_id, {
            "lat": 12.9716, "lon": 77.5946,
            "police_station": "General Traffic",
            "name": camera_id
        })

        cluster_id = self.get_spatial_cluster(meta["lat"], meta["lon"])
        h_sin, h_cos, d_sin, d_cos = self.compute_temporal_features(dt)
        m_sin = math.sin(2 * math.pi * dt.month / 12.0)
        m_cos = math.cos(2 * math.pi * dt.month / 12.0)

        # Build feature vector
        row = {col: 0 for col in self.cb_model.feature_names_}
        row["latitude"] = meta["lat"]
        row["longitude"] = meta["lon"]
        row["vehicle_type"] = "CAR"
        row["police_station"] = meta.get("police_station", "UNKNOWN")
        row["junction_name"] = meta.get("name", "UNKNOWN")
        row["cluster_id"] = cluster_id
        row["created_is_weekend"] = 1 if dt.weekday() >= 5 else 0
        row["created_time_sin"] = h_sin
        row["created_time_cos"] = h_cos
        row["created_day_sin"] = d_sin
        row["created_day_cos"] = d_cos
        row["created_month_sin"] = m_sin
        row["created_month_cos"] = m_cos
        row["modified_is_weekend"] = 1 if dt.weekday() >= 5 else 0
        row["modified_time_sin"] = h_sin
        row["modified_time_cos"] = h_cos
        row["modified_day_sin"] = d_sin
        row["modified_day_cos"] = d_cos
        row["modified_month_sin"] = m_sin
        row["modified_month_cos"] = m_cos
        row["processing_delay_hours"] = 0.5
        row["viol_NO PARKING"] = 1

        try:
            df_in = pd.DataFrame([row])
            probs = self.cb_model.predict_proba(df_in)[0]
            # Probability of active friction/violation validation (class 1)
            return float(probs[1]) if len(probs) > 1 else float(probs[0])
        except Exception:
            return 0.5

    def optimize_signal_timing(self, queue_len: float, vehicle_count: int, capacity: int) -> int:
        """Computes optimal signal green phase using Adaptive Signal Optimizer."""
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
    ) -> Dict[str, Any]:
        """
        Full ML Pipeline:
        1. Query Spatial BallTree for nearest corridor cluster
        2. Run CatBoost ML model inference
        3. Evaluate V/C density, speed drop, lane occupancy
        4. Optimize signal green duration with Adaptive Signal Optimizer
        """
        meta = self.corridor_metadata.get(
            camera_id, {"capacity": 150, "free_flow_speed": 50.0, "lat": 12.9716, "lon": 77.5946}
        )
        capacity = meta["capacity"]
        free_flow_speed = meta["free_flow_speed"]

        # Run CatBoost model prediction
        cb_friction = self.predict_catboost_friction(camera_id)

        # Feature 1: Volume to Capacity ratio
        vc_ratio = min(1.3, vehicle_count / max(capacity, 1))

        # Feature 2: Speed Deficit Ratio
        speed_deficit = max(0.0, min(1.0, (free_flow_speed - average_speed) / free_flow_speed))

        # Feature 3: Lane Occupancy
        occ_ratio = max(0.0, min(1.0, occupancy))

        # ML Ensembled Congestion Score
        # 30% Speed deficit + 30% Occupancy + 20% V/C ratio + 15% CatBoost Friction + 5% Incident
        raw_score = (
            (speed_deficit * 0.30)
            + (occ_ratio * 0.30)
            + (min(1.0, vc_ratio) * 0.20)
            + (cb_friction * 0.15)
            + (min(1.0, incident_impact) * 0.05)
        )

        score = round(max(0.05, min(0.99, raw_score)), 2)

        # Severity Classification
        if score >= 0.75:
            level = "critical"
        elif score >= 0.55:
            level = "high"
        elif score >= 0.35:
            level = "moderate"
        else:
            level = "normal"

        # Estimated Queue Length based on ML score and capacity
        queue_len = int(max(0, (score**1.6) * (capacity * 0.45)))

        # Signal Optimization
        optimal_green = self.optimize_signal_timing(queue_len, vehicle_count, capacity)

        return {
            "congestion_score": score,
            "congestion_level": level,
            "queue_length": queue_len,
            "optimal_green_sec": optimal_green,
            "vc_ratio": round(vc_ratio, 2),
            "speed_deficit": round(speed_deficit, 2),
            "ml_friction_probability": round(cb_friction, 3),
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
        "ml_friction_probability": res["ml_friction_probability"],
    }

