import requests 
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def fetchJunction(city, limit=5):

    url = "https://overpass-api.de/api/interpreter"

    query = f"""
    [out:json];
    area["name"="{city}"]["admin_level"="8"]->.searchArea;
    node["highway"="traffic_signals"](area.searchArea);
    out body {limit};
    """

    try:
        response = requests.get(
            url,
            params={"data": query},
            headers={
                "User-Agent": "SIH-Smart-Traffic-Prototype/1.0"
            },
            timeout=20
        )

        print(f"{city}: HTTP {response.status_code}")
        response.raise_for_status()
        if "application/json" not in response.headers.get("Content-Type", ""):
            print(f"{city}: Server did not return JSON")
            print(response.text[:500])
            return []

        data = response.json()
        junctionList = []

        for el in data.get("elements", []):
            tags = el.get("tags", {})
            j_name = tags.get(
                "name",
                f"Junction {el['id']}"
            )
            junctionList.append({
                "id": str(el["id"]),
                "name": f"{j_name} ({city})",
                "city": city,
                "latitude": el["lat"],
                "longitude": el["lon"],
                "capacity": np.random.randint(160, 300),
                "zone_type": np.random.choice([
                    "Commercial Hub",
                    "Transit Corridor",
                    "Residential Area",
                    "Highway"
                ])
            })

        print(f"{city}: found {len(junctionList)} junctions")
        return junctionList

    except requests.exceptions.RequestException as e:
        print(f"{city}: HTTP request failed: {e}")
        return []

    except ValueError as e:
        print(f"{city}: Invalid JSON response: {e}")
        print(response.text[:500])
        return []

    except Exception as e:
        print(f"{city}: Unexpected error: {e}")
        return []
        

cities = ["Bengaluru","Hyderabad","Delhi","Mumbai","Kolkata"]
junctions = []
for city in cities:
    j = fetchJunction(city,limit=5)
    junctions.extend(j)
    
startDate = datetime(2026,8,17,0,0,0)
numDays = 3
totalTicks = numDays*288 #5 min interval
rows = []
np.random.seed(42)

for t in range(totalTicks):
    currentTime = startDate + timedelta(minutes=t*5)
    hour = currentTime.hour
    minute = currentTime.minute
    dayOfWeek = currentTime.strftime("%A")
    isWeekend = currentTime.weekday()>=5
    
    for j in junctions:
        isPeak = ((7<=hour<=10) or (18<=hour<=22)) and not isWeekend
        baseDensity = (0.85 if isPeak else 0.35) + np.random.normal(0,0.08)
        congestionIndex = round(float(np.clip(baseDensity,0.05,1.0)),2)
        vehicleCount = int(congestionIndex * j["capacity"])
        avgSpeed = round(float(max(4.0,60.0*(1 - congestionIndex**1.3))),1)   
        adaptiveSignal = int(15 + (congestionIndex*(90-15)))
        vehicleType = np.random.choice(["2 WHEELER","4 WHEELER","AUTO RICKSHAW","BUS"],p=[0.45,0.35,0.15,0.05])
        vehicleSpeed = round(float(np.clip(np.random.normal(avgSpeed + 10,15),0,100)),1)
        redSignal = int(np.random.choice([0,1],p=[0.65,0.35]))
        pastStopLine = round(float(np.random.uniform(-4.0,12.0)),1)
        hasHelmet = int(np.random.choice([0,1],p=[0.25,0.75])) if vehicleType=="2 WHEELER" else 1
        hasSeatBelt = int(np.random.choice([0, 1], p=[0.35, 0.65])) if vehicleType == "4_WHEELER" else 1
        isRedJump = (redSignal==1) and (pastStopLine>1.2) and (vehicleSpeed>8.0)
        overspeeding = vehicleSpeed > 55.0
        noHelmet = (vehicleType == "2 WHEELER") and (hasHelmet == 0) and (vehicleSpeed > 5.0)
        noSeatbelt = (vehicleType == "4 WHEELER") and (hasSeatBelt == 0) and (vehicleSpeed > 5.0)
        trueViolation = int(isRedJump or overspeeding or noHelmet or noSeatbelt)
    
        
                
        offence = "No VIOLATION"
        fine = 0
        if isRedJump:
            offence,fine = "RED LIGHT JUMPED",1000
        elif overspeeding:
            offence,fine = "OVERSPEEDING",2000
        elif noHelmet:
            offence,fine = "NO HELMET",1000
        elif noSeatbelt:
            offence,fine = "NO SEATBELT",1000
        
        rows.append({
            "timestamp": currentTime.strftime("%Y-%m-%d %H:%M:%S"),
            "day_of_week": dayOfWeek,
            "is_weekend": int(isWeekend),
            "city": j["city"],
            "junction_id": j["id"],
            "junction_name": j["name"],
            "latitude": j["latitude"],
            "longitude": j["longitude"],
            "zone_type": j["zone_type"],
            "road_capacity": j["capacity"],
            "vehicle_count": vehicleCount,
            "avg_speed_kmh": avgSpeed,
            "congestion_index": congestionIndex,
            "fixed_green_sec": 30,
            "adaptive_green_sec": adaptiveSignal,
            "green_time_difference_sec": adaptiveSignal - 30,
            "captured_vehicle_type": vehicleType,
            "event_vehicle_speed_kmh": vehicleSpeed,
            "event_signal_is_red": redSignal,
            "event_dist_past_line_m": pastStopLine,
            "has_helmet": hasHelmet,
            "has_seatbelt": hasSeatBelt,
            "is_true_violation": trueViolation,
            "offence_category": offence,
            "fine_amount_inr": fine
            
        })
     
df = pd.DataFrame(rows)
df.to_csv("generatedData.csv",index=False)
print(f"generated csv file with {len(df)} rows!")


    
