from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Iterable

from .controller import SignalController
from .fixed_time import FixedTimeController
from .models import IntersectionState, Phase

@dataclass
class SimulationMetrics:
    seconds: int = 0
    total_waiting_vehicle_seconds: float = 0.0
    total_arrivals: float = 0.0
    total_vehicles_served: float = 0.0
    total_queue_vehicle_seconds: float = 0.0
    max_queue: float = 0.0
    total_stops: float = 0.0

    @property
    def average_queue(self) -> float:
        if self.seconds <= 0:
            return 0.0
        return self.total_queue_vehicle_seconds / self.seconds

    @property
    def average_waiting_per_vehicle(self) -> float:
        if self.total_vehicles_served <= 0:
            return 0.0
        return (
            self.total_waiting_vehicle_seconds
            / self.total_vehicles_served
        )

    @property
    def throughput(self) -> float:
        if self.seconds <= 0:
            return 0.0
        return self.total_vehicles_served / self.seconds

class SimpleIntersectionDemandModel:
    

    def __init__(
        self,
        rates: dict[str, float],
        seed: int = 42,
    ) -> None:
        import random

        self.rates = rates
        self.random = random.Random(seed)

    def arrivals(self, approach_name: str) -> float:
        rate = self.rates.get(approach_name, 0.0)

                                                      
        count = 0
        probability = min(0.95, max(0.0, rate))

        if probability == 0:
            return 0.0

        if probability < 1.0:
            if self.random.random() < probability:
                count = 1
        else:
            count = int(probability)

        return float(count)

class IntersectionSimulator:
    

    def __init__(
        self,
        state: IntersectionState,
        controller,
        demand_model: SimpleIntersectionDemandModel | None = None,
    ) -> None:
        self.state = state
        self.controller = controller
        self.metrics = SimulationMetrics()

        self.demand_model = demand_model or SimpleIntersectionDemandModel(
            rates={
                "north": state.north.arrival_rate,
                "south": state.south.arrival_rate,
                "east": state.east.arrival_rate,
                "west": state.west.arrival_rate,
            }
        )

        self._initialize_controller()

    def _initialize_controller(self) -> None:
        if isinstance(self.controller, SignalController):
            self.controller.initialize(self.state)

    def _controller_phase(self) -> Phase:
        if isinstance(self.controller, SignalController):
            output = self.controller.tick()
            return output.phase if output.state == "GREEN" else output.phase

        if isinstance(self.controller, FixedTimeController):
            return self.controller.tick()

        raise TypeError(
            "Controller must be SignalController or FixedTimeController."
        )

    def _is_green(self) -> bool:
        if isinstance(self.controller, SignalController):
            return self.controller.phase_state == "GREEN"

        if isinstance(self.controller, FixedTimeController):
            return self.controller.phase_state == "GREEN"

        return False

    def _approaches(self):
        return self.state.all_approaches()

    def _active_approaches(self, phase: Phase):
        return self.state.approaches_for_phase(phase)

    def _update_waiting_times(self, active_phase: Phase) -> None:
        for approach in self._approaches():
            if approach.queue > 0 and approach not in self._active_approaches(
                active_phase
            ):
                approach.waiting_since_green += 1.0
            elif approach.queue <= 0:
                approach.waiting_since_green = 0.0

    def step(self) -> None:
        phase = self._controller_phase()
        is_green = self._is_green()

                      
        for approach in self._approaches():
            arrivals = self.demand_model.arrivals(approach.name)
            approach.queue += arrivals
            self.metrics.total_arrivals += arrivals

                       
        served_this_second = 0.0

        if is_green:
            for approach in self._active_approaches(phase):
                before = approach.queue

                discharge = min(
                    approach.queue,
                    approach.saturation_flow,
                )

                approach.queue -= discharge
                served_this_second += discharge

                                                                          
                                                                     
                if before > 0 and discharge > 0:
                    self.metrics.total_stops += discharge

                                     
        current_queue = sum(
            approach.queue
            for approach in self._approaches()
        )

        self.metrics.total_waiting_vehicle_seconds += current_queue
        self.metrics.total_queue_vehicle_seconds += current_queue
        self.metrics.total_vehicles_served += served_this_second

        self.metrics.max_queue = max(
            self.metrics.max_queue,
            current_queue,
        )

        self._update_waiting_times(phase)

                                    
        self.state.timestamp += 1.0
        self.metrics.seconds += 1

                                                    
        if isinstance(self.controller, SignalController):
            if (
                self.controller.cycle_elapsed == 0
                and self.state.timestamp > 0
            ):
                self.controller.replan(self.state)

    def run(self, seconds: int) -> SimulationMetrics:
        if seconds <= 0:
            raise ValueError("seconds must be positive")

        for _ in range(seconds):
            self.step()

        return self.metrics

def clone_state(state: IntersectionState) -> IntersectionState:
    
    import copy

    return copy.deepcopy(state)
