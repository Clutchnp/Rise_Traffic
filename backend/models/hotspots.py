from typing import Optional, List
from pydantic import BaseModel, Field
from backend.models.traffic import CongestionLevel


class SignalAdvisoryModel(BaseModel):
    corridor_id: str
    corridor_name: str
    current_congestion: CongestionLevel
    recommendation_title: str
    recommendation_text: str
    suggested_green_extension_sec: int
    enable_vms_reroute: bool
    enable_green_wave: bool


class HotspotDetailModel(BaseModel):
    camera_id: str
    name: str
    latitude: float
    longitude: float
    congestion_level: CongestionLevel
    congestion_score: float = Field(0.0, description="Normalized score 0.0 to 1.0")
    vehicle_count: int
    average_speed: float
    occupancy: float
    queue_length: int
    signal_phase: str = Field("NORTH_SOUTH_GREEN", description="Active signal phase")
    green_time_sec: int = Field(45, description="Green light duration in seconds")
    signal_mode: str = Field("ADAPTIVE", description="ADAPTIVE or MANUAL")
    is_surge_active: bool = Field(False, description="True if actively surging")
    recommendation: Optional[str] = Field(None, description="Operational status directive")
    suggested_green_extension_sec: int = Field(0, description="Recommended green duration")


class SignalTuningRequest(BaseModel):
    phase: Optional[str] = Field("NORTH_SOUTH_GREEN", description="Target signal phase")
    green_extension_sec: Optional[int] = 45
    enable_green_wave: Optional[bool] = True
    vms_message: Optional[str] = None
    override_reason: Optional[str] = "Operator Signal Switch"
    mode: Optional[str] = "MANUAL"


class SignalTuningResponse(BaseModel):
    status: str = "success"
    message: str
    camera_id: str
    corridor_name: str
    applied_phase: str = "NORTH_SOUTH_GREEN"
    applied_green_extension_sec: int = 45
    applied_at: str

