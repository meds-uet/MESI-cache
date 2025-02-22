

interface core_interface(input logic clk);

    logic rst;
      
    logic [3:0] read ,write;
    logic [31:0] pr_addr[3:0];
    logic [31:0] pr_data[3:0];
    logic [3:0] Core_send;
    logic [3:0] c_flush;
    logic [127:0] mem_read_data;
    logic mem_ready;

    logic [31:0] data_out_pr [3:0];
    logic stall;
    logic stall_1;
    logic stall_2;
    logic stall_3;
    logic write_signal;
  
  
endinterface: core_interface