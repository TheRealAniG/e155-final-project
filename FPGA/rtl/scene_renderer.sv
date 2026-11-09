// Four vertical color bars with a one-pixel white border.
// Palette convention: 0 = black, 1 = red, 2 = green, 3 = blue,
// 4 = yellow, 15 = white. The output stage maps indices to RGB.
module scene_renderer (
    input  logic signed [10:0] sx, sy,
    input  logic               visible,
    output logic         [3:0] color_index
);
    localparam logic [3:0] BLACK  = 4'd0,
                           RED    = 4'd1,
                           GREEN  = 4'd2,
                           BLUE   = 4'd3,
                           YELLOW = 4'd4,
                           WHITE  = 4'd15;

    always_comb begin
        if (!visible)
            color_index = BLACK;
        else if (sx == 0 || sx == 639 || sy == 0 || sy == 479)
            color_index = WHITE;
        else if (sx < 160)
            color_index = RED;
        else if (sx < 320)
            color_index = GREEN;
        else if (sx < 480)
            color_index = BLUE;
        else
            color_index = YELLOW;
    end
endmodule
