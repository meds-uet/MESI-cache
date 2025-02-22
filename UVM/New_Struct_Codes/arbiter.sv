typedef struct packed {
    logic [3:0] Com_Bus_Req_proc;   // Processor requests
    logic [3:0] Com_Bus_Req_snoop;  // Snoop requests
} Arbiter_Input_t;

// Struct for Outputs
typedef struct packed {
    logic [3:0] Com_Bus_Gnt_proc;   // Processor grant signals
    logic [3:0] Com_Bus_Gnt_snoop;  // Snoop grant signals
    logic wr_en;
    logic [3:0] fifo_data_in;
    logic [3:0] fifo_data_snoop;
    logic [3:0] proc_gnt;
    logic [3:0] snoop_gnt;
    logic snoop_active;
    logic no_snoop;
} Arbiter_Output_t;

module arbiter (
    input logic rst,
    input logic clk,
    input Arbiter_Input_t arbiter_input,   // Input struct
    output Arbiter_Output_t arbiter_output // Output struct
);

    reg [1:0] state;
    reg [3:0] prev_fifo_data_in; // Store previous fifo_data_in value
    reg fifo_hold; // Flag to track if FIFO data should be held
    integer i; 

    // State encoding
    parameter IDLE = 2'b00;
    parameter PROC_REQ = 2'b01;
    parameter SNOOP_REQ = 2'b10;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        arbiter_output.wr_en <= 1'b0;
        arbiter_output.fifo_data_snoop <= 0;
        arbiter_output.fifo_data_in <= 0;
        prev_fifo_data_in <= 0; 
        fifo_hold <= 1'b0;
    end else begin
        if (~|arbiter_input.Com_Bus_Req_snoop) begin
            arbiter_output.snoop_active  <= 1'b0;
        end
        case (state)
            IDLE: begin
                arbiter_output.proc_gnt = 0;
                arbiter_output.snoop_gnt = 0;
                if (|arbiter_input.Com_Bus_Req_snoop) begin  
                    state <= SNOOP_REQ;
                end else if (|arbiter_input.Com_Bus_Req_proc) begin
                    state <= PROC_REQ;
                end
            end
            PROC_REQ: begin
                if (~|arbiter_input.Com_Bus_Req_proc) begin 
                    state <= IDLE;
                end else begin
                    arbiter_output.proc_gnt <= arbiter_output.Com_Bus_Gnt_proc;
                    prev_fifo_data_in <= arbiter_output.fifo_data_in;
                end
            end
            SNOOP_REQ: begin
                if (~|arbiter_input.Com_Bus_Req_snoop) begin
                    state <= IDLE;
                end else begin
                    for (i = 0; i < 4; i = i + 1) begin
                        if (arbiter_input.Com_Bus_Req_snoop[i]) begin
                            arbiter_output.snoop_gnt <= arbiter_output.Com_Bus_Gnt_snoop;
                            break;
                        end
                    end
                end
            end
        endcase
    end
end

always @(*) begin
    arbiter_output.Com_Bus_Gnt_proc = 4'b0000;
    arbiter_output.Com_Bus_Gnt_snoop = 4'b0000;
    case (state)
        PROC_REQ: begin
            for (i = 0; i < 4; i = i + 1) begin
                if (arbiter_input.Com_Bus_Req_proc[i]) begin
                    arbiter_output.Com_Bus_Gnt_proc[i] = 1'b1;
                    break;
                end
            end
        end
        SNOOP_REQ: begin
            for (i = 0; i < 4; i = i + 1) begin
                if (arbiter_input.Com_Bus_Req_snoop[i]) begin
                    arbiter_output.Com_Bus_Gnt_snoop[i] = 1'b1;                       
                    break;
                end
            end
        end
    endcase
end

always @(*) begin
    arbiter_output.wr_en = 1'b0;  
    case (state)
        PROC_REQ: begin
            for (i = 0; i < 4; i = i + 1) begin
                if (arbiter_input.Com_Bus_Req_proc[i]) begin
                    arbiter_output.fifo_data_in = {2'b01, i[1:0]}; 
                  if (arbiter_output.fifo_data_in != prev_fifo_data_in || fifo_hold) begin 
                     
                        arbiter_output.wr_en = 1'b1;
                        fifo_hold = 1'b0; // Reset hold flag once written
                    end else begin
                        fifo_hold = 1'b1; // Hold if same grant repeats
                    end
                    break;
                end
            end
        end
        SNOOP_REQ: begin
            case (arbiter_output.Com_Bus_Gnt_snoop)
                4'b0001: arbiter_output.fifo_data_snoop = {2'b10, 2'b00};
                4'b0010: arbiter_output.fifo_data_snoop = {2'b10, 2'b01};
                4'b0100: arbiter_output.fifo_data_snoop = {2'b10, 2'b10};
                4'b1000: arbiter_output.fifo_data_snoop = {2'b10, 2'b11};
                default: arbiter_output.fifo_data_snoop = {2'b00, 2'b00};
            endcase
            arbiter_output.snoop_active  <= 1'b1;
        end
    endcase
end

always_comb begin
    if (arbiter_output.snoop_active)begin
         arbiter_output.no_snoop = 1'b0;
    end else if (~|arbiter_input.Com_Bus_Req_snoop || (^arbiter_input.Com_Bus_Req_snoop === 1'bx)) begin
        arbiter_output.no_snoop = 1'b1;
    end else begin
        arbiter_output.no_snoop = 1'b0;
    end
end

endmodule
