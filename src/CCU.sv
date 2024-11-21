`define BUF_WIDTH 2
`define BUF_SIZE (1 << `BUF_WIDTH)

module CCU(
    input logic clk,
    input logic rst,
    input logic [3:0] read, 
    input logic [3:0] write,
    input logic [3:0] cache_hit,
    input logic [3:0] cache_miss,
    input logic [31:0] pr_addr_ccu [3:0],
    input logic [31:0] pr_data_ccu [3:0],
    input logic l2_ready,
    input logic [127:0] l2_data,
    input logic [31:0] snoop_data, //32 20,8,4 offset
    input logic [31:0] snoop_data_1,
    input logic [31:0] snoop_data_2,
    input logic [31:0] snoop_data_3,
    input logic core1_valid,
    input logic core2_valid,
    input logic core3_valid,
    input logic core4_valid,
    input logic [127:0] cache_data1,
    input logic [127:0] cache_data2,
    input logic [127:0] cache_data3,
    input logic [127:0] cache_data4,
    input logic [1:0] cache_state_core1,
    input logic [1:0] cache_state_core2,
    input logic [1:0] cache_state_core3,
    input logic [1:0] cache_state_core4,
    input logic [3:0] buf_out,        // 4-bit data output.
    input logic buf_empty,                // Empty flag.
    input logic buf_full,                // Full flag.
    //input logic [`BUF_WIDTH:0] fifo_counter  // Counter to track number of elements. 

    output logic bs_req,
    output logic bs_req_data,
    output logic l2_write_req,
    output logic l2_read_req,
    output logic [127:0] write_data,
    output logic [31:0] data_out_CCU,
    output logic [1:0] cache_upd_state_core1, // 00 M, 01 E, 10 S, 11 I
    output logic [1:0] cache_upd_state_core2,
    output logic [1:0] cache_upd_state_core3,
    output logic [1:0] cache_upd_state_core4,
    output logic [7:0] CCU_index,
    output logic start,
    output logic CCU_ready,
    output logic L1_1_CCU,
    output logic L1_2_CCU,
    output logic L1_3_CCU,
    output logic L1_4_CCU,
    output logic [31:0] snoop_address,
    output logic rd_en,
    output logic Mem_request
);

    typedef enum logic [1:0] {M = 2'b00, E = 2'b01, S = 2'b10, I = 2'b11} mesi_t;
    mesi_t core_mesi_state [4];
     mesi_t core_mesi_state_duplicate [4];
  

    typedef enum logic [2:0] {IDLE = 3'b000, PROCESS_REQ = 3'b001, SNOOPING = 3'b010, READ_FROM_L2 = 3'b011, WRITE_TO_L2 = 3'b100} state_t;
    state_t current_state, next_state;

    logic [19:0] p_tag;
    logic [7:0] p_index;
    logic [3:0] p_offset;
    logic [1:0]cache_state;
    logic upd_cache;
    logic [1:0] req_core;
    //logic rst_dup;
    logic bs_resp1; // [2] bit tells data of that particular tag is available, [1:0] will tell which core
    logic bs_resp2;
    logic bs_resp3;
    logic bs_resp4;
  
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            for (int i = 0; i < 4; i++) begin
                core_mesi_state_duplicate [i] <= I; // Set duplicate to invalid at reset
            end
            //rst_dup = 1'b1;
            //bs_req <= 1'b0;
            //l2_write_req <= 1'b0;
            //l2_read_req <= 1'b0;
            //write_data <= 0;
            //data_out_CCU <= 0;
        end else begin
            current_state <= next_state;
    end
    end

always_comb begin
        // Default values for control signals
        start = 1'b0;
        //upd_cache = 1'b0;
        CCU_ready = 1'b0;
        bs_req = 1'b0;
        l2_read_req = 1'b0;
        l2_write_req = 1'b0; 
     

         // Update core states for next state calculation
       /*for (int i = 0; i < 4; i++) begin
            next_mesi_state[i] = core_mesi_state[i];  
        end*/
      if(rst)begin
        for (int i = 0; i < 4; i++) begin
            core_mesi_state[i] = core_mesi_state_duplicate[i];
        end
      end
        
      if (start)begin
          case(req_core)
            2'b00:cache_state = cache_state_core1;
            2'b01:cache_state = cache_state_core2;
            2'b10:cache_state = cache_state_core3;
            2'b11:cache_state = cache_state_core4;
          endcase

          if(cache_state == 2'b00)begin
             core_mesi_state[req_core] = M;
          end
          else if(cache_state == 2'b01)begin
             core_mesi_state[req_core] = E;
          end
          else if(cache_state == 2'b10)begin
             core_mesi_state[req_core] = S;
          end
          else if(cache_state == 2'b11)begin
             core_mesi_state[req_core] = I;
          end

        end
        
        
       /* if(upd_cache) begin
          case(req_core)
            2'b00: cache_upd_state_core1 = core_mesi_state[0];  
            2'b01: cache_upd_state_core2 = core_mesi_state[1];
            2'b10: cache_upd_state_core3 = core_mesi_state[2];
            2'b11: cache_upd_state_core4 = core_mesi_state[3];
          endcase
    end*/
    if(upd_cache) begin
      cache_upd_state_core1 = core_mesi_state[0];  
      cache_upd_state_core2 = core_mesi_state[1];
      cache_upd_state_core3 = core_mesi_state[2];
      cache_upd_state_core4 = core_mesi_state[3];
      upd_cache = 1'b0;
    end

    case(current_state)
        IDLE: begin
            
            for (int i = 0; i < 4; i++) begin
                if (i != req_core) begin
                    core_mesi_state[i] = I;  // Set all other cores to invalid state
                end
             end
            
            start = 1'b1; //4 core 

            if(!buf_empty) begin
              rd_en = 1'b1;
              case(buf_out)
               4'b0000: req_core = 2'b00;
               4'b0001: req_core = 2'b01;
               4'b0010: req_core = 2'b10;
               4'b0011: req_core = 2'b11;
              endcase
              if(req_core == 2'b00)begin
                L1_1_CCU  = 1'b1;  //signal 
                p_tag    = pr_addr_ccu[0][31:12];  
                p_index  = pr_addr_ccu[0][11:4];   
                p_offset = pr_addr_ccu[0][3:0]; 
                CCU_index = p_index; 
              end
              if(req_core == 2'b01)begin
                L1_2_CCU  = 1'b1;
                p_tag    = pr_addr_ccu[1][31:12];  
                p_index  = pr_addr_ccu[1][11:4];   
                p_offset = pr_addr_ccu[1][3:0]; 
                CCU_index = p_index; 
              end
              if(req_core == 2'b10)begin
                L1_3_CCU  = 1'b1;
                p_tag    = pr_addr_ccu[2][31:12];  
                p_index  = pr_addr_ccu[2][11:4];   
                p_offset = pr_addr_ccu[2][3:0]; 
                CCU_index = p_index; 
              end
              if(req_core == 2'b11)begin
                L1_4_CCU  = 1'b1; //
                p_tag    = pr_addr_ccu[3][31:12];  
                p_index  = pr_addr_ccu[3][11:4];   
                p_offset = pr_addr_ccu[3][3:0]; 
                CCU_index = p_index; 
              end
            //upd_cache = 1'b0;
            CCU_ready = 1'b0;
            next_state =  PROCESS_REQ;
            end
            else begin
             next_state = IDLE;
            end
        end
        PROCESS_REQ: begin
        
        rd_en = 1'b0;
        L1_1_CCU = 1'b0;
        L1_2_CCU = 1'b0;
        L1_3_CCU = 1'b0;
        L1_4_CCU = 1'b0;
        if(|cache_hit || |cache_miss)begin 
               case (core_mesi_state[req_core])
                M: begin 
                    if (|write && |cache_hit) begin
                    l2_write_req = 1'b1;
                    Mem_request = 1'b1;
                    bs_req_data = 1'b0;
                    next_state = WRITE_TO_L2; // Change to next_state for state transition
                    end else if ((|read || |write ) && |cache_miss) begin
                    bs_req = 1'b1;
                    snoop_address = pr_addr_ccu[req_core];
                    next_state = SNOOPING; // Change to next_state for state transition
                    end
                end
                E: begin
                    if (|write && |cache_hit) begin
                    //core_mesi_state[req_core] = M;  
                    bs_req_data = 1'b1;  
                    snoop_address = pr_addr_ccu[req_core];;
                    next_state = SNOOPING; // Change to next_state for state transition
                    end else if ((|read || |write) && |cache_miss) begin
                    bs_req = 1'b1;
                    l2_read_req = 1'b1; 
                    Mem_request = 1'b1;
                    next_state = READ_FROM_L2; // Change to next_state for state transition
                    end
                end
                S: begin
                    if (|write && |cache_hit) begin
                    //core_mesi_state[req_core] = M;  
                    bs_req_data = 1'b1; 
                    snoop_address = pr_addr_ccu[req_core];
                    next_state = SNOOPING; // Change to next_state for state transition
                    end else if ((|read || |write) && |cache_miss) begin
                    bs_req = 1'b1;
                    l2_read_req = 1'b1; 
                    Mem_request = 1'b1;
                    next_state = READ_FROM_L2; // Change to next_state for state transition
                    end
                end
                I: begin
                    if (|read && |cache_hit) begin
                        bs_req = 1'b1;
                        snoop_address = pr_addr_ccu[req_core];
                        //core_mesi_state[req_core] = S;
                        next_state = SNOOPING; // Change to next_state for state transition
                    end else if (|write && |cache_hit) begin
                        //core_mesi_state[req_core] = M;
                        bs_req_data = 1'b1;
                        snoop_address = pr_addr_ccu[req_core];
                        next_state = SNOOPING; // Change to next_state for state transition
                    end else if ((|read || |write) && |cache_miss) begin
                        bs_req = 1'b1;
                       snoop_address = pr_addr_ccu[req_core];
                        next_state = SNOOPING; // Change to next_state for state transition
                    end
                end
                endcase
                end else begin
                next_state = PROCESS_REQ;
                end
        end
        SNOOPING: begin
            // Logic for SNOOPING state remains unchanged
            if(!buf_empty) begin
              case(buf_out)
                4'b0100: bs_resp1 = 1'b1;
                4'b0101: bs_resp2 = 1'b1;
                4'b0110: bs_resp3 = 1'b1;
                4'b0111: bs_resp4 = 1'b1;
              endcase
            end

            if (((|read || |write) && |cache_miss || (|read && |cache_hit))) begin
                if (bs_resp1 && core1_valid || bs_resp2 && core2_valid|| bs_resp3 && core3_valid|| bs_resp4 && core4_valid) begin
                    if (bs_resp1 && core1_valid) begin
                        data_out_CCU = snoop_data;
                        core_mesi_state[0] = S;
                       // cache_upd_state_core1 = core_mesi_state[bs_resp1[1:0]];
                    end
                    if (bs_resp2 && core2_valid) begin
                        data_out_CCU = snoop_data_1;
                        core_mesi_state[1] = S;
                       // cache_upd_state_core2 = core_mesi_state[bs_resp2[1:0]];
                    end
                    if (bs_resp3 && core3_valid) begin
                        data_out_CCU = snoop_data_2;
                        core_mesi_state[2] = S;
                      //  cache_upd_state_core3 = core_mesi_state[bs_resp3[1:0]];
                    end
                    if (bs_resp4 && core4_valid) begin
                        data_out_CCU = snoop_data_3;
                        core_mesi_state[3] = S;
                      //  cache_upd_state_core4 = core_mesi_state[bs_resp4[1:0]];
                    end
                    next_state = IDLE; // Change to next_state for state transition
                    upd_cache = 1'b1;
                    bs_req = 1'b0;
                    start = 1'b0;
                    core_mesi_state[req_core] = S;
                    CCU_ready = 1'b1;
                end else begin
                    l2_read_req = 1'b1;
                    next_state = READ_FROM_L2; // Change to next_state for state transition
                    Mem_request = 1'b1;
                    start = 1'b0;
                    bs_req = 1'b0;
                end
            end else if (|write && |cache_hit) begin
                if (bs_resp1 || bs_resp2 || bs_resp3 || bs_resp4) begin
                    if (bs_resp1) begin
                        core_mesi_state[0] = I;
                    end
                    if (bs_resp2) begin
                        core_mesi_state[1] = I;
                    end
                    if (bs_resp3) begin
                        core_mesi_state[2] = I;
                    end
                    if (bs_resp4) begin
                        core_mesi_state[3] = I;
                    end
                end
                next_state = WRITE_TO_L2; // Change to next_state for state transition
                l2_write_req = 1'b1;  
                start = 1'b0;
                Mem_request = 1'b1;
                bs_req_data = 1'b0;
            end else begin
                next_state = IDLE; // Change to next_state for state transition
                upd_cache = 1'b1; 
                start = 1'b0; 
            end
        end

        READ_FROM_L2: begin
            if (l2_ready && (buf_out == 4'b1000)) begin
                case (p_offset)
                    4'b0000: data_out_CCU = l2_data[31:0];
                    4'b0100: data_out_CCU = l2_data[63:32];
                    4'b1000: data_out_CCU = l2_data[95:64];
                    4'b1100: data_out_CCU = l2_data[127:96];
                endcase
                core_mesi_state[req_core] = E; 
                next_state = IDLE; // Change to next_state for state transition
                upd_cache = 1'b1;
                l2_read_req = 1'b0;
                Mem_request = 1'b0;
                start = 1'b0;
                CCU_ready = 1'b1;
            end
        end

        WRITE_TO_L2: begin
            if (l2_ready && (buf_out == 4'b1000)) begin
                l2_write_req = 1'b0;
                case (req_core)
                    2'b00: write_data = cache_data1;  
                    2'b01: write_data = cache_data2;  
                    2'b10: write_data = cache_data3;  
                    2'b11: write_data = cache_data4;  
                endcase
                next_state = IDLE; // Change to next_state for state transition
                upd_cache = 1'b1;
                start = 1'b0;
                Mem_request = 1'b0;
                core_mesi_state[req_core] = M;
            end
            else begin
              next_state = WRITE_TO_L2;
            end
        end
    endcase
end
endmodule
           