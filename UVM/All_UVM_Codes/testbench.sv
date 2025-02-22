// Quad Core Cache Coherence Verification
// Date: 21 January 2025


`timescale 1ns/1ns

import uvm_pkg::*;
`include "uvm_macros.svh"


//--------------------------------------------------------
//Include Files
//--------------------------------------------------------
`include "interface.sv"
`include "sequence_item.sv"
`include "sequence.sv"
`include "sequencer.sv"
`include "driver.sv"
`include "driver1.sv"
`include "driver2.sv"
`include "driver3.sv"
`include "monitor.sv"
`include "monitor1.sv"
`include "monitor2.sv"
`include "monitor3.sv"
`include "agent.sv"
`include "agent1.sv"
`include "agent2.sv"
`include "agent3.sv"
`include "scoreboard.sv"
`include "env.sv"
`include "test.sv"


module top;
  
  //--------------------------------------------------------
  //Instantiation
  //--------------------------------------------------------

  logic clk;
  
  core_interface intf(.clk(clk));
   
   // Instantiate top module
   top_module dut (
     .clk(intf.clk),
        .rst(intf.rst),
        .read(intf.read),
        .write(intf.write),
        .pr_addr(intf.pr_addr),
        .pr_data(intf.pr_data),
        .Core_send(intf.Core_send),
        .c_flush(intf.c_flush),
        .mem_read_data(intf.mem_read_data),
        .mem_ready(intf.mem_ready),
        .data_out_pr(intf.data_out_pr),
        .write_signal(intf.write_signal),
        .stall(intf.stall),
        .stall_1(intf.stall_1),
        .stall_2(intf.stall_2),
        .stall_3(intf.stall_3)
    );
  
  
  //--------------------------------------------------------
  //Interface Setting
  //--------------------------------------------------------
  initial begin
    uvm_config_db #(virtual core_interface)::set(null, "*", "vif", intf );
    //-- Refer: https://www.synopsys.com/content/dam/synopsys/services/whitepapers/hierarchical-testbench-configuration-using-uvm.pdf
  end
  
  
  
  //--------------------------------------------------------
  //Start The Test
  //--------------------------------------------------------
  initial begin
    run_test("core_test");
  end

  
  
  //--------------------------------------------------------
  //Clock Generation
  //--------------------------------------------------------
  initial begin
    clk = 0;
    #5;
    forever begin
      clk = ~clk;
      #2;
    end
  end
  
  
  //--------------------------------------------------------
  //Maximum Simulation Time
  //--------------------------------------------------------
  initial begin
    #5000;
    $display("Sorry! Ran out of clock cycles!");
    $finish();
  end
  
  
  //--------------------------------------------------------
  //Generate Waveforms
  //--------------------------------------------------------
  initial begin
    $dumpfile("d.vcd");
    $dumpvars();
  end
  
  
  
endmodule: top