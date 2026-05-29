# FPGA HDMI Display — VGA Timing over HDMI
**Platform:** Puzhi PA35T-EDU (AMD Artix-7 XC7A35T-2FGG484I)  
**Reference:** *FPGA Prototyping by SystemVerilog Examples* — Pong P. Chu (MicroBlaze MCS SoC Edition)  
**Resolution:** 640 × 480 @ 60 Hz  
**Interface:** HDMI (DVI-compatible, no audio)

---

## Table of Contents

1. [What This Project Does](#what-this-project-does)
2. [Why HDMI Instead of VGA](#why-hdmi-instead-of-vga)
3. [Architecture Overview](#architecture-overview)
4. [The Display Pipeline — Layer by Layer](#the-display-pipeline--layer-by-layer)
   - [Layer 1: VGA Timing (display_pkg + vga_sync_demo)](#layer-1-vga-timing)
   - [Layer 2: Pixel Content (bar_demo + rgb2gray + vga_demo)](#layer-2-pixel-content)
   - [Layer 3: TMDS Encoding (tmds_encoder_dvi)](#layer-3-tmds-encoding)
   - [Layer 4: Serialization (OSERDESE2 + OBUFDS)](#layer-4-serialization)
   - [Layer 5: Clock Generation (clk_wiz MMCM)](#layer-5-clock-generation)
5. [Why Questions — Design Decisions Explained](#why-questions--design-decisions-explained)
6. [File Structure](#file-structure)
7. [Key Parameters](#key-parameters)
8. [How to Reproduce](#how-to-reproduce)
9. [Pin Constraints (XDC)](#pin-constraints-xdc)
10. [What You See on Screen](#what-you-see-on-screen)
11. [Known Limitations and Next Steps](#known-limitations-and-next-steps)

---

## What This Project Does

This project drives a modern HDMI monitor from an FPGA by generating:

- Standard **VGA 640×480 @ 60 Hz timing** (horizontal and vertical sync, pixel counters)
- A **color bar test pattern** with three zones: grayscale ramp, primary colors, and smooth rainbow transitions
- Optional **grayscale conversion** controlled by onboard DIP switches
- All wrapped in a **TMDS-encoded HDMI output** using only FPGA fabric and built-in primitives — no external video chips

The key insight this project demonstrates: **HDMI is just a wire**. The HDMI connector carries no intelligence. All encoding, timing, and serialization logic must live in your RTL. This project builds that logic from scratch, layer by layer.

---

## Why HDMI Instead of VGA

Chu's book targets the Basys3 or Nexys4 boards, which include a **VGA DAC** — a small resistor ladder that converts FPGA digital signals to analog voltages. The Puzhi PA35T-EDU board has no VGA connector and no DAC. It has an **HDMI connector**.

| Aspect | VGA (Basys3) | HDMI (Puzhi PA35T-EDU) |
|---|---|---|
| Signal type | Analog voltage (0–0.7V) | Digital differential (TMDS) |
| Sync signals | Separate wires | Embedded in data stream during blanking |
| Color depth | Limited by DAC resistors | Full 24-bit per pixel |
| External chip needed | Resistor DAC on board | None — FPGA does everything |
| Timing standard | VGA (1987 VESA) | DVI/HDMI (compatible with VGA timing) |

**The good news:** The VGA timing standard (640×480 @ 60 Hz, 800×525 total pixels, 25.175 MHz pixel clock) is fully preserved inside HDMI/DVI. Modern HDMI monitors still accept it. Chu's sync generator code is reused **unchanged**. Only the output layer changes.

---

## Architecture Overview

```
                    ┌─────────────────────────────────────────────────┐
                    │              hdmi_top (top module)              │
                    │                                                 │
  200 MHz ──────────┤── clk_wiz ──► 25 MHz ──► vga_demo               │
  diff clock        │          └──► 125 MHz       │                   │
                    │                             │ hsync,vsync,rgb   │
  sw[13:0] ─────────┤────────────────────────────►                    │
  (DIP switches)    │                             │                   │
                    │                  ┌──────────▼──────────────┐    │
                    │                  │  tmds_encoder_dvi × 3   │    │
                    │                  │  (Blue, Green, Red)     │    │
                    │                  └─────────┬───────────────┘    │
                    │                            │ 10-bit TMDS words  │
                    │                  ┌─────────▼──────────────┐     │
                    │                  │  tmds_serializer × 4   │     │
                    │                  │  (3 data + 1 clock)    │     │
                    │                  │  OSERDESE2 + OBUFDS    │     │
                    │                  └─────────┬──────────────┘     │
                    └────────────────────────────┼────────────────────┘
                                                 │
                                    ┌────────────▼────────────┐
                                    │     HDMI Connector      │
                                    │  (4 differential pairs) │
                                    └─────────────────────────┘
```

---

## The Display Pipeline — Layer by Layer

### Layer 1: VGA Timing

**Files:** `display_pkg.sv`, `vga_sync_demo.sv`, `frame_counter.sv`

Every display — VGA, HDMI, LCD — works on the same principle: a pixel counter scanning from left to right, top to bottom, like reading a page. The counter runs through both the **visible area** and the surrounding **blanking regions**.

```
Total horizontal pixels: 800 (not 640)
─────────────────────────────────────────────────────────
 Active (640)  │ Front  │   Sync   │     Back Porch     │
               │ Porch  │  Pulse   │                    │
               │ (16)   │  (96)    │       (48)         │
─────────────────────────────────────────────────────────
0             640      656        752                  800
                        ↑          ↑
                    hsync goes  hsync returns
                      LOW         HIGH

Total vertical lines: 525 (not 480)
───────────────────────────────────────
 Active (480) │ Front │ Sync  │ Back  │
              | Porch | pulse | Porch |
              | (10)  |  (2)  | (33)  |
───────────────────────────────────────
0            480     490     492     525
                      ↑       ↑
                    vsync   vsync 
                  goes LOW  returns HIGH
```

`vga_sync_demo` maintains two counters (`hc` for horizontal, `vc` for vertical) via `frame_counter`. The sync signals are asserted when the counters fall inside the sync pulse window. The `video_on` flag is HIGH only when both counters are inside the active region (hc < 640, vc < 480). During blanking, RGB is forced to zero.

**The 100 MHz → 25 MHz division:** The board clock runs at 200 MHz. The pixel clock for 640×480@60Hz is 25.175 MHz (approximated as 25 MHz). `vga_sync_demo` receives the 25 MHz clock directly from the MMCM and advances one pixel per clock cycle.

---

### Layer 2: Pixel Content

**Files:** `bar_demo.sv`, `rgb2gray.sv`, `vga_demo.sv`

Pixel colors are **computed from coordinates** — no frame buffer or memory is needed. Given the current `(x, y)` pixel position, combinational logic instantly outputs an RGB value. This is Chu's "scanline architecture."

```
bar_demo color zones:

y < 128:  Grayscale ramp
          r = g = b = x[8:5]  (brightness = horizontal position)

128 ≤ y < 256: 8 primary colors at half intensity
          r = x[8]×2, g = x[7]×2, b = x[6]×2

y ≥ 256:  Rainbow transitions across 8 segments
          Smooth hue rotation using up/down ramps
```

`rgb2gray` applies the ITU-R BT.601 luminance formula:  
`Y = 0.299×R + 0.587×G + 0.114×B`  
implemented with fixed-point coefficients `{0x35, 0xB8, 0x12}`.

`vga_demo` muxes between color and grayscale based on DIP switch `sw[0]`, and between the bar pattern and a solid background color (from `sw[13:2]`) based on `sw[1]`.

**Color depth:** CD = 12 means 4 bits per channel (R, G, B). This gives 4096 distinct colors. Sufficient for demonstrating the pipeline; expanding to CD = 24 requires only changing the package parameter.

---

### Layer 3: TMDS Encoding

**File:** `tmds_encoder_dvi.sv` (adapted from Project F / Will Green)

TMDS (Transition Minimized Differential Signaling) is the encoding scheme that DVI and HDMI use to serialize pixel data. It solves two problems that raw binary signaling over long cables cannot:

**Problem 1 — Too many transitions:** A wire that toggles every cycle radiates EMI and is hard to clock-recover at the receiver. TMDS uses XOR/XNOR encoding to minimize the number of 0→1 and 1→0 transitions per 8-bit symbol.

**Problem 2 — DC bias:** A long string of 1s would shift the average voltage, causing coupling capacitors in the receiver to charge up and distort the signal. TMDS tracks a running disparity counter and inverts the encoded word when necessary to keep the average at zero.

**The encoding process for each 8-bit color value:**

```
Step 1: Count ones in input data
  → More ones than zeros? Use XNOR chain (fewer transitions)
  → Otherwise? Use XOR chain

Step 2: Produce 9-bit q_m word
  q_m[0]   = data[0]
  q_m[i+1] = q_m[i] XOR/XNOR data[i+1]
  q_m[8]   = encoding type (0=XNOR, 1=XOR)

Step 3: DC balance using running disparity
  → Track count of 1s minus 0s sent so far (bias register)
  → If bias drifts positive and word has more 1s: invert q_m[7:0]
  → Result: 10-bit TMDS word

Step 4: During blanking (de=0): send control tokens
  → Four fixed 10-bit patterns encode {vsync, hsync}
  → These patterns are chosen to have maximum transitions
     (7 transitions) so the receiver can re-lock its PLL
```

**Why three encoders?** HDMI carries three data channels: Blue, Green, Red (plus a clock channel). Each is encoded independently and serialized on its own differential pair. The **Blue channel is special** — it carries `{vsync, hsync}` in the `ctrl_in` port, which the encoder embeds into the blanking-period control tokens. Green and Red channels pass `2'b00` as control input since they carry no sync information.

**4-bit to 8-bit expansion:** The design uses CD=12 (4 bits per channel) but TMDS requires 8-bit input. Bit replication is used:

```systemverilog
// Example for blue channel (bits [3:0]):
data_in = {rgb[3:0], rgb[3:0]}  // e.g., 4'b1111 → 8'b11111111 = 255

// Why not zero-padding {rgb[3:0], 4'b0}?
// That maps maximum 4'b1111 → 8'b11110000 = 240, not 255.
// White would never be fully white.

// Why not sign extension?
// Color values are unsigned. Sign-extending 4'b1000
// gives 8'b11111000 = 248 — completely wrong.

// Bit replication maps:  value_8 = value_4 × 17
// 0x0 × 17 = 0   ✓ black is black
// 0xF × 17 = 255 ✓ white is white
// All 16 levels distribute evenly across 0–255
```

---

### Layer 4: Serialization

**File:** `tmds_serializer.sv` (instantiated in `hdmi_top.sv`)

The TMDS encoder produces a 10-bit parallel word every pixel clock cycle (25 MHz). HDMI requires this to be sent as a 1-bit serial stream at 250 Mbps (10 × 25 MHz). The Xilinx `OSERDESE2` primitive performs this 10:1 serialization inside dedicated I/O circuitry — not in the programmable fabric.

**Why OSERDESE2 instead of a shift register in fabric?**

A shift register clocked at 250 MHz in fabric would consume routing resources and is difficult to meet timing for. `OSERDESE2` is a hard-coded I/O block placed physically next to the output pins. It is guaranteed by Xilinx to meet timing at its rated speed.

**Why Master + Slave pair?**

A single `OSERDESE2` has only 8 data inputs (D1–D8). TMDS requires 10 bits. Xilinx's solution: chain two `OSERDESE2` blocks:

```
SLAVE  (bits [9:8])                MASTER (bits [7:0])
┌───────────────┐                 ┌────────────────────┐
│ D3 ← bit[8]   │                 │ D1 ← bit[0]        │
│ D4 ← bit[9]   │                 │ D2 ← bit[1]        │
│               │  SHIFTOUT1 ──►  │ D3 ← bit[2]        │
│               │  SHIFTOUT2 ──►  │ ...                │
│               │  (shift chain)  │ D8 ← bit[7]        │
│               │                 │                    │
│ OQ: unused    │                 │ OQ ──► serial data │
└───────────────┘                 └────────────────────┘
```

The SLAVE handles bits 8 and 9, shifting them into the MASTER via the SHIFTOUT/SHIFTIN chain. The MASTER combines all 10 bits and drives the `OQ` output pin.

**Why DDR mode (5x clock, not 10x)?**

Two approaches achieve 10:1 serialization:
- SDR at 10× pixel clock = 250 MHz in fabric routing
- **DDR at 5× pixel clock = 125 MHz** ← used here

DDR mode shifts one bit on the rising edge and one on the falling edge of the 125 MHz clock, effectively doubling throughput. 125 MHz is significantly easier to route on Artix-7 than 250 MHz and stays well within the OSERDESE2's 1066 Mbps limit.

**OBUFDS:** After serialization, `OBUFDS` drives the signal differentially — two wires carrying `signal` and `~signal`. Differential signaling rejects common-mode noise (power supply fluctuations, EMI), enabling reliable signal integrity over HDMI cables.

**The clock channel:** HDMI requires a fourth differential pair carrying the pixel clock itself (no data). A fixed 10-bit pattern `10'b0000011111` — which looks like a clock waveform after serialization — is sent on this channel. The monitor uses it for clock recovery and to align its TMDS decoder.

---

### Layer 5: Clock Generation

**IP:** Vivado Clocking Wizard (MMCM)

```
Board input: 200 MHz differential
                    │
            ┌───────▼────────┐
            │  MMCM / PLL    │
            │  VCO = 1000MHz │  (200 × 5)
            └───────┬────────┘
                    │
         ┌──────────┴──────────┐
         │                     │
    ÷ 40 │                ÷ 8  │
         ▼                     ▼
      25 MHz                125 MHz
   (clk_pixel)            (clk_5x)
   feeds vga_sync       feeds OSERDESE2
   feeds tmds_encoder
```

**Why not use the board clock directly?** The OSERDESE2 requires the CLKDIV and CLK inputs to be phase-aligned — meaning they must come from the same MMCM. Generating both 25 MHz and 125 MHz from the same VCO guarantees their phase relationship and eliminates clock domain crossing issues between the TMDS encoder and serializer.

**Why 1000 MHz VCO?** Artix-7 MMCMs require their internal VCO to run between 600 MHz and 1440 MHz. With 200 MHz input and MULT=5: VCO = 1000 MHz, which is comfortably inside this window.

---

## Why Questions — Design Decisions Explained

### Why does VGA timing work for HDMI?

The VGA timing standard (640×480 @ 60 Hz) was defined in 1987. When DVI was designed in 1999 and HDMI in 2002, backward compatibility was a requirement. Every HDMI monitor manufactured since then contains a timing controller that still accepts VGA-era resolutions and refresh rates. The monitor doesn't care about the wire protocol — it cares about the pixel timing. Since HDMI embeds the same hsync/vsync information that VGA had (just encoded differently into TMDS control tokens), any monitor that accepts HDMI also accepts 640×480 @ 60 Hz.

### Why is there no frame buffer?

A frame buffer stores one complete image in memory and reads it out pixel by pixel at the display rate. It is required when the image being displayed is computed slowly (a CPU rendering a scene) or needs to persist between frames (video playback).

In Chu's "scanline architecture," the color of each pixel is computed **combinationally in one clock cycle** from only its (x, y) coordinates. The color bar pattern is a pure mathematical function: given x and y, output RGB immediately. No storage is needed because the result is always available instantly. This is how all classic FPGA demos work — the FPGA computes every pixel from scratch 60 times per second.

A frame buffer would be required for: displaying images stored in memory, video from a camera, anything a CPU draws, or any content that cannot be described as a simple function of pixel coordinates.

### Why is HDMI "just a wire"?

An HDMI connector is a physical and electrical standard — it defines pin positions, impedances, and voltage levels. It contains no processing logic whatsoever. A GPU contains a dedicated HDMI transmitter block in its silicon that performs TMDS encoding and serialization. On an FPGA, there is no such dedicated block (except in some high-end devices). You must implement the encoding and serialization yourself in RTL and use the I/O primitives (OSERDESE2, OBUFDS) to drive the physical pins. The HDMI connector is just the socket at the end of this chain.

### Why does the Blue channel carry sync signals?

This is defined in the DVI specification (Section 3.3.1), which HDMI inherited. During blanking periods (when `de` is LOW and no pixel data is transmitted), the three data channels carry 2-bit control tokens instead of color data. The Blue channel's control token encodes `{vsync, hsync}`. Green and Red channels send `2'b00`. This assignment is arbitrary but standardized — every HDMI receiver expects sync on the Blue channel.

### Why use a SystemVerilog package for timing parameters?

```systemverilog
package display_pkg;
    localparam HD = 640;
    localparam HF = 16;
    ...
endpackage
```

All five modules that deal with display timing need to agree on the same numbers. A package imported with `import display_pkg::*` guarantees consistency — change the resolution in one place and every module updates automatically. Without a package, copying constants into each module file risks typos and inconsistencies.

### Why does the counter run to 800 horizontally, not 640?

The visible area is 640 pixels, but the counter runs from 0 to 799 (800 total). The extra 160 pixels are the blanking interval:

```
0 → 639:   Active region — draw pixels
640 → 655: Front porch  — brief gap before sync
656 → 751: Sync pulse   — hsync goes LOW (monitor locks here)
752 → 799: Back porch   — recovery time before next line
```

The back porch exists because CRT electron guns needed physical time to fly back from the right edge of the screen to the left edge and stabilize before the next line began. Modern LCDs preserve this timing for backward compatibility with the standard.

### Why 4 bits per color channel instead of 8?

Chu's book uses CD=12 (4+4+4) because the Basys3's VGA DAC is a simple resistor network with only 4 bits per channel. This project preserves CD=12 to remain faithful to the book's exercises. The TMDS encoder requires 8-bit input, so each 4-bit value is expanded by bit replication ({nibble, nibble}), which maps 0→0 and 15→255 correctly. Changing CD to 24 in `display_pkg.sv` would enable full 8-bit color depth throughout the design.

### Why use a dedicated OSERDESE2 primitive instead of a shift register?

The OSERDESE2 is a hard silicon block located physically adjacent to the I/O pads. It can serialize data at up to 1066 Mbps — far exceeding what routed fabric could achieve reliably. A shift register implemented in LUTs and flip-flops running at 250 MHz would require careful placement, manual timing constraints, and would consume significant routing resources. The OSERDESE2 handles all of this for free and is guaranteed by Xilinx to meet timing.

### Why does the Artix-7 -2 speed grade matter?

Artix-7 devices come in three speed grades: -1 (slowest), -2 (standard), -3 (fastest). The Puzhi board uses **-2FGG484I** (industrial temperature, -2 speed). The OSERDESE2 on -2 devices supports up to 1066 Mbps serial output. Our 125 MHz × 2 (DDR) = 250 Mbps is less than 25% of this limit, leaving substantial margin for timing closure.

---

## File Structure

```
HDMI_Display/
│
├── display_pkg.sv          # VGA timing constants and color depth parameter
│                           # Single source of truth for all timing values
│
├── frame_counter.sv        # Horizontal/vertical pixel counter
│                           # Counts to HT=800 and VT=525
│
├── vga_sync_demo.sv        # Sync signal generator
│                           # Produces hsync, vsync, video_on from counters
│
├── bar_demo.sv             # Color bar pattern generator
│                           # Pure combinational: f(x,y) → RGB
│
├── rgb2gray.sv             # Luminance conversion (BT.601 coefficients)
│                           # Y = 0.299R + 0.587G + 0.114B
│
├── vga_demo.sv             # VGA subsystem integrator
│                           # Muxes bar/background and color/gray
│
├── tmds_encoder_dvi.sv     # TMDS encoding (Project F / Will Green)
│                           # 8-bit color → 10-bit DC-balanced TMDS word
│
├── tmds_serializer.sv      # 10:1 serializer + differential output
│                           # Uses OSERDESE2 (Master+Slave) + OBUFDS
│
├── hdmi_top.sv             # Top-level module
│                           # Integrates all layers, drives HDMI pins
│
└── constraints.xdc         # Pin assignments for Puzhi PA35T-EDU
                            # Clock definitions for timing analysis
```

---

## Key Parameters

| Parameter | Value | Why |
|---|---|---|
| CD | 12 | 4 bits × 3 channels; matches Chu's book |
| HD | 640 | Visible pixels per line |
| HT | 800 | Total pixels per line (including blanking) |
| VD | 480 | Visible lines per frame |
| VT | 525 | Total lines per frame (including blanking) |
| Pixel clock | 25 MHz | 800 × 525 × 60 Hz = 25.2 MHz ≈ 25 MHz |
| Serial clock | 125 MHz | 5× pixel clock, DDR gives 10× effective |
| TMDS word width | 10 bits | 8b/10b encoding (DVI specification) |
| OSERDESE2 mode | DDR, width=10 | Requires Master+Slave pair |
| MMCM VCO | 1000 MHz | 200 × 5; within Artix-7 600–1440 MHz range |

---

## How to Reproduce

### Prerequisites

- Vivado 2020.1 or later (any edition including WebPACK)
- Puzhi PA35T-EDU board or compatible Artix-7 board with HDMI

### Step 1 — Create Vivado Project

```
File → Project → New
  Part: XC7A35T-2FGG484I
  Add all .sv files listed in File Structure
```

### Step 2 — Generate Clocking Wizard IP

```
IP Catalog → Clocking Wizard
  Component Name: clk_wiz_0

  Input Clocks tab:
    Primary: Differential clock, 200 MHz

  Output Clocks tab:
    clk_out1: 25 MHz   (rename to clk_25MHz)
    clk_out2: 125 MHz  (rename to clk_5x)

  Locked Output: enabled
  Reset Type: Active Low
```

### Step 3 — Add Constraints

Create `constraints.xdc` with the pin assignments from the section below.

### Step 4 — Build

```
Run Synthesis → Run Implementation → Generate Bitstream
Program Device
```

---

## Pin Constraints (XDC)

```tcl
# System clock — 200 MHz differential (from Puzhi board schematic)
set_property PACKAGE_PIN R4 [get_ports sys_clk_p]
set_property PACKAGE_PIN T4 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_n]

# System reset — active LOW pushbutton (NRST)
set_property PACKAGE_PIN R14 [get_ports sys_rstn]
set_property IOSTANDARD LVCMOS33 [get_ports sys_rstn]

# DIP switches SW1–SW14 (used for RGB background and display mode)
# Refer to Puzhi manual Part 3.15 for full 16-bit switch mapping

# HDMI output — from Puzhi PA35T-EDU manual Part 3.10
set_property PACKAGE_PIN Y18  [get_ports hdmi_clk_p]
set_property PACKAGE_PIN Y19  [get_ports hdmi_clk_n]
set_property PACKAGE_PIN V18  [get_ports hdmi_data0_p]   ;# Blue
set_property PACKAGE_PIN V19  [get_ports hdmi_data0_n]
set_property PACKAGE_PIN AA19 [get_ports hdmi_data1_p]   ;# Green
set_property PACKAGE_PIN AB20 [get_ports hdmi_data1_n]
set_property PACKAGE_PIN V17  [get_ports hdmi_data2_p]   ;# Red
set_property PACKAGE_PIN W17  [get_ports hdmi_data2_n]

# IOSTANDARD for HDMI differential pairs
set_property IOSTANDARD TMDS_33 [get_ports hdmi_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_clk_n]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_data0_p]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_data0_n]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_data1_p]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_data1_n]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_data2_p]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_data2_n]

# Timing constraints
create_clock -period 5.000 -name sys_clk [get_ports sys_clk_p]
```

---

## What You See on Screen

When programmed and connected via HDMI to any monitor:

```
┌─────────────────────────────────────┐
│  ░░▒▒▓▓██████████ (grayscale ramp)  │  y: 0–127
│                                     │
│  ■ ■ ■ ■ ■ ■ ■  (8 primary colors)  │  y: 128–255
│                                     │
│  Red→Yellow→Green→Cyan→Blue→Magenta │  y: 256–479
│         (smooth rainbow)            │
└─────────────────────────────────────┘

DIP Switch sw[0] = ON:  Grayscale mode (all zones converted to gray)
DIP Switch sw[1] = ON:  Solid color background (color set by sw[13:2])
DIP Switch sw[1] = OFF: Color bar pattern (default)
```

---

## Known Limitations and Next Steps

### Current Limitations

- **No audio:** This implements DVI-over-HDMI (no audio data island packets). Monitors will display video but audio is not transmitted.
- **4-bit color:** 4096 colors (4+4+4 bits). Expanding CD to 24 enables 16.7M colors.
- **No frame buffer:** Content is limited to what can be computed as a function of (x, y). Displaying arbitrary images requires DDR3 memory.
- **Fixed resolution:** 640×480 @ 60 Hz only. Other resolutions require changing `display_pkg.sv` parameters and regenerating the MMCM.

### Natural Next Steps

**1. Add more patterns**  
Extend `bar_demo.sv` or add new pattern generators (checkerboard, sine wave, Lissajous figures). Wire them into `vga_demo.sv` with switch-controlled muxing.

**2. Full 24-bit color**  
Change `CD = 24` in `display_pkg.sv`. Remove bit replication in `hdmi_top.sv` (connect 8-bit channels directly). Explore richer gradient and color effects.

**3. Higher resolution**  
Change timing parameters for 1280×720 @ 60 Hz (720p). Update MMCM: pixel clock becomes 74.25 MHz, serial clock 371.25 MHz (or 5x = 371.25 MHz DDR). Verify OSERDESE2 timing margin.

**4. Moving objects**  
Add a frame counter that increments once per `vsync` pulse. Use the frame count as a parameter in your pixel generator to animate objects across the screen — without any frame buffer.

**5. MicroBlaze SoC integration**  
Following Chu's later chapters: instantiate MicroBlaze MCS, map video control registers to MMIO addresses, write C code to control display mode, scroll text, or implement a simple game. This introduces the CPU ↔ RTL interface design pattern.

**6. Frame buffer with DDR3**  
The Puzhi board has 1 GB DDR3. A Xilinx AXI Video DMA IP block can stream pixel data from DDR3 to the display pipeline at full frame rate, enabling display of arbitrary images and video.

---

## References

- Pong P. Chu — *FPGA Prototyping by SystemVerilog Examples: Xilinx MicroBlaze MCS SoC Edition*
- Puzhi PA35T-EDU User Manual and Schematic — [puzhi.com](https://www.puzhi.com)
- Project F (Will Green) — TMDS Encoder DVI — [github.com/projf/projf-explore](https://github.com/projf/projf-explore)
- DVI Specification 1.0 — Digital Display Working Group (DDWG), April 1999
- Xilinx UG471 — 7 Series FPGAs SelectIO Resources User Guide (OSERDESE2, OBUFDS)
- Xilinx UG472 — 7 Series FPGAs Clocking Resources User Guide (MMCM parameters)
- VESA Standard — DMT (Display Monitor Timings), 640×480 @ 60 Hz

---

*Built as part of a self-study journey through Chu's FPGA Prototyping book, adapting VGA-based examples to a modern HDMI-only development board.*
