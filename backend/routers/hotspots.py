from typing import List, Dict, Any
from fastapi import APIRouter, HTTPException

from backend.models.hotspots import (
    HotspotDetailModel,
    SignalAdvisoryModel,
    SignalTuningRequest,
    SignalTuningResponse,
)
from backend.services.hotspot_service import hotspot_service

router = APIRouter(prefix="/api/v1/hotspots", tags=["Hotspots & AI Signal Optimization"])


@router.get("", response_model=List[HotspotDetailModel], summary="List congestion bottlenecks with AI advisories")
def get_congestion_hotspots():
    """Returns AI-detected recurring bottlenecks and adaptive signal optimization recommendations."""
    return hotspot_service.get_hotspots()


@router.get("/{camera_id}/advisory", response_model=SignalAdvisoryModel, summary="Get AI signal optimization advisory for junction")
def get_signal_advisory(camera_id: str):
    """Fetches real-time signal timing recommendations, green wave progression, and VMS rerouting instructions."""
    advisory = hotspot_service.get_advisory_for_camera(camera_id)
    if not advisory:
        raise HTTPException(status_code=404, detail=f"No junction found with ID '{camera_id}'")
    return advisory


@router.post("/{camera_id}/tune-signal", response_model=SignalTuningResponse, summary="Apply AI adaptive signal timing adjustment")
def apply_signal_tuning(camera_id: str, payload: SignalTuningRequest):
    """Applies dynamic green phase timing extensions and synchronizes arterial green waves."""
    response = hotspot_service.apply_signal_tuning(camera_id, payload)
    if not response:
        raise HTTPException(status_code=404, detail=f"No junction found with ID '{camera_id}'")
    return response


@router.get("/tuning-history", response_model=List[Dict[str, Any]], summary="Get history of applied signal tunings")
def get_tuning_history():
    """Returns the historical audit trail of automated and manual signal tuning adjustments."""
    return hotspot_service.get_tuning_history()
