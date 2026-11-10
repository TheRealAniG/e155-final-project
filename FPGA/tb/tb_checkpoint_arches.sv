module tb_checkpoint_arches;
    timeunit 1ns;
    timeprecision 1ps;
    logic signed [10:0] sx, sy;
    logic opaque;
    logic [23:0] rgb;
    checkpoint_arches dut (.sx(sx), .sy(sy), .opaque(opaque), .rgb(rgb));
    task automatic check(input int x, y, input bit covered,
                         input logic [23:0] color);
        sx = x;
        sy = y;
        #1ns;
        if (opaque !== covered || (covered && rgb !== color))
            $fatal(1, "Arch pixel (%0d,%0d): opaque=%b rgb=%h", x, y, opaque, rgb);
    endtask
    initial begin
        check(544, 236, 0, 0);
        check(544, 237, 1, 24'hf4f4f4);
        check(552, 240, 1, 24'hffcc33);
        check(544, 242, 1, 24'hf4f4f4);
        check(544, 243, 0, 0);
        check(488, 232, 1, 24'h242a35);
        check(496, 232, 0, 0); // opening between posts
        check(592, 247, 1, 24'h242a35);
        check(96, 240, 1, 24'hf4f4f4);
        check(40, 232, 1, 24'h242a35);
        check(320, 384, 1, 24'hf4f4f4);
        check(320, 392, 1, 24'hffcc33);
        check(316, 384, 0, 0);
        check(323, 384, 0, 0);
        check(312, 328, 1, 24'h242a35);
        check(327, 439, 1, 24'h242a35);
        check(-1, -1, 0, 0);
        $display("PASS: checkpoint beams, stripes, posts, and openings");
        $finish;
    end
endmodule
