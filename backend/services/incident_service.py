from typing import List, Optional, Dict
from datetime import datetime
from backend.models.incident import (
    IncidentRecordModel,
    IncidentCreateRequest,
    IncidentUpdateRequest,
    DispatchBackupRequest,
    IncidentType,
    IncidentStatus,
)
from backend.models.traffic import CongestionLevel

INITIAL_INCIDENTS = [
    IncidentRecordModel(
        id="INC-1049",
        title="Major Congestion Bottleneck",
        location="Silk Board Junction",
        time="2 min ago",
        type=IncidentType.CONGESTION,
        severity=CongestionLevel.CRITICAL,
        description="Severe traffic buildup due to heavy inflow from Hosur Road towards BTM.",
        assigned_unit="Patrol Alpha-4",
        status=IncidentStatus.IN_PROGRESS,
        latitude=12.9176,
        longitude=77.6238,
    ),
    IncidentRecordModel(
        id="INC-1048",
        title="Traffic Lane Obstruction",
        location="Outer Ring Road (Marathahalli)",
        time="6 min ago",
        type=IncidentType.OBSTRUCTION,
        severity=CongestionLevel.HIGH,
        description="Fallen tree branch blocking the left lane heading towards Bellandur.",
        assigned_unit="Quick Response Team 2",
        status=IncidentStatus.DISPATCHED,
        latitude=12.9591,
        longitude=77.6974,
    ),
    IncidentRecordModel(
        id="INC-1047",
        title="Slow Moving Traffic",
        location="Koramangala 80ft Road",
        time="11 min ago",
        type=IncidentType.CONGESTION,
        severity=CongestionLevel.MODERATE,
        description="Intermittent signal delays causing steady queue accumulation.",
        assigned_unit="Traffic Warden 09",
        status=IncidentStatus.MONITORING,
        latitude=12.9352,
        longitude=77.6245,
    ),
    IncidentRecordModel(
        id="INC-1046",
        title="Commercial Vehicle Breakdown",
        location="MG Road Junction",
        time="18 min ago",
        type=IncidentType.BREAKDOWN,
        severity=CongestionLevel.MODERATE,
        description="Stalled delivery van on right turning lane, tow truck requested.",
        assigned_unit="Tow Unit 3",
        status=IncidentStatus.DISPATCHED,
        latitude=12.9756,
        longitude=77.6066,
    ),
    IncidentRecordModel(
        id="INC-1045",
        title="Traffic Signal Desync",
        location="Hebbal Interchange",
        time="34 min ago",
        type=IncidentType.SIGNAL_FAILURE,
        severity=CongestionLevel.NORMAL,
        description="Signal timing reverted to fixed backup cycle; technician notified.",
        assigned_unit="Signals Dept Tech",
        status=IncidentStatus.UNDER_REVIEW,
        latitude=13.0358,
        longitude=77.5970,
    ),
]


class IncidentService:
    def __init__(self):
        self._incidents: Dict[str, IncidentRecordModel] = {
            inc.id: inc for inc in INITIAL_INCIDENTS
        }
        self._next_id_counter = 1050

    def list_incidents(
        self,
        severity: Optional[CongestionLevel] = None,
        status: Optional[IncidentStatus] = None,
    ) -> List[IncidentRecordModel]:
        results = list(self._incidents.values())
        if severity:
            results = [i for i in results if i.severity == severity]
        if status:
            results = [i for i in results if i.status == status]
        return results

    def get_incident(self, incident_id: str) -> Optional[IncidentRecordModel]:
        return self._incidents.get(incident_id)

    def create_incident(self, req: IncidentCreateRequest) -> IncidentRecordModel:
        incident_id = f"INC-{self._next_id_counter}"
        self._next_id_counter += 1

        record = IncidentRecordModel(
            id=incident_id,
            title=req.title,
            location=req.location,
            time="Just now",
            type=req.type,
            severity=req.severity,
            description=req.description,
            assigned_unit=req.assigned_unit or "Patrol Central",
            status=IncidentStatus.IN_PROGRESS,
            latitude=req.latitude,
            longitude=req.longitude,
        )
        self._incidents[incident_id] = record
        return record

    def update_incident(
        self, incident_id: str, req: IncidentUpdateRequest
    ) -> Optional[IncidentRecordModel]:
        record = self._incidents.get(incident_id)
        if not record:
            return None

        update_dict = req.model_dump(exclude_unset=True)
        updated_record = record.model_copy(update=update_dict)
        self._incidents[incident_id] = updated_record
        return updated_record

    def dispatch_backup(
        self, incident_id: str, req: DispatchBackupRequest
    ) -> Optional[IncidentRecordModel]:
        record = self._incidents.get(incident_id)
        if not record:
            return None

        unit_str = f"{record.assigned_unit} + {req.unit_name or 'Backup Patrol'}"
        notes_str = f"{record.description} [Backup dispatched at {datetime.now().strftime('%H:%M:%S')}: {req.notes or 'Urgent assistance requested'}]"

        updated = record.model_copy(
            update={
                "assigned_unit": unit_str,
                "status": IncidentStatus.DISPATCHED,
                "description": notes_str,
            }
        )
        self._incidents[incident_id] = updated
        return updated

    def delete_incident(self, incident_id: str) -> bool:
        if incident_id in self._incidents:
            del self._incidents[incident_id]
            return True
        return False

    def get_metrics(self) -> Dict[str, Any]:
        all_inc = list(self._incidents.values())
        active = [i for i in all_inc if i.status != IncidentStatus.RESOLVED]
        critical = [i for i in active if i.severity == CongestionLevel.CRITICAL]
        return {
            "total_active": len(active),
            "critical_count": len(critical),
            "resolved_count": len(all_inc) - len(active) + 29,  # baseline resolved today
            "response_rate": "98.4%",
            "avg_dispatch_time": "3.8 min",
        }


incident_service = IncidentService()
