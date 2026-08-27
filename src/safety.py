from __future__ import annotations

from typing import Dict

from .models import Phase, SignalConfig

def validate_green_time(green_time: int, config: SignalConfig) -> int:
    return max(
        config.min_green,
        min(config.max_green, int(green_time)),
    )

def validate_allocation(
    allocations: Dict[Phase, int],
    config: SignalConfig,
) -> None:
    expected_phases = {Phase.NORTH_SOUTH, Phase.EAST_WEST}

    if set(allocations) != expected_phases:
        raise ValueError(
            f"Expected phases {expected_phases}; got {set(allocations)}"
        )

    total = sum(allocations.values())

    if total != config.available_green:
        raise ValueError(
            f"Invalid green total: expected {config.available_green}, got {total}"
        )

    for phase, green in allocations.items():
        if not config.min_green <= green <= config.max_green:
            raise ValueError(
                f"{phase.value} green={green} violates "
                f"[{config.min_green}, {config.max_green}]"
            )

def assert_safe_transition(
    current_phase: Phase,
    next_phase: Phase,
    phase_state: str,
) -> None:
    
    if current_phase != next_phase and phase_state == "GREEN":
        raise RuntimeError(
            "Unsafe phase transition attempted directly from GREEN. "
            "Use YELLOW then ALL_RED."
        )
