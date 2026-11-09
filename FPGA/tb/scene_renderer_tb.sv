module scene_renderer_tb;
    timeunit 1ns;
    timeprecision 1ps;

    logic signed [10:0] sx, sy;
    logic visible;
    logic [3:0] color_index;

    scene_renderer dut (
        .sx(sx), .sy(sy), .visible(visible), .color_index(color_index)
    );

    task automatic check_pixel(
        input logic signed [10:0] x, y,
        input logic active,
        input logic [3:0] expected
    );
        sx = x;
        sy = y;
        visible = active;
        #1ns;
        if (color_index !== expected)
            $fatal(1, "At (%0d,%0d), visible=%b: expected %0d, got %0d",
                   x, y, active, expected, color_index);
    endtask

    initial begin
        // Blanking takes priority, even where the border comparison matches.
        check_pixel(-1, 100, 0, 0);
        check_pixel(0, -1, 0, 0);
        check_pixel(320, 480, 0, 0);

        // Scan across an interior row: edges and both sides of each transition.
        check_pixel(0,   100, 1, 15);
        check_pixel(1,   100, 1, 1);
        check_pixel(159, 100, 1, 1);
        check_pixel(160, 100, 1, 2);
        check_pixel(319, 100, 1, 2);
        check_pixel(320, 100, 1, 3);
        check_pixel(479, 100, 1, 3);
        check_pixel(480, 100, 1, 4);
        check_pixel(638, 100, 1, 4);
        check_pixel(639, 100, 1, 15);

        // Check that the top and bottom borders are each one pixel thick.
        check_pixel(320,   0, 1, 15);
        check_pixel(320,   1, 1, 3);
        check_pixel(320, 478, 1, 3);
        check_pixel(320, 479, 1, 15);

        $display("PASS: blanking, four color bars, and one-pixel border");
        $finish;
    end
endmodule
