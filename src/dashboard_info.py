# view_dashboard.py
import json
from datetime import datetime
from ml_engine import AutonomousTrafficEngine

def generate_dashboard_view():
    engine = AutonomousTrafficEngine()
    nodes = engine.get_corridor_telemetry()
    
   
    critical_nodes = [n for n in nodes if n["status"] == "Critical"]
    high_nodes = [n for n in nodes if n["status"] == "High"]
    
    avg_occ = sum(n["telemetry"]["lane_occupancy_pct"] for n in nodes) / len(nodes)
    overall_status = "Critical" if avg_occ >= 80 else "High" if avg_occ >= 60 else "Moderate" if avg_occ >= 40 else "Normal"

    trend_24h = []
    for h in range(24):
        mult = engine._get_time_multiplier(h)
        base_pct = int(min(98, 48 * mult + (3 if 17 <= h <= 20 else 0)))
        trend_24h.append({"time": f"{str(h).zfill(2)}:00", "intensity_pct": base_pct})

   
    active_incidents = [
        {"id": "INC-1049", "title": "Major Congestion Bottleneck", "location": "Silk Board Junction", "severity": "Critical", "time": "2 min ago"},
        {"id": "INC-1048", "title": "Traffic Lane Obstruction", "location": "Outer Ring Road (Marathahalli)", "severity": "High", "time": "6 min ago"},
        {"id": "INC-1047", "title": "Slow Moving Traffic", "location": "Koramangala 80ft Road", "severity": "Moderate", "time": "11 min ago"},
        {"id": "INC-1046", "title": "Commercial Vehicle Breakdown", "location": "MG Road Junction", "severity": "Moderate", "time": "38 min ago"}
    ]

    
    hotspots = sorted(nodes, key=lambda x: x["telemetry"]["vehicle_count"], reverse=True)[:4]
    hotspot_list = [
        {
            "location": h["location"],
            "summary": f"{h['telemetry']['vehicle_count']} veh • {h['telemetry']['avg_speed_kmh']} km/h",
            "severity": h["status"]
        } for h in hotspots
    ]

    dashboard_payload = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S IST"),
        "kpis": {
            "traffic_status": overall_status,
            "monitored_corridors": len(nodes),
            "active_incidents_count": 5,
            "critical_priority_count": len(critical_nodes),
            "congestion_hotspots_count": len(critical_nodes) + len(high_nodes),
            "critical_junctions_count": len(critical_nodes),
            "response_status_pct": "98.4%"
        },
        "congestion_trend": {
            "peak_label": "Peak: 98%",
            "avg_label": "Avg: 53%",
            "hourly_data": trend_24h
        },
        "active_incidents_preview": active_incidents,
        "congestion_hotspots_preview": hotspot_list,
        "map_markers": [
            {"name": n["location"], "lat": n["latitude"], "lon": n["longitude"], "status": n["status"], "cluster_id": n["cluster_id"]}
            for n in nodes
        ]
    }

    with open("ui_screen1_dashboard.json", "w") as f:
        json.dump(dashboard_payload, f, indent=4)
    print("ui_screen1_dashboard.json successfully generated.")

if __name__ == "__main__":
    generate_dashboard_view()