`define BUF_WIDTH 2    // BUF_SIZE = 4 -> BUF_WIDTH = 2, number of bits for the pointer
`define BUF_SIZE (1 << `BUF_WIDTH)
`include "fifo.sv"

module arbiter (
    input [3:0] Com_Bus_Req_proc,    // Processor requests
    input [3:0] Com_Bus_Req_snoop,   // Snoop requests
    input Mem_snoop_req,             // Memory snoop request
    output reg [3:0] Com_Bus_Gnt_proc,   // Processor grant signals
    output reg [3:0] Com_Bus_Gnt_snoop,  // Snoop grant signals
    output reg Mem_snoop_gnt              // Memory snoop grant signal

);

    // Internal signals
    reg [1:0] state;
    reg clk;
    reg rst;
    reg wr_en;  // Write enable for FIFO
    reg rd_en;  // Read enable for FIFO

    wire [3:0] buf_out;
    wire buf_empty, buf_full;
    wire [`BUF_WIDTH:0] fifo_counter;
    reg [3:0] fifo_data_in;
 

    integer i;
     


    // State encoding
    parameter IDLE = 2'b00;
    parameter PROC_REQ = 2'b01;
    parameter SNOOP_REQ = 2'b10;
    parameter MEM_REQ = 2'b11;

    // FIFO instance for storing granted requests
    fifo f1 (
        .data_in(fifo_data_in), // Update if needed to write appropriate data based on the state
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .buf_out(buf_out),
        .buf_empty(buf_empty),
        .buf_full(buf_full),
        .fifo_counter(fifo_counter)
    );

    // Clock generation (1ns period for testing purposes)
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // Reset logic
    initial begin
        rst = 1'b1;
        #2 rst = 1'b0;
    end

    // FSM for arbiter with priority logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            wr_en <= 1'b0;
            rd_en <= 1'b0;
        end else begin
            wr_en <= 1'b0; // Default FIFO write enable to 0
            case (state)
                IDLE: begin
                    if(Mem_snoop_req && Com_Bus_Req_snoop && Com_Bus_Req_proc)begin
                        state <= MEM_REQ; 
                    end else if (Mem_snoop_req) begin
                        state <= MEM_REQ;
                    end else if (|Com_Bus_Req_snoop) begin
                        state <= SNOOP_REQ;
                    end else if (|Com_Bus_Req_proc) begin
                        state <= PROC_REQ;
                    end
                end
                PROC_REQ: begin
                    if (~|Com_Bus_Req_proc) begin
                        state <= IDLE;
                    end else begin
                        wr_en <= 1'b1; // Write granted request to FIFO
                    end
                end
                SNOOP_REQ: begin
                    if (~|Com_Bus_Req_snoop) begin
                        state <= IDLE;
                    end else begin
                        wr_en <= 1'b1; // Write granted snoop request to FIFO
                    end
                end
                MEM_REQ: begin
                    if (~Mem_snoop_req) begin
                        state <= IDLE;
                    end else begin
                        wr_en <= 1'b1; // Write granted memory request to FIFO
                    end
                      
                end
            endcase
        end
    end

    // Grant logic based on the FSM state
    always @(*) begin
        // Reset all grants
        Com_Bus_Gnt_proc = 4'b0000;
        Com_Bus_Gnt_snoop = 4'b0000;
        Mem_snoop_gnt = 1'b0;

        // Set grants based on the current FSM state
        case (state)
            PROC_REQ: begin
                for (i = 0; i < 4; i = i + 1) begin
                    if (Com_Bus_Req_proc[i]) begin
                        Com_Bus_Gnt_proc[i] = 1'b1;
                        break; // Grant the first active processor request found
                    end
                end
            end
            SNOOP_REQ: begin
                for (i = 0; i < 4; i = i + 1) begin
                    if (Com_Bus_Req_snoop[i]) begin
                        Com_Bus_Gnt_snoop[i] = 1'b1;
                        break; // Grant the first active snoop request found
                    end
                end
            end
            MEM_REQ: begin
                Mem_snoop_gnt = 1'b1; // Grant memory snoop request
            end
        endcase
    end
 
// Define constants for request types
    parameter PROC_REQ_TYPE = 2'b00;
    parameter SNOOP_REQ_TYPE = 2'b01;
    parameter MEM_REQ_TYPE = 2'b10;
    
    // Modify fifo_data_in assignments
always @(*) begin
        case (state)
            PROC_REQ: begin
                for (i = 0; i < 4; i = i + 1) begin
                    if (Com_Bus_Req_proc[i]) begin
                        fifo_data_in = {PROC_REQ_TYPE, i[1:0]}; // Encode processor ID (last 2 bits)
                        break;
                    end
                end
            end
            SNOOP_REQ: begin
                for (i = 0; i < 4; i = i + 1) begin
                    if (Com_Bus_Req_snoop[i]) begin
                        fifo_data_in = {SNOOP_REQ_TYPE, i[1:0]}; // Encode snoop ID (last 2 bits)
                        break;
                    end
                end
            end
            MEM_REQ: fifo_data_in = {MEM_REQ_TYPE, 2'b00}; // Encode memory request type (fixed ID)
            default: fifo_data_in = 4'b0000;
        endcase
    end
 endmodule
 