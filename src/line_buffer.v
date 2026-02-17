// line_buffer.v
// Single-port BRAM-inferred line buffer: 320 entries x 8-bit wide.
// Used by sobel_stream to hold two previous rows.
// Write and read happen on different addresses each cycle.

module line_buffer (
    input  wire       clk,
    input  wire       we,       
    input  wire [8:0] waddr,    
    input  wire [7:0] din,      
    input  wire [8:0] raddr,    
    output reg  [7:0] dout      
);
    reg [7:0] buf_mem [0:319];

    always @(posedge clk) begin
        if (we)
            buf_mem[waddr] <= din;
        dout <= buf_mem[raddr];
    end


endmodule
