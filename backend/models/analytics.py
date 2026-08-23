from typing import List
from pydantic import BaseModel, Field


class KPIOverviewModel(BaseModel):
    traffic_status: str = Field(..., description="Overall city network status (Normal, Moderate, High, Critical)")
    active_incidents: int = Field(..., description="Number of currently open incidents")
    critical_incidents: int = Field(..., description="Number of critical priority incidents")
    congestion_hotspots: int = Field(..., description="Count of identified bottleneck corridors")
    critical_hotspots: int = Field(..., description="Count of critical bottlenecks")
    response_status: str = Field(..., description="Response efficiency percentage, e.g. 98.4%")
    daily_vehicle_volume: str = Field(..., description="Aggregated vehicle volume today, e.g. 148,250")
    peak_flow_rate: str = Field(..., description="Peak vehicles per hour, e.g. 12,400 /hr")
    peak_flow_time: str = Field(..., description="Time of peak observation, e.g. 18:30 IST")
    avg_corridor_speed: str = Field(..., description="Network average speed, e.g. 24.9 km/h")
    speed_delta: str = Field(..., description="Speed change metric, e.g. +3.1 km/h post AI tuning")
    carbon_savings_tons: str = Field(..., description="Estimated reduced idle emissions, e.g. 1.42 Tons")


class CongestionTrendPointModel(BaseModel):
    hour: int = Field(..., description="Hour of day (0-23)")
    time_label: str = Field(..., description="Display label, e.g. '08:00'")
    congestion_score: float = Field(..., description="Congestion score 0.0 - 1.0")
    average_speed: float = Field(..., description="Observed corridor speed km/h")
    vehicle_count: int = Field(..., description="Estimated network vehicle volume")


class VehicleCompositionModel(BaseModel):
    cars_and_cabs: int = Field(48, description="Percentage of cars and ride-hail cabs")
    two_wheelers: int = Field(34, description="Percentage of motorbikes and scooters")
    buses_and_transit: int = Field(12, description="Percentage of public transit and BMTC buses")
    commercial_freight: int = Field(6, description="Percentage of trucks and commercial delivery vans")


class CorridorThroughputModel(BaseModel):
    corridor: str
    volume: str
    status: str
    congestion_level: str
    average_speed_kmh: float
