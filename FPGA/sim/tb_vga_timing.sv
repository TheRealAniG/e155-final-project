module tb_vga_timing;
    timeunit 1ns;
    timeprecision 1ps;
    logic clk_pix, reset, visible, hsync, vsync, vblank_tick;
    logic [9:0] x, y;
    vga_timing dut (.*);
    // TODO: generate the clock, apply reset and check the waveform in WORK_PLAN.md.
    initial $fatal(1, "Timing testbench has not been implemented.");
endmodule
