# kuyu-core

Core protocols and types for the Kuyu simulation environment.

## Overview

kuyu-core is the zero-dependency foundation of the Kuyu ecosystem. It defines the abstract protocols, value types, and simulation primitives that all other Kuyu packages build upon.

### Foundation Primitives

- **`WorldSimulator`** — Core simulation loop with configurable subsystem scheduling.
- **`PlantEngine`** / **`SensorField`** / **`ActuatorEngine`** — Abstract interfaces for physics, sensors, and actuators.
- **`CutInterface`** — Controller-under-test abstraction.

### Value Types

`DriveIntent`, `ActuatorValue`, `ChannelSample`, `WorldTime`, `TimeStep`, `SwapEvent`, `HFStressEvent`, and more.

## Package Structure

| Module | Dependencies | Description |
|--------|-------------|-------------|
| **KuyuCore** | None | Protocols, types, fusion architecture |

## Requirements

- Swift 6.2+
- macOS 26+

## Related Packages

```
KuyuCore (this package, zero dependencies)
  |
  +-- kuyu-physics      Analytical models & physical simulation
  +-- kuyu-scenarios    Evaluation scenarios & logging
  +-- kuyu-training     Backend-agnostic training contracts/runtime
  +-- kuyu-mlx          Manas/MLX backend implementation
  +-- kuyu-app          CLI/UI application adapters
  +-- Bounded           macOS document shell
  +-- manas             CNS-style robotic control system
```

Normative package responsibilities are defined in
`../KUYU_PACKAGE_ARCHITECTURE.md`.

## License

See repository for license information.
