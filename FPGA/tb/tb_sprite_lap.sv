// Scripted clockwise lap: 32 corner frames and 18 straight frames.
// Run from FPGA/radiant/<simulation directory>, as with tb_sprite_frame.
module tb_sprite_lap;
    timeunit 1ns;
    timeprecision 1ps;

    parameter BITMAP = "../../assets/car.mem";
    parameter PALETTE = "../../assets/car_palette.mem";
    // Bitmap faces right (+X) at zero rotation, matching heading zero.
    parameter real ARTWORK_HEADING_DEG = 0.0;
    localparam int FRAMES = 50;
    localparam real PI = 3.141592653589793;
    logic clk_pix = 0, reset_n = 0;
    logic signed [10:0] sx, sy, car_center_x, car_center_y;
    logic signed [9:0] cos_q8, sin_q8;
    logic visible, hsync, vsync, vblank_tick;
    logic [23:0] rgb;
    int path_x [0:FRAMES-1], path_y [0:FRAMES-1];
    real heading [0:FRAMES-1];
    int samples = 0;
    int fd, pixels, sprite_pixels;
    real radians;
    string filename;

    always #19.841 clk_pix = ~clk_pix;
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
    // Drive frame state directly: demo_motion's fixed speed would require
    // hundreds of frames and does not provide smoothly changing headings.
    race_scene #(.BITMAP(BITMAP), .PALETTE(PALETTE)) scene (
        .clk_pix(clk_pix), .visible(visible), .sx(sx), .sy(sy), .car_center_x(car_center_x), .car_center_y(car_center_y),
        .cos_q8(cos_q8), .sin_q8(sin_q8), .rgb(rgb)
    );

    task automatic point(input int x, y, input real angle);
        if (samples >= FRAMES) $fatal(1, "Too many path samples");
        path_x[samples] = x;
        path_y[samples] = y;
        heading[samples] = angle;
        samples++;
    endtask

    // Eight distinct headings per 90-degree turn. Radius 64 keeps the
    // rounded path near the middle of the rectangular road at each corner.
    task automatic corner(input int cx, cy, input real start_deg);
        real angle;
        for (int step = 1; step <= 8; step++) begin
            angle = start_deg + step * 11.25;
            point(cx + int'(64.0 * $cos(angle * PI / 180.0)),
                  cy + int'(64.0 * $sin(angle * PI / 180.0)), angle + 90.0);
        end
    endtask

    initial begin
        // Start left of the finish stripe [312,328), head east, then take
        // a full clockwise circuit before crossing the stripe at the end.
        point(280, 96, 0.0);
        point(380, 96, 0.0);
        point(480, 96, 0.0);
        corner(480, 160, -90.0);
        for (int step = 1; step <= 3; step++)
            point(544, 160 + int'(160.0 * step / 3.0), 90.0);
        corner(480, 320, 0.0);
        for (int step = 1; step <= 5; step++)
            point(480 - 64 * step, 384, 180.0);
        corner(160, 320, 90.0);
        for (int step = 1; step <= 3; step++)
            point(96, 320 - int'(160.0 * step / 3.0), 270.0);
        corner(160, 160, 180.0);
        point(200, 96, 360.0);
        point(240, 96, 360.0);
        point(280, 96, 360.0);
        point(352, 96, 360.0);
        if (samples != FRAMES) $fatal(1, "Expected 50 samples, got %0d", samples);

        // Require the entire possible rotated 32x32 footprint (radius <23)
        // to stay on the road, including the rounded corner samples.
        for (int frame = 0; frame < FRAMES; frame++) begin
            if (path_x[frame] - 23 < 48 || path_x[frame] + 23 >= 592 ||
                path_y[frame] - 23 < 48 || path_y[frame] + 23 >= 432 ||
                (path_x[frame] + 23 >= 144 && path_x[frame] - 23 < 496 &&
                 path_y[frame] + 23 >= 144 && path_y[frame] - 23 < 336))
                $fatal(1, "Frame %0d sprite footprint leaves road", frame);
        end
        fd = $fopen(BITMAP, "r");
        if (!fd) $fatal(1, "Cannot open %s", BITMAP);
        $fclose(fd);
        fd = $fopen(PALETTE, "r");
        if (!fd) $fatal(1, "Cannot open %s", PALETTE);
        $fclose(fd);
        repeat (2) @(negedge clk_pix);
        reset_n = 1;
        #1ns;

        for (int frame = 0; frame < FRAMES; frame++) begin
            if (vblank_tick !== 1'b1) $fatal(1, "Expected frame boundary");
            car_center_x = path_x[frame];
            car_center_y = path_y[frame];
            radians = (heading[frame] - ARTWORK_HEADING_DEG) * PI / 180.0;
            cos_q8 = int'(256.0 * $cos(radians));
            sin_q8 = int'(256.0 * $sin(radians));
            filename = $sformatf("lap_%04d.ppm", frame);
            fd = $fopen(filename, "wb");
            if (!fd) $fatal(1, "Cannot open %s", filename);
            $fwrite(fd, "P6\n640 480\n255\n");
            pixels = 0;
            sprite_pixels = 0;
            repeat (800 * 525) begin
                if (visible) begin
                    if (sx !== pixels % 640 || sy !== pixels / 640)
                        $fatal(1, "Unexpected coordinate (%0d,%0d)", sx, sy);
                    if ($isunknown(rgb) || $isunknown(scene.opaque))
                        $fatal(1, "Unknown rendering at (%0d,%0d)", sx, sy);
                    if (scene.opaque) sprite_pixels++;
                    $fwrite(fd, "%c%c%c", rgb[23:16], rgb[15:8], rgb[7:0]);
                    pixels++;
                end else if (visible !== 1'b0 || rgb !== 24'd0)
                    $fatal(1, "Invalid blanking at (%0d,%0d)", sx, sy);
                @(negedge clk_pix);
            end
            $fclose(fd);
            if (pixels != 640 * 480 || sprite_pixels == 0)
                $fatal(1, "Frame %0d: pixels=%0d sprite=%0d", frame, pixels, sprite_pixels);
            $display("Saved %s: center=(%0d,%0d), heading=%0.2f, sprite pixels=%0d",
                     filename, path_x[frame], path_y[frame], heading[frame], sprite_pixels);
        end
        $display("PASS: 50-frame clockwise lap");
        $finish;
    end
endmodule
