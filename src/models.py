from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional

class Phase(str, Enum):
    NORTH_SOUTH = "north_south"
    EAST_WEST = "east_west"

@dataclass
class EmergencyRequest:
    

    approach: str
    vehicles: int = 1
    active: bool = True

    def __post_init__(self) -> None:
        if not self.approach:
            raise ValueError("approach cannot be empty")
        if self.vehicles < 1:
            raise ValueError("vehicles must be >= 1")

@dataclass
class ApproachState:
    

    name: str
    queue: float
    arrival_rate: float
    saturation_flow: float

    downstream_queue: float = 0.0
    speed_kph: Optional[float] = None
    lanes: int = 1
    weight: float = 1.0

                                                                     
    waiting_since_green: float = 0.0

                                             
    emergency_vehicle_count: int = 0

    def __post_init__(self) -> None:
        if not self.name:
            raise ValueError("name cannot be empty")
        if self.queue < 0:
            raise ValueError("queue cannot be negative")
        if self.arrival_rate < 0:
            raise ValueError("arrival_rate cannot be negative")
        if self.saturation_flow <= 0:
            raise ValueError("saturation_flow must be positive")
        if self.downstream_queue < 0:
            raise ValueError("downstream_queue cannot be negative")
        if self.lanes < 1:
            raise ValueError("lanes must be >= 1")
        if self.weight <= 0:
            raise ValueError("weight must be positive")
        if self.waiting_since_green < 0:
            raise ValueError("waiting_since_green cannot be negative")
        if self.emergency_vehicle_count < 0:
            raise ValueError("emergency_vehicle_count cannot be negative")
        if self.speed_kph is not None and self.speed_kph < 0:
            raise ValueError("speed_kph cannot be negative")

@dataclass
class IntersectionState:
    

    intersection_id: str

    north: ApproachState
    south: ApproachState
    east: ApproachState
    west: ApproachState

    current_phase: Phase = Phase.NORTH_SOUTH
    elapsed_green: float = 0.0

                                                      
    prediction_horizon: float = 15.0

                                        
    emergency: Optional[EmergencyRequest] = None

                                                
    timestamp: float = 0.0

    def __post_init__(self) -> None:
        if not self.intersection_id:
            raise ValueError("intersection_id cannot be empty")
        if self.prediction_horizon <= 0:
            raise ValueError("prediction_horizon must be positive")
        if self.elapsed_green < 0:
            raise ValueError("elapsed_green cannot be negative")

    def approaches_for_phase(self, phase: Phase) -> List[ApproachState]:
        if phase == Phase.NORTH_SOUTH:
            return [self.north, self.south]
        if phase == Phase.EAST_WEST:
            return [self.east, self.west]
        raise ValueError(f"Unsupported phase: {phase}")

    def all_approaches(self) -> List[ApproachState]:
        return [self.north, self.south, self.east, self.west]

@dataclass
class SignalConfig:
    

    cycle_length: int = 90
    min_green: int = 15
    max_green: int = 55
    yellow_time: int = 3
    all_red_time: int = 1

    replanning_interval: int = 90
    min_phase_hold: int = 10

    emergency_priority: bool = True
    emergency_pressure_multiplier: float = 10.0

                        
    queue_weight: float = 1.0
    arrival_weight: float = 15.0
    downstream_weight: float = 0.5
    starvation_weight: float = 1.5
    speed_weight: float = 0.1

    def __post_init__(self) -> None:
        if self.cycle_length <= 0:
            raise ValueError("cycle_length must be positive")
        if self.min_green <= 0:
            raise ValueError("min_green must be positive")
        if self.max_green < self.min_green:
            raise ValueError("max_green must be >= min_green")
        if self.yellow_time < 0 or self.all_red_time < 0:
            raise ValueError("clearance times cannot be negative")
        if self.replanning_interval <= 0:
            raise ValueError("replanning_interval must be positive")
        if self.min_phase_hold < 0:
            raise ValueError("min_phase_hold cannot be negative")
        if self.emergency_pressure_multiplier < 1:
            raise ValueError("emergency_pressure_multiplier must be >= 1")

        if self.available_green < 2 * self.min_green:
            raise ValueError(
                "Available green time must be at least 2 * min_green. "
                f"Got {self.available_green}."
            )

        if self.available_green > 2 * self.max_green:
            raise ValueError(
                "Available green time exceeds combined max_green bounds. "
                f"Got {self.available_green}."
            )

    @property
    def lost_time_per_phase(self) -> int:
        return self.yellow_time + self.all_red_time

    @property
    def total_lost_time(self) -> int:
        return 2 * self.lost_time_per_phase

    @property
    def available_green(self) -> int:
        return self.cycle_length - self.total_lost_time

@dataclass
class PhaseAllocation:
    phase: Phase
    green_time: int
    pressure: float
    demand: float
    estimated_served_vehicles: float
    emergency: bool = False

@dataclass
class SignalPlan:
    intersection_id: str
    allocations: Dict[Phase, PhaseAllocation]

    cycle_length: int
    yellow_time: int
    all_red_time: int

    objective_value: float
    generated_at: float = 0.0

    explanation: str = ""

    @property
    def total_green(self) -> int:
        return sum(item.green_time for item in self.allocations.values())

    def green_for(self, phase: Phase) -> int:
        return self.allocations[phase].green_time
