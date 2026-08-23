import asyncio
import json
from typing import List, Set
from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from backend.services.sim_service import traffic_service

router = APIRouter(tags=["Real-Time Streaming"])


class ConnectionManager:
    def __init__(self):
        self.active_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.add(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.discard(websocket)

    async def broadcast_json(self, data: dict):
        dead_connections = []
        for connection in list(self.active_connections):
            try:
                await connection.send_json(data)
            except Exception:
                dead_connections.append(connection)
        for dead in dead_connections:
            self.active_connections.discard(dead)


manager = ConnectionManager()


@router.websocket("/ws/traffic")
async def websocket_traffic_stream(websocket: WebSocket):
    """
    Real-time WebSocket endpoint streaming continuous live corridor telemetry and congestion updates.
    Sends instant snapshot upon connection and streams updates every 3 seconds.
    """
    await manager.connect(websocket)
    try:
        # Send initial snapshot immediately
        initial_data = traffic_service.get_summary().model_dump()
        await websocket.send_json({"event": "traffic_snapshot", "payload": initial_data})

        while True:
            # Check if client sent any command (non-blocking with timeout)
            try:
                msg_text = await asyncio.wait_for(websocket.receive_text(), timeout=3.0)
                try:
                    msg_json = json.loads(msg_text)
                    if msg_json.get("action") == "tick":
                        traffic_service.update_all()
                    elif msg_json.get("action") == "ping":
                        await websocket.send_json({"event": "pong"})
                except json.JSONDecodeError:
                    pass
            except asyncio.TimeoutError:
                pass

            # Broadcast current live state
            summary = traffic_service.get_summary().model_dump()
            await websocket.send_json({"event": "telemetry_update", "payload": summary})

    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception:
        manager.disconnect(websocket)
