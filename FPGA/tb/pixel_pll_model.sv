// Simulation-only functional model of the working 12 MHz -> 24 MHz IP.
// Models reset/lock startup, not analog jitter, loss of reference, or PLL timing.
module pixel_pll (
    input logic ref_clk_i, rst_n_i,
    output logic lock_o = 0,
    output wire outcore_o, outglobal_o
);
    timeunit 1ns; timeprecision 1ps;
    logic osc = 0;
    int lock_count = 0;
    always #20.833 osc = ~osc;
    always @(posedge ref_clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin lock_count <= 0; lock_o <= 0; end
        else if (lock_count < 8) begin
            lock_count <= lock_count + 1;
            if (lock_count == 7) lock_o <= 1;
        end
    end
    assign outglobal_o = rst_n_i ? osc : 1'b0;
    assign outcore_o = outglobal_o;
endmodule
