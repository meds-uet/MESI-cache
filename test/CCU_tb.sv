module CCU_tb;

  // Clock and Reset
  logic clk;
  logic rst;

  // Inputs to the CCU
  logic read;
  logic write;
  logic cache_hit;
  logic cache_miss;
  logic [31:0] pr_addr;
  logic [31:0] pr_data;
  logic bs_resp1, bs_resp2, bs_resp3, bs_resp4;
  logic l2_ready;
  logic [127:0] l2_data;
  logic core1_valid, core2_valid, core3_valid, core4_valid;
  logic [31:0] snoop_data;
  logic [1:0] req_core;
  logic [127:0] cache_data1, cache_data2, cache_data3, cache_data4;
  logic [1:0] cache_upd_state_core1, cache_upd_state_core2, cache_upd_state_core3, cache_upd_state_core4;
  logic [1:0] cache_state_core1, cache_state_core2, cache_state_core3, cache_state_core4;

  // Outputs from the CCU
  logic bs_req;
  logic l2_write_req;
  logic l2_read_req;
  logic [127:0] write_data;
  logic [31:0] data_out_CCU;
  logic [7:0] CCU_index;
  logic CCU_ready;
  logic start;

  // Instantiate the CCU module
  CCU dut (
    .clk(clk),
    .rst(rst),
    .read(read),
    .write(write),
    .cache_hit(cache_hit),
    .cache_miss(cache_miss),
    .pr_addr(pr_addr),
    .pr_data(pr_data),
    .bs_resp1(bs_resp1),
    .bs_resp2(bs_resp2),
    .bs_resp3(bs_resp3),
    .bs_resp4(bs_resp4),
    .l2_ready(l2_ready),
    .l2_data(l2_data),
    .snoop_data(snoop_data),
    .req_core(req_core),
    .cache_data1(cache_data1),
    .cache_data2(cache_data2),
    .cache_data3(cache_data3),
    .cache_data4(cache_data4),
    .cache_state_core1(cache_state_core1),
    .cache_state_core2(cache_state_core2),
    .cache_state_core3(cache_state_core3),
    .cache_state_core4(cache_state_core4),
    .bs_req(bs_req),
    .l2_write_req(l2_write_req),
    .l2_read_req(l2_read_req),
    .write_data(write_data),
    .data_out_CCU(data_out_CCU),
    .core1_valid(core1_valid),
    .core2_valid(core2_valid),
    .core3_valid(core3_valid),
    .core4_valid(core4_valid),
    .cache_upd_state_core1(cache_upd_state_core1),
    .cache_upd_state_core2(cache_upd_state_core2),
    .cache_upd_state_core3(cache_upd_state_core3),
    .cache_upd_state_core4(cache_upd_state_core4),
    .CCU_index(CCU_index),
    .start(start),
    .CCU_ready(CCU_ready)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10 time units clock period
  end
  
   initial begin
    // Open the VCD file for dumping
    $dumpfile("dump.vcd");  // VCD file name
    $dumpvars(0, CCU_tb);    // Dump all signals in CCU_tb module
end

  // Test sequence
  initial begin
    // Initialize signals
    rst = 1;
    pr_addr = 32'b0;
    pr_data = 32'b0;
    bs_resp1 = 1'b0;
    bs_resp2 = 1'b0;
    bs_resp3 = 1'b0;
    bs_resp4 = 1'b0;
    l2_ready = 0;
    l2_data = 128'b0;
    snoop_data = 32'b0;
    req_core = 2'b00;
    cache_data1 = 128'b0;
    cache_data2 = 128'b0;
    cache_data3 = 128'b0;
    cache_data4 = 128'b0;
    cache_state_core1 = 2'b11; // Invalid state initially
    cache_state_core2 = 2'b11;
    cache_state_core3 = 2'b11;
    cache_state_core4 = 2'b11;

    // Reset
    #10;
    rst = 0;

    // Test Case 1: Read miss, snoop hit from core 2
    pr_addr = 32'h0000_1234;
    req_core = 2'b00; 
    core2_valid = 1'b1; 
    bs_resp2 = 1'b1;  
    snoop_data = 32'hAAAA_BBBB;
    read = 1;
    cache_hit = 0;
    cache_miss = 1;
    l2_ready = 1'b0; 
    #20;
    if (data_out_CCU == snoop_data) begin
      $display("Test Case 1 Passed!");
    end else begin
      $error("Test Case 1 Failed!");
    end
    
    // Test Case 2: Write hit, L2 write
    read = 0;
    write = 1;
    cache_hit = 1;
    cache_miss = 0;
    l2_ready = 1'b1;
    cache_state_core1 = 2'b11; 
    cache_data1 = 128'h1111_2222_3333_4444_5555_6666_7777_8888;
    #60;
    if (write_data == cache_data1) begin
      $display("Test Case 2 Passed!");
    end else begin
      $error("Test Case 2 Failed!");
    end
   
    // Test Case 3: Read miss, data retrieved from L2
    write = 0;
    read = 1;
    cache_miss = 1;
    cache_hit = 0;
    bs_resp2 = 1'b0;
    core2_valid = 1'b0; 
    l2_ready = 1'b1;
    l2_data = 128'hDEAD_BEEF_CAFE_F00D_DEAD_BEEF_CAFE_F00D;
    #120;
    if (data_out_CCU == l2_data[127:96]) begin
      $display("Test Case 3 Passed!");
    end else begin
      $error("Test Case 3 Failed!");
    end
    
    // Test Case 4: Read hit, checking core state Shared
    read = 1;
    write = 0;
    cache_hit = 1;
    cache_miss = 0;
    req_core = 2'b01;
    cache_state_core2 = 2'b11;
    bs_resp2 = 1'b1;
    core2_valid = 1'b1;
    cache_data1 = 128'hDEAD_BEEF_CAFE_F00D_DEAD_BEEF_CAFE_F00D; 
    #20;
    if (cache_upd_state_core2 == 2'b10) begin 
      $display("Test Case 4 Passed!");
    end else begin
      $error("Test Case 4 Failed!");
    end

    // Test Case 5: Core 1 reads data and gets a cache miss
    pr_addr = 32'h0000_5678;
    req_core = 2'b01; 
    core1_valid = 1'b1; 
    cache_hit = 0;
    cache_miss = 1;
    l2_ready = 1'b1;
    l2_data = 128'hAAAA_BBBB_CCCC_DDDD_1234_5678_9ABC_DEF0;
    #30;
    if (data_out_CCU == 32'hCCCC_DDDD) begin
      $display("Test Case 5 Passed!");
    end else begin
      $error("Test Case 5 Failed!");
    end

    // Test Case 6: Core 4 write-back to L2 and cache invalidation
    write = 1;
    read = 0;
    req_core = 2'b11; // Core 4
    cache_data4 = 128'h1234_5678_9ABC_DEF0_1111_2222_3333_4444;
    cache_hit = 1;
    cache_miss = 0;
    l2_ready = 1'b1;
    #40;
    if (l2_write_req == 1'b1) begin
      $display("Test Case 6 Passed!");
    end else begin
      $error("Test Case 6 Failed!");
    end

    // Test Case 6: Core 4 write-back to L2 and cache invalidation
    write = 1;
    read = 0;
    req_core = 2'b11; // Core 4
    cache_data4 = 128'h1234_5678_9ABC_DEF0_1111_2222_3333_4444;
    cache_hit = 1;
    cache_miss = 0;
    l2_ready = 1'b1;
    pr_addr = 32'h0000_1235;
    #10;
    pr_addr = 32'h0000_1237;
    #50 $finish;
  end

endmodule
