import random
from datetime import datetime


LOCATIONS = [
    {
        "camera_id": "CAM_001",
        "name": "Silk Board",
        "latitude": 12.9176,
        "longitude": 77.6238,
        "base_traffic": 120,
    },
    {
        "camera_id": "CAM_002",
        "name": "Marathahalli",
        "latitude": 12.9591,
        "longitude": 77.6974,
        "base_traffic": 100,
    },
    {
        "camera_id": "CAM_003",
        "name": "Koramangala",
        "latitude": 12.9352,
        "longitude": 77.6245,
        "base_traffic": 85,
    },
    {
        "camera_id": "CAM_004",
        "name": "Hebbal",
        "latitude": 13.0358,
        "longitude": 77.5970,
        "base_traffic": 90,
    },
]


def get_time_factor(hour):
    if 7 <= hour <= 10:
        return 1.5

    if 17 <= hour <= 21:
        return 1.7

    if 11 <= hour <= 16:
        return 1.0

    return 0.45


def generate_traffic(location):
    now = datetime.now()

    time_factor = get_time_factor(now.hour)

    expected_vehicles = (
        location["base_traffic"] * time_factor
    )

    vehicle_count = int(
        random.gauss(
            expected_vehicles,
            expected_vehicles * 0.08,
        )
    )

    vehicle_count = max(vehicle_count, 0)

    congestion_ratio = min(
        vehicle_count /
        (location["base_traffic"] * 1.7),
        1.0,
    )

    average_speed = (
        45 - congestion_ratio * 32
    )

    average_speed += random.uniform(-3, 3)

    average_speed = round(
        max(5, average_speed),
        1,
    )

    occupancy = (
        0.15 +
        congestion_ratio * 0.8
    )

    occupancy += random.uniform(-0.03, 0.03)

    occupancy = round(
        max(0, min(occupancy, 1)),
        2,
    )

    return {
        "camera_id": location["camera_id"],
        "location": location["name"],
        "latitude": location["latitude"],
        "longitude": location["longitude"],
        "timestamp": now.isoformat(),

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
