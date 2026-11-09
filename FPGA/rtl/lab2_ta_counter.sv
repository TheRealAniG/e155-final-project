//Name: Thiven Anderson
//Email: thanderson@g.hmc.edu
//Date: 9/12/2026
//Description: Generic counter module
module lab2_ta_counter #(
		parameter int WIDTH = 23,
		parameter int MAX_COUNT = 5_000_399)(
		input logic clk, reset, enable,
		output logic [WIDTH-1:0] counter
		);
	
		
	always_ff @(posedge clk, negedge reset) begin
		
			if (!reset) 
				counter <= 0;
			 else if (enable) begin
				 if (counter == MAX_COUNT)
					counter <= 0;
				else 
					counter <= counter + 1'b1;
			end
			else
				counter <= counter;
	end
endmodule