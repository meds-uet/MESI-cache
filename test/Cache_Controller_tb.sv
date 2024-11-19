module tb_Cache_Controller_0;

    // Clock and reset signals
    logic clk;
    logic rst;

    // Input and output signals for Cache_Controller_0
    logic read, write, c_flush, start, Core_send;
    logic [31:0] pr_addr, pr_data, data_out_CCU;
    logic bs_req;
    logic [1:0] cache_upd_state_core;
    logic CCU_ready;
    logic [31:0] snoop_address;

    // Outputs
    logic cache_hit, cache_miss;
    logic [31:0] data_out_pr, data_out, snoop_data;
    logic bs_resp, core_valid, Cache_Ready, stall;
    logic [127:0] cache_data;
    logic [1:0] cache_state_core;

    // Instantiate the module under test
    Cache_Controller_0 uut (
        .clk(clk),
        .rst(rst),
        .read(read),
        .write(write),
        .pr_addr(pr_addr),
        .pr_data(pr_data),
        .c_flush(c_flush),
        .data_out_CCU(data_out_CCU),
        .bs_req(bs_req),
        .cache_upd_state_core(cache_upd_state_core),
        .CCU_ready(CCU_ready),
        .start(start),
        .snoop_address(snoop_address),
        .Core_send(Core_send),
        .cache_hit(cache_hit),
        .cache_miss(cache_miss),
        .data_out_pr(data_out_pr),
        .data_out(data_out),
        .bs_resp(bs_resp),
        .cache_data(cache_data),
        .core_valid(core_valid),
        .cache_state_core(cache_state_core),
        .snoop_data(snoop_data),
        .Cache_Ready(Cache_Ready),
        .stall(stall)
    );

     // Clock generation
    initial begin
      clk = 0;
      forever #5 clk = ~clk; 
    end

    // Task to initialize inputs
    task initialize();
        rst = 1;
        read = 0;
        write = 0;
        c_flush = 0;
        start = 0;
        Core_send = 0;
        pr_addr = 32'h0;
        pr_data = 32'h0;
        data_out_CCU = 32'h0;
        snoop_data = 32'h0;
        bs_resp = 1'b0;
        bs_req = 0;
        cache_upd_state_core = 2'b00;
        core_valid = 0;
        CCU_ready = 0;
        #10;
        rst = 0;
    endtask

    // Task for read request
    task read_request(input [31:0] address);
        start = 1;
        Core_send = 1;
        pr_addr = address;
        read = 1;
        write = 0;
        CCU_ready =1;
        data_out_CCU = 32'hDEAD_BEEF;
        #10;
        start = 0;
        Core_send = 0;
        #10;
    endtask

    // Task for write request
    task write_request(input [31:0] address, input [31:0] data);
        start = 1;
        Core_send = 1;
        pr_addr = address;
        pr_data = data;
        read = 0;
        write = 1;
        CCU_ready = 0;
        #10;
        start = 0;
        Core_send = 0;
        write = 0;
        #10;
    endtask

    // Task to flush cache
    task flush_cache();
        c_flush = 1;
        start = 1;
        Core_send = 1;
        #50;
        c_flush = 0;
        start = 0;
        #10;
    endtask

    // Task for snoop request
    task snoop_request(input [31:0] address);
        bs_req = 1;
        snoop_address = address;
        #50;
        bs_req = 0;
    endtask

    // Test sequence
    initial begin
        // Initialize inputs
        initialize();

        // Perform a read operation and check for cache miss
        $display("Test Case 1: Read Request - Expecting cache miss");
        read_request(32'hAABBCCDD);
        if (cache_miss)
            $display("Cache miss detected as expected.");
        else
            $display("Error: Cache miss not detected as expected.");

        // Perform a write operation
        $display("Test Case 2: Write Request");
        write_request(32'hAABBCCDD, 32'h12345678);
        #20;
        if (cache_hit)
            $display("Cache hit on write as expected.");
        else
            $display("Error: Cache hit not detected on write as expected.");

        // Perform a snoop request
        $display("Test Case 3: Snoop Request");
        snoop_request(32'hAABBCCDD);
        #20;
        if (bs_resp)
            $display("Snoop response received as expected.");
        else
            $display("Error: Snoop response not received as expected.");

        $stop;
    end
endmodule
