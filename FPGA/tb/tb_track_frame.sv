// Simulation top: capture visible pixels as portable pixmap (binary P6).
module tb_track_frame;
    timeunit 1ns;
    timeprecision 1ps;
    parameter int FRAMES = 8;
    logic clk_pix = 0;
    logic reset_n = 0;
    logic signed [10:0] sx, sy;
    logic visible, hsync, vsync, vblank_tick;
    logic [3:0] color_index;
    int fd, pixels;
    string filename;
    logic [23:0] rgb;

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
    logic signed [10:0] car_center_x, car_center_y;
    demo_motion motion (.clk_pix(clk_pix), .reset_n(reset_n), .vblank_tick(vblank_tick), .car_center_x(car_center_x), .car_center_y(car_center_y));
    track_renderer renderer (.sx(sx), .sy(sy), .car_center_x(car_center_x), .car_center_y(car_center_y), .visible(visible), .color_index(color_index));

    // Preview palette for track_renderer. Replace with DUT RGB when available.
    function automatic logic [23:0] palette(input logic [3:0] idx);
        case (idx)
            0:  return 24'h000000;
            1:  return 24'hff0000;
            2:  return 24'h287348;
            5:  return 24'h454951;
            3:  return 24'h0000ff;
            4:  return 24'hffff00;
            15: return 24'hffffff;
            default: return 24'hxxxxxx;
        endcase
    endfunction

    initial begin
        if (FRAMES < 1) $fatal(1, "FRAMES must be positive");
        repeat (2) @(negedge clk_pix);
        reset_n = 1;
        #1ns;

        for (int frame = 0; frame < FRAMES; frame++) begin
            if (vblank_tick !== 1'b1) $fatal(1, "Expected start of frame");
            filename = $sformatf("track_%04d.ppm", frame);
            fd = $fopen(filename, "wb");
            if (!fd) $fatal(1, "Cannot open %s", filename);
            $fwrite(fd, "P6\n640 480\n255\n");
            pixels = 0;

            repeat (800 * 525) begin
                if (visible) begin
                    if (sx !== pixels % 640 || sy !== pixels / 640)
                        $fatal(1, "Unexpected visible coordinate (%0d,%0d)", sx, sy);
                    rgb = palette(color_index);
                    if ($isunknown(rgb))
                        $fatal(1, "Undefined palette index %h at (%0d,%0d)", color_index, sx, sy);
                    $fwrite(fd, "%c%c%c", rgb[23:16], rgb[15:8], rgb[7:0]);
                    pixels++;
                end else if (visible !== 1'b0 || color_index !== 4'd0)
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
