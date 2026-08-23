import random
from datetime import datetime

LOCATIONS = [
    {
        "camera_id": "CAM-001",
        "name": "Silk Board Junction",
        "latitude": 12.9176,
        "longitude": 77.6238,
        "base_traffic": 130,
    },
    {
        "camera_id": "CAM-002",
        "name": "Marathahalli Bridge",
        "latitude": 12.9591,
        "longitude": 77.6974,
        "base_traffic": 100,
    },
    {
        "camera_id": "CAM-003",
        "name": "Koramangala 80ft Rd",
        "latitude": 12.9352,
        "longitude": 77.6245,
        "base_traffic": 90,
    },
    {
        "camera_id": "CAM-004",
        "name": "Hebbal Flyover",
        "latitude": 13.0358,
        "longitude": 77.5970,
        "base_traffic": 95,
    },
    {
        "camera_id": "CAM-005",
        "name": "MG Road Junction",
        "latitude": 12.9756,
        "longitude": 77.6066,
        "base_traffic": 80,
    },
    {
        "camera_id": "CAM-006",
        "name": "Indiranagar 100ft Rd",
        "latitude": 12.9784,
        "longitude": 77.6408,
        "base_traffic": 75,
    },
    {
        "camera_id": "CAM-007",
        "name": "Whitefield ITPL Main Rd",
        "latitude": 12.9866,
        "longitude": 77.7381,
        "base_traffic": 110,
    },
    {
        "camera_id": "CAM-008",
        "name": "Electronic City Toll Plaza",
        "latitude": 12.8452,
        "longitude": 77.6602,
        "base_traffic": 105,
    },
]


def get_time_factor(hour):
    if 8 <= hour <= 10:
        return 1.6
    if 17 <= hour <= 21:
        return 1.75
    if 11 <= hour <= 16:
        return 1.05
    if 22 <= hour or hour <= 5:
        return 0.35
    return 0.8


def generate_traffic(location):
    now = datetime.now()
    time_factor = get_time_factor(now.hour)

    expected_vehicles = location["base_traffic"] * time_factor
    vehicle_count = int(random.gauss(expected_vehicles, expected_vehicles * 0.08))
    vehicle_count = max(vehicle_count, 5)

    congestion_ratio = min(vehicle_count / (location["base_traffic"] * 1.65), 1.0)

    average_speed = 48.0 - congestion_ratio * 34.0 + random.uniform(-2.5, 2.5)
    average_speed = round(max(5.0, min(65.0, average_speed)), 1)

    occupancy = 0.12 + congestion_ratio * 0.82 + random.uniform(-0.02, 0.02)
    occupancy = round(max(0.05, min(0.99, occupancy)), 2)

    return {
        "camera_id": location["camera_id"],
        "location": location["name"],
        "latitude": location["latitude"],
        "longitude": location["longitude"],
        "timestamp": now.strftime("%H:%M:%S"),
        "vehicle_count": vehicle_count,
        "average_speed": average_speed,
        "occupancy": occupancy,
    }


class TrafficSimulator:
    def __init__(self):
        self.latest_data = []

    def update(self):
        self.latest_data = []
        for location in LOCATIONS:
            traffic = generate_traffic(location)
            self.latest_data.append(traffic)
        return self.latest_data

    def get_data(self):
        return self.latest_data
