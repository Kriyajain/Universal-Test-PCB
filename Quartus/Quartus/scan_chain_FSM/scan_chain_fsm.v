module scan_chain_fsm (
  input wire clk,
  input wire key,         // Active-low key input (e.g., KEY0 from FPGA)
  output reg clk_out,     // Divided clock output
  output reg din,         // Serial data out
  output reg reset,        // Reset for scan chain
  output reg [2:0] state
);

parameter CLK_DIV = 128;
reg [6:0] clk_count = 0;
reg clk_out_int = 0;

reg [7:0] data = 8'b00011100;
reg [3:0] bit_index = 0;
reg [3:0] reset_counter = 0;
reg flag = 0;

//reg [2:0] state = 3'b000;
reg [2:0] next_state = 3'b000;

// FSM states
parameter IDLE  = 3'b000;
parameter START = 3'b001;
parameter RESET = 3'b010;
parameter SHIFT = 3'b011;

initial begin
state = IDLE;
next_state = IDLE;
clk_out <= 0;
din<=0;
reset <= 0;
flag <=0;
end

// clock Divider to Generate clk_out

always @(posedge clk) begin
		if (key == 1)
			flag <=0;
		if (state == START)
			flag <=1;

		clk_count <= clk_count+1;

		clk_out <= clk_count [6];

end

// FSM outputs and behavior
always @(negedge clk_out) begin

	  case (state)
		 IDLE: begin
			reset <= 0;
			din <= 1;
			bit_index <= 0;
			reset_counter <= 0;
			if (key == 0 && flag == 0) begin
			state <=START;
			end
			else	
			state <= IDLE;
		 end

		 START: begin
			reset <= 1;
			state <= RESET;
		 end

		 RESET: begin
			reset <= 1;
			reset_counter <= reset_counter + 1;
			if (reset_counter == 10) begin
				state <= SHIFT;
				din <= data[bit_index];
				bit_index <= bit_index + 1;
				reset<=0;
				end
			else
				state<=RESET;
		 end

		 SHIFT: begin
			reset <= 0;
			din <= data[bit_index];
			bit_index <= bit_index + 1;
			if(bit_index == 8) begin
				state <= IDLE;
				reset <= 0;
				din <= 1;
				bit_index <= 0;
				reset_counter <= 0;
			end
			else
				state <= SHIFT;
				
			
		 end
		 
		 default: next_state <= IDLE;
		 
	  endcase
end

endmodule
