from typing import List
from fastapi import APIRouter

from backend.models.analytics import (
    KPIOverviewModel,
    CongestionTrendPointModel,
    VehicleCompositionModel,
    CorridorThroughputModel,
    InsightsResponseModel,
)
from backend.services.analytics_service import analytics_service

router = APIRouter(prefix="/api/v1/analytics", tags=["Traffic Intelligence & Analytics"])


@router.get("/kpi", response_model=KPIOverviewModel, summary="Get high-level traffic intelligence KPIs")
def get_kpi_overview():
    """Returns top-level operational KPIs, daily volume throughput, response rate, and emissions savings."""
    return analytics_service.get_kpi_overview()


@router.get("/congestion-trend", response_model=List[CongestionTrendPointModel], summary="Get 24-hour congestion curve")
def get_congestion_trend():
    """Returns 24-hour diurnal congestion curves, network speed degradation profiles, and flow volumes."""
    return analytics_service.get_congestion_trend_24h()


@router.get("/vehicle-composition", response_model=VehicleCompositionModel, summary="Get vehicle modality classification distribution")
def get_vehicle_composition():
    """Returns classification percentage breakdown for cars, two-wheelers, buses, and commercial freight."""
    return analytics_service.get_vehicle_composition()


@router.get("/corridor-throughput", response_model=List[CorridorThroughputModel], summary="Get corridor volume throughput rankings")
def get_corridor_throughput():
    """Returns 24-hour volume throughput and capacity status across monitored arterial corridors."""
    return analytics_service.get_corridor_throughput()


@router.get("/insights", response_model=InsightsResponseModel, summary="Get dataset graph insights")
def get_dataset_insights():
    """Returns aggregated temporal flow, hotspot rankings, and accident-prone zones from the core dataset."""
    return analytics_service.get_graph_insights()
