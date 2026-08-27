from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query

from backend.models.traffic import (
    CameraNodeModel,
    TrafficSummaryModel,
    RawTelemetryEntry,
    IngestTelemetryRequest,
    CongestionLevel,
)
from backend.services.sim_service import traffic_service

router = APIRouter(prefix="/api/v1/traffic", tags=["Live Traffic & Telemetry"])


@router.get("", response_model=TrafficSummaryModel, summary="Get full live traffic summary and corridor nodes")
def get_traffic_summary():
    """Returns network-wide traffic telemetry, active corridor metrics, and all monitored cameras."""
    return traffic_service.get_summary()


@router.get("/nodes", response_model=List[CameraNodeModel], summary="List camera nodes with optional filters")
def get_camera_nodes(
    filter_by: Optional[str] = Query(
        None, description="Filter options: 'Online', 'Congested', or None for all"
    )
):
    """Returns camera sensor nodes with optional filtering for congested zones or online-only cameras."""
    cameras = traffic_service.get_cameras()
    if filter_by == "Online":
        return [c for c in cameras if c.is_online]
    elif filter_by == "Congested":
        return [
            c
            for c in cameras
            if c.congestion_level in [CongestionLevel.CRITICAL, CongestionLevel.HIGH]
        ]
    return cameras


@router.get("/nodes/{camera_id}", response_model=CameraNodeModel, summary="Get telemetry for a specific camera")
def get_camera_node(camera_id: str):
    """Fetches real-time sensor metrics for a specific corridor camera node."""
    node = traffic_service.get_camera(camera_id)
    if not node:
        raise HTTPException(status_code=404, detail=f"Camera node '{camera_id}' not found")
    return node


@router.get("/logs", response_model=List[RawTelemetryEntry], summary="Get raw sensor telemetry log buffer")
def get_raw_telemetry_logs(
    limit: int = Query(50, ge=1, le=100, description="Max number of log records to return")
):
    """Returns unprocessed edge sensor telemetry readings received from the corridor camera network."""
    return traffic_service.get_raw_logs(limit=limit)


@router.post("/tick", response_model=List[CameraNodeModel], summary="Trigger simulation cycle tick")
def trigger_simulation_tick():
    """Forces an immediate simulation update cycle across all corridor sensor nodes."""
    return traffic_service.update_all()


@router.post("/ingest", response_model=CameraNodeModel, summary="Ingest custom edge telemetry reading")
def ingest_telemetry(payload: IngestTelemetryRequest):
    """Receives and parses live telemetry data from physical edge computing camera sensors."""
    return traffic_service.ingest_telemetry(payload)


@router.post("/nodes/{camera_id}/signal", response_model=CameraNodeModel, summary="Switch corridor traffic signal phase")
def switch_corridor_signal(camera_id: str, req: SwitchSignalRequest):
    """Directly switches traffic signal phase and timer for a specific corridor."""
    node = traffic_service.switch_signal(camera_id, req)
    if not node:
        raise HTTPException(status_code=404, detail=f"Camera node '{camera_id}' not found")
    return node


@router.get("/surge-info", summary="Get 30-second shifting congestion surge status")
def get_congestion_surge_info():
    """Returns the current actively congested corridor in the 30-second rolling demo cycle."""
    return traffic_service.get_surge_status()

