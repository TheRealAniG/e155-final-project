//Description: Check VGA output alignment, frame timing, motion, and reset
module tb_fpga_top;
    timeunit 1ns;
    timeprecision 1ps;

    wire clk_pix = dut.clk_pix;
    logic reset_n = 1'b0;
    logic clk_12m = 0;
    logic spi_sck = 0, spi_mosi = 0, spi_cs_n = 1;
    wire spi_miso, pll_lock_debug;
    always #41.6665 clk_12m = ~clk_12m;
    logic [3:0] vga_red, vga_green, vga_blue;
    logic vga_hsync, vga_vsync;
    logic [11:0] expected_rgb;
    logic expected_hsync, expected_vsync, expected_visible;
    logic signed [10:0] frame_x, frame_y;
    int active_pixels = 0, hsync_pixels = 0, vsync_pixels = 0, ticks = 0;

    fpga_top #(
        .BITMAP("../../assets/car.mem"),
        .PALETTE("../../assets/car_palette.mem"),
        .MAP_FILE("../../assets/maps/rectangle.mem")
    ) dut (
        .reset_n(reset_n),
        .clk_12m(clk_12m),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n),
        .spi_miso(spi_miso), .pll_lock_debug(pll_lock_debug),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync)
    );

    task automatic send_pose(input int px, py, pc, ps);
        logic [79:0] packet;
        logic [7:0] sum;
        packet = {8'ha5, 16'(px), 16'(py), 16'(pc), 16'(ps), 8'h00};
        sum = 0;
        for (int b = 1; b < 10; b++) sum ^= packet[8*b +: 8];
        packet[7:0] = sum;
        #73; spi_cs_n = 0; #250;
        for (int b = 79; b >= 0; b--) begin
            spi_mosi = packet[b];
            #200; spi_sck = 1;
            #200; spi_sck = 0;
        end
        #100; spi_cs_n = 1; #350;
    endtask

    initial begin
        repeat (2) @(negedge clk_12m);
        reset_n = 1'b1;
        wait (dut.pll_locked);
        // First edge fills the reset synchronizer; second releases reset.
        @(negedge clk_pix);
        if (dut.reset_pix_n !== 1'b0) $fatal(1, "Reset released too early");
        @(negedge clk_pix);
        if (dut.reset_pix_n !== 1'b1) $fatal(1, "Reset did not release");
        repeat (8) @(negedge clk_pix); // Fill the scene and sync pipelines.

        repeat (800 * 525) begin
            @(posedge clk_pix);
            // Capture the pre-edge scene and syncs, before NBA updates.
            expected_rgb = {dut.rgb[23:20], dut.rgb[15:12], dut.rgb[7:4]};
            expected_hsync = dut.hsync_q[3];
            expected_vsync = dut.vsync_q[3];
            expected_visible = dut.i_RACE_SCENE.visible_q[3];
            if (!dut.hsync) hsync_pixels++;
            if (!dut.vsync) vsync_pixels++;
            if (dut.vblank_tick) ticks++;
            if (dut.visible) begin
                if (active_pixels == 0) begin
                    frame_x = dut.car_center_x;
                    frame_y = dut.car_center_y;
                end
                if (dut.car_center_x !== frame_x || dut.car_center_y !== frame_y)
                    $fatal(1, "Demo position changed during visible frame");
                active_pixels++;
            end
            #1ns;
            if ({vga_red, vga_green, vga_blue} !== expected_rgb ||
                vga_hsync !== expected_hsync || vga_vsync !== expected_vsync)
                $fatal(1, "VGA output pipeline mismatch");
            if (!expected_visible && {vga_red, vga_green, vga_blue} !== 12'd0)
                $fatal(1, "VGA blanking must be black");
        end
        if (active_pixels != 640 * 480 || hsync_pixels != 96 * 525 ||
            vsync_pixels != 2 * 800 || ticks != 1)
            $fatal(1, "Incorrect VGA frame counts");
        if (frame_x !== 100 || frame_y !== 96)
            $fatal(1, "Demo motion did not advance during blanking");

        // Exercise the real top-level receiver/mux while a frame is visible.
        wait (dut.visible);
        frame_x = dut.car_center_x; frame_y = dut.car_center_y;
        send_pose(400, 220, 0, -256);
        send_pose(420, 240, 181, 181);
        if (dut.spi_active || dut.car_center_x !== frame_x || dut.car_center_y !== frame_y)
            $fatal(1, "SPI pose changed a visible frame");
        wait (dut.spi_active);
        #1ns;
        if (dut.visible || dut.car_center_x !== 420 || dut.car_center_y !== 240 ||
            dut.cos_q8 !== 181 || dut.sin_q8 !== 181)
            $fatal(1, "Top-level SPI frame commit failed");
        wait (dut.visible);
        repeat (800 * 480) begin
            @(negedge clk_pix);
            if (dut.car_center_x !== 420 || dut.car_center_y !== 240 ||
                dut.cos_q8 !== 181 || dut.sin_q8 !== 181)
                $fatal(1, "SPI pose changed without a new packet");
        end

        // Assert reset away from a clock edge and require immediate black.
        @(negedge clk_pix);
        #3ns;
        reset_n = 1'b0;
        #1ns;
        if ({vga_red, vga_green, vga_blue, vga_hsync, vga_vsync} !== 14'b11)
            $fatal(1, "Reset must drive black RGB and inactive syncs");
        if (dut.car_center_x !== 96 || dut.car_center_y !== 96)
            $fatal(1, "Reset did not restore demo pose");
        $display("PASS: VGA top frame counts, output alignment, demo fallback, SPI takeover, hold, and reset");
        $finish;
    end

    initial begin
        #60ms;
        $fatal(1, "VGA top test timed out");
    end
endmodule

// Behavioral model of the enabled internal oscillator, divided to 24 MHz.
module HSOSC #(parameter CLKHF_DIV = "0b01") (
    input CLKHFPU, CLKHFEN, output logic CLKHF = 0
);
    timeunit 1ns; timeprecision 1ps;
    always #20.833 CLKHF = CLKHFPU && CLKHFEN ? ~CLKHF : 1'b0;
endmodule
