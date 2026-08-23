# Routers package
from backend.routers.traffic import router as traffic_router
from backend.routers.incidents import router as incidents_router
from backend.routers.hotspots import router as hotspots_router
from backend.routers.analytics import router as analytics_router
from backend.routers.websocket import router as ws_router

__all__ = [
    "traffic_router",
    "incidents_router",
    "hotspots_router",
    "analytics_router",
    "ws_router",
]
