from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field


class CongestionLevel(str, Enum):
    NORMAL = "normal"
    MODERATE = "moderate"
    HIGH = "high"
    CRITICAL = "critical"


class CameraNodeModel(BaseModel):
    id: str = Field(..., description="Unique Camera/Sensor Node ID, e.g. CAM-001")
    name: str = Field(..., description="Corridor or Junction Name")
    latitude: float = Field(..., description="Latitude coordinate")
    longitude: float = Field(..., description="Longitude coordinate")
    is_online: bool = Field(True, description="Online status of the sensor")
    vehicle_count: int = Field(..., description="Estimated live vehicle count")
    average_speed: float = Field(..., description="Average observed speed in km/h")
    occupancy: float = Field(..., description="Lane occupancy ratio from 0.0 to 1.0")
    queue_length: int = Field(0, description="Estimated queue length in number of vehicles")
    congestion_score: float = Field(0.0, description="Normalized congestion score between 0.0 and 1.0")
    congestion_level: CongestionLevel = Field(..., description="Congestion category: normal, moderate, high, critical")
    last_updated: str = Field(..., description="Formatted timestamp, e.g. 17:30:45")
    description: Optional[str] = Field(None, description="Corridor contextual description")


class TrafficSummaryModel(BaseModel):
    status: str = "success"
    active_corridors: int
    overall_status: str
    average_speed: float
    total_vehicles: int
    cameras: List[CameraNodeModel]


class RawTelemetryEntry(BaseModel):
    camera_id: str
    corridor_location: str
    vehicles: int
    avg_speed: float
    occupancy: float
    queue: int
    timestamp: str
    status: str


class IngestTelemetryRequest(BaseModel):
    camera_id: str
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    vehicle_count: int
    average_speed: float
    occupancy: float
    queue_length: Optional[int] = None
