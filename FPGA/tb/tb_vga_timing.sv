module tb_vga_timing;
    timeunit 1ns;
    timeprecision 1ps;

    logic clk_pix = 0;
    logic reset_n;
    logic signed [10:0] sx, sy;
    logic visible, hsync, vsync, vblank_tick;

    // Approximately 25.2 MHz
    always #19.841 clk_pix = ~clk_pix;

    vga_timing dut (
        .clk_pix     (clk_pix),
        .reset_n       (reset_n),
        .sx          (sx),
        .sy          (sy),
        .visible     (visible),
        .hsync       (hsync),
        .vsync       (vsync),
        .vblank_tick (vblank_tick)
    );

    task automatic check_pixel(input int x, input int y);
        logic expected_visible, expected_hsync, expected_vsync, expected_tick;

        expected_visible = (x >= 0) && (y >= 0);
        expected_hsync   = !((x >= -144) && (x < -48));
        expected_vsync   = !((y >=  -35) && (y < -33));
        expected_tick    = (x == -160) && (y == -45);

        if (sx !== x || sy !== y)
            $fatal(1, "Expected position (%0d,%0d), got (%0d,%0d)",
                   x, y, sx, sy);

        if ({visible, hsync, vsync, vblank_tick} !==
            {expected_visible, expected_hsync, expected_vsync, expected_tick})
            $fatal(1, "At (%0d,%0d): expected visible/hs/vs/tick=%b%b%b%b, got %b%b%b%b",
                   x, y, expected_visible, expected_hsync, expected_vsync,
                   expected_tick, visible, hsync, vsync, vblank_tick);
    endtask

    initial begin
        reset_n = 1'b0; //button pressed
        repeat (2) @(negedge clk_pix);

        if (sx !== -160 || sy !== -45 || vblank_tick !== 1'b0)
            $fatal(1, "Unexpected reset position or tick");

        reset_n = 1'b1;  //button released
        #1ns;  // Allow combinational outputs to settle after reset release.

        for (int y = -45; y < 480; y++) begin
            for (int x = -160; x < 640; x++) begin
                check_pixel(x, y);
                @(negedge clk_pix);
            end
        end

        check_pixel(-160, -45);  // First pixel period of the next frame
        $display("PASS: VGA coordinates, visible, sync pulses, and frame wrap");
        $finish;
    end

endmodule