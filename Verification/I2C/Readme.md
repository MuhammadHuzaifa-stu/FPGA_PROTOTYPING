# I2C Master Controller — Functional Verification

Functional verification environment for the `chu_i2c_core` I2C master controller,
written in SystemVerilog. Covers single/burst read and write transactions, protocol
assertions, FSM state/transition coverage, and command/ACK cross coverage.

---

## Table of Contents

- [Project Structure](#project-structure)
- [Design Under Test](#design-under-test)
- [Verification Architecture](#verification-architecture)
- [Testbench Components](#testbench-components)
- [Test Plan](#test-plan)
- [Assertions](#assertions)
- [Coverage](#coverage)
- [Running Simulations](#running-simulations)
- [Coverage Reports](#coverage-reports)
- [Results](#results)
- [Known Limitations](#known-limitations)
- [References](#references)

---

## Project Structure

```
I2C/
├── include/
│   └── i2c_pkg.sv              # Package — parameters, typedefs, state enums
│
├── src/
│   ├── i2c_master.sv           # I2C master FSM (bit-level controller)
│   ├── chu_i2c_core.sv         # Top-level DUT (register interface + master)
│   └── i2c_slave_bfm.sv        # I2C slave Bus Functional Model (OpenCores)
│
├── verif/
│   ├── flist                   # File list for VCS compilation
│   ├── Makefile                # Build, elaborate, simulate, report targets
│   ├── tb_i2c_core.sv          # Top-level testbench — stimulus and checking
│   ├── i2c_assertions.sv       # SVA protocol assertions (separate module)
│   └── i2c_coverage.sv         # Functional covergroups (separate module)
│
└── README.md
```

---

## Design Under Test

**Module:** `chu_i2c_core`
**Source:** FPGA Prototyping by SystemVerilog Examples — Pong P. Chu

The DUT is an I2C master controller with a simple register interface:

| Address | Register | Description |
|---------|----------|-------------|
| `0x0` | Frequency (DVSR) | Sets I2C clock frequency — `dvsr = fsys / (4 × fi2c)` |
| `0x1` | Command / Data | `[7:0]` data, `[10:8]` command, `[0]` NACK bit for reads |

**Read-back (`rdata`):**

| Bits | Field | Description |
|------|-------|-------------|
| `[7:0]` | rx_data | Byte received from slave |
| `[8]` | rdy | Ready — handshake signal, command accepted when high |
| `[9]` | ack | ACK/NACK received from slave after last byte |

**Supported Commands:**

| Command | Encoding | Description |
|---------|----------|-------------|
| START | `3'b000` | Generate I2C START condition |
| WRITE | `3'b001` | Write one byte to bus |
| READ | `3'b010` | Read one byte from bus |
| STOP | `3'b011` | Generate I2C STOP condition |
| RESTART | `3'b100` | Generate repeated START |

**Handshake Protocol:** Valid/Ready — master holds `cs`, `wr_en`, and `wdata`
stable while `rdy` is low. Command is accepted on the clock edge where `rdy` is high.

---

## Verification Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    tb_i2c_core.sv                       │
│                                                         │
│  ┌─────────────┐    ┌──────────────┐   ┌─────────────┐  │
│  │  Stimulus   │    │  chu_i2c     │   │  i2c_slave  │  │
│  │  (tasks)    │--> │  _core (DUT) │-->│  _bfm       │  │
│  │             │    │              │   │  (OpenCores)│  │
│  └─────────────┘    └──────┬───────┘   └─────────────┘  │
│                            │ internal                   │
│  ┌─────────────┐           │ signals                    │
│  │  Checker    │<----------┘                            │
│  │  (display)  │                                        │
│  └─────────────┘                                        │
│                                                         │
│  ┌──────────────────┐   ┌──────────────────────────────┐│
│  │ i2c_assertions   │   │      i2c_coverage            ││
│  │ (separate module)│   │      (separate module)       ││
│  │                  │   │                              ││
│  │ • p_valid_start  │   │ • cp_freq  (freq bins)       ││
│  │ • p_sda_stable   │   │ • cp_cmd   (all commands)    ││
│  │ • p_data_on_low  │   │ • cp_ack   (ack/nack)        ││
│  │ • p_valid_stop   │   │ • cp_state (FSM states)      ││
│  │ • p_bus_free     │   │ • cp_trans (FSM transitions) ││
│  │                  │   │ • cp_read_nack               ││
│  └──────────────────┘   │ • cx_cmd_ack (cross)         ││
│                         └──────────────────────────────┘|
└─────────────────────────────────────────────────────────┘
```

**Key design decisions:**

- Assertions gated on `u_dut.u_i2c_master.CS` (DUT internal FSM state) — not
  on command input or derived flags — ensuring cycle-accurate disable conditions
  that match actual bus activity rather than when the command was issued.

- Slave BFM used as a black-box responder. Master verification checks whether the
  master correctly transferred what the slave had — not whether the slave stored
  the correct value. The two are independent verification concerns.

- Burst read data capture is intentionally offset by one transaction due to the
  master's pipelined register read-back behavior: `rdata` reflects the result of
  the previous command, not the current one.

---

## Testbench Components

### `tb_i2c_core.sv` — Top-Level Testbench

**Helper Tasks:**

| Task | Description |
|------|-------------|
| `wait_rdy()` | Blocks until `rdy` goes high; has a 100,000-cycle timeout guard |
| `set_freq(freq)` | Writes frequency divider register |
| `start()` | Issues START command |
| `restart()` | Issues RESTART command |
| `stop()` | Issues STOP command |
| `write_byte(data)` | Issues WRITE command with data byte |
| `read_byte(nack)` | Issues READ command; `nack=1` on last byte |

### `i2c_slave_bfm.sv` — I2C Slave Bus Functional Model

Based on the OpenCores Wishbone I2C slave model. Provides:

- 16-byte internal memory (`mem[0:15]`) — valid addresses `0x00`–`0x0F`
- ACK on valid address, NACK on address > `0x0F`
- Auto-increment of memory address pointer on burst transactions
- `specify` block with I2C standard timing checks (Standard 100kHz)
- Direct memory inspection from testbench for write verification

### `i2c_assertions.sv` — Protocol Assertions

Separate module instantiated from testbench. Receives `master_cs` as a port
(resolved from `u_dut.u_i2c_master.CS` at testbench level) — avoids hierarchical
reference inside the assertion module itself.

### `i2c_coverage.sv` — Functional Coverage

Separate module instantiated from testbench. Uses `bind`-compatible structure
but currently instantiated directly for XSIM/VCS portability.

---

## Test Plan

| Test | Transaction Type | Address | Data | Verification Method |
|------|-----------------|---------|------|---------------------|
| 1 | Single Byte Write | `0x05` | `0xAB` | Peek `u_i2c_slave_model.mem[0x05]` |
| 2 | Single Byte Read | `0x05` | — | Compare `rx_data` vs `mem[0x05]` |
| 3 | Burst Write (16B) | `0x00`–`0x0F` | Descending `0x0F`..`0x00` | Verify all `mem[i]` vs `data_wr_arr[i]` |
| 4 | Burst Read (16B) | `0x00`–`0x0F` | — | Compare `data_rd_arr[i]` vs `mem[i]` |

**Transaction flow for Read (Tests 2 and 4):**
```
START → [SLAVE_ADDR+W] → ACK → [MEM_ADDR] → ACK →
RESTART → [SLAVE_ADDR+R] → ACK → [DATA×N] → NACK → STOP
```

**Transaction flow for Write (Tests 1 and 3):**
```
START → [SLAVE_ADDR+W] → ACK → [MEM_ADDR] → ACK → [DATA×N] → ACK → STOP
```

---

## Assertions

All assertions are in `i2c_assertions.sv`, disabled during reset via
`disable iff (!arst_n)`, and gated on the DUT's internal FSM state for
cycle-accurate enable/disable windows.

| Assertion | Property | Trigger State |
|-----------|----------|---------------|
| `ap_start` | SDA fell → SCL must be high | `START1` |
| `ap_sda_stable` | SCL high → SDA must be stable | `DATA2`, `DATA3` |
| `ap_data_on_low` | SDA changed → SCL must be low | `DATA1`, `DATA4` |
| `ap_stop` | SDA rose → SCL must be high | `STOP2` |
| `ap_bus_free` | After STOP2→IDLE transition → SCL and SDA both high | `STOP2`→`IDLE` |

**Why FSM-state gating:**
SDA is intentionally changed while SCL is high during START and STOP conditions —
this is required by the I2C protocol. A naive `SDA stable while SCL high` assertion
would fire false failures on every START and STOP. Gating on the master's own FSM
state is the only cycle-accurate way to distinguish legitimate protocol transitions
from real data stability violations.

**Pass counters** are maintained per assertion and printed at `$finish` to confirm
each assertion's antecedent was actually evaluated during simulation. A count of 0
indicates the assertion was never triggered — a sign of a dead or misconfigured check.

---

## Coverage

Covergroup `i2c_cg` in `i2c_coverage.sv`, sampled on `posedge clk`.

### Coverpoints

**`cp_freq`** — I2C clock frequency exercised:
```
bins freq_100kHz = {250}       dvsr for 100kHz at 100MHz sysclk
bins freq_400kHz = {62, 63}    dvsr for 400kHz (rounded)
bins freq_1MHz   = {25}        dvsr for 1MHz
```

**`cp_cmd`** — All commands issued (sampled at valid handshake):
```
bins cmd_start, cmd_write, cmd_read, cmd_stop, cmd_restart
```

**`cp_read_nack`** — Both mid-burst ACK and last-byte NACK on read:
```
bins read_with_ack   wdata[0]=0, mid-burst
bins read_with_nack  wdata[0]=1, last byte
```

**`cp_ack`** — Both ACK and NACK received from slave:
```
bins got_ack, bins got_nack
```

**`cp_state`** — All FSM states visited:
```
IDLE, HOLD, START1, START2, DATA1, DATA2, DATA3, DATA4,
DATA_END, RESTART, STOP1, STOP2
```

**`cp_trans`** — All FSM state transition arcs taken:
```
14 individual arc bins covering all valid transitions
```

### Cross Coverage

**`cx_cmd_ack`** — Every command type exercised against both ACK and NACK outcomes.
Structurally impossible bins excluded:
```
ignore_bins: start×nack, stop×nack, restart×nack
(bus conditions — slave never NACKs these)
```

---

## Running Simulations

### Prerequisites

- Synopsys VCS with Verdi (for GUI) or `urg` (for text reports)
- GNU Make

### Quick Start

```bash
cd verif/

# Full flow: compile → elaborate → simulate → generate report
make all

# Individual steps
make compile     # vlogan — analyze all source files
make elab        # vcs    — elaborate and link
make sim         # run simulation, generate coverage database
make report      # urg    — generate HTML + text coverage report
```

### Open Coverage GUI

```bash
make coverage    # Verdi coverage browser (requires Verdi license)
```

### View HTML Report

```bash
make report
# Then open in browser:
xdg-open ./coverage_report/dashboard.html
```

### VCS Flags Reference

| Flag | Purpose |
|------|---------|
| `-full64` | 64-bit simulation |
| `-sverilog` | Enable SystemVerilog |
| `-debug_access+all` | Enable force/release and hierarchical probing |
| `-lca` | Enable latest VCS features |
| `-assert svaext` | Enable SVA extensions |
| `-kdb` | Generate Verdi-compatible knowledge database |
| `+error+100` | Stop after 100 errors |
| `-cm line+cond+fsm+branch+assert+tgl` | Enable all coverage types |
| `-assert enable` | Enable assertions at runtime |
| `-assert report` | Print assertion summary at `$finish` |

---

## Coverage Results

Results from running all 4 tests at 100kHz:

```
Overall______: 90.48%
cp_freq______: 33.33%   ← 400kHz and 1MHz tests pending
cp_cmd_______: 100.00%
cp_read_nack_: 100.00%
cp_ack_______: 100.00%
cp_state_____: 100.00%
cp_trans_____: 100.00%
cx_cmd_ack___: 100.00%
```

**Remaining gap:** `cp_freq` — requires adding Test 5 (400kHz) and Test 6 (1MHz).
Target is 100% overall after frequency tests are added.

---

## Known Limitations

- **XSIM:** SVA properties and `assert property` are not supported in Vivado XSIM.
  Use VCS, Questa, or ModelSim for assertion-enabled simulation.

- **Test isolation:** Tests 1–4 are sequential — Test 2 reads data written by
  Test 1, Test 4 reads data written by Test 3. If an earlier test fails, results
  of dependent tests should be interpreted carefully.

- **Negative tests:** Only happy-path transactions are currently tested. Planned
  additions include invalid memory address (expect NACK), wrong slave address
  (expect timeout), and back-to-back transactions without idle gap.

- **Slave BFM memory size:** The OpenCores slave BFM has 16 bytes of addressable
  memory (`0x00`–`0x0F`). Addresses above `0x0F` receive NACK on the memory
  address phase. Burst transactions wrap at address `0x0F`.

- **`rd_en` unused:** The DUT port `rd_en` is connected but not driven by the
  testbench. The register interface does not require it for the tested operations.

---

## References

- Pong P. Chu — *FPGA Prototyping by SystemVerilog Examples* (DUT source)
- OpenCores I2C Master/Slave — Richard Herveille (slave BFM source)
  https://github.com/olofk/i2c
- NXP Semiconductors — *I2C-bus specification and user manual* Rev 7.0
  https://www.nxp.com/docs/en/user-guide/UM10204.pdf
- IEEE Std 1800-2017 — SystemVerilog Language Reference Manual
- Synopsys VCS User Guide — Assertion-Based Verification