// Prototype track: an outer rectangle with a grass infield.
module track_renderer (
    input logic signed [10:0] sx, sy, car_center_x, car_center_y,
    input logic visible,
    output logic [3:0] color_index
);
    logic outer, infield, car;
    assign outer = sx >= 48 && sx < 592 && sy >= 48 && sy < 432;
    assign infield = sx >= 144 && sx < 496 && sy >= 144 && sy < 336;
    assign car = sx >= car_center_x-12 && sx < car_center_x+12 &&
                 sy >= car_center_y-7 && sy < car_center_y+7;

    always_comb begin
        if (!visible) color_index = 0;
        else if (car) color_index = 1;
        else if (outer && !infield) color_index = 5;
        else color_index = 2;
    end
endmodule
