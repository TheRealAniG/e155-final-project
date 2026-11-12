// Compare the pipelined compositor against an independent pixel model.
module tb_sprite_pipeline;
    timeunit 1ns; timeprecision 1ps;
    logic clk = 0, visible;
    logic signed [10:0] sx, sy, cx, cy;
    logic signed [9:0] c, s;
    logic [23:0] rgb, arch_rgb, expected [0:3];
    logic arch_opaque;
    logic [3:0] bitmap [0:1023];
    logic [23:0] palette [0:15];
    integer x, y, col, row, index;
    logic road, finish_line;
    always #5 clk = ~clk;
    race_scene #(.BITMAP("../../assets/car.mem"), .PALETTE("../../assets/car_palette.mem")) dut
        (.clk_pix(clk), .visible(visible), .sx(sx), .sy(sy),
         .car_center_x(cx), .car_center_y(cy), .cos_q8(c), .sin_q8(s), .rgb(rgb));
    checkpoint_arches arches (.sx(sx), .sy(sy), .opaque(arch_opaque), .rgb(arch_rgb));
    initial begin
        $readmemh("../../assets/car.mem", bitmap);
        $readmemh("../../assets/car_palette.mem", palette);
        for (int n = 0; n < 10000; n++) begin
            @(negedge clk);
            // Change position and heading every pixel to expose stage skew.
            cx = 11'(280 + n % 3); cy = 11'(96 + n % 5);
            sx = 11'(250 + n % 65); sy = 11'(64 + (n / 65) % 65);
            case (n % 5)
                0: begin c = 256; s = 0; end
                1: begin c = 0; s = 256; end
                2: begin c = -256; s = 0; end
                3: begin c = 0; s = -256; end
                4: begin c = 181; s = 181; end
            endcase
            visible = n % 17 != 0;
            #1;
            x = int'(sx) - int'(cx); y = int'(sy) - int'(cy);
            col = ((x * int'(c) + y * int'(s) + 128) >>> 8) + 16;
            row = ((y * int'(c) - x * int'(s) + 128) >>> 8) + 16;
            index = 0;
            if (col >= 0 && col < 32 && row >= 0 && row < 32) index = int'(bitmap[row*32+col]);
            road = sx >= 48 && sx < 592 && sy >= 48 && sy < 432 &&
                   !(sx >= 144 && sx < 496 && sy >= 144 && sy < 336);
            finish_line = sx >= 312 && sx < 328 && sy >= 48 && sy < 144;
            for (int j = 3; j > 0; j--) expected[j] = expected[j-1];
            if (!visible) expected[0] = 0;
            else if (arch_opaque) expected[0] = arch_rgb;
            else if (index != 0) expected[0] = palette[index];
            else if (finish_line) expected[0] = (sx[3] ^ sy[3]) ? 24'hffffff : 24'h101010;
            else expected[0] = road ? 24'h454951 : 24'h287348;
            @(posedge clk); #1;
            if (n >= 3 && rgb !== expected[3])
                $fatal(1, "Pixel %0d: got %h expected %h", n, rgb, expected[3]);
        end
        $display("PASS: 10000 pipelined pixels, rotations, blanking and composition");
        $finish;
    end
endmodule
