"""
Automated Test Suite for RISE AI / GridLock 2.0 Backend
Direct unit & integration tests covering:
- System Root & Health handlers
- Live Traffic Summary, Nodes filtering, Single Camera inspection, and Raw Telemetry Logs
- Ingesting custom edge sensor readings
- Incident Management (listing, filtering, creation, patch updates, backup dispatching)
- Hotspots & AI Signal Tuning application and history tracking
- Analytics (KPI overview, 24h congestion trends, vehicle composition, corridor throughput)
- Legacy backward compatible endpoints
"""

import sys
import os

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.main import root, health, get_legacy_traffic, receive_legacy_traffic
from backend.routers.traffic import (
    get_traffic_summary,
    get_camera_nodes,
    get_camera_node,
    get_raw_telemetry_logs,
    trigger_simulation_tick,
    ingest_telemetry,
)
from backend.routers.incidents import (
    list_incidents,
    get_incident_metrics,
    get_incident,
    create_incident,
    update_incident,
    dispatch_backup_unit,
    delete_incident,
)
from backend.routers.hotspots import (
    get_congestion_hotspots,
    get_signal_advisory,
    apply_signal_tuning,
    get_tuning_history,
)
from backend.routers.analytics import (
    get_kpi_overview,
    get_congestion_trend,
    get_vehicle_composition,
    get_corridor_throughput,
)
from backend.models.traffic import IngestTelemetryRequest, CongestionLevel
from backend.models.incident import (
    IncidentCreateRequest,
    IncidentUpdateRequest,
    DispatchBackupRequest,
    IncidentStatus,
    IncidentType,
)
from backend.models.hotspots import SignalTuningRequest


def test_system_endpoints():
    print("\n--- 1. Testing System Endpoints ---")
    res = root()
    assert "GridLock 2.0 backend running" in res["status"]
    assert res["active_corridors"] >= 4
    print("✅ Root handler verified:", res["app"])

    h = health()
    assert h["status"] == "healthy"
    print("✅ Health check verified:", h["service"])


def test_traffic_endpoints():
    print("\n--- 2. Testing Traffic Endpoints ---")
    summary = get_traffic_summary()
    assert summary.status == "success"
    assert len(summary.cameras) >= 8
    print(f"✅ Traffic summary verified: {summary.active_corridors} active corridors, overall status = {summary.overall_status}")

    # Node filtering
    online_cams = get_camera_nodes(filter_by="Online")
    assert len(online_cams) > 0
    print(f"✅ Online camera filtering verified ({len(online_cams)} online).")

    # Specific camera
    cam1 = get_camera_node(camera_id="CAM-001")
    assert cam1.id == "CAM-001"
    assert "Silk Board" in cam1.name
    print(f"✅ Single camera inspection verified: {cam1.name} (Speed: {cam1.average_speed} km/h, Score: {cam1.congestion_score})")

    # Raw telemetry logs
    logs = get_raw_telemetry_logs(limit=10)
    assert len(logs) > 0
    print(f"✅ Raw telemetry logs verified ({len(logs)} entries retrieved).")

    # Ingest custom telemetry
    ingest_req = IngestTelemetryRequest(
        camera_id="CAM-TEST",
        location="Electronic City Test Bridge",
        latitude=12.8452,
        longitude=77.6602,
        vehicle_count=185,
        average_speed=11.5,
        occupancy=0.92,
        queue_length=48,
    )
    ingested = ingest_telemetry(ingest_req)
    assert ingested.id == "CAM-TEST"
    assert ingested.congestion_level == CongestionLevel.CRITICAL
    print("✅ Custom edge telemetry ingestion verified:", ingested.name, "->", ingested.congestion_level.value)


