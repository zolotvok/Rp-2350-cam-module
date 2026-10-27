# proto2

Second prototype of the camera module, work in progress. It is built on [proto1](../proto1): the camera's supply and clock circuitry moves onto the board, the camera is wired straight to the RP2350B, a CAN bus interface is added, and the board shrinks to 40 × 40 mm.

## Changes from proto1

- **Camera supply and clock on the board.** The support circuitry of the [Adafruit OV5640 breakout](https://github.com/adafruit/Adafruit-OV5640-Camera-Breakout-PCB) is on the board: a 24-pin OV5640 module connector (X1), 2.8 V and 1.5 V regulators (U8 TLV74328, U9 TLV74315) and a footprint for a 24 MHz oscillator (OSC1). Only the circuit comes from the breakout's schematic; the layout is not copied (see [NOTICE.md](../../NOTICE.md)).
- **Camera wired directly to the RP2350B.** The header pair between the board and the breakout (J2 on proto1, JP1/JP2 on the breakout) is gone. The camera uses the same GPIOs as on proto1, with two differences:
  - D2–D9 are on GPIO0–GPIO7 in order. The pairwise swap of proto1 is fixed, so **the firmware must not reorder the bits on proto2**.
  - The camera reset has its own net (CAM_~{RESET}, GPIO22). In the imported breakout circuit it shared the `~{RESET}` net name with the RP2350 RUN pin, which tied the camera reset to the MCU reset.
- **CAN bus.** An MCP2515 controller (U3) on SPI0 and an SN65HVD230 transceiver (U6), with a JST SH connector (J4) and a jumper-selectable 120 Ω terminator.
- **Smaller parts.** Passives are 0402 (10 µF capacitors 0603), diodes SOD-523, LEDs 0402. LCSC part numbers are filled in for JLC assembly, using basic or preferred parts where one exists.
- **Standard footprints.** Every footprint comes from the KiCad 10 standard libraries; the project needs no extra footprint library.
- **Board size.** 40 × 40 mm, 4 layers, parts on both sides (proto1: 41.6 × 78 mm).

## Status

Snapshot from October 2026:

- **Schematic:** complete apart from review. ERC still reports errors carried over from proto1 and from the imported Adafruit symbols (missing symbol libraries, undriven power pins); none of them are known to be real faults, but they have not all been checked.
- **PCB:** 40 × 40 mm outline with every part placed roughly; nothing is routed yet. In1 is a GND plane and In2 a 3.3 V plane (zones drawn, not filled).
- **To check before routing:** the orientation of the edge connectors (X1 camera FPC on the left edge, J1 USB-C on the top edge, J4 CAN in the bottom-right corner) in the 3D viewer. They were placed from the pad layout, without 3D models.

## RP2350B pin assignment

| GPIO | Signal | Connected to |
|---|---|---|
| 0–7 | DATA2–DATA9 | Camera data, D2 (LSB) to D9 (MSB) |
| 8 | EXT_XCLK | Camera clock through SJ1 |
| 9 | HSYNC | Camera HREF |
| 10 | VSYNC | Camera VSYNC |
| 11 | PCLK | Camera pixel clock |
| 16–19 | TX, RX, CTS, RTS | UART header J3 |
| 20 | SDA | Camera I²C, 10 kΩ pull-up (R12) |
| 21 | SCL | Camera I²C, 10 kΩ pull-up (R13) |
| 22 | CAM_~{RESET} | Camera reset, 10 kΩ pull-up (R10) |
| 23 | PWDN | Camera power-down, 10 kΩ pull-down (R11); LED L0 |
| 24 | USBBOOT | BOOT button S1, test point TP1 |
| 26 | GPIO26 | PSRAM bank select (74LVC1G19, U4) |
| 32 | CAN_MISO | MCP2515 SO (SPI0 RX) |
| 33 | CAN_CS | MCP2515 CS (SPI0 CSn) |
| 34 | CAN_SCK | MCP2515 SCK (SPI0 SCK) |
| 35 | CAN_MOSI | MCP2515 SI (SPI0 TX) |
| 36 | CAN_INT | MCP2515 INT (active low, push-pull) |
| 37 | CAN_STBY | SN65HVD230 Rs: low = normal (high-speed), high = standby; 10 kΩ pull-down (R32) |
| 41 | A0 | LEDs L6 and L2 |
| 42–44 | A1–A3 | LEDs L3, L4, L5 |
| 47 | PSRAM_CS | QSPI CS1, routed to one PSRAM by U4 |

The camera's I/O supply (DOVDD) is 3.3 V, the same as the RP2350's, so the camera signals need no level shifting.

## Camera clock (SJ1)

SJ1 selects where the camera's XCLK comes from. It is bridged 1–2 on the PCB, so by default the RP2350 generates XCLK on GPIO8, as on proto1, and OSC1 is not populated. GPIO8 is not a clock-output (GPOUT) pin, so XCLK has to come from PWM or PIO; it is clean only when the system clock is an integer multiple of it (150 MHz / 6 = 25 MHz, or 144 MHz / 6 = 24 MHz).

To use the on-board oscillator instead: fit OSC1 (24 MHz, 3.3 V, LCSC C712738), cut the 1–2 bridge of SJ1 and close 2–3. OSC1's enable pin is tied to 3.3 V, so it runs whenever it is fitted.

## CAN bus

- **Controller:** MCP2515 on SPI0 (max. 10 MHz SPI clock), 16 MHz crystal (Y2). Its reset comes from an RC circuit (R17, C28, D1); the RP2350 can also reset it with the SPI RESET command.
- **Transceiver:** SN65HVD230, 3.3 V. CAN_STBY (GPIO37) switches it between normal mode and standby; R32 keeps it in normal mode while GPIO37 is not driven.
- **Connector J4:** JST SH, 1.0 mm pitch, 3 pins.

  | Pin | Signal |
  |---|---|
  | 1 | CANH |
  | 2 | CANL |
  | 3 | GND |

- **Termination:** close JP3 to put 120 Ω (R31) between CANH and CANL. Close it only if this board is at one end of the bus.

## Other connectors

- **J1:** USB-C, power and data.
- **J3:** UART (1×5, 2.54 mm, not populated). Pin 1 TX, 2 RX, 3 CTS, 4 RTS, 5 GND; TX and RX are named from the RP2350's point of view.
- **DEBUG0:** SWD (1×3, 2.54 mm, not populated). Pin 1 SWCLK, 2 GND, 3 SWDIO.

## Solder jumpers

| Jumper | Default | Function |
|---|---|---|
| SJ1 | 1–2 bridged | Camera clock source, see [Camera clock](#camera-clock-sj1) |
| SJ2 | open | Connects 3.3 V to the camera's DATA1 pin, which powers the focus motor of autofocus modules. Close it only with an autofocus module: on other modules DATA1 is a data output. |
| JP3 | open | CAN bus termination |

## LEDs

| LED | Colour | Driven by | Populated |
|---|---|---|---|
| ON0 | green | 3.3 V (power indicator) | yes |
| L6 | red | GPIO41 (A0) | yes |
| L0 | red | GPIO23 (PWDN) | no |
| L2 | red | GPIO41 (A0) | no |
| L3 | green | GPIO42 (A1) | no |
| L4 | yellow | GPIO43 (A2) | no |
| L5 | blue | GPIO44 (A3) | no |

## Files

| Path | Contents |
|---|---|
| [`kicad/`](kicad) | KiCad 10 project: schematic and PCB |

Fabrication files and docs will be added when the design is ready for manufacturing. `scripts/export-docs.sh proto2` generates a schematic PDF and renders at any time.
