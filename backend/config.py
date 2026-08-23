from typing import List, Dict, Any

APP_NAME = "RISE AI - GridLock Traffic Intelligence Platform"
APP_VERSION = "2.0.0"
APP_DESCRIPTION = "Real-time Traffic Congestion Mapping, AI Signal Optimization, Incident Management, and Corridor Telemetry"

# Major monitored corridors in Bengaluru
DEFAULT_CORRIDORS: List[Dict[str, Any]] = [
    {
        "camera_id": "CAM-001",
        "name": "Silk Board Junction",
        "latitude": 12.9176,
        "longitude": 77.6238,
        "base_traffic": 130,
        "is_online": True,
        "description": "High-density convergence point connecting Hosur Road, BTM Layout, and HSR Layout",
    },
    {
        "camera_id": "CAM-002",
        "name": "Marathahalli Bridge",
        "latitude": 12.9591,
        "longitude": 77.6974,
        "base_traffic": 100,
        "is_online": True,
        "description": "Critical Outer Ring Road intersection connecting Whitefield and HAL Airport Road",
    },
    {
        "camera_id": "CAM-003",
        "name": "Koramangala 80ft Rd",
        "latitude": 12.9352,
        "longitude": 77.6245,
        "base_traffic": 90,
        "is_online": True,
        "description": "Commercial arterial corridor experiencing heavy peak hour retail and commute transit",
    },
    {
        "camera_id": "CAM-004",
        "name": "Hebbal Flyover",
        "latitude": 13.0358,
        "longitude": 77.5970,
        "base_traffic": 95,
        "is_online": True,
        "description": "Northern gateway corridor connecting Bellary Road and Kempegowda International Airport",
    },
    {
        "camera_id": "CAM-005",
        "name": "MG Road Junction",
        "latitude": 12.9756,
        "longitude": 77.6066,
        "base_traffic": 80,
        "is_online": True,
        "description": "Central Business District corridor with integrated metro feeder lanes",
    },
    {
        "camera_id": "CAM-006",
        "name": "Indiranagar 100ft Rd",
        "latitude": 12.9784,
        "longitude": 77.6408,
        "base_traffic": 75,
        "is_online": True,
        "description": "High-volume lifestyle and mixed-use commercial corridor",
    },
    {
        "camera_id": "CAM-007",
        "name": "Whitefield ITPL Main Rd",
        "latitude": 12.9866,
        "longitude": 77.7381,
        "base_traffic": 110,
        "is_online": True,
        "description": "Tech hub transit artery serving major tech parks and commuter buses",
    },
    {
        "camera_id": "CAM-008",
        "name": "Electronic City Toll Plaza",
        "latitude": 12.8452,
        "longitude": 77.6602,
        "base_traffic": 105,
        "is_online": True,
        "description": "Elevated expressway terminus connecting South Bengaluru industrial zone",
    },
]

# Congestion Thresholds
CONGESTION_THRESHOLDS = {
    "critical": 0.75,
    "high": 0.55,
    "moderate": 0.35,
}

# Simulation Interval in seconds
SIMULATION_TICK_INTERVAL_SEC = 3.0
