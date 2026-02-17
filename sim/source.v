`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/08/2026 10:56:44 PM
// Design Name: 
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sobel_frame #(
    parameter integer WIDTH  = 1600,
    parameter integer HEIGHT = 900
)();

    reg  [7:0] in_mem  [0:WIDTH*HEIGHT-1];
    reg  [7:0] out_mem [0:WIDTH*HEIGHT-1];

    integer x, y, idx;

    integer p00, p01, p02;
    integer p10, p11, p12;
    integer p20, p21, p22;

    integer gx, gy;
    integer mag;
    integer ax, ay;

    integer fhex;   // ?move declaration here

    function integer I;
        input integer xx;
        input integer yy;
        begin
            I = yy*WIDTH + xx;
        end
    endfunction

    function integer iabs;
        input integer v;
        begin
            if (v < 0) iabs = -v;
            else       iabs =  v;
        end
    endfunction

    initial begin
        $readmemh("in_pixels.hex", in_mem);

        for (idx = 0; idx < WIDTH*HEIGHT; idx = idx + 1)
            out_mem[idx] = 8'd0;

        for (y = 0; y < HEIGHT; y = y + 1) begin
            for (x = 0; x < WIDTH; x = x + 1) begin
                if (x == 0 || y == 0 || x == WIDTH-1 || y == HEIGHT-1) begin
                    out_mem[I(x,y)] = 8'd0;
                end else begin
                    p00 = in_mem[I(x-1,y-1)];
                    p01 = in_mem[I(x,  y-1)];
                    p02 = in_mem[I(x+1,y-1)];

                    p10 = in_mem[I(x-1,y)];
                    p11 = in_mem[I(x,  y)];
                    p12 = in_mem[I(x+1,y)];

                    p20 = in_mem[I(x-1,y+1)];
                    p21 = in_mem[I(x,  y+1)];
                    p22 = in_mem[I(x+1,y+1)];

                    gx = (-1*p00) + (0*p01) + (1*p02)
                       + (-2*p10) + (0*p11) + (2*p12)
                       + (-1*p20) + (0*p21) + (1*p22);

                    gy = ( 1*p00) + (2*p01) + (1*p02)
                       + ( 0*p10) + (0*p11) + (0*p12)
                       + (-1*p20) + (-2*p21) + (-1*p22);

                    ax  = iabs(gx);
                    ay  = iabs(gy);
                    mag = ax + ay; // L1 magnitude

                    if (mag > 255) mag = 255;
                    if (mag < 0)   mag = 0;

                    out_mem[I(x,y)] = mag[7:0];
                end
            end
        end

        fhex = $fopen("out_verilog.hex", "w");
        for (idx = 0; idx < WIDTH*HEIGHT; idx = idx + 1)
            $fwrite(fhex, "%02x\n", out_mem[idx]);
        $fclose(fhex);

        $display("Verilog Sobel done. Wrote out_verilog.hex");
        $finish;
    end

endmodule
