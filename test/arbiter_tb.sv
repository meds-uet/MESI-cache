`timescale 1ns/1ps

module arbiter_tb;
    reg [3:0] Com_Bus_Req_proc;
    reg [3:0] Com_Bus_Req_snoop;
    reg Mem_snoop_req;
    reg rst;
    wire [3:0] Com_Bus_Gnt_proc;
    wire [3:0] Com_Bus_Gnt_snoop;
    wire Mem_snoop_gnt;
    //wire [3:0] fifo_data_in; // Added to monitor FIFO data input

    // Instantiate the arbiter module
    arbiter uut (
        .Com_Bus_Req_proc(Com_Bus_Req_proc),
        .Com_Bus_Req_snoop(Com_Bus_Req_snoop),
        .Mem_snoop_req(Mem_snoop_req),
        .Com_Bus_Gnt_proc(Com_Bus_Gnt_proc),
        .Com_Bus_Gnt_snoop(Com_Bus_Gnt_snoop),
        .Mem_snoop_gnt(Mem_snoop_gnt)
        //.fifo_data_in(fifo_data_in) // Added output for monitoring
    );

    // Clock generation
    reg clk;
    always begin
        #5 clk = ~clk;  // 10ns clock period
    end

    // Initial setup
    initial begin
        clk = 0;
        rst = 1;
        #10 rst = 0;    // Release reset after 10ns

        // Test cases
        test_case_1;
        test_case_2;
        test_case_3;
        test_case_4;
        test_case_5;

        #50 $stop;      // Stop the simulation
    end

    // Task for each test case
    task test_case_1;
        // Test 1: Processor request with no snoop or memory requests
        #10; // Wait for a clock cycle
        Com_Bus_Req_proc = 4'b0001;   // Only Processor 0 requests
        Com_Bus_Req_snoop = 4'b0000;
        Mem_snoop_req = 1'b0;
        #20; // Wait 10ns
        assert(Com_Bus_Gnt_proc[0]) else $display("Test 1 Failed at time %t", $time);
        Com_Bus_Req_proc = 4'b0000;   // Clear request
        #10; 
    endtask

    task test_case_2;
        // Test 2: Snoop request has higher priority than processor request
        #10;
        Com_Bus_Req_proc = 4'b0010;   // Processor 1 requests
        Com_Bus_Req_snoop = 4'b0001;  // Snoop 0 requests
        Mem_snoop_req = 1'b0;
        #20;
        assert(Com_Bus_Gnt_snoop[0]) else $display("Test 2 Failed at time %t", $time);
        Com_Bus_Req_snoop = 4'b0000;
        #20
        Com_Bus_Req_proc = 4'b0000;   // Clear request
          // Clear request
        #10;
    endtask

    task test_case_3;
         // Test 3: Memory snoop has highest priority
    #10;
    Com_Bus_Req_proc = 4'b0100;   // Processor 2 requests
    Com_Bus_Req_snoop = 4'b0010;  // Snoop 1 requests
    Mem_snoop_req = 1'b1;         // Memory requests
    #30;
    assert(Mem_snoop_gnt) else $display("Test 3 Failed at time %t", $time);
    Mem_snoop_req = 1'b0;  
    #30
    Com_Bus_Req_snoop = 4'b0000; 
    #20
    Com_Bus_Req_proc = 4'b0000; 
          // Clear request 
    #10;
    endtask

    task test_case_4;
        // Test 4: Multiple processor requests, no snoop or memory requests
    #10;
    Com_Bus_Req_proc = 4'b1010;   // Processors 1 and 3 request
    Com_Bus_Req_snoop = 4'b0000;
    Mem_snoop_req = 1'b0;
    #20;
    assert(Com_Bus_Gnt_proc[1] || Com_Bus_Gnt_proc[3]) else $display("Test 4 Failed at time %t", $time);
    Com_Bus_Req_proc[1] = 1'b0;
    #20;
    Com_Bus_Req_proc = 4'b0000;   // Clear request
    
    #10;
    endtask

    task test_case_5;
        // Test 5: Multiple requests including memory, snoop, and processors
#10;
                Com_Bus_Req_proc = 4'b1111;   // All processors request
                Com_Bus_Req_snoop = 4'b0101;  // Snoops 0 and 2 request
                Mem_snoop_req = 1'b1;         // Memory requests
                #50;
                assert(Mem_snoop_gnt) else $display("Test 5 Failed at time %t", $time); // Memory should be granted first
                Mem_snoop_req = 1'b0;
                
                #40;
                assert(Com_Bus_Gnt_snoop[0] || Com_Bus_Gnt_snoop[2]) else $display("Test 5 Failed at time %t", $time);
                Com_Bus_Req_snoop[0] = 4'b0000; // Clear snoop
                 #10
                       Com_Bus_Req_snoop[2] = 4'b0000; // Clear snoop
                #40
                Com_Bus_Req_proc[0] = 4'b0000; 
                #10
                Com_Bus_Req_proc[1] = 4'b0000; 
                 #10
                Com_Bus_Req_proc[2] = 4'b0000; 
                #10
                Com_Bus_Req_proc[3] = 4'b0000; 
                #10;
            endtask
endmodule
