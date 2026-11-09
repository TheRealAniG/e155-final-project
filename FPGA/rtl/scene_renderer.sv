module scene_renderer (
    input  logic [9:0] x, y, car_center_x, car_center_y,
    input  logic       visible,
    output logic [3:0] color_index
);
    // TODO: choose background or foreground. Reserve index zero for output black.
    // Physical RGB conversion belongs to the palette/output stage.
endmodule
