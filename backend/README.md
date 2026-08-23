# 🚦 RISE AI (GridLock 2.0) - Traffic Intelligence Backend

A high-performance, modular **FastAPI** backend powering real-time traffic congestion mapping, AI adaptive signal optimization, incident management, and corridor telemetry streams.

---

## 🏛️ Architecture & Project Structure

```
backend/
├── config.py                  # Corridor registry, default coordinates, and thresholds
├── main.py                    # FastAPI application, CORS middleware, and lifespan background worker
├── requirements.txt           # Minimal, production-ready dependencies
├── models/                    # Pydantic validation and serialization models
│   ├── __init__.py
│   ├── traffic.py             # Camera node, congestion score, and telemetry models
│   ├── incident.py            # Incident records, severities, and dispatch schemas
│   ├── hotspots.py            # Bottlenecks and AI signal optimization schemas
│   └── analytics.py           # KPIs, 24h congestion trend, and throughput models
├── services/                  # Core domain and simulation business logic
│   ├── __init__.py
│   ├── sim_service.py         # Multi-corridor diurnal simulation and live node tracker
│   ├── incident_service.py    # Active incident lifecycle and backup unit dispatching
│   ├── hotspot_service.py     # Bottleneck ranking and AI signal advisory engine
│   └── analytics_service.py   # 24h curve aggregation and carbon savings analytics
├── routers/                   # Modular FastAPI route handlers
│   ├── __init__.py
│   ├── traffic.py             # /api/v1/traffic routes
│   ├── incidents.py           # /api/v1/incidents routes
│   ├── hotspots.py            # /api/v1/hotspots routes
│   ├── analytics.py           # /api/v1/analytics routes
│   └── websocket.py           # /ws/traffic real-time WebSocket stream
├── sim.py                     # Standalone simulator module (backward compatible)
├── traffic_processor.py       # Congestion scoring utility (backward compatible)
├── some.py                    # Standalone edge ingestion simulation script
└── test_backend.py            # Automated end-to-end test suite
```

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Run the Backend Server
```bash
# Start FastAPI with live-reload on port 8000
uvicorn main:app --reload --port 8000
```
- **Interactive OpenAPI Documentation:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **Alternative ReDoc UI:** [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

## 📡 API Reference

### 1. Live Traffic & Telemetry (`/api/v1/traffic`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/v1/traffic` | Full network traffic summary, active corridors, and camera nodes |
| `GET` | `/api/v1/traffic/nodes` | List corridor camera nodes (supports `?filter_by=Online` or `?filter_by=Congested`) |
| `GET` | `/api/v1/traffic/nodes/{camera_id}` | Get telemetry for a specific camera (e.g. `CAM-001`) |
| `GET` | `/api/v1/traffic/logs` | Retrieve raw edge sensor telemetry logs table (`?limit=50`) |
| `POST` | `/api/v1/traffic/tick` | Trigger an immediate simulation calculation cycle across corridors |
| `POST` | `/api/v1/traffic/ingest` | Ingest external sensor telemetry reading from edge device |

#### Sample Ingestion Payload (`POST /api/v1/traffic/ingest`):
```json
{
  "camera_id": "CAM-001",
  "location": "Silk Board Junction",
  "latitude": 12.9176,
  "longitude": 77.6238,
  "vehicle_count": 175,
  "average_speed": 13.5,
  "occupancy": 0.91,
  "queue_length": 45
}
```

---

### 2. Incident Management & Dispatch (`/api/v1/incidents`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/v1/incidents` | List all incidents (supports `?severity=critical` or `?status=In Progress`) |
| `GET` | `/api/v1/incidents/metrics` | Retrieve incident statistics (total active, critical, dispatch times) |
| `GET` | `/api/v1/incidents/{incident_id}` | Get single incident metadata |
| `POST` | `/api/v1/incidents` | Log a new traffic incident |
| `PATCH` | `/api/v1/incidents/{incident_id}` | Update incident status, severity, or assigned unit |
| `POST` | `/api/v1/incidents/{incident_id}/dispatch` | Dispatch backup response unit |
| `DELETE` | `/api/v1/incidents/{incident_id}` | Resolve and remove incident from active registry |

#### Sample Create Incident Payload (`POST /api/v1/incidents`):
```json
{
  "title": "Lane Blockage near Agara Lake",
  "location": "Outer Ring Road (Agara)",
  "type": "obstruction",
  "severity": "high",
  "description": "Multi-car fender bender blocking center lane towards Bellandur.",
  "assigned_unit": "Patrol Bravo-2"
}
```

---

### 3. Hotspots & Adaptive Signal Tuning (`/api/v1/hotspots`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/v1/hotspots` | List active bottlenecks ranked by severity with AI advisories |
| `GET` | `/api/v1/hotspots/{camera_id}/advisory` | Fetch AI signal advisory for specific junction |
| `POST` | `/api/v1/hotspots/{camera_id}/tune-signal` | Execute dynamic signal timing adjustment (+25s green phase, green wave) |
| `GET` | `/api/v1/hotspots/tuning-history` | View historical audit log of applied signal adjustments |

#### Sample Signal Tuning Payload (`POST /api/v1/hotspots/CAM-001/tune-signal`):
```json
{
  "green_extension_sec": 25,
  "enable_green_wave": true,
  "vms_message": "Congestion on Hosur Rd: Divert via BTM 29th Main",
  "override_reason": "AI Adaptive Peak Congestion Relief"
}
```

---

### 4. Traffic Intelligence & Analytics (`/api/v1/analytics`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/v1/analytics/kpi` | Top-level operational KPIs, daily vehicle volume, and carbon savings |
| `GET` | `/api/v1/analytics/congestion-trend` | 24-hour diurnal congestion curves and speed degradation profiles |
| `GET` | `/api/v1/analytics/vehicle-composition` | Modality distribution (Cars/Cabs, Two-Wheelers, Buses, Freight) |
| `GET` | `/api/v1/analytics/corridor-throughput` | Volume throughput and capacity status across monitored corridors |

---

### 5. Real-Time WebSocket Streaming (`/ws/traffic`)

Connect to `ws://localhost:8000/ws/traffic` to receive continuous real-time telemetry updates.

- Upon connection, the server immediately pushes a `traffic_snapshot` event.
- Every 3 seconds (or when an event occurs), the server pushes a `telemetry_update` event with live corridor stats.
- Clients can send `{"action": "tick"}` to force an update, or `{"action": "ping"}` for a heartbeat check.

---

### 6. Legacy Backward Compatibility

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/traffic` | Returns `{ "status": "success", "data": [...] }` (backward compatible) |
| `POST` | `/traffic` | Accepts `{ ... }` telemetry and returns `{ "status": "received", "data": ... }` |

---

## 🧪 Running Automated Tests

Run the backend verification suite:
```bash
python test_backend.py
```
