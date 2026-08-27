from __future__ import annotations

from dataclasses import dataclass

from .models import IntersectionState, Phase, SignalPlan
from .optimizer import AdaptiveSignalOptimizer
from .safety import assert_safe_transition

@dataclass
class ControllerOutput:
    phase: Phase
    state: str
    remaining_seconds: int
    plan: SignalPlan | None

class SignalController:
    

    def __init__(
        self,
        optimizer: AdaptiveSignalOptimizer,
    ) -> None:
        self.optimizer = optimizer

        self.active_plan: SignalPlan | None = None
        self.current_phase = Phase.NORTH_SOUTH
        self.phase_state = "GREEN"
        self.elapsed = 0
        self.cycle_elapsed = 0

    def initialize(self, state: IntersectionState) -> SignalPlan:
        self.active_plan = self.optimizer.optimize(state)
        self.current_phase = state.current_phase
        self.phase_state = "GREEN"
        self.elapsed = 0
        self.cycle_elapsed = 0
        return self.active_plan

    def replan(
        self,
        state: IntersectionState,
    ) -> SignalPlan:
        
        plan = self.optimizer.optimize(state)

        if self.phase_state == "GREEN" and self.active_plan is not None:
                                                                           
                                                               
            self.active_plan = plan
        else:
            self.active_plan = plan

        return plan

    def _green_duration(self) -> int:
        if self.active_plan is None:
            raise RuntimeError("Controller is not initialized.")

        return self.active_plan.green_for(self.current_phase)

    def _next_phase(self) -> Phase:
        return (
            Phase.EAST_WEST
            if self.current_phase == Phase.NORTH_SOUTH
            else Phase.NORTH_SOUTH
        )

    def tick(self) -> ControllerOutput:
        if self.active_plan is None:
            raise RuntimeError("Controller is not initialized.")

               
        if self.phase_state == "GREEN":
            duration = self._green_duration()
            remaining = max(0, duration - self.elapsed - 1)

            self.elapsed += 1
            self.cycle_elapsed += 1

            if self.elapsed >= duration:
                self.phase_state = "YELLOW"
                self.elapsed = 0

            return ControllerOutput(
                phase=self.current_phase,
                state="GREEN",
                remaining_seconds=remaining,
                plan=self.active_plan,
            )

                
        if self.phase_state == "YELLOW":
            remaining = max(
                0,
                self.optimizer.config.yellow_time
                - self.elapsed
                - 1,
            )

            self.elapsed += 1
            self.cycle_elapsed += 1

            if self.elapsed >= self.optimizer.config.yellow_time:
                self.phase_state = "ALL_RED"
                self.elapsed = 0

            return ControllerOutput(
                phase=self.current_phase,
                state="YELLOW",
                remaining_seconds=remaining,
                plan=self.active_plan,
            )

                 
        if self.phase_state == "ALL_RED":
            next_phase = self._next_phase()

            assert_safe_transition(
                current_phase=self.current_phase,
                next_phase=next_phase,
                phase_state="ALL_RED",
            )

            remaining = max(
                0,
                self.optimizer.config.all_red_time
                - self.elapsed
                - 1,
            )

            self.elapsed += 1
            self.cycle_elapsed += 1

            if self.elapsed >= self.optimizer.config.all_red_time:
                self.current_phase = next_phase
                self.phase_state = "GREEN"
                self.elapsed = 0

                if self.cycle_elapsed >= self.active_plan.cycle_length:
                    self.cycle_elapsed = 0

            return ControllerOutput(
                phase=self.current_phase,
                state="ALL_RED",
                remaining_seconds=remaining,
                plan=self.active_plan,
            )

        raise RuntimeError(
            f"Unknown controller state {self.phase_state}"
        )
