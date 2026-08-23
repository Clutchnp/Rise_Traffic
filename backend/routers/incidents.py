from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, Query, status

from backend.models.incident import (
    IncidentRecordModel,
    IncidentCreateRequest,
    IncidentUpdateRequest,
    DispatchBackupRequest,
    IncidentStatus,
)
from backend.models.traffic import CongestionLevel
from backend.services.incident_service import incident_service

router = APIRouter(prefix="/api/v1/incidents", tags=["Incident Management"])


@router.get("", response_model=List[IncidentRecordModel], summary="List all traffic incidents")
def list_incidents(
    severity: Optional[CongestionLevel] = Query(
        None, description="Filter by severity: critical, high, moderate, normal"
    ),
    status: Optional[IncidentStatus] = Query(
        None, description="Filter by status: 'In Progress', 'Dispatched', 'Monitoring', 'Resolved'"
    ),
):
    """Returns all logged traffic incidents matching optional severity or status filters."""
    return incident_service.list_incidents(severity=severity, status=status)


@router.get("/metrics", response_model=Dict[str, Any], summary="Get incident resolution metrics")
def get_incident_metrics():
    """Returns incident metrics including total active, critical priority count, and dispatch efficiency."""
    return incident_service.get_metrics()


@router.get("/{incident_id}", response_model=IncidentRecordModel, summary="Get single incident by ID")
def get_incident(incident_id: str):
    """Fetches full metadata and status for a specific incident."""
    incident = incident_service.get_incident(incident_id)
    if not incident:
        raise HTTPException(status_code=404, detail=f"Incident '{incident_id}' not found")
    return incident


@router.post(
    "",
    response_model=IncidentRecordModel,
    status_code=status.HTTP_201_CREATED,
    summary="Log a new traffic incident",
)
def create_incident(payload: IncidentCreateRequest):
    """Logs a new traffic incident and assigns it to central dispatch."""
    return incident_service.create_incident(payload)


@router.patch("/{incident_id}", response_model=IncidentRecordModel, summary="Update incident details or status")
def update_incident(incident_id: str, payload: IncidentUpdateRequest):
    """Updates status, severity, or assigned unit for an active incident."""
    updated = incident_service.update_incident(incident_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail=f"Incident '{incident_id}' not found")
    return updated


@router.post("/{incident_id}/dispatch", response_model=IncidentRecordModel, summary="Dispatch backup response unit")
def dispatch_backup_unit(incident_id: str, payload: DispatchBackupRequest):
    """Dispatches backup emergency patrol or tow units to an active incident location."""
    updated = incident_service.dispatch_backup(incident_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail=f"Incident '{incident_id}' not found")
    return updated


@router.delete("/{incident_id}", summary="Delete an incident record")
def delete_incident(incident_id: str):
    """Removes an incident record from the active dispatch registry."""
    success = incident_service.delete_incident(incident_id)
    if not success:
        raise HTTPException(status_code=404, detail=f"Incident '{incident_id}' not found")
    return {"status": "success", "message": f"Incident '{incident_id}' deleted successfully"}
