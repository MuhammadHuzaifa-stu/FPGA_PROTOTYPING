# 🧩 MicroBlaze Modular SOC Firmware
### Hardware-Software Co-Design for the Artix-7 PA35T-EDU

This repository contains the firmware for a MicroBlaze-based System on Chip (SoC), organized using a layered **Hardware Abstraction Layer (HAL)** approach. This structure separates high-level application logic from low-level register manipulation.

---

## 🏗️ System Architecture

The software is organized into a hierarchical tree where each layer has a specific responsibility:

* **Application Layer (`main.c`)**: High-level logic and system coordination.
* **Core Layer (`***_core.h`)**: Driver logic for specific hardware IPs (Timer, UART, GPIO).
* **Initialization Layer (`chu_init.h`)**: Centralized system startup and core linking.
* **Hardware Mapping (`chu_io_map.h`)**: Definition of physical AXI addresses (Slots).
* **Abstraction Layer (`chu_io_rw.h`)**: Macro-based wrappers for memory-mapped I/O.

---

## 📂 Project Directory Structure

```text
src/
├── main.c                 # Top-level application logic
├── chu_init.h             # System initialization & core registry
│   ├── timer_core.h       # AXI Timer drivers (Slot 0)
│   └── uart_core.h        # AXI UART Lite drivers (Slot 1)
├── gpio_core.h            # AXI GPIO drivers (Switches/LEDs)
├── chu_io_rw.h            # Low-level Read/Write macros
│   ├── chu_io_map.h       # Physical Address & Slot definitions
│   └── <inttypes.h>       # Standard integer types
└── ***_core.h             # Placeholder for future IPs (PWM, I2C, etc.)