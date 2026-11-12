// Simulation top: capture visible pixels as portable pixmap (binary P6).
module tb_sprite_frame;
    timeunit 1ns;
    timeprecision 1ps;
    parameter int FRAMES = 8;
    parameter real START_DEG = 0.0;
    parameter real STEP_DEG = 17.0;
    real radians;
    logic signed [9:0] cos_q8, sin_q8;
    parameter BITMAP = "../../assets/car.mem";
    parameter PALETTE = "../../assets/car_palette.mem";
    logic clk_pix = 0;
    logic reset_n = 0;
    logic signed [10:0] sx, sy;
    logic visible, hsync, vsync, vblank_tick;
    // race_scene produces final digital RGB.
    int fd, pixels;
    string filename;
    logic [23:0] rgb;

    always #19.841 clk_pix = ~clk_pix;
    // Coordinates belonging to the compositor's four-stage output.
    logic signed [10:0] pixel_x [0:3], pixel_y [0:3];
    always @(posedge clk_pix) begin
        pixel_x[0] <= sx; pixel_y[0] <= sy;
        for (int i = 1; i < 4; i++) begin
            pixel_x[i] <= pixel_x[i-1]; pixel_y[i] <= pixel_y[i-1];
        end
    end

    vga_timing timing (
        .clk_pix(clk_pix),
        .reset_n(reset_n),
        .sx(sx),
        .sy(sy),
        .visible(visible),
        .hsync(hsync),
        .vsync(vsync),
        .vblank_tick(vblank_tick)
    );
    logic signed [10:0] car_center_x, car_center_y;
    demo_motion motion (.clk_pix(clk_pix), .reset_n(reset_n), .vblank_tick(vblank_tick), .car_center_x(car_center_x), .car_center_y(car_center_y));
    race_scene #(.BITMAP(BITMAP), .PALETTE(PALETTE)) scene (.clk_pix(clk_pix), .sx(sx), .sy(sy), .car_center_x(car_center_x), .car_center_y(car_center_y), .cos_q8(cos_q8), .sin_q8(sin_q8), .visible(visible), .rgb(rgb));

    initial begin
        fd = $fopen(BITMAP, "r");
        if (!fd) $fatal(1, "Cannot open %s", BITMAP);
        $fclose(fd);
        fd = $fopen(PALETTE, "r");
        if (!fd) $fatal(1, "Cannot open %s", PALETTE);
        $fclose(fd);
        if (FRAMES < 1) $fatal(1, "FRAMES must be positive");
        repeat (6) @(negedge clk_pix);
        reset_n = 1;
        #1ns;
        repeat (4) @(negedge clk_pix); // Start at the delayed frame boundary.

        for (int frame = 0; frame < FRAMES; frame++) begin
            if (pixel_x[3] !== -160 || pixel_y[3] !== -45) $fatal(1, "Expected start of frame");
            radians = (START_DEG + frame * STEP_DEG) * 3.141592653589793 / 180.0;
            // Integral casts round the real coefficients to the nearest integer.
            cos_q8 = int'(256.0 * $cos(radians));
            sin_q8 = int'(256.0 * $sin(radians));
            filename = $sformatf("sprite_%04d.ppm", frame);
            fd = $fopen(filename, "wb");
            if (!fd) $fatal(1, "Cannot open %s", filename);
            $fwrite(fd, "P6\n640 480\n255\n");
            pixels = 0;

            repeat (800 * 525) begin
                if (scene.visible_q[3]) begin
                    if (pixel_x[3] !== pixels % 640 || pixel_y[3] !== pixels / 640)
                        $fatal(1, "Unexpected visible coordinate (%0d,%0d)", sx, sy);
                    if ($isunknown(rgb))
                        $fatal(1, "Unknown RGB at (%0d,%0d)", sx, sy);
                    $fwrite(fd, "%c%c%c", rgb[23:16], rgb[15:8], rgb[7:0]);
                    pixels++;
                end else if (scene.visible_q[3] !== 1'b0 || rgb !== 24'd0)
                    $fatal(1, "Unknown visible or nonblack blanking at (%0d,%0d)", sx, sy);
                @(negedge clk_pix);
            end

            $fclose(fd);
            if (pixels != 640 * 480) $fatal(1, "Captured %0d pixels", pixels);
            $display("Saved %s (%0d pixels)", filename, pixels);
        end
        $finish;
    end
endmodule
