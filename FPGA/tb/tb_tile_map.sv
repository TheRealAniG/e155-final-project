// Independent pixel oracle for asphalt, sand shoulders, and alternating wall.
module tb_tile_map;
    timeunit 1ns; timeprecision 1ps;
    logic clk = 0, visible = 0;
    logic signed [10:0] sx = 0, sy = 0;
    logic [23:0] rgb, fixture_rgb;
    int checks = 0;
    always #5 clk = ~clk;
    tile_map_renderer dut (.clk_pix(clk), .visible(visible), .sx(sx), .sy(sy), .rgb(rgb));
    tile_map_renderer #(.MAP_FILE("../../tb/tile_fixture.mem")) fixture
        (.clk_pix(clk), .visible(visible), .sx(sx), .sy(sy), .rgb(fixture_rgb));

    function automatic logic [23:0] reference_pixel(input int x, y, input bit v);
        if (!v || x < 0 || x >= 640 || y < 0 || y >= 480) return 0;
        if (x >= 48 && x < 592 && y >= 48 && y < 432 &&
            !(x >= 144 && x < 496 && y >= 144 && y < 336)) return 24'h454951;
        if (x >= 16 && x < 624 && y >= 16 && y < 464 &&
            !(x >= 32 && x < 608 && y >= 32 && y < 448))
            return ((x / 16 + y / 16) % 2) ? 24'hf4f4f4 : 24'hd93636;
        if ((x >= 32 && x < 608 && y >= 32 && y < 448 &&
             !(x >= 48 && x < 592 && y >= 48 && y < 432)) ||
            (x >= 144 && x < 496 && y >= 144 && y < 336 &&
             !(x >= 160 && x < 480 && y >= 160 && y < 320))) return 24'hd9bd80;
        return 24'h287348;
    endfunction
    task automatic check(input int x, y, input bit v);
        @(negedge clk);
        sx = 11'(x); sy = 11'(y); visible = v;
        @(posedge clk); #1;
        if (rgb !== reference_pixel(x, y, v))
            $fatal(1, "Map pixel (%0d,%0d) visible=%b got %h", x, y, v, rgb);
        checks++;
    endtask
    initial begin
        // A discontinuous scan catches address and row-boundary mistakes.
        for (int x = 0; x < 640; x++)
            for (int y = 0; y < 480; y++) check(x, y, 1);
        check(-1, 0, 1); check(0, -1, 1); check(640, 0, 1);
        check(0, 480, 1); check(1023, 1023, 1); check(100, 100, 0);
        check(0, 0, 1); check(639, 479, 1); check(-160, -45, 0);
        check(96, 96, 1);
        // Fixture first row: grass, asphalt, gravel, red/white walls, invalid ID.
        for (int id = 0; id < 6; id++) begin
            check(id * 16, 0, 1);
            case (id)
                0: if (fixture_rgb !== 24'h287348) $fatal(1, "Grass palette");
                1: if (fixture_rgb !== 24'h454951) $fatal(1, "Asphalt palette");
                2: if (fixture_rgb !== 24'hd9bd80) $fatal(1, "Sand gravel palette");
                3: if (fixture_rgb !== 24'hd93636) $fatal(1, "Red wall palette");
                4: if (fixture_rgb !== 24'hf4f4f4) $fatal(1, "White wall palette");
                5: if (fixture_rgb !== 24'hff00ff) $fatal(1, "Invalid ID palette");
            endcase
        end
        check(16, 0, 0);
        if (fixture_rgb !== 0) $fatal(1, "Fixture blanking");
        $display("PASS: %0d map checks, all pixels, bounds, tile colors, one-stage latency", checks);
        $finish;
    end
endmodule
