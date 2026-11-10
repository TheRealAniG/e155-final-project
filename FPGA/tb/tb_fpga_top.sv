//Description: Check VGA output alignment, frame timing, motion, and reset
module tb_fpga_top;
    timeunit 1ns;
    timeprecision 1ps;

    logic clk_pix = 1'b0;
    logic reset_n = 1'b0;
    logic [3:0] vga_red, vga_green, vga_blue;
    logic vga_hsync, vga_vsync;
    logic [11:0] expected_rgb;
    logic expected_hsync, expected_vsync, expected_visible;
    logic signed [10:0] frame_x, frame_y;
    int active_pixels = 0, hsync_pixels = 0, vsync_pixels = 0, ticks = 0;

    always #19.841 clk_pix = ~clk_pix;

    fpga_top #(
        .BITMAP("../../assets/car.mem"),
        .PALETTE("../../assets/car_palette.mem")
    ) dut (
        .clk_pix(clk_pix),
        .reset_n(reset_n),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync)
    );

    initial begin
        repeat (2) @(negedge clk_pix);
        reset_n = 1'b1;
        // First edge fills the reset synchronizer; second releases reset.
        @(negedge clk_pix);
        if (dut.reset_pix_n !== 1'b0) $fatal(1, "Reset released too early");
        @(negedge clk_pix);
        if (dut.reset_pix_n !== 1'b1) $fatal(1, "Reset did not release");

        repeat (800 * 525) begin
            @(posedge clk_pix);
            // Capture the pre-edge scene and syncs, before NBA updates.
            expected_rgb = {dut.rgb[23:20], dut.rgb[15:12], dut.rgb[7:4]};
            expected_hsync = dut.hsync;
            expected_vsync = dut.vsync;
            expected_visible = dut.visible;
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

        // Assert reset away from a clock edge and require immediate black.
        @(negedge clk_pix);
        #3ns;
        reset_n = 1'b0;
        #1ns;
        if ({vga_red, vga_green, vga_blue, vga_hsync, vga_vsync} !== 14'b11)
            $fatal(1, "Reset must drive black RGB and inactive syncs");
        if (dut.car_center_x !== 96 || dut.car_center_y !== 96)
            $fatal(1, "Reset did not restore demo pose");
        $display("PASS: VGA top frame counts, output alignment, motion, and reset");
        $finish;
    end

    initial begin
        #20ms;
        $fatal(1, "VGA top test timed out");
    end
endmodule
