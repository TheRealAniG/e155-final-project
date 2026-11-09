// Present address for the next horizontal pixel before its rising clock edge.
// During visible video the raster advances by one column on that edge.
module car_sprite #(
    parameter BITMAP = "car.mem",
    parameter PALETTE = "car_palette.mem"
) (
    input logic clk_pix,
    input logic signed [10:0] sx, sy, car_center_x, car_center_y,
    output logic opaque,
    output logic [23:0] rgb
);
    logic [3:0] pixels [0:1023];
    logic [23:0] colors [0:15];
    initial begin
        $readmemh(BITMAP, pixels);
        $readmemh(PALETTE, colors);
    end

    logic signed [12:0] col, row;
    assign col = sx + 1 - car_center_x + 16;
    assign row = sy - car_center_y + 16;
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
