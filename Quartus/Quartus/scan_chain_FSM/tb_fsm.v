//module tb_fsm;
//
//reg clk = 0;
//reg key = 1;        // Active-low: 1 = not pressed, 0 = pressed
//wire clk_out, din, reset;
//wire [2:0] state;
//
//scan_chain_fsm dut (
//  .clk(clk),
//  .key(key),
//  .clk_out(clk_out),
//  .din(din),
//  .reset(reset),
//  .state(state)
//);
//
//// 50 MHz clock (period = 20 ns)
//always #10 clk = ~clk;
//
//// Stimulus
//initial begin
////  $dumpfile("fsm.vcd");  // For GTKWave
////  $dumpvars(0, tb_fsm);
//
//  // Initially idle
//  #10000;
//
//  // Simulate key press (start)
//  key = 0;
//  #4000;    // Key press duration
//  key = 1;
//
//  // Wait enough time for FSM to go through all stages
//  #500000;
//
//  $finish;
//end
//
//endmodule
