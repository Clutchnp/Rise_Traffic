from __future__ import annotations

from dataclasses import dataclass

from .models import Phase
from .safety import validate_allocation
from .models import SignalConfig

@dataclass
class FixedTimePlan:
    north_south_green: int
    east_west_green: int

class FixedTimeController:
    

    def __init__(
        self,
        config: SignalConfig | None = None,
        north_south_ratio: float = 0.5,
    ) -> None:
        self.config = config or SignalConfig()

        if not 0.0 < north_south_ratio < 1.0:
            raise ValueError("north_south_ratio must be in (0, 1)")

        total = self.config.available_green

        ns = int(round(total * north_south_ratio))
        ew = total - ns

                                          
        ns = max(self.config.min_green, min(self.config.max_green, ns))
        ew = total - ns

        if ew < self.config.min_green:
            ew = self.config.min_green
            ns = total - ew

        if ew > self.config.max_green:
            ew = self.config.max_green
            ns = total - ew

        validate_allocation(
            {
                Phase.NORTH_SOUTH: ns,
                Phase.EAST_WEST: ew,
            },
            self.config,
        )

        self.plan = FixedTimePlan(
            north_south_green=ns,
            east_west_green=ew,
        )

        self.current_phase = Phase.NORTH_SOUTH
        self.phase_state = "GREEN"
        self.elapsed = 0

    def green_duration(self) -> int:
        if self.current_phase == Phase.NORTH_SOUTH:
            return self.plan.north_south_green
        return self.plan.east_west_green

    def tick(self) -> Phase:
        if self.phase_state == "GREEN":
            self.elapsed += 1

            if self.elapsed >= self.green_duration():
                self.phase_state = "YELLOW"
                self.elapsed = 0

            return self.current_phase

        if self.phase_state == "YELLOW":
            self.elapsed += 1

            if self.elapsed >= self.config.yellow_time:
                self.phase_state = "ALL_RED"
                self.elapsed = 0

            return self.current_phase

        if self.phase_state == "ALL_RED":
            self.elapsed += 1

            if self.elapsed >= self.config.all_red_time:
                self.current_phase = (
                    Phase.EAST_WEST
                    if self.current_phase == Phase.NORTH_SOUTH
                    else Phase.NORTH_SOUTH
                )
                self.phase_state = "GREEN"
                self.elapsed = 0

            return self.current_phase

        raise RuntimeError(f"Unknown state: {self.phase_state}")
