# view_cctv_telemetry.py
import json
from datetime import datetime
from ml_engine import AutonomousTrafficEngine

def generate_cctv_telemetry_view():
    engine = AutonomousTrafficEngine()
    nodes = engine.get_corridor_telemetry()
    
    congested_count = len([n for n in nodes if n["status"] in ["Critical", "High"]])
    
    
    camera_nodes = []
    for node in nodes:
        camera_nodes.append({
            "camera_id": node["camera_id"],
            "location": node["location"],
            "status": node["status"],
            "is_online": True,
            "last_updated": datetime.now().strftime("%H:%M:%S IST"),
            "telemetry": {
                "vehicle_count": node["telemetry"]["vehicle_count"],
                "average_speed": f"{node['telemetry']['avg_speed_kmh']} km/h",
                "lane_occupancy": f"{node['telemetry']['lane_occupancy_pct']}%",
                "estimated_queue": f"{node['telemetry']['queue_length_veh']} veh"
            }
        })

    payload = {
        "header_summary": {
            "all_cameras": len(nodes),
            "online_only": len(nodes),
            "congested_zones": congested_count,
            "telemetry_stream_status": "LIVE"
        },
        "selected_camera_detail": camera_nodes[0], # Defaults to CAM-001 (Silk Board)
        "camera_nodes_list": camera_nodes,
        "raw_sensor_log": {
            "source": "Unprocessed edge computing readings received from camera network",
            "sample_records": [
                f"[{datetime.now().strftime('%H:%M:%S')}] {node['camera_id']} INGEST: count={node['telemetry']['vehicle_count']}, occ={node['telemetry']['lane_occupancy_pct']}%"
                for node in nodes[:4]
            ]
        }
    }

    with open("ui_screen2_cctv_telemetry.json", "w") as f:
        json.dump(payload, f, indent=4)
    print("ui_screen2_cctv_telemetry.json successfully generated.")

if __name__ == "__main__":
    generate_cctv_telemetry_view()