//Description: VGA demo top; supply a verified 25.175 or 25.2 MHz pixel clock
// Clock generation and physical pin constraints depend on the board wiring.
module fpga_top #(
    parameter int RGB_BITS = 4,
    parameter BITMAP = "../assets/car.mem",
    parameter PALETTE = "../assets/car_palette.mem"
) (
    input  logic clk_pix,
    input  logic reset_n,
    output logic [RGB_BITS-1:0] vga_red, vga_green, vga_blue,
    output logic vga_hsync, vga_vsync
);
    logic reset_pix_n;
    logic signed [10:0] sx, sy;
    logic visible, hsync, vsync, vblank_tick;
    logic signed [10:0] car_center_x, car_center_y;
    logic signed [9:0] cos_q8, sin_q8;
    logic [23:0] rgb;

    //Reset synchronizer
    reset_sync i_RESET_SYNC (
        .clk(clk_pix),
        .reset_n(reset_n),
        .reset_sync_n(reset_pix_n)
    );

    //VGA timing
    vga_timing i_VGA_TIMING (
        .clk_pix(clk_pix),
        .reset_n(reset_pix_n),
        .sx(sx),
        .sy(sy),
        .visible(visible),
        .hsync(hsync),
        .vsync(vsync),
        .vblank_tick(vblank_tick)
    );

    //Autonomous motion until MCU display state is available
    demo_motion i_DEMO_MOTION (
        .clk_pix(clk_pix),
        .reset_n(reset_pix_n),
        .vblank_tick(vblank_tick),
        .car_center_x(car_center_x),
        .car_center_y(car_center_y)
    );

    //Heading follows the clockwise rectangular demo path
    always_comb begin
        cos_q8 = 10'sd256;
        sin_q8 = 10'sd0;
        if (car_center_x == 544 && car_center_y < 384) begin
            cos_q8 = 10'sd0;
            sin_q8 = 10'sd256;
        end else if (car_center_y == 384 && car_center_x > 96) begin
            cos_q8 = -10'sd256;
            sin_q8 = 10'sd0;
        end else if (car_center_x == 96 && car_center_y > 96) begin
            cos_q8 = 10'sd0;
            sin_q8 = -10'sd256;
        end
    end

    //Track, car, finish line, and checkpoint arches
    race_scene #(
        .BITMAP(BITMAP),
        .PALETTE(PALETTE)
    ) i_RACE_SCENE (
        .clk_pix(clk_pix),
        .visible(visible),
        .sx(sx),
        .sy(sy),
        .car_center_x(car_center_x),
        .car_center_y(car_center_y),
        .cos_q8(cos_q8),
        .sin_q8(sin_q8),
        .rgb(rgb)
    );

    //VGA output registers: RGB and both syncs have the same one-cycle delay.
    // RGB_BITS must be 1..8; select it to match the breakout resistor DAC.
    always_ff @(posedge clk_pix or negedge reset_pix_n) begin
        if (!reset_pix_n) begin
            vga_red <= '0;
            vga_green <= '0;
            vga_blue <= '0;
            vga_hsync <= 1'b1;
            vga_vsync <= 1'b1;
        end else begin
            vga_red <= rgb[23 -: RGB_BITS];
            vga_green <= rgb[15 -: RGB_BITS];
            vga_blue <= rgb[7 -: RGB_BITS];
            vga_hsync <= hsync;
            vga_vsync <= vsync;
        end
    end
endmodule
