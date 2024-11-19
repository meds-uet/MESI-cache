`define BUF_WIDTH 2
`define BUF_SIZE (1 << `BUF_WIDTH)

module fifo (
    input [3:0] data_in,             // 4-bit data input.
    input rst,                       // Reset signal.
    input wr_en,                     // Write enable.
    input rd_en,                     // Read enable.
    output reg [3:0] buf_out,        // 4-bit data output.
    output buf_empty,                // Empty flag.
    output buf_full,                 // Full flag.
    output reg [`BUF_WIDTH:0] fifo_counter  // Counter to track number of elements.
);

    reg [3:0] buffer [`BUF_SIZE-1:0];  // FIFO storage.
    reg [`BUF_WIDTH-1:0] rd_ptr, wr_ptr; // Read and write pointers.

    assign buf_full = (fifo_counter == `BUF_SIZE);  // Full condition.
    assign buf_empty = (fifo_counter == 0);         // Empty condition.

    always @(posedge wr_en or posedge rd_en or posedge rst) begin
        if (rst) begin
            fifo_counter <= 0;      // Reset counter.
            rd_ptr <= 0;            // Reset read pointer.
            wr_ptr <= 0;            // Reset write pointer.
            buf_out <= 4'b0000;     // Reset output
         
        end else begin
            // Write operation.
            if (wr_en && !buf_full) begin
                buffer[wr_ptr] <= data_in;   // Write data to FIFO.
                wr_ptr <= wr_ptr + 1;        // Increment write pointer.
                fifo_counter <= fifo_counter + 1; // Increment counter.
            end

            // Read operation.
            if (rd_en && !buf_empty) begin
                buf_out <= buffer[rd_ptr];   // Read data from FIFO.
                rd_ptr <= rd_ptr + 1;        // Increment read pointer.
                fifo_counter <= fifo_counter - 1; // Decrement counter.
            end
        end
    end
endmodule
