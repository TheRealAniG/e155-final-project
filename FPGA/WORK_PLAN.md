# MicroPs FPGA work plan

Thiven owns display hardware and RTL. Ani owns controls, vehicle physics, collisions and race data. Agree on a top-left screen origin, car-center coordinates, orientation codes and the track boundaries together. Keep a single track drawing with dimensions so the displayed wall and the MCU collision wall agree.

## Reference and authorship

Use Project F's Exploring FPGA Graphics series to understand the design decisions. Beginning FPGA Graphics provides the timing specification and waveform examples. Racing the Beam and FPGA Pong show how coordinates and frame enables produce motion. Display Signals introduces a different signed-coordinate convention. Use unsigned visible-first scan coordinates in this design. Hardware Sprites shows where bitmap addressing and memory latency enter the design. Framebuffers explains the cost of storing a whole image. A full 8-bit frame here costs 300 KiB. Compute track pixels directly and store artwork in EBR.

Write the timing generator, output gating, renderer, display-state logic and verification from your own diagrams. Vendor oscillator/PLL primitives can be wrapped in board-specific code. List any adapted open-source files with source, revision, changes and license in your report. The starter files contain original interface declarations only.

Tutorial: https://projectf.io/posts/fpga-graphics/
Sprite chapter: https://projectf.io/posts/hardware-sprites/
Framebuffer chapter: https://projectf.io/posts/framebuffers/
Examples: https://github.com/projf/projf-explore
Proposal: https://docs.google.com/document/d/1fiSslISm0iNoLZjBpIJzmf_fp7wRtDgqarEp64QOsdE/edit
Tracker: https://docs.google.com/spreadsheets/d/1PYhaVfVK_865ltp4t7e3H1x6MUtiM5W5zv3-RlMhMI4/edit

## Architecture

Pixel clock -> timing counters -> scan coordinates -> renderer -> registered VGA outputs.
Timing counters also drive visible, horizontal sync, vertical sync and vblank_tick. Route sync alongside RGB through every pipeline stage. Demo motion uses vblank_tick as an enable and feeds the renderer car coordinates. Later, the SPI receiver supplies pending state and frame registers supply the same coordinates to the renderer.

## Work and evidence

| Target | Build | Evidence |
|---|---|---|
| Nov 6–9 | Sketch and write vga_timing.sv. Verify the board clock source, realizable PLL settings, RGB resistor interface and package pin map before hardware programming. | Timing bench checks reset and two full frames. |
| Nov 9–11 | Connect clock, timing, color bars and a one-pixel border in the board top. | All four edges visible. Scope shows roughly 31.5 kHz horizontal and 59–61 Hz vertical. Save traces and pin map. |
| Nov 12–14 | Render the stationary track and a rectangle. Update the rectangle position during vertical blanking using an autonomous test path. | Track and rectangle appear independently. Position holds during active scan. |
| Nov 14–18 | Replace rectangle interior with one original asymmetric 32×32 indexed bitmap. Reserve one index for transparency. Use synchronous EBR and delay background, visible and sync to match the pixel read. | Verify sprite corners, transparent pixels and orientation. Save a moving-sprite video, ten-minute sync-lock result and Radiant memory/timing reports. Nov 18 is the internal readiness target. |
| Nov 19–24 | Implement SPI reception, packet validation and frame-state transfer. Agree on field offsets, endian order and coordinate widths with Ani. Add eight orientations, timer and lap digits. | Test fixed, scripted and live MCU coordinates in order. An incomplete packet leaves displayed state intact. A burst before vblank displays the newest complete state. |
| Dec 2–9 | Finish leaderboard, clipping, latency measurements and final evidence. | Compare displayed lap times with MCU values. Record 20 input-to-visible trials against 50 ms maximum. Recheck a ten-minute stable run and archive the working build. |

## First lab session

1. Draw two 10-bit registers x and y, each with reset to zero. x advances every rising edge. At x=799, wrap x and enable y. At the end of line 524, y wraps to zero.
2. Draw one line with boundaries at 0, 640, 656, 752, 800. Draw one frame with boundaries at 0, 480, 490, 492, 525. Label visible interval, front porch, negative sync and back porch. visible is true only inside BOTH visible intervals. Porches occupy time and output black.
3. Define vblank_tick at (0,480), one pixel period at the start of vertical blank. Draw a pulse there on the waveform. Write expected transitions at (639,0), (799,0), (799,479) and (799,524).
4. Fill in rtl/vga_timing.sv from the drawing. Write a bench using a simulated pixel clock before configuring a physical PLL. Count 800 clocks per line, 525 lines per frame, 307200 visible samples and one blanking tick per frame. Check HS low for 96 clocks on every line and VS low for two lines. Check reset mid-line.
5. Next add the board top and test pattern. Generate the physical clock from the verified source and record its actual frequency. Calculate expected rates as pixel frequency / 800 and pixel frequency / 420000. Map pins only after checking the board schematic.

## FSM decisions

Counters encode the raster phases. Rectangle and track selection use combinational comparisons. For a fixed-width ROM sprite, calculate row and column relative to its top-left corner, then address = row * 32 + column. With car-center coordinates, derive the top-left using signed widened arithmetic so sprites near an edge clip correctly. Draw a cycle table for address, EBR output, transparency and sync before adding pipeline registers. A straight bitmap lookup does not require the line-scanning FSM from the tutorial.

For SPI, draw a receive FSM before writing it: idle on deselect, collect bits while selected, accept a complete valid packet at the specified boundary, discard a truncated or overlong transaction. Choose either a verified pixel-clock oversampling scheme or a clock-domain crossing with a handshake and stable multi-bit payload. Never independently synchronize each payload bit. Swap the complete pending state into the displayed registers once per vblank; hold displayed state for the frame.

## File growth

Included: rtl/vga_timing.sv, rtl/demo_motion.sv, rtl/scene_renderer.sv, sim/tb_vga_timing.sv. These are source shells, with no implemented driver or passing tests yet. Start with the timing file and its bench.

Add in sequence:
- rtl/pixel_clock.sv, rtl/fpga_top.sv, constraints/board.pdc — board clock/reset, wiring and output registers. Choose physical RGB widths from the resistor network.
- rtl/track_renderer.sv, rtl/car_sprite.sv, assets/car.mem — track geometry, sprite address/lookup and packed artwork.
- rtl/spi_display_rx.sv, rtl/display_state.sv, sim/tb_display_state.sv — complete packet reception and coherent frame updates.
- rtl/hud_renderer.sv, assets/font.mem — lap timer, lap count and leaderboard.

Memory budget from the proposal: eight 32×32 sprites at 4 bits/pixel = 4096 bytes; 96 glyphs at 8 bytes each = 768 bytes; two 32-byte states = 64 bytes. Raw total 4928 bytes. Check packing and actual EBR block count after synthesis against the 8 KiB design budget and 15 KiB device capacity. Small state registers may map to flops.
