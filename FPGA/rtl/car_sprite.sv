// Present address for the next horizontal pixel before its rising clock edge.
// During visible video the raster advances by one column on that edge.
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
    initial begin
        $readmemh(BITMAP, pixels);
        $readmemh(PALETTE, colors);
    end

    logic signed [12:0] dx, dy;
    logic signed [23:0] col, row;
    assign dx = sx + 1 - car_center_x;
    assign dy = sy - car_center_y;
    // Inverse map, round to nearest texel, then shift origin into the ROM.
    assign col = ((dx*cos_q8 + dy*sin_q8 + 24'sd128) >>> 8) + 24'sd16;
    assign row = ((dy*cos_q8 - dx*sin_q8 + 24'sd128) >>> 8) + 24'sd16;
    logic covered, covered_q;
    logic [3:0] index_q;
    assign covered = col >= 0 && col < 32 && row >= 0 && row < 32;

    always_ff @(posedge clk_pix) begin
        index_q <= pixels[{row[4:0], col[4:0]}];
        covered_q <= covered;
    end
    assign opaque = covered_q && index_q != 0;
    assign rgb = colors[index_q];
endmodule
