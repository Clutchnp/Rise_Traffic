from __future__ import annotations

from dataclasses import asdict
from typing import Dict, Type

from .models import IntersectionState, SignalConfig
from .simulator import (
    IntersectionSimulator,
    SimulationMetrics,
    clone_state,
)
from .optimizer import AdaptiveSignalOptimizer
from .controller import SignalController
from .fixed_time import FixedTimeController

def summarize_metrics(metrics: SimulationMetrics) -> dict:
    return {
        "seconds": metrics.seconds,
        "total_waiting_vehicle_seconds": round(
            metrics.total_waiting_vehicle_seconds, 3
        ),
        "average_waiting_per_vehicle": round(
            metrics.average_waiting_per_vehicle, 3
        ),
        "average_queue": round(
            metrics.average_queue, 3
        ),
        "maximum_queue": round(
            metrics.max_queue, 3
        ),
        "total_arrivals": round(
            metrics.total_arrivals, 3
        ),
        "vehicles_served": round(
            metrics.total_vehicles_served, 3
        ),
        "throughput_vehicles_per_second": round(
            metrics.throughput, 5
        ),
        "total_stops": round(
            metrics.total_stops, 3
        ),
    }

def percent_improvement(
    baseline: float,
    adaptive: float,
) -> float:
    if baseline == 0:
        return 0.0
    return (baseline - adaptive) / baseline * 100.0

def compare_controllers(
    initial_state: IntersectionState,
    seconds: int = 3600,
    config: SignalConfig | None = None,
) -> dict:
    
    config = config or SignalConfig()

    fixed_state = clone_state(initial_state)
    adaptive_state = clone_state(initial_state)

    fixed = FixedTimeController(
        config=config,
        north_south_ratio=0.5,
    )

    adaptive_optimizer = AdaptiveSignalOptimizer(config=config)
    adaptive = SignalController(
        optimizer=adaptive_optimizer,
    )

    fixed_sim = IntersectionSimulator(
        state=fixed_state,
        controller=fixed,
    )

    adaptive_sim = IntersectionSimulator(
        state=adaptive_state,
        controller=adaptive,
    )

    fixed_metrics = fixed_sim.run(seconds)
    adaptive_metrics = adaptive_sim.run(seconds)

    fixed_summary = summarize_metrics(fixed_metrics)
    adaptive_summary = summarize_metrics(adaptive_metrics)

    return {
        "fixed_time": fixed_summary,
        "adaptive": adaptive_summary,
        "improvement": {
            "waiting_time_percent": percent_improvement(
                fixed_metrics.total_waiting_vehicle_seconds,
                adaptive_metrics.total_waiting_vehicle_seconds,
            ),
            "average_queue_percent": percent_improvement(
                fixed_metrics.average_queue,
                adaptive_metrics.average_queue,
            ),
            "max_queue_percent": percent_improvement(
                fixed_metrics.max_queue,
                adaptive_metrics.max_queue,
            ),
                                                                         
            "throughput_percent": (
                0.0
                if fixed_metrics.throughput == 0
                else (
                    adaptive_metrics.throughput
                    - fixed_metrics.throughput
                )
                / fixed_metrics.throughput
                * 100.0
            ),
            "stops_percent": percent_improvement(
                fixed_metrics.total_stops,
                adaptive_metrics.total_stops,
            ),
        },
    }
