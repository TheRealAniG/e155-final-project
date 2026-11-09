module race_scene #(
    parameter BITMAP = "car.mem",
    parameter PALETTE = "car_palette.mem"
) (
    input logic clk_pix, visible,
    input logic signed [10:0] sx, sy, car_center_x, car_center_y,
    output logic [23:0] rgb
);
    function automatic logic inside_rect(input integer x, y, left, top, right, bottom);
        return x >= left && x < right && y >= top && y < bottom;
    endfunction
    logic road, finish_line, light_square;
    assign road = inside_rect(sx, sy, 48, 48, 592, 432) &&
                 !inside_rect(sx, sy, 144, 144, 496, 336);
    assign finish_line = inside_rect(sx, sy, 312, 48, 328, 144);
    assign light_square = sx[3] ^ sy[3]; // eight-pixel checker squares
    logic opaque;
    logic [23:0] car_rgb;
    car_sprite #(.BITMAP(BITMAP), .PALETTE(PALETTE)) car (
        .clk_pix, .sx, .sy, .car_center_x, .car_center_y, .opaque, .rgb(car_rgb)
    );
    always_comb begin
        if (!visible) rgb = 24'h000000;
        else if (opaque) rgb = car_rgb;
        else if (finish_line) rgb = light_square ? 24'hffffff : 24'h101010;
        else if (road) rgb = 24'h454951;
        else rgb = 24'h287348;
    end
endmodule
