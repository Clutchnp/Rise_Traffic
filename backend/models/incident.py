from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field
from backend.models.traffic import CongestionLevel


class IncidentType(str, Enum):
    CONGESTION = "congestion"
    OBSTRUCTION = "obstruction"
    BREAKDOWN = "breakdown"
    ACCIDENT = "accident"
    SIGNAL_FAILURE = "signalFailure"


class IncidentStatus(str, Enum):
    IN_PROGRESS = "In Progress"
    DISPATCHED = "Dispatched"
    MONITORING = "Monitoring"
    RESOLVED = "Resolved"
    UNDER_REVIEW = "Under Review"


class IncidentRecordModel(BaseModel):
    id: str = Field(..., description="Unique incident identifier, e.g. INC-1049")
    title: str = Field(..., description="Short incident summary")
    location: str = Field(..., description="Corridor or landmark name")
    time: str = Field(..., description="Human readable relative time, e.g. 2 min ago")
    type: IncidentType = Field(..., description="Classification category")
    severity: CongestionLevel = Field(..., description="Severity level")
    description: str = Field(..., description="Detailed situation description")
    assigned_unit: str = Field(..., description="Designated patrol or warden unit, e.g. Patrol Alpha-4")
    status: IncidentStatus = Field(..., description="Resolution status")
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class IncidentCreateRequest(BaseModel):
    title: str
    location: str
    type: IncidentType = IncidentType.CONGESTION
    severity: CongestionLevel = CongestionLevel.MODERATE
    description: str
    assigned_unit: Optional[str] = "Central Dispatch Unit"
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class IncidentUpdateRequest(BaseModel):
    title: Optional[str] = None
    severity: Optional[CongestionLevel] = None
    description: Optional[str] = None
    assigned_unit: Optional[str] = None
    status: Optional[IncidentStatus] = None


class DispatchBackupRequest(BaseModel):
    unit_name: Optional[str] = "Quick Response Backup Unit"
    notes: Optional[str] = None
