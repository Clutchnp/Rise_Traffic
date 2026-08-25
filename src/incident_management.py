# view_incident_management.py
import json
from datetime import datetime

def generate_incident_management_view():
    incidents = [
        {
            "incident_id": "INC-1049",
            "severity": "CRITICAL",
            "title": "Major Congestion Bottleneck",
            "location": "Silk Board Junction",
            "description": "Severe traffic buildup due to heavy inflow from Hosur Road towards BTM.",
            "assigned_unit": "Patrol Alpha-4",
            "status": "Active",
            "time_ago": "2 min ago",
            "action_button": "Dispatch Backup"
        },
        {
            "incident_id": "INC-1048",
            "severity": "HIGH",
            "title": "Traffic Lane Obstruction",
            "location": "Outer Ring Road (Marathahalli)",
            "description": "Fallen tree branch blocking the left lane heading towards Bellandur.",
            "assigned_unit": "Quick Response Team 2",
            "status": "Dispatched",
            "time_ago": "6 min ago",
            "action_button": "Dispatch Reinforcement"
        },
        {
            "incident_id": "INC-1047",
            "severity": "MODERATE",
            "title": "Slow Moving Traffic",
            "location": "Koramangala 80ft Road",
            "description": "Intermittent signal delays causing steady queue accumulation.",
            "assigned_unit": "Patrol Charlie-1",
            "status": "Monitoring",
            "time_ago": "11 min ago",
            "action_button": "Assign Unit"
        },
        {
            "incident_id": "INC-1046",
            "severity": "MODERATE",
            "title": "Commercial Vehicle Breakdown",
            "location": "MG Road Junction",
            "description": "Stalled delivery truck causing tailback into adjacent lane.",
            "assigned_unit": "Traffic Tow Unit 3",
            "status": "Dispatched",
            "time_ago": "38 min ago",
            "action_button": "Track Unit"
        },
        {
            "incident_id": "INC-1045",
            "severity": "NORMAL",
            "title": "Pedestrian Congestion",
            "location": "Indiranagar 100ft Rd",
            "description": "Heavy pedestrian crossing near metro station.",
            "assigned_unit": "Patrol Bravo-2",
            "status": "Resolved",
            "time_ago": "52 min ago",
            "action_button": "Archive"
        }
    ]

    payload = {
        "kpis": {
            "total_active": len(incidents),
            "critical_priority": len([i for i in incidents if i["severity"] == "CRITICAL"]),
            "avg_dispatch_time": "3.8 min",
            "dispatch_time_diff": "-45s vs last week",
            "units_deployed": "8 Patrols",
            "units_deployed_sub": "Across 4 zones",
            "response_rate": "98.4%",
            "clearance_efficiency": "Clearance efficiency"
        },
        "incident_filter_tabs": {
            "all": len(incidents),
            "critical": 1,
            "high": 1,
            "moderate": 2
        },
        "incidents_feed": incidents
    }

    with open("ui_screen3_incidents.json", "w") as f:
        json.dump(payload, f, indent=4)
    print("ui_screen3_incidents.json successfully generated.")

if __name__ == "__main__":
    generate_incident_management_view()