//Description: VGA top; 12 MHz external reference, working 24 MHz pixel PLL.
// Raw PLL lock is exposed on GPIO6 for scope diagnosis.
module fpga_top #(
    parameter int RGB_BITS = 4,
    parameter BITMAP = "../assets/car.mem",
    parameter PALETTE = "../assets/car_palette.mem",
    parameter MAP_FILE = "../assets/maps/rectangle.mem"
) (
    input  logic reset_n, clk_12m,
    input  logic spi_sck, spi_mosi, spi_cs_n,
    output wire spi_miso,
    output logic [RGB_BITS-1:0] vga_red, vga_green, vga_blue,
    output logic vga_hsync, vga_vsync,
    output wire pll_lock_debug
);
    logic reset_pix_n;
    logic signed [10:0] sx, sy;
    logic visible, hsync, vsync, vblank_tick;
    logic signed [10:0] car_center_x, car_center_y;
    logic signed [9:0] cos_q8, sin_q8;
    logic signed [10:0] demo_x, demo_y, received_x, received_y;
    logic signed [9:0] demo_cos, demo_sin, received_cos, received_sin;
    logic pose_valid, spi_active;
    // Ani's sender ignores receive bytes. Status/readback is not implemented.
    assign spi_miso = 1'b0;
    logic [23:0] rgb;
    logic [3:0] hsync_q, vsync_q;
    logic clk_pix;
    logic pll_locked;
    assign pll_lock_debug = pll_locked;

    //HSOSC #(.CLKHF_DIV("0b01")) i_HSOSC (
        //.CLKHFPU(1'b1),
        //.CLKHFEN(1'b1),
        //.CLKHF(clk_pix)
    //);

    // Existing pixel_pll IP: 12 MHz in, 24 MHz out, SIMPLE feedback,
    // one output, and Enable Lock Port checked. Leave clock settings intact.
    pixel_pll i_PIXEL_PLL (
        .ref_clk_i(clk_12m),
        .rst_n_i(reset_n),
        .lock_o(pll_locked),
        .outcore_o(),
        .outglobal_o(clk_pix)
    );

    //Reset synchronizer
    reset_sync i_RESET_SYNC (
        .clk(clk_pix),
        .reset_n(reset_n && pll_locked),
        //.reset_n(reset_n),
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
        .car_center_x(demo_x),
        .car_center_y(demo_y)
    );

    //Heading follows the clockwise rectangular demo path
    always_comb begin
        demo_cos = 10'sd256;
        demo_sin = 10'sd0;
        if (demo_x == 544 && demo_y < 384) begin
            demo_cos = 10'sd0;
            demo_sin = 10'sd256;
        end else if (demo_y == 384 && demo_x > 96) begin
            demo_cos = -10'sd256;
            demo_sin = 10'sd0;
        end else if (demo_x == 96 && demo_y > 96) begin
            demo_cos = 10'sd0;
            demo_sin = -10'sd256;
        end
    end

    spi_pose_receiver i_SPI_POSE (
        .clk(clk_pix), .reset_n(reset_pix_n),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n),
        .pose_valid(pose_valid), .packet_error(),
        .pose_x(received_x), .pose_y(received_y),
        .pose_cos(received_cos), .pose_sin(received_sin)
    );
    frame_pose i_FRAME_POSE (
        .clk(clk_pix), .reset_n(reset_pix_n), .vblank_tick(vblank_tick),
        .pose_valid(pose_valid), .pose_x(received_x), .pose_y(received_y),
        .pose_cos(received_cos), .pose_sin(received_sin),
        .demo_x(demo_x), .demo_y(demo_y), .demo_cos(demo_cos), .demo_sin(demo_sin),
        .spi_active(spi_active), .car_x(car_center_x), .car_y(car_center_y),
        .car_cos(cos_q8), .car_sin(sin_q8)
    );

    //Track, car, finish line, and checkpoint arches
    race_scene #(
        .BITMAP(BITMAP),
        .PALETTE(PALETTE),
        .MAP_FILE(MAP_FILE)
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

    // Match the scene's four stages before the common output register.
    always_ff @(posedge clk_pix or negedge reset_pix_n) begin
        if (!reset_pix_n) begin
            hsync_q <= '1;
            vsync_q <= '1;
        end else begin
            hsync_q <= {hsync_q[2:0], hsync};
            vsync_q <= {vsync_q[2:0], vsync};
        end
    end

    //VGA output registers.
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
            vga_hsync <= hsync_q[3];
            vga_vsync <= vsync_q[3];
        end
    end
endmodule
