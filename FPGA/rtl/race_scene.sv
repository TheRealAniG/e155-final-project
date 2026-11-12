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
    logic [23:0] background, background_q [0:3];
    logic [23:0] arch_rgb_q [0:3];
    logic [3:0] visible_q, arch_opaque_q;

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

    // Match the sprite's four stages using the same input pixel.
    always_comb begin
        if (finish_line) background = light_square ? 24'hffffff : 24'h101010;
        else if (road) background = 24'h454951;
        else background = 24'h287348;
    end
    always_ff @(posedge clk_pix) begin
        visible_q <= {visible_q[2:0], visible};
        arch_opaque_q <= {arch_opaque_q[2:0], arch_opaque};
        background_q[0] <= background;
        arch_rgb_q[0] <= arch_rgb;
        for (int i = 1; i < 4; i++) begin
            background_q[i] <= background_q[i-1];
            arch_rgb_q[i] <= arch_rgb_q[i-1];
        end
    end

    //Pixel priority: blanking, overhead arches, car, finish, road, grass
    always_comb begin
        if (!visible_q[3]) rgb = 24'h000000;
        else if (arch_opaque_q[3]) rgb = arch_rgb_q[3];
        else if (opaque) rgb = car_rgb;
        else rgb = background_q[3];
    end
endmodule
