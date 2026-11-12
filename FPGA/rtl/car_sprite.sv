//Description: Rotated synchronous-ROM car sprite with palette transparency
// Four clock stages: offsets, products, texel coordinates, ROM lookup.
module car_sprite #(
    parameter BITMAP = "car.mem",
    parameter PALETTE = "car_palette.mem"
) (
    input logic clk_pix,
    input logic signed [10:0] sx, sy, car_center_x, car_center_y,
    input logic signed [9:0] cos_q8, sin_q8,
    output logic opaque,
    output logic [23:0] rgb
);
    logic [3:0] pixels [0:1023];
    logic [23:0] colors [0:15];
    logic signed [12:0] dx, dy;
    logic signed [9:0] cos_q, sin_q;
    logic signed [23:0] dx_cos, dy_sin, dy_cos, dx_sin;
    logic signed [23:0] col, row;
    logic covered, covered_q;
    logic [3:0] index_q;

    //Sprite and palette initialization
    initial begin
        $readmemh(BITMAP, pixels);
        $readmemh(PALETTE, colors);
    end

    // Capture matching position and heading; extend before subtraction.
    always_ff @(posedge clk_pix) begin
        dx <= {{2{sx[10]}}, sx} - {{2{car_center_x[10]}}, car_center_x};
        dy <= {{2{sy[10]}}, sy} - {{2{car_center_y[10]}}, car_center_y};
        cos_q <= cos_q8;
        sin_q <= sin_q8;
        dx_cos <= dx * cos_q;
        dy_sin <= dy * sin_q;
        dy_cos <= dy * cos_q;
        dx_sin <= dx * sin_q;
        // Inverse map, round to nearest texel, then shift into the ROM.
        col <= ((dx_cos + dy_sin + 24'sd128) >>> 8) + 24'sd16;
        row <= ((dy_cos - dx_sin + 24'sd128) >>> 8) + 24'sd16;
    end
    assign covered = col >= 0 && col < 32 && row >= 0 && row < 32;

    //Synchronous pixel lookup
    always_ff @(posedge clk_pix) begin
        index_q <= pixels[{row[4:0], col[4:0]}];
        covered_q <= covered;
    end
    assign opaque = covered_q && index_q != 0;
    assign rgb = colors[index_q];
endmodule
