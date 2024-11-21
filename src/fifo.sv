`define BUF_WIDTH 2
`define BUF_SIZE (1 << `BUF_WIDTH)

module fifo (
    input [3:0] data_in,             
    input rst,                       
    input wr_en,                     
    input rd_en,                     
    output reg [3:0] buf_out,        
    output buf_empty,                
    output buf_full,                 
    output reg [`BUF_WIDTH:0] fifo_counter  // Counter to track number of elements.
);

    reg [3:0] buffer [`BUF_SIZE-1:0];  // FIFO storage.
    reg [`BUF_WIDTH-1:0] rd_ptr, wr_ptr; 

    assign buf_full = (fifo_counter == `BUF_SIZE);  
    assign buf_empty = (fifo_counter == 0);         

    always @(posedge wr_en or posedge rd_en or posedge rst) begin
        if (rst) begin
            fifo_counter <= 0;      
            rd_ptr <= 0;            
            wr_ptr <= 0;            
            buf_out <= 4'b0000;     
         
        end else begin
            // Write operation.
            if (wr_en && !buf_full) begin
                buffer[wr_ptr] <= data_in;   // Write data to FIFO.
                wr_ptr <= wr_ptr + 1;        
                fifo_counter <= fifo_counter + 1; // Increment counter.
            end

            // Read operation.
            if (rd_en && !buf_empty) begin
                buf_out <= buffer[rd_ptr];   
                rd_ptr <= rd_ptr + 1;        
                fifo_counter <= fifo_counter - 1; 
            end
        end
    end
endmodule
