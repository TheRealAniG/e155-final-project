//Name: Thiven Anderson
//Email: thanderson@g.hmc.edu
//Date: 9/12/2026
//Description: Generic enabled counter with active-low reset
module lab2_ta_counter #(
    parameter int WIDTH = 23,
    parameter int MAX_COUNT = 5_000_399
) (
    input  logic clk, reset, enable,
    output logic [WIDTH-1:0] counter
);
    //Counter timing
    always_ff @(posedge clk or negedge reset) begin
        if (!reset)
            counter <= '0;
        else if (enable) begin
            if (counter == MAX_COUNT)
                counter <= '0;
            else
                counter <= counter + 1'b1;
        end
    end
endmodule
