# Physics poses to VGA frames

`tb_physics_frames.sv` reads the C demo's four-column `poses.txt`, holds
each pose for one complete VGA frame, and writes binary P6 PPM images.
It instantiates the actual VGA timing, race scene, and sprite RTL. It
checks raster order, known RGB, black blanking, 307200 pixels per frame,
and at least one opaque sprite pixel. Falling-edge capture allows the
sprite ROM output to settle; pose updates happen in vertical blanking.
The simulation processes full 800x525 timing, exporting only 640x480 pixels.

First regenerate `MCU/physics/poses.txt` with the desktop demo if desired.
From the repository root, test one frame using the installed Questa:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File FPGA/tb/render_physics.ps1 -Frames 1
```

Then export all 180 frames:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File FPGA/tb/render_physics.ps1
```

The execution-policy option applies only to this PowerShell process.
Pass `-Qrun 'C:\path\to\qrun.exe'` if the simulator location differs.
The script creates `FPGA/sim/physics`; outputs are `physics_0000.ppm`
through `physics_0179.ppm` (about 158 MiB total). Generated files are
ignored by Git. Each run overwrites matching filenames; a short run does
not remove files from an earlier longer run.

Open the desired numbered images with GIMP's **Open as Layers**, confirm
layer order, and use Animation Playback at 60 fps (approximately 17 ms
per frame). The PPMs themselves do not store playback timing.

## Verification status

The installed Questa Lattice OEM 2025.2 compiled and optimized this
testbench and its RTL dependencies with zero errors. Runtime could not
start because license checkout failed (`Invalid license environment`,
with a diagnostic mentioning `SALT_LICENSE_SERVER`). No PPMs were generated,
and the runtime assertions and visual appearance remain unverified.
Launching Radiant's GUI is not required for this command-line simulation,
but a valid Questa license configuration is required.

## Alternative after installing Icarus Verilog

These commands are provided for a compatibility trial; Icarus is not
currently installed and this route has not been verified. Run from the
repository root with `iverilog` and `vvp` available on PATH:

```powershell
New-Item -ItemType Directory -Force FPGA/sim/physics | Out-Null
Set-Location FPGA/sim/physics
iverilog -g2012 -s tb_physics_frames -Ptb_physics_frames.FRAMES=1 -o physics.vvp ../../rtl/lab2_ta_counter.sv ../../rtl/vga_timing.sv ../../rtl/car_sprite.sv ../../rtl/race_scene.sv ../../tb/tb_physics_frames.sv
vvp physics.vvp
```

For the full run change `FRAMES=1` to `FRAMES=180` and compile again.
Expect `PASS: 180 physics frames` before treating the export as complete.
