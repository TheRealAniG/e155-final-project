//Description: Compose track, finish line, car sprite, and checkpoint arches
module race_scene #(
    parameter BITMAP = "car.mem",
    parameter PALETTE = "car_palette.mem"
) (
    input logic clk_pix, visible,
    input logic signed [10:0] sx, sy, car_center_x, car_center_y,
    input logic signed [9:0] cos_q8, sin_q8,
    output logic [23:0] rgb
);
    logic road, finish_line, light_square;
    logic opaque, arch_opaque;
    logic [23:0] car_rgb, arch_rgb;

    function automatic logic inside_rect(input integer x, y, left, top, right, bottom);
        return x >= left && x < right && y >= top && y < bottom;
    endfunction

    //Track geometry
    assign road = inside_rect(sx, sy, 48, 48, 592, 432) &&
                 !inside_rect(sx, sy, 144, 144, 496, 336);
    assign finish_line = inside_rect(sx, sy, 312, 48, 328, 144);
    assign light_square = sx[3] ^ sy[3]; // eight-pixel checker squares
    //Car sprite
    car_sprite #(
        .BITMAP(BITMAP),
        .PALETTE(PALETTE)
    ) i_CAR_SPRITE (
        .clk_pix(clk_pix),
        .sx(sx),
        .sy(sy),
        .car_center_x(car_center_x),
        .car_center_y(car_center_y),
        .cos_q8(cos_q8),
        .sin_q8(sin_q8),
        .opaque(opaque),
        .rgb(car_rgb)
    );

    //Checkpoint arches
    checkpoint_arches i_CHECKPOINT_ARCHES (
        .sx(sx),
        .sy(sy),
        .opaque(arch_opaque),
        .rgb(arch_rgb)
    );

    //Pixel priority: blanking, overhead arches, car, finish, road, grass
    always_comb begin
        if (!visible) rgb = 24'h000000;
        else if (arch_opaque) rgb = arch_rgb;
        else if (opaque) rgb = car_rgb;
        else if (finish_line) rgb = light_square ? 24'hffffff : 24'h101010;
        else if (road) rgb = 24'h454951;
        else rgb = 24'h287348;
    end
endmodule
