# MicroPs Driving Game — FPGA Display

E155 final project using an STM32L432KC microcontroller and an iCE40UP5K FPGA to run a driving game with VGA output.

## Project overview

The microcontroller handles player input, game logic, and the physics calculations. The FPGA receives display state from the microcontroller and draws the game on a VGA monitor.

**Current status:** Starting development. The modules and milestones below are planned; hardware operation has not yet been verified.

## First milestone

Display a moving sprite on a VGA monitor using only the FPGA. Start with a solid rectangle as the sprite and generate its movement inside the FPGA for this demo. MCU communication and joystick input will be added later.


## Integration notes

The MCU and FPGA should agree on screen coordinates, position units, sprite identifiers, and reset behavior before communication is implemented. Buffer incoming updates and apply a complete display state at a frame boundary so a frame does not mix old and new positions.

Keep wiring diagrams, testbench results, scope captures, and demonstration videos with the project documentation as development progresses.
