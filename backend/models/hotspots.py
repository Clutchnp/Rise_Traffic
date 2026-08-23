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
    vehicle_count: int
    average_speed: float
    occupancy: float
    queue_length: int
    recommendation: str
    suggested_green_extension_sec: int


class SignalTuningRequest(BaseModel):
    green_extension_sec: Optional[int] = 25
    enable_green_wave: Optional[bool] = True
    vms_message: Optional[str] = None
    override_reason: Optional[str] = "AI Adaptive Congestion Relief"


class SignalTuningResponse(BaseModel):
    status: str = "success"
    message: str
    camera_id: str
    corridor_name: str
    applied_green_extension_sec: int
    applied_at: str
