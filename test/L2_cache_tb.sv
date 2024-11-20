module tb_L2_cache;
    logic clk, rst;
    logic read_req, write_req;
    logic [31:0] addr;
    logic [127:0] write_data, read_data;
    logic ready, l2_miss, l2_hit;
    logic mem_read_req, mem_write_req;
    logic [31:0] mem_addr;
    logic [127:0] mem_write_data, mem_read_data;
    logic mem_ready;

    // Instantiate the L2 cache module
    L2_cache uut (
        .clk(clk),
        .rst(rst),
        .read_req(read_req),
        .write_req(write_req),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data),
        .ready(ready),
        .l2_miss(l2_miss),
        .l2_hit(l2_hit),
        .mem_read_req(mem_read_req),
        .mem_write_req(mem_write_req),
        .mem_addr(mem_addr),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        read_req = 0;
        write_req = 0;
        addr = 0;
        write_data = 0;
        mem_read_data = 0;
        mem_ready = 0;
        @(posedge clk);
        rst = 0;

        read_hit();
        read_miss();
        write_hit();
        write_miss();
        empty_addr();
        invalid_addr();
        zero_data();
        max_data();
        $finish;
    end

    // 1st case: Read hit
    task read_hit();
        begin
            // Write and read the data from same address
            addr = 32'h1000;
            write_req = 1;
            write_data = 128'hA5A5_A5A5_A5A5_A5A5_A5A5_A5A5_A5A5_A5A5;
            @(posedge clk);
            write_req = 0;
            #10;

            addr = 32'h1000;
            read_req = 1;
            @(posedge clk);
            read_req = 0;
            #10;
        end
    endtask

    // 2nd case: Read miss
    task read_miss();
        begin
            addr = 32'h2000; // Empty cache address
            read_req = 1;
            write_req = 0;
            @(posedge clk);
            read_req = 0;
            @(posedge clk);
            #10;
        end
    endtask

    // 3rd case: Write hit
    task write_hit();
        begin
            addr = 32'h1000;
            read_req = 0;
            write_req = 1;
            write_data = 128'h1234_5678_1234_5678_1234_5678_1234_5678;
            @(posedge clk);
            write_req = 0;
            @(posedge clk);
            #10;

            // Read back to confirm write
            read_req = 1;
            addr = 32'h1000;
            @(posedge clk);
            read_req = 0;
            @(posedge clk);
            #10;
        end
    endtask

    // 4th case: Write miss
    task write_miss();
        begin
            addr = 32'h3000;
            read_req = 0;
            write_data = 128'hBEEF_CAFE_BEEF_CAFE_BEEF_CAFE_BEEF_CAFE;
            write_req = 1;
            mem_ready = 1;
            @(posedge clk);
            write_req = 0;
            mem_ready = 0;
            @(posedge clk);
            #10;

            // Read back to confirm write
            read_req = 1;
            addr = 32'h3000;
            @(posedge clk);
            read_req = 0;
            @(posedge clk);
            #10;

        end
    endtask

    // 5th case: Empty address
    task empty_addr();
        begin
            addr = 32'h0;
            read_req = 1;
            write_req = 0;
            @(posedge clk);
            read_req = 0;
            @(posedge clk);
            #10;
        end
    endtask

    // 6th case: Invalid address
    task invalid_addr();
        begin
            addr = 32'hFFFFFFFF;
            read_req = 1;
            write_req = 0;
            @(posedge clk);
            read_req = 0;
            @(posedge clk);
            #10;
        end
    endtask

    // 7th case: Zero data write
    task zero_data();
        begin
            addr = 32'h5000;
            write_req = 1;
            write_data = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
            @(posedge clk);
            write_req = 0;
            @(posedge clk);
            #10;

            // Confirm write
            addr = 32'h5000;
            read_req = 1;
            @(posedge clk);
            read_req = 0;
            @(posedge clk);
            #10;
        end
    endtask

    // 8th case: Max data write
    task max_data();
        begin
            addr = 32'h6000;
            write_req = 1;
            write_data = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            @(posedge clk);
            write_req = 0;
            @(posedge clk);
            #10;

            // Confirm write
            addr = 32'h6000;
            read_req = 1;
            @(posedge clk);
            read_req = 0;
            @(posedge clk);
            #10;
        end
    endtask

endmodule

