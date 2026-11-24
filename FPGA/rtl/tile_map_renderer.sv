// One synchronous ROM read; rgb belongs to the pixel sampled at the last edge.
// 16x16 tiles, 40 columns, 30 rows. No framebuffer or address multiplier.
module tile_map_renderer #(
    parameter MAP_FILE = "../../assets/maps/rectangle.mem"
) (
    input logic clk_pix, visible,
    input logic signed [10:0] sx, sy,
    output logic [23:0] rgb
);
    (* syn_ramstyle = "block_ram" *) logic [7:0] tiles [0:1199];
    logic [10:0] address;
    logic [7:0] tile_q;
    logic valid, valid_q;
    logic [10:0] tile_row;
    logic [23:0] tile_rgb;

    initial $readmemh(MAP_FILE, tiles);

    assign valid = visible && sx >= 0 && sx < 640 && sy >= 0 && sy < 480;
    assign tile_row = {6'b0, sy[8:4]};
    // row*40 = row*32 + row*8; slice coordinates only after range checking.
    assign address = valid ? (tile_row << 5) + (tile_row << 3) +
                             {5'b0, sx[9:4]} : 11'd0;
    always_ff @(posedge clk_pix) begin
        tile_q <= tiles[address];
        valid_q <= valid;
    end
    tile_palette i_TILE_PALETTE (.tile_id(tile_q), .rgb(tile_rgb));
    assign rgb = valid_q ? tile_rgb : 24'h000000;
endmodule
