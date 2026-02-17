// img_rom_320x240.v
// 320x240 = 76800 bytes, 8-bit wide, synchronous read -> inferred BRAM (ROM)
// Vivado will infer Block RAM (RAMB18/RAMB36) automatically.
// Place "in_pixels_320x240.hex" in your Vivado project sources directory
// (same folder as the .xpr file, or add to project search path).

module img_rom_320x240 (
    input  wire        clk,
    input  wire [16:0] addr,
    output wire [7:0]  dout
);

    blk_mem_gen_0 u_bram (
        .clka  (clk),
        .addra (addr),
        .douta (dout)   // Always enabled
    );

endmodule