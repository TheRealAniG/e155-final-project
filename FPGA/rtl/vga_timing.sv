//Description: Generate scan coordinates and sync signals for 640x480 VGA
// reset is active low at this module's interface.
module vga_timing (
    input  logic clk_pix,
    input  logic reset_n,

    output logic signed [10:0] sx, sy,
    output logic visible,
    output logic hsync, vsync,
    output logic vblank_tick
);

    // Horizontal timing in pixel clocks
    localparam int H_ACTIVE = 640;
    localparam int H_FRONT  = 16;
    localparam int H_SYNC   = 96;
    localparam int H_BACK   = 48;
    localparam int H_BLANK  = H_FRONT + H_SYNC + H_BACK;
    localparam int H_TOTAL  = H_BLANK + H_ACTIVE;

    // Vertical timing in lines
    localparam int V_ACTIVE = 480;
    localparam int V_FRONT  = 10;
    localparam int V_SYNC   = 2;
    localparam int V_BACK   = 33;
    localparam int V_BLANK  = V_FRONT + V_SYNC + V_BACK;
    localparam int V_TOTAL  = V_BLANK + V_ACTIVE;

    logic [9:0] h_count, v_count;
    logic end_of_line;

    // Scan counters
    assign end_of_line = (h_count == H_TOTAL - 1);

    lab2_ta_counter #(
        .WIDTH(10),
        .MAX_COUNT(H_TOTAL - 1)
    ) i_HORIZONTAL_COUNTER (
        .clk     (clk_pix),
        .reset   (reset_n),
        .enable  (1'b1),
        .counter (h_count)
    );

    lab2_ta_counter #(
        .WIDTH(10),
        .MAX_COUNT(V_TOTAL - 1)
    ) i_VERTICAL_COUNTER (
        .clk     (clk_pix),
        .reset   (reset_n),
        .enable  (end_of_line),
        .counter (v_count)
    );

    // Screen coordinates: visible image starts at (0, 0).
    // The leading zero preserves counts above 511 when casting to signed.
    assign sx = $signed({1'b0, h_count}) - 11'(H_BLANK);
    assign sy = $signed({1'b0, v_count}) - 11'(V_BLANK);

    // Output logic: front porch, sync pulse, back porch, then visible pixels.
    assign visible = (sx >= 0) && (sy >= 0);

    assign hsync = !((h_count >= H_FRONT) &&
                     (h_count <  H_FRONT + H_SYNC));

    assign vsync = !((v_count >= V_FRONT) &&
                     (v_count <  V_FRONT + V_SYNC));

    // Enable for updating display state at the start of vertical blanking.
    assign vblank_tick = reset_n && (h_count == 0) && (v_count == 0);

endmodule
