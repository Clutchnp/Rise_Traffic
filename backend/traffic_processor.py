def calculate_congestion(traffic: dict) -> dict:
    """
    Computes weighted congestion score and assigns severity status.
    Score formula: 40% speed penalty + 40% lane occupancy + 20% vehicle volume density.
    """
    avg_speed = traffic.get("average_speed", 30.0)
    occupancy = traffic.get("occupancy", 0.5)
    vehicle_count = traffic.get("vehicle_count", 80)

    speed_score = max(0.0, min(1.0, (50.0 - avg_speed) / 45.0))
    occupancy_score = max(0.0, min(1.0, occupancy))
    vehicle_score = min(1.0, vehicle_count / 200.0)

    score = (speed_score * 0.4) + (occupancy_score * 0.4) + (vehicle_score * 0.2)
    score = round(score, 2)

    if score >= 0.75:
        status = "Critical"
    elif score >= 0.55:
        status = "High"
    elif score >= 0.35:
        status = "Moderate"
    else:
        status = "Normal"

    return {
        **traffic,
        "congestion_score": score,
        "status": status,
    }
