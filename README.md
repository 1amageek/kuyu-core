# kuyu-core

Core protocols and types for the Kuyu simulation environment.

## Overview

kuyu-core is the zero-dependency foundation of the Kuyu ecosystem. It defines the abstract protocols, value types, and simulation primitives that all other Kuyu packages build upon.

### Fusion Architecture

The Fusion subsystem defines the boundary between analytical physics and learned world models:

- **`AnalyticalModel`** — Protocol for ODE-based physics: `x' = f(x, u)`. The boundary of `f` determines what physics computes vs. what the world model learns.
- **`WorldModelProtocol`** — Protocol for learned corrections and extensions on top of physics predictions. Physics predictions are never modified.
- **`FusedEnvironment<A, W, S>`** — Composes an AnalyticalModel, WorldModel, and SensorField into a single simulation step.
- **`FusedState<S>`** — Holds physics prediction (unchanged) + residual corrections + latent extensions.
- **`IdentityWorldModel`** — No-op world model (residual=0, extensions=empty) for backward compatibility.

### Simulation Primitives

- **`WorldSimulator`** — Core simulation loop with configurable subsystem scheduling.
- **`PlantEngine`** / **`SensorField`** / **`ActuatorEngine`** — Abstract interfaces for physics, sensors, and actuators.
- **`CutInterface`** — Controller-under-test abstraction.

### Value Types

`DriveIntent`, `ActuatorValue`, `ChannelSample`, `WorldTime`, `TimeStep`, `SwapEvent`, `HFStressEvent`, and more.

## Package Structure

| Module | Dependencies | Description |
|--------|-------------|-------------|
| **KuyuCore** | None | Protocols, types, fusion architecture |
| **KuyuRuntime** | KuyuCore, swift-log, swift-configuration | Logging and configuration |

## Requirements

- Swift 6.2+
- macOS 26+

## Related Packages

```
KuyuCore (this package, zero dependencies)
  |
  +-- kuyu-physics      Analytical models & physical simulation
  +-- kuyu-world-model  DreamerV3-based learned world model (MLX)
  +-- kuyu-scenarios    Evaluation scenarios & logging
  +-- kuyu-training     Training data collection & pipeline
  +-- kuyu              Application layer (UI, CLI, MLX bridge)
  +-- manas             CNS-style robotic control system
```

## License

See repository for license information.
