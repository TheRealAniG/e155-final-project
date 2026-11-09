module vga_timing (
    input  logic       clk_pix,
    input  logic       reset,
    output logic [9:0] x, y,
    output logic       visible, hsync, vsync, vblank_tick
);
    // TODO: implement the two counters and interval decoders from your diagram.
endmodule
