# view_hotspots_advisory.py
import json
from ml_engine import AutonomousTrafficEngine

def generate_hotspots_advisory_view():
    engine = AutonomousTrafficEngine()
    nodes = engine.get_corridor_telemetry()
    
    hotspots = []
    critical_count = 0
    high_count = 0
    moderate_count = 0

    for node in nodes:
        status = node["status"]
        if status == "Critical":
            critical_count += 1
            severity_tag = "CRITICAL BOTTLENECK"
            ai_msg = f"Increase green phase timing by +25s on {node['location']} inbound corridor."
            ai_buttons = ["+25s Green Phase", "Green Wave Sync", "VMS Advisory"]
        elif status == "High":
            high_count += 1
            severity_tag = "HIGH BOTTLENECK"
            ai_msg = f"Standard adaptive cycle active. Queue buildup detected at {node['location']}."
            ai_buttons = ["Adaptive Phase", "Green Wave Sync", "VMS Advisory"]
        elif status == "Moderate":
            moderate_count += 1
            severity_tag = "MODERATE LOAD"
            ai_msg = "Traffic flowing steadily. Maintain standard signal cycle."
            ai_buttons = ["Monitor Cycle"]
        else:
            continue

        hotspots.append({
            "location": node["location"],
            "severity_badge": severity_tag,
            "telemetry": {
                "vehicle_count": node["telemetry"]["vehicle_count"],
                "avg_speed": f"{node['telemetry']['avg_speed_kmh']} km/h",
                "lane_occupancy": f"{node['telemetry']['lane_occupancy_pct']}%",
                "queue_length": f"{node['telemetry']['queue_length_veh']} veh"
            },
            "ai_optimization_advisory": {
                "message": ai_msg,
                "action_buttons": ai_buttons
            }
        })

    payload = {
        "header_kpis": {
            "total_hotspots": len(hotspots),
            "critical_priority": critical_count,
            "high_congestion": high_count,
            "moderate_load": moderate_count
        },
        "hotspot_cards": hotspots
    }

    with open("ui_screen4_hotspots_advisory.json", "w") as f:
        json.dump(payload, f, indent=4)
    print("ui_screen4_hotspots_advisory.json successfully generated.")

if __name__ == "__main__":
    generate_hotspots_advisory_view()