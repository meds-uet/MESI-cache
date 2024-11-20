module L2_cache (
    input logic clk,
    input logic rst,
    input logic read_req,                // Request from CCU to read from L2
    input logic write_req,               // Request from CCU to write to L2
    input logic [31:0] addr,             // Address from CCU for read/write
    input logic [127:0] write_data,      // Data to be written to L2 from CCU
    output logic [127:0] read_data,      // Data read from L2 to be sent to CCU
    output logic ready,                  // Ready signal to CCU
    output logic l2_miss,                // Indicates a miss in L2
    output logic l2_hit,                 // Indicates a hit in L2
    output logic mem_read_req,           // Signal to read from main memory
    output logic mem_write_req,          // Signal to write to main memory
    output logic [31:0] mem_addr,        // Address to access in main memory
    output logic [127:0] mem_write_data, // Write data to memory
    input logic [127:0] mem_read_data,   // Read data from memory
    input logic mem_ready                // Signal that memory operation is complete
    );

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        PROCESS_REQ = 3'b001,      // New state to process CCU requests
        READ_FROM_L2 = 3'b010,
        WRITE_TO_L2 = 3'b011,
        MEM_FETCH = 3'b100,        // Fetching data from main memory (L2 miss)
        MEM_WRITEBACK = 3'b101     // Writing dirty data back to memory
    } state_t;

    state_t current_state, next_state;

    logic [19:0] tag;    // If the requested data is in the cache line
    logic [7:0] index;   // Which cache line to check
    logic [3:0] offset;  // Exact location within the cache line

    // Cache storage (each line holds 128 bits of data)
    logic [149:0] cache [0:511]; // 511 sets, direct-mapped (1 line per set), 148 bits per line
	
	logic [19:0] cache_tag;
	logic cache_valid;
	logic cache_dirty;
	logic [127:0] cache_data;

    // Signals to handle multi driven error
    logic next_ready;
    logic next_l2_hit;
    logic next_l2_miss;
    logic next_mem_read_req;
    logic next_mem_write_req;
    logic [31:0] next_mem_addr;
    logic [127:0] next_read_data;
    logic [127:0] next_mem_write_data;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            read_data <= 128'b0;
            ready <= 1'b0;
            l2_miss <= 1'b0;
            l2_hit <= 1'b0;
            mem_read_req <= 1'b0;
            mem_write_req <= 1'b0;
            mem_addr <= 32'b0;
            mem_write_data <= 128'b0;
        end else begin
            current_state <= next_state;
            read_data <= next_read_data;
            ready <= next_ready;
            l2_miss <= next_l2_miss;
            l2_hit <= next_l2_hit;
            mem_read_req <= next_mem_read_req;
            mem_write_req <= next_mem_write_req;
            mem_addr <= next_mem_addr;
            mem_write_data <= next_mem_write_data;
        end
    end

    always_comb begin
        tag = addr[31:12];
        index = addr[11:4];
        offset = addr[3:0];
    end

    always_comb begin
        next_state = current_state;
        next_read_data = read_data;
        next_ready = 1'b0;
        next_l2_miss = 1'b0;
        next_l2_hit = 1'b0;
        next_mem_read_req = 1'b0;
        next_mem_write_req = 1'b0;
        next_mem_addr = mem_addr;
        next_mem_write_data = mem_write_data;

        cache_data = cache[index][127:0];
        cache_dirty = cache[index][128];
        cache_valid = cache[index][129];
        cache_tag = cache[index][149:130];

        case (current_state)
            IDLE: begin
                if (read_req || write_req) begin
                    next_state = PROCESS_REQ;
                end else begin
                    next_state = IDLE;
                end
            end

            PROCESS_REQ: begin
                if (cache_valid && (cache_tag == tag)) begin
                    // Cache hit
                    next_l2_hit = 1'b1;
                    next_l2_miss = 1'b0;

                    if (read_req) begin
                        next_state = READ_FROM_L2;
                    end else if (write_req) begin
                        next_state = WRITE_TO_L2;
                    end
                end else begin
                    // Cache miss
                    next_l2_miss = 1'b1;
                    next_l2_hit = 1'b0;
                    if (cache_valid && cache_dirty) begin
                        // Dirty line, writeback to main memory
                        next_state = MEM_WRITEBACK;
                        next_mem_addr = {cache_tag, index, 4'b0};
                        next_mem_write_data = cache_data;
                        next_mem_write_req = 1'b1;
                    end else begin
                        // Empty line, fetch from main memory
                        next_state = MEM_FETCH;
                        next_mem_addr = addr;
                        next_mem_read_req = 1'b1;
                    end
                end
            end

            READ_FROM_L2: begin
                next_ready = 1'b1;
                case (offset)
                    4'b0000: next_read_data = cache_data[31:0];
                    4'b0100: next_read_data = cache_data[63:32];
                    4'b1000: next_read_data = cache_data[95:64];
                    4'b1100: next_read_data = cache_data[127:96];
                endcase
                next_state = IDLE;
            end

            WRITE_TO_L2: begin
                next_ready = 1'b1;
                case (offset)
                    4'b0000: cache_data[31:0] = write_data;
                    4'b0001: cache_data[63:32] = write_data;
                    4'b0010: cache_data[95:64] = write_data;
                    4'b0011: cache_data[127:96] = write_data;    
                endcase
                cache_dirty = 1'b1;  // Dirty
                cache_valid = 1'b1;  // Valid
                cache_tag = tag;
                next_state = IDLE;
            end

            MEM_FETCH: begin
                if (mem_ready) begin
                    cache_data = mem_read_data;
                    cache_dirty = 1'b0;  // Not dirty
                    cache_valid = 1'b1;  // Valid
                    cache_tag = tag;
                    next_state = READ_FROM_L2;
                end else begin
                    next_mem_read_req = 1'b1;
                end
            end

            MEM_WRITEBACK: begin
                if (mem_ready) begin
                    next_mem_addr = {cache_tag, index, 4'b0000};
                    next_mem_write_data = cache_data;
                    next_mem_write_req = 1'b0;
                    cache_dirty = 1'b0; // Line is clean now
                    next_state = WRITE_TO_L2;
                end else begin
                    next_mem_write_req = 1'b1;
                end
            end
        endcase
    end
endmodule
