module Cache_Controller_2(

      // Inputs 
      input logic clk,
      input logic rst,
      input logic read,
      input logic write,
      input logic [31:0] pr_addr, // processor address
      input logic [31:0] pr_data, // processor data
      input logic c_flush,// flush 
      input logic [31:0] data_out_CCU, // CCU sends data 
      input logic bs_req, // CCU 
      input logic [1:0] cache_upd_state_core,// M,E,S,I 
      input logic CCU_ready,// for sending data from CCU to L1 Cache
      input logic start,
	  input logic Core_send,
	  input logic [31:0] snoop_address,
	  input logic L1_3_CCU,
	  input logic bs_req_data,

      // Outputs
      output logic hit,
      output logic miss,
      output logic [31:0] data_out_pr,
      output logic bs_resp,
      output logic [127:0] cache_data,
      output logic core_valid, 
      output logic [1:0] cache_state_core, //M 
      output logic [31:0] snoop_data, //bs resp i have data , data 
	  output logic Cache_Ready,
	  output logic Request,
	  output logic stall,
	  output logic [31:0] addr,
	  output logic [31:0] data,
	  output logic rd,
	  output logic wr
);

     logic [19:0] p_tag; //20 bit      pr_addr{32} == 20 + 8 + 4, 
     logic [7:0] p_index; // 8 bit
     logic [3:0] p_offset;// 16 bytes 
     
     logic [19:0] snoop_tag; //20 bit      pr_addr{32} == 20 + 8 + 4, 
     logic [7:0] snoop_index; // 8 bit
     logic [3:0] snoop_offset;// 16 bytes
      
     logic [149:0] cache [0 : 255];  // 128 + 20 + 1 (data + tag + valid) 256 = 2^8
    
     logic [19:0]cache_tag;
     logic cache_valid;
     logic cache_dirty;
     logic [127 :0] cache_data_out; 
     logic send;
     int i;
	 logic update;
	 logic cache_hit;
	 logic cache_miss;
	
     typedef enum logic [2:0] {IDLE, PROCESS_REQ, SEND_TO_CCU, FLUSH, RECEIVE_FROM_CCU,STALL} state_t;
     state_t current_state, next_state;

     typedef enum logic [1:0] {M = 2'b00, E = 2'b01, S = 2'b10, I = 2'b11} mesi_t;
     mesi_t cache_mesi_state [0:255];

     // Sequential block for state and cache data updates
     always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            for(i = 0; i < 256; i++) begin
                cache_mesi_state[i] <= I; // invalid
            end
			update <= 1'b0;
			send <= 1'b0;
			//cache_dirty = 1'b0;
			//cache_valid = 1'b0;
        end else begin
            current_state <= next_state;
            
            // Update cache state only in sequential block
            /*cache[p_index][127:0] <= cache_data_out;
            cache[p_index][149:130] <= cache_tag;
            cache[p_index][129] <= cache_valid ;
	        cache[p_index][128] <= cache_dirty;*/
        end
     end

     // Combinational logic for tag and index calculation
     always_comb begin

		if(Core_send)begin
			p_tag = pr_addr[31:12];  // Tag is 20 bits
            p_index = pr_addr[11:4];  // Index is 8 bits
            p_offset = pr_addr[3:0];  // Offset is 4 bits
		end
     
        if (send) begin
            cache_data = cache_data_out;
        end

        if (start) begin
            cache_state_core = cache_mesi_state[p_index];
			/*if(cache_state_core = 2'b11)begin
				cache_valid = 1'b0;
			end*/
        end
     end

	always_comb begin
	 
	  //next_state = current_state;
	  //cache_data_out = 0;
	  //cache_tag = p_tag;
	  //cache_valid = 0;
	  //cache_dirty = 0;
	  //cache_state_core = cache_mesi_state[p_index];
      if(L1_3_CCU)begin
	    addr = pr_addr;
		data = pr_data;
		wr = write;
		rd = read;
		hit = cache_hit;
		miss = cache_miss;
      end

	  case (current_state)
        IDLE: begin
           //finish = 1'b1;
		    if(bs_req || bs_req_data)begin
				next_state = SEND_TO_CCU;
				snoop_tag = snoop_address[31:12];  // Tag is 20 bits
                snoop_index = snoop_address[11:4];  // Index is 8 bits
                snoop_offset = snoop_address[3:0]; 
				cache_data_out = cache[snoop_index][127:0];  
                cache_tag      = cache[snoop_index][149:130];
                cache_valid    = cache[snoop_index][129];
                cache_dirty    = cache[snoop_index][128];
                stall = 1'b1;
			end else if (Core_send && read || write) begin
                next_state  = PROCESS_REQ;
	  			cache_valid = 1'b0;
	  			cache_hit   = 1'b0;
				cache_miss  = 1'b0; 
				cache_data_out = cache[p_index][127:0];
                cache_tag      = cache[p_index][149:130];
                cache_valid    = cache[p_index][129];
                cache_dirty    = cache[p_index][128];
				stall = 1'b1;
				Cache_Ready = 1'b0;
            end else if (Core_send && c_flush) begin
                next_state = FLUSH;
				stall = 1'b1;
				Cache_Ready = 1'b0;
			end else begin
                next_state = IDLE;
            end

           end
	  	
        PROCESS_REQ: begin
          cache_hit  = 1'b0;
          cache_miss = 1'b0;
    
			// Case 1: Tag matches and data is valid (Cache hit)
		  if (cache_tag == p_tag && cache_valid) begin
			cache_hit = 1'b1;
			if (read) begin
			  case(p_offset)
				4'b0000: data_out_pr = cache_data_out[31:0];
				4'b0100: data_out_pr = cache_data_out[63:32];
				4'b1000: data_out_pr = cache_data_out[95:64];
				4'b1100: data_out_pr = cache_data_out[127:96];
			  endcase
			  next_state = STALL;
			end else if (write) begin
			  case(p_offset)
				4'b0000: cache_data_out[31:0] = pr_data;
				4'b0100: cache_data_out[63:32] = pr_data;
				4'b1000: cache_data_out[95:64] = pr_data;
				4'b1100: cache_data_out[127:96] = pr_data;
			  endcase
			  send = 1'b1;
			  update = 1'b1;
			  cache_tag   = p_tag;
			  cache_mesi_state[p_index] = M;  // Update MESI state
			  next_state  = STALL;      // Move to CCU state
			end

		  end else if (cache_tag == p_tag && !cache_valid) begin
			  if (read) begin
				cache_miss = 1'b1;
				cache_tag  = p_tag;   // Keep the tag
				cache_dirty = cache[p_index][128];
				next_state = RECEIVE_FROM_CCU;
			  end
			  else if (write) begin
				case(p_offset)
				  4'b0000: cache_data_out[31:0] = pr_data;
				  4'b0100: cache_data_out[63:32] = pr_data;
				  4'b1000: cache_data_out[95:64] = pr_data;
				  4'b1100: cache_data_out[127:96] = pr_data;
				endcase
				cache_valid = 1'b1;
				send = 1'b1;
				update = 1'b1;
				cache_tag   = p_tag;
				cache_mesi_state[p_index] = M;  // Update MESI state
				cache_hit = 1'b1;               // Consider this as a hit after writing
				next_state  = STALL;      // Move to CCU for further processing
			  end
		  end else begin
				cache_miss = 1'b1;
				cache_valid = 1'b0;
				//cache_tag   = p_tag;  // New tag
				next_state = RECEIVE_FROM_CCU;  // Move to receive state
		  end
		end

	    SEND_TO_CCU: begin
           send = 1'b0;
           // cache_tag = p_tag;
		   if (bs_req) begin
			  if (cache_tag == snoop_tag && cache_valid) begin
				case(p_offset) 
					4'b0000: snoop_data = cache_data_out[31:0];
					4'b0100: snoop_data = cache_data_out[63:32];
					4'b1000: snoop_data = cache_data_out[95:64];
					4'b1100: snoop_data = cache_data_out[127:96];
				endcase
				bs_resp = 1'b1;
				cache_mesi_state[p_index]  = cache_upd_state_core;
				next_state = STALL;
				// finish = 1'b1;
				core_valid = 1'b1;
				// cache_miss = 1'b0;
			  end else begin
				bs_resp = 1'b0;
				// cache_state_core = cache_mesi_state[p_index];
				next_state = STALL;
			  end
			end else if (bs_req_data) begin
			  if (cache_tag == snoop_tag && cache_valid) begin
				bs_resp = 1'b1;
				next_state = STALL;
				cache_mesi_state[p_index]  = cache_upd_state_core;
				core_valid = 1'b1;
			  end
			end else begin
				next_state = SEND_TO_CCU;
			end
		end


		RECEIVE_FROM_CCU: begin
		  cache_tag   = p_tag;
		  Request = 1'b1;
		  if (CCU_ready) begin
			data_out_pr = data_out_CCU;
			cache_mesi_state[p_index]  = cache_upd_state_core;
			next_state = STALL;
			//finish = 1'b1;
			cache_miss = 1'b0;
			cache_valid = 1'b1;
		  end
		end
	  	
	  	FLUSH: begin
            if(c_flush) begin
              cache_dirty = 1'b0; 
              cache_valid = 1'b0;
              p_index = p_index + 1;    
              if (p_index == 8'd255) begin 
                p_index <= 0; 
                next_state = STALL; 
				//finish = 1'b1;
              end else begin
                next_state = FLUSH; 
              end
            end
		end

		STALL: begin
			if(stall == 1'b1)begin
				stall = 1'b0;
				Cache_Ready = 1'b1;
				next_state = IDLE;
				Request = 1'b0;
			end
		end

		endcase
		cache[p_index][127:0] = cache_data_out;
        cache[p_index][149:130] = cache_tag;
        cache[p_index][129] = cache_valid ;
	    cache[p_index][128] = cache_dirty;
		//finish = 1'b1;
    end
endmodule

