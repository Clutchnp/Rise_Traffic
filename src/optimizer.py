from __future__ import annotations

from typing import Dict, Tuple

from .models import (
    IntersectionState,
    Phase,
    PhaseAllocation,
    SignalConfig,
    SignalPlan,
)
from .safety import validate_allocation

class AdaptiveSignalOptimizer:
    

    def __init__(self, config: SignalConfig | None = None) -> None:
        self.config = config or SignalConfig()

    def predicted_demand(
        self,
        queue: float,
        arrival_rate: float,
        horizon: float,
    ) -> float:
        return max(0.0, queue + arrival_rate * horizon)

    def starvation_bonus(self, waiting_seconds: float) -> float:
        threshold = 60.0
        if waiting_seconds <= threshold:
            return 0.0

        excess = waiting_seconds - threshold
        return self.config.starvation_weight * (excess / threshold)

    def approach_pressure(
        self,
        queue: float,
        arrival_rate: float,
        saturation_flow: float,
        downstream_queue: float,
        waiting_since_green: float,
        speed_kph: float | None,
        emergency_vehicle_count: int,
        weight: float,
        horizon: float,
    ) -> Tuple[float, float]:
        demand = self.predicted_demand(
            queue=queue,
            arrival_rate=arrival_rate,
            horizon=horizon,
        )

        capacity_reference = max(saturation_flow, 1e-9)

        queue_component = (
            self.config.queue_weight * queue / capacity_reference
        )

        arrival_component = (
            self.config.arrival_weight
            * arrival_rate
            * horizon
            / capacity_reference
        )

        downstream_penalty = (
            self.config.downstream_weight
            * downstream_queue
            / capacity_reference
        )

        starvation = self.starvation_bonus(waiting_since_green)

        speed_penalty = 0.0
        if speed_kph is not None:
                                                                          
            speed_penalty = self.config.speed_weight * max(
                0.0,
                40.0 - speed_kph,
            ) / 40.0

        raw_pressure = (
            queue_component
            + arrival_component
            + starvation
            + speed_penalty
            - downstream_penalty
        )

        raw_pressure *= weight

        if emergency_vehicle_count > 0 and self.config.emergency_priority:
            raw_pressure *= self.config.emergency_pressure_multiplier

        return max(0.0, raw_pressure), demand

    def phase_pressure(
        self,
        state: IntersectionState,
        phase: Phase,
    ) -> Tuple[float, float]:
        approaches = state.approaches_for_phase(phase)

        total_pressure = 0.0
        total_demand = 0.0

        for approach in approaches:
            pressure, demand = self.approach_pressure(
                queue=approach.queue,
                arrival_rate=approach.arrival_rate,
                saturation_flow=approach.saturation_flow,
                downstream_queue=approach.downstream_queue,
                waiting_since_green=approach.waiting_since_green,
                speed_kph=approach.speed_kph,
                emergency_vehicle_count=approach.emergency_vehicle_count,
                weight=approach.weight,
                horizon=state.prediction_horizon,
            )

            total_pressure += pressure
            total_demand += demand

        return total_pressure, total_demand

    def _initial_allocation(self) -> Dict[Phase, int]:
        return {
            Phase.NORTH_SOUTH: self.config.min_green,
            Phase.EAST_WEST: self.config.min_green,
        }

    def _marginal_score(
        self,
        state: IntersectionState,
        phase: Phase,
        current_green: int,
        pressure: float,
    ) -> float:
        
        approaches = state.approaches_for_phase(phase)

        discharge = 0.0

        for approach in approaches:
            expected_queue = self.predicted_demand(
                approach.queue,
                approach.arrival_rate,
                state.prediction_horizon,
            )

            discharge += min(
                approach.saturation_flow,
                expected_queue,
            )

        fairness_penalty = current_green / self.config.max_green

        return (
            discharge * (1.0 + pressure)
            - fairness_penalty
        )

    def _allocate_by_marginal_value(
        self,
        state: IntersectionState,
        phase_data: Dict[Phase, Tuple[float, float]],
    ) -> Dict[Phase, int]:
        allocation = self._initial_allocation()

        remaining = (
            self.config.available_green
            - sum(allocation.values())
        )

        while remaining > 0:
            best_phase = None
            best_score = float("-inf")

            for phase in allocation:
                if allocation[phase] >= self.config.max_green:
                    continue

                pressure, _ = phase_data[phase]

                score = self._marginal_score(
                    state=state,
                    phase=phase,
                    current_green=allocation[phase],
                    pressure=pressure,
                )

                if score > best_score:
                    best_score = score
                    best_phase = phase

            if best_phase is None:
                raise RuntimeError(
                    "Unable to allocate remaining green time within bounds."
                )

            allocation[best_phase] += 1
            remaining -= 1

        return allocation

    def _apply_emergency_priority(
        self,
        state: IntersectionState,
        allocation: Dict[Phase, int],
        phase_data: Dict[Phase, Tuple[float, float]],
    ) -> Dict[Phase, int]:
        
        if not self.config.emergency_priority:
            return allocation

        emergency = state.emergency
        if emergency is None or not emergency.active:
            return allocation

        emergency_phase = None
        if emergency.approach in {"north", "south"}:
            emergency_phase = Phase.NORTH_SOUTH
        elif emergency.approach in {"east", "west"}:
            emergency_phase = Phase.EAST_WEST

        if emergency_phase is None:
            return allocation

        other = (
            Phase.EAST_WEST
            if emergency_phase == Phase.NORTH_SOUTH
            else Phase.NORTH_SOUTH
        )

        if allocation[emergency_phase] >= allocation[other]:
            return allocation

                                                                        
        while (
            allocation[emergency_phase] < allocation[other]
            and allocation[other] > self.config.min_green
        ):
            allocation[emergency_phase] += 1
            allocation[other] -= 1

        validate_allocation(allocation, self.config)
        return allocation

    def optimize(self, state: IntersectionState) -> SignalPlan:
        phases = [
            Phase.NORTH_SOUTH,
            Phase.EAST_WEST,
        ]

        phase_data: Dict[Phase, Tuple[float, float]] = {
            phase: self.phase_pressure(state, phase)
            for phase in phases
        }

        allocation = self._allocate_by_marginal_value(
            state,
            phase_data,
        )

        allocation = self._apply_emergency_priority(
            state,
            allocation,
            phase_data,
        )

        validate_allocation(
            allocation,
            self.config,
        )

        phase_allocations: Dict[Phase, PhaseAllocation] = {}

        objective = 0.0

        for phase in phases:
            pressure, demand = phase_data[phase]
            green = allocation[phase]

            estimated_served = 0.0
            for approach in state.approaches_for_phase(phase):
                predicted_queue = self.predicted_demand(
                    approach.queue,
                    approach.arrival_rate,
                    state.prediction_horizon,
                )

                potential_discharge = (
                    approach.saturation_flow * green
                )

                estimated_served += min(
                    predicted_queue,
                    potential_discharge,
                )

            phase_allocations[phase] = PhaseAllocation(
                phase=phase,
                green_time=green,
                pressure=pressure,
                demand=demand,
                estimated_served_vehicles=estimated_served,
                emergency=(
                    state.emergency is not None
                    and state.emergency.active
                    and (
                        (
                            phase == Phase.NORTH_SOUTH
                            and state.emergency.approach in {"north", "south"}
                        )
                        or (
                            phase == Phase.EAST_WEST
                            and state.emergency.approach in {"east", "west"}
                        )
                    )
                ),
            )

            objective += pressure * demand

        dominant_phase = max(
            phase_data,
            key=lambda phase: phase_data[phase][0],
        )

        explanation = (
            f"{dominant_phase.value} receives "
            f"{allocation[dominant_phase]} seconds of green because "
            f"its predicted pressure is highest. "
            f"Available green={self.config.available_green}s."
        )

        if state.emergency is not None and state.emergency.active:
            explanation += (
                f" Emergency priority active for "
                f"{state.emergency.approach}."
            )

        return SignalPlan(
            intersection_id=state.intersection_id,
            allocations=phase_allocations,
            cycle_length=self.config.cycle_length,
            yellow_time=self.config.yellow_time,
            all_red_time=self.config.all_red_time,
            objective_value=objective,
            generated_at=state.timestamp,
            explanation=explanation,
        )
