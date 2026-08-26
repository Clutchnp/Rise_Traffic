# ml_engine.py
import numpy as np
import pandas as pd
import joblib
from datetime import datetime
from sklearn.cluster import DBSCAN

class TrafficMLEngine:
   
    def __init__(self):
        print("Loading Multi-Model Pipeline")
        
        self.vol_model = joblib.load('traffic_model.joblib')
        
        hotspot_data = joblib.load('hotspot_model.joblib')
        self.hotspot_model = hotspot_data['model']
        self.hotspot_classes = hotspot_data['classes']
        
        incident_data = joblib.load('incident_model.joblib')
        self.incident_model = incident_data['model']
        self.incident_classes = incident_data['classes']
        
        self.corridors = [
            {"camera_id": "CAM-001", "name": "Silk Board Junction", "latitude": 12.9176, "longitude": 77.6238, "capacity": 650},
            {"camera_id": "CAM-002", "name": "Marathahalli Bridge", "latitude": 12.9591, "longitude": 77.6974, "capacity": 550},
            {"camera_id": "CAM-003", "name": "Koramangala 80ft Rd", "latitude": 12.9352, "longitude": 77.6245, "capacity": 450},
            {"camera_id": "CAM-004", "name": "Hebbal Flyover", "latitude": 13.0358, "longitude": 77.5970, "capacity": 600},
            {"camera_id": "CAM-005", "name": "MG Road Junction", "latitude": 12.9756, "longitude": 77.6066, "capacity": 400},
            {"camera_id": "CAM-006", "name": "Indiranagar 100ft Rd", "latitude": 12.9784, "longitude": 77.6408, "capacity": 350},
            {"camera_id": "CAM-007", "name": "Whitefield ITPL Main Rd", "latitude": 12.9863, "longitude": 77.7340, "capacity": 500},
            {"camera_id": "CAM-008", "name": "Outer Ring Road (Bellandur)", "latitude": 12.9260, "longitude": 77.6762, "capacity": 650}
        ]

    def get_corridor_telemetry(self, hour=None, day=None):
        now = datetime.now()
        h = now.hour if hour is None else hour
        d = now.weekday() if day is None else day

        df_predict = pd.DataFrame(self.corridors)
        
        df_predict['hour_sin'] = np.sin(2 * np.pi * h / 24.0)
        df_predict['hour_cos'] = np.cos(2 * np.pi * h / 24.0)
        df_predict['day_sin'] = np.sin(2 * np.pi * d / 7.0)
        df_predict['day_cos'] = np.cos(2 * np.pi * d / 7.0)
        
        
        df_predict['weather_condition'] = 0 
        df_predict['weather_code'] = 0 
        df_predict['temperature'] = 25.0
        df_predict['humidity'] = 60.0
        df_predict['accident_reported'] = np.random.choice([0, 1], size=len(df_predict), p=[0.85, 0.15])

        
        vol_features = ['hour_sin', 'hour_cos', 'day_sin', 'day_cos', 'latitude', 'longitude', 'weather_condition', 'temperature', 'humidity', 'accident_reported']
        
        preds = self.vol_model.predict(df_predict[vol_features])
        df_predict['number_of_vehicles'] = np.maximum(0, preds).astype(int)
        
        
        df_predict['lane_occupancy'] = np.minimum(100, (df_predict['number_of_vehicles'] / df_predict['capacity']) * 100)

        
        hotspot_features = ['hour_sin', 'hour_cos', 'weather_code', 'number_of_vehicles', 'lane_occupancy']
        adv_preds = self.hotspot_model.predict(df_predict[hotspot_features])
        
        df_predict['ai_advisory'] = [self.hotspot_classes[idx] for idx in adv_preds]

        
        inc_features = ['number_of_vehicles', 'lane_occupancy', 'accident_reported', 'weather_code']
        inc_preds = self.incident_model.predict(df_predict[inc_features])
        df_predict['incident_action'] = [self.incident_classes[idx] for idx in inc_preds]

        
        telemetry_nodes = []
        for _, row in df_predict.iterrows():
            speed = max(5.0, round(45.0 - (row['lane_occupancy'] * 0.35), 1))
            
            telemetry_nodes.append({
                "camera_id": row["camera_id"],
                "location": row["name"],
                "latitude": row["latitude"],
                "longitude": row["longitude"],
                "status": "Critical" if row['lane_occupancy'] > 80 else "Normal",
                "telemetry": {
                    "vehicle_count": int(row['number_of_vehicles']),
                    "avg_speed_kmh": speed,
                    "lane_occupancy_pct": round(row['lane_occupancy'], 1)
                },
                
                "ai_predictions": {
                    "signal_advisory": row['ai_advisory'],
                    "dispatch_action": row['incident_action']
                }
            })

        
        coords = np.radians([[n["latitude"], n["longitude"]] for n in telemetry_nodes])
        db = DBSCAN(eps=4.0 / 6371.0, min_samples=2, metric='haversine')
        cluster_labels = db.fit_predict(coords)

        for i, node in enumerate(telemetry_nodes):
            node["cluster_id"] = int(cluster_labels[i])

        return telemetry_nodes