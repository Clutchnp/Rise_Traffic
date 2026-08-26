# view_traffic_analytics.py
import json
from ml_engine import AutonomousTrafficEngine

def generate_traffic_analytics_view():
    engine = AutonomousTrafficEngine()
    nodes = engine.get_corridor_telemetry()
    
    
    corridor_throughput = [
        {"name": "Silk Board Junction", "status": "Near Capacity", "volume_24h": "54,200 veh"},
        {"name": "Marathahalli Bridge", "status": "Moderate Load", "volume_24h": "38,900 veh"},
        {"name": "Koramangala 80ft Road", "status": "Stable Flow", "volume_24h": "31,400 veh"},
        {"name": "Hebbal Flyover Corridor", "status": "Optimal Flow", "volume_24h": "23,700 veh"}
    ]

    
    vehicle_classification = [
        {"modality": "Cars & Cabs", "percentage": "48%", "progress_val": 48},
        {"modality": "Two-Wheelers & Bikes", "percentage": "34%", "progress_val": 34},
        {"modality": "Buses & Public Transit", "percentage": "12%", "progress_val": 12},
        {"modality": "Commercial Freight & Trucks", "percentage": "6%", "progress_val": 6}
    ]

    payload = {
        "top_kpis": {
            "daily_vehicle_volume": "148,250",
            "daily_volume_sub": "+8.4% vs monthly avg",
            "peak_flow_rate": "12,400 /hr",
            "peak_flow_sub": "Observed at 18:30 IST",
            "avg_corridor_speed": "24.9 km/h",
            "avg_speed_sub": "+3.1 km/h post AI tuning",
            "carbon_savings": "1.42 Tons",
            "carbon_savings_sub": "Reduced idle emissions today"
        },
        "vehicle_classification": vehicle_classification,
        "corridor_volume_throughput": corridor_throughput
    }

    with open("ui_screen5_analytics.json", "w") as f:
        json.dump(payload, f, indent=4)
    print("ui_screen5_analytics.json successfully generated.")

if __name__ == "__main__":
    generate_traffic_analytics_view()