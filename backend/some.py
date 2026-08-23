import time
import requests
from sim import TrafficSimulator
from traffic_processor import calculate_congestion

simulator = TrafficSimulator()
API_URL = "http://127.0.0.1:8000/traffic"

print("Starting simulation ingestion loop (pushing to backend)...")

while True:
    try:
        traffic_data = simulator.update()
        for raw_traffic in traffic_data:
            processed = calculate_congestion(raw_traffic)
            response = requests.post(API_URL, json=processed, timeout=2.0)
            print(f"[{processed['camera_id']} - {processed['location']}] -> Status: {processed['status']} ({response.status_code})")
        print("--- Cycle complete. Next tick in 5 seconds. ---")
    except Exception as e:
        print(f"Ingestion notice: Backend not reachable at {API_URL} ({e}). Retrying in 5s...")
    time.sleep(5)