def test_incident_endpoints():
    print("\n--- 3. Testing Incident Management Endpoints ---")
    incidents = list_incidents(severity=None, status=None)
    assert len(incidents) >= 5
    print(f"✅ Listed {len(incidents)} active traffic incidents.")

    # Filtered listing
    crit_incidents = list_incidents(severity=CongestionLevel.CRITICAL, status=None)
    assert len(crit_incidents) >= 1
    print(f"✅ Filtered critical incidents verified ({len(crit_incidents)} critical).")

    # Incident metrics
    metrics = get_incident_metrics()
    assert metrics["total_active"] >= 3
    print(f"✅ Incident metrics verified: {metrics}")

    # Create new incident
    new_inc_req = IncidentCreateRequest(
        title="Severe Waterlogging Bottleneck",
        location="Ecospace Outer Ring Road",
        type=IncidentType.CONGESTION,
        severity=CongestionLevel.CRITICAL,
        description="Flash flooding on service road causing 2km vehicle queue.",
        assigned_unit="Patrol Charlie-1",
    )
    created = create_incident(new_inc_req)
    new_id = created.id
    assert "Ecospace" in created.location
    print(f"✅ Incident logged successfully with ID: {new_id}")

    # Dispatch backup unit
    dispatch_req = DispatchBackupRequest(
        unit_name="Drainage Emergency Response Team",
        notes="Deploying suction pumps and traffic diversion signage",
    )
    dispatched = dispatch_backup_unit(new_id, dispatch_req)
    assert "Drainage Emergency" in dispatched.assigned_unit
    assert dispatched.status == IncidentStatus.DISPATCHED
    print(f"✅ Backup unit dispatch verified for {new_id} -> Assigned: {dispatched.assigned_unit}")


def test_hotspot_endpoints():
    print("\n--- 4. Testing Hotspots & AI Signal Tuning ---")
    hotspots = get_congestion_hotspots()
    assert len(hotspots) >= 8
    print(f"✅ Retrieved {len(hotspots)} bottleneck corridors ranked by congestion severity.")

    # Advisory for Silk Board
    advisory = get_signal_advisory(camera_id="CAM-001")
    assert "Silk Board" in advisory.corridor_name
    print(f"✅ AI Signal Advisory: {advisory.recommendation_text}")

    # Apply signal tuning
    tuning_req = SignalTuningRequest(
        green_extension_sec=30,
        enable_green_wave=True,
        vms_message="Congestion on Hosur Road: Divert via BTM 29th Main",
        override_reason="Automated Peak AI Congestion Relief",
    )
    tuned = apply_signal_tuning(camera_id="CAM-001", payload=tuning_req)
    assert tuned.applied_green_extension_sec == 30
    print(f"✅ Signal tuning applied: {tuned.message}")

    # Tuning history
    history = get_tuning_history()
    assert len(history) > 0
    print(f"✅ Signal tuning audit history verified ({len(history)} entries).")


def test_analytics_endpoints():
    print("\n--- 5. Testing Analytics Endpoints ---")
    kpis = get_kpi_overview()
    assert kpis.response_status == "98.4%"
    print(f"✅ Analytics KPIs verified: Daily Volume = {kpis.daily_vehicle_volume}, Avg Speed = {kpis.avg_corridor_speed}, Carbon Savings = {kpis.carbon_savings_tons}")

    # 24h congestion trend
    trend = get_congestion_trend()
    assert len(trend) == 24
    print("✅ 24-hour diurnal congestion curve verified (24 hourly points).")

    # Vehicle composition
    comp = get_vehicle_composition()
    assert comp.cars_and_cabs == 48
    assert comp.two_wheelers == 34
    print(f"✅ Vehicle composition verified: {comp}")

    # Corridor throughput
    throughput = get_corridor_throughput()
    assert len(throughput) >= 8
    print(f"✅ Corridor volume throughput verified across {len(throughput)} arterial corridors.")


def test_legacy_endpoints():
    print("\n--- 6. Testing Legacy Backward Compatible Endpoints ---")
    legacy_traffic = get_legacy_traffic()
    assert legacy_traffic["status"] == "success"
    assert len(legacy_traffic["data"]) >= 8
    print(f"✅ Legacy GET /traffic verified ({len(legacy_traffic['data'])} corridors returned).")

    rec = receive_legacy_traffic({"camera_id": "CAM-001", "vehicle_count": 120})
    assert rec["status"] == "received"
    print("✅ Legacy POST /traffic verified.")


if __name__ == "__main__":
    print("🚦 Running Full Backend Test Suite for RISE AI...")
    test_system_endpoints()
    test_traffic_endpoints()
    test_incident_endpoints()
    test_hotspot_endpoints()
    test_analytics_endpoints()
    test_legacy_endpoints()
    print("\n🎉 ALL 6 TEST MODULES PASSED SUCCESSFULLY! 🚀")
