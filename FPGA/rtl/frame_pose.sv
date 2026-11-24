// Keep the newest received pose pending; publish all fields at vertical blank.
// Before the first committed packet, pass through the autonomous demo pose.
module frame_pose (
    input logic clk, reset_n, vblank_tick, pose_valid,
    input logic signed [10:0] pose_x, pose_y, demo_x, demo_y,
    input logic signed [9:0] pose_cos, pose_sin, demo_cos, demo_sin,
    output logic spi_active,
    output logic signed [10:0] car_x, car_y,
    output logic signed [9:0] car_cos, car_sin
);
    logic pending;
    logic signed [10:0] pending_x, pending_y, active_x, active_y;
    logic signed [9:0] pending_cos, pending_sin, active_cos, active_sin;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pending <= 0; spi_active <= 0;
            pending_x <= 96; pending_y <= 96; pending_cos <= 256; pending_sin <= 0;
            active_x <= 96; active_y <= 96; active_cos <= 256; active_sin <= 0;
        end else begin
            if (pose_valid) begin
                pending_x <= pose_x; pending_y <= pose_y;
                pending_cos <= pose_cos; pending_sin <= pose_sin;
                pending <= 1;
            end
            if (vblank_tick && (pending || pose_valid)) begin
                // Same-edge receive wins over older pending data.
                active_x <= pose_valid ? pose_x : pending_x;
                active_y <= pose_valid ? pose_y : pending_y;
                active_cos <= pose_valid ? pose_cos : pending_cos;
                active_sin <= pose_valid ? pose_sin : pending_sin;
                pending <= 0;
                spi_active <= 1;
            end
        end
    end
    assign car_x = spi_active ? active_x : demo_x;
    assign car_y = spi_active ? active_y : demo_y;
    assign car_cos = spi_active ? active_cos : demo_cos;
    assign car_sin = spi_active ? active_sin : demo_sin;
endmodule
