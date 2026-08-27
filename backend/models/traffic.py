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
    signal_phase: str = Field("NORTH_SOUTH_GREEN", description="Current traffic signal phase")
    green_time_sec: int = Field(45, description="Active green phase timer in seconds")
    signal_mode: str = Field("ADAPTIVE", description="Signal controller mode: ADAPTIVE or MANUAL")
    is_surge_active: bool = Field(False, description="True if currently experiencing live 30s congestion surge")


class TrafficSummaryModel(BaseModel):
    status: str = "success"
    active_corridors: int
    overall_status: str
    average_speed: float
    total_vehicles: int
    cameras: List[CameraNodeModel]
    active_surge_corridor: Optional[str] = None
    seconds_to_next_surge: int = 30


class RawTelemetryEntry(BaseModel):
    camera_id: str
    corridor_location: str
    vehicles: int
    avg_speed: float
    occupancy: float
    queue: int
    timestamp: str
    status: str


class SwitchSignalRequest(BaseModel):
    phase: str = Field(..., description="Target signal phase: NORTH_SOUTH_GREEN, EAST_WEST_GREEN, PRIORITY_CLEARANCE, ALL_RED")
    green_duration_sec: Optional[int] = Field(45, description="Duration in seconds for the green phase")
    mode: Optional[str] = Field("MANUAL", description="Control mode: MANUAL or ADAPTIVE")


class IngestTelemetryRequest(BaseModel):
    camera_id: str
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    vehicle_count: int
    average_speed: float
    occupancy: float
    queue_length: Optional[int] = None
    
    # New optional fields to support the RandomForest model features
    weather: Optional[str] = Field("Clear", description="Weather Conditions")
    roadwork: Optional[str] = Field("No", description="Roadwork and Construction Activity")
    pedestrian_count: Optional[int] = Field(15, description="Pedestrian and Cyclist Count")
