// Run from FPGA/sim/physics; no device libraries or Radiant GUI required.
module tb_physics_frames;
    timeunit 1ns;
    timeprecision 1ps;
    parameter int FRAMES = 180;
    parameter BITMAP = "../../assets/car.mem";
    parameter PALETTE = "../../assets/car_palette.mem";
    parameter POSES = "../../../MCU/physics/poses.txt";
    logic clk_pix = 0, reset_n = 0;
    logic signed [10:0] sx, sy, car_center_x, car_center_y;
    logic signed [9:0] cos_q8, sin_q8;
    logic visible, hsync, vsync, vblank_tick;
    logic [23:0] rgb;
    int input_fd, output_fd, asset_fd, count, pixels, sprite_pixels;
    int x, y, c, s;
    string filename, line;

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
    race_scene #(.BITMAP(BITMAP), .PALETTE(PALETTE)) scene (
        .clk_pix(clk_pix), .visible(visible), .sx(sx), .sy(sy), .car_center_x(car_center_x), .car_center_y(car_center_y),
        .cos_q8(cos_q8), .sin_q8(sin_q8), .rgb(rgb)
    );

    initial begin
        if (FRAMES < 1) $fatal(1, "FRAMES must be positive");
        asset_fd = $fopen(BITMAP, "r");
        if (!asset_fd) $fatal(1, "Cannot open %s", BITMAP);
        $fclose(asset_fd);
        asset_fd = $fopen(PALETTE, "r");
        if (!asset_fd) $fatal(1, "Cannot open %s", PALETTE);
        $fclose(asset_fd);
        input_fd = $fopen(POSES, "r");
        if (!input_fd) $fatal(1, "Cannot open %s", POSES);
        repeat (2) @(negedge clk_pix);
        reset_n = 1;
        #1ns;

        for (int frame = 0; frame < FRAMES; frame++) begin
            if (vblank_tick !== 1'b1) $fatal(1, "Expected frame boundary");
            count = $fgets(line, input_fd);
            if (!count || $sscanf(line, "%d %d %d %d", x, y, c, s) != 4)
                $fatal(1, "Missing/malformed pose at frame %0d", frame);
            if (x < -1024 || x > 1023 || y < -1024 || y > 1023 ||
                c < -256 || c > 256 || s < -256 || s > 256)
                $fatal(1, "Pose outside renderer range at frame %0d", frame);
            car_center_x = x;
            car_center_y = y;
            cos_q8 = c;
            sin_q8 = s;
            filename = $sformatf("%0d", frame);
            while (filename.len() < 4) filename = {"0", filename};
            filename = {"physics_", filename, ".ppm"};
            output_fd = $fopen(filename, "wb");
            if (!output_fd) $fatal(1, "Cannot write %s", filename);
            $fwrite(output_fd, "P6\n640 480\n255\n");
            pixels = 0;
            sprite_pixels = 0;
            // Sample at falling edges: the sprite ROM has settled after
            // the rising edge. Its sx+1 lookahead matches the VGA counter.
            // Pose changes occur in leading vertical blanking, allowing
            // the pipeline to fill before the first visible pixel.
            repeat (800 * 525) begin
                if (visible === 1'b1) begin
                    if (sx !== pixels % 640 || sy !== pixels / 640)
                        $fatal(1, "Unexpected raster at (%0d,%0d)", sx, sy);
                    if ($isunknown(rgb) || $isunknown(scene.opaque))
                        $fatal(1, "Unknown RGB/sprite at (%0d,%0d)", sx, sy);
                    if (scene.arch_opaque && rgb !== scene.arch_rgb)
                        $fatal(1, "Checkpoint must draw above car at (%0d,%0d)", sx, sy);
                    if (!scene.arch_opaque && scene.opaque && rgb !== scene.car_rgb)
                        $fatal(1, "Car hidden outside checkpoint at (%0d,%0d)", sx, sy);
                    if (scene.opaque) sprite_pixels++;
                    $fwrite(output_fd, "%c%c%c", rgb[23:16], rgb[15:8], rgb[7:0]);
                    pixels++;
                end else if (visible !== 1'b0 || rgb !== 24'd0)
                    $fatal(1, "Invalid blanking at (%0d,%0d)", sx, sy);
                @(negedge clk_pix);
            end
            $fclose(output_fd);
            if (pixels != 640 * 480 || sprite_pixels == 0)
                $fatal(1, "Frame %0d: pixels=%0d sprite=%0d", frame, pixels, sprite_pixels);
            $display("Saved %s center=(%0d,%0d) Q8=(%0d,%0d) sprite=%0d",
                     filename, x, y, c, s, sprite_pixels);
        end
        $fclose(input_fd);
        $display("PASS: %0d physics frames", FRAMES);
        $finish;
    end
endmodule
