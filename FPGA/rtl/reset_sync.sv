//Description: Active-low reset with asynchronous assertion and synchronous release
module reset_sync (
    input  logic clk,
    input  logic reset_n,
    output logic reset_sync_n
);
    (* syn_preserve = 1 *) logic reset_meta_n;

    //Reset timing
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reset_meta_n <= 1'b0;
            reset_sync_n <= 1'b0;
        end else begin
            reset_meta_n <= 1'b1;
            reset_sync_n <= reset_meta_n;
        end
    end
endmodule
