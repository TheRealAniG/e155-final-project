// The demo car follows the center of a rectangular track, clockwise.
module demo_motion (
    input logic clk_pix, reset_n, vblank_tick,
    output logic signed [10:0] car_center_x, car_center_y
);
    localparam int LEFT=96, RIGHT=544, TOP=96, BOTTOM=384, STEP=4;
    typedef enum logic [1:0] {EAST, SOUTH, WEST, NORTH} direction_t;
    direction_t direction, next_direction;
    logic signed [10:0] next_x, next_y;

    always_comb begin
        next_x = car_center_x;
        next_y = car_center_y;
        next_direction = direction;
        case (direction)
            EAST: begin
                next_x = car_center_x + STEP;
                if (next_x >= RIGHT) begin
                    next_x = RIGHT;
                    next_direction = SOUTH;
                end
            end
            SOUTH: begin
                next_y = car_center_y + STEP;
                if (next_y >= BOTTOM) begin
                    next_y = BOTTOM;
                    next_direction = WEST;
                end
            end
            WEST: begin
                next_x = car_center_x - STEP;
                if (next_x <= LEFT) begin
                    next_x = LEFT;
                    next_direction = NORTH;
                end
            end
            NORTH: begin
                next_y = car_center_y - STEP;
                if (next_y <= TOP) begin
                    next_y = TOP;
                    next_direction = EAST;
                end
            end
        endcase
    end

    always_ff @(posedge clk_pix or negedge reset_n) begin
        if (!reset_n) begin
            car_center_x <= LEFT;
            car_center_y <= TOP;
            direction <= EAST;
        end else if (vblank_tick) begin
            car_center_x <= next_x;
            car_center_y <= next_y;
            direction <= next_direction;
        end
    end
endmodule
