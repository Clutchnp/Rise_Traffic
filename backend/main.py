import asyncio
from contextlib import asynccontextmanager
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.config import APP_NAME, APP_VERSION, APP_DESCRIPTION, SIMULATION_TICK_INTERVAL_SEC
from backend.routers.traffic import router as traffic_router
from backend.routers.incidents import router as incidents_router
from backend.routers.hotspots import router as hotspots_router
from backend.routers.analytics import router as analytics_router
from backend.routers.websocket import router as ws_router
from backend.services.sim_service import traffic_service

background_simulation_task = None


async def run_simulation_loop():
    """Background task that periodically updates corridor traffic telemetry."""
    while True:
        try:
            await asyncio.sleep(SIMULATION_TICK_INTERVAL_SEC)
            traffic_service.update_all()
        except asyncio.CancelledError:
            break
        except Exception as e:
            print(f"[Simulation Worker Error]: {e}")
            await asyncio.sleep(5)


@asynccontextmanager
async def lifespan(app: FastAPI):
    global background_simulation_task
    print(f"🚀 Starting {APP_NAME} v{APP_VERSION}...")
    traffic_service.update_all()
    background_simulation_task = asyncio.create_task(run_simulation_loop())
    yield
    print("🛑 Shutting down traffic intelligence platform...")
    if background_simulation_task:
        background_simulation_task.cancel()


app = FastAPI(
    title=APP_NAME,
    version=APP_VERSION,
    description=APP_DESCRIPTION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Enable CORS for Flutter Web, Mobile, and Desktop clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount modular API routers
app.include_router(traffic_router)
app.include_router(incidents_router)
app.include_router(hotspots_router)
app.include_router(analytics_router)
app.include_router(ws_router)


# System Health & Root Endpoints
@app.get("/", tags=["System"])
def root():
    summary = traffic_service.get_summary()
    return {
        "app": APP_NAME,
        "version": APP_VERSION,
        "status": "GridLock 2.0 backend running",
        "active_corridors": summary.active_corridors,
        "overall_traffic_status": summary.overall_status,
        "documentation": "/docs",
        "timestamp": datetime.now().isoformat(),
    }


@app.get("/health", tags=["System"])
def health():
    return {
        "status": "healthy",
        "service": "traffic_intelligence_api",
        "corridors_monitored": len(traffic_service.get_cameras()),
        "timestamp": datetime.now().isoformat(),
    }


# Legacy Backward Compatibility Endpoints
@app.get("/traffic", tags=["Legacy Compatibility"])
def get_legacy_traffic():
    """Legacy endpoint returning list of corridor updates."""
    data = [node.model_dump() for node in traffic_service.update_all()]
    return {
        "status": "success",
        "data": data,
    }


@app.post("/traffic", tags=["Legacy Compatibility"])
def receive_legacy_traffic(data: dict):
    """Legacy endpoint receiving raw traffic payloads."""
    print("Received telemetry via legacy endpoint:", data)
    return {
        "status": "received",
        "data": data,
    }
