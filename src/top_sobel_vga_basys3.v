// top_sobel_vga_basys3.v - UPDATED
// Switch sw0 (U17):
//   UP   (sw0=1) -> show original grayscale image
//   DOWN (sw0=0) -> show Sobel edge detection output

module top_sobel_vga_basys3 (
    input  wire        clk,
    input  wire        btnC,      // Center button = reset
    input  wire        sw0,       // Slide switch 0 (U17): 1=original, 0=sobel
    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue,
    output wire        Hsync,
    output wire        Vsync
);

    // -------------------------------------------------------
    // Clock generation
    // -------------------------------------------------------
    wire pclk;
    wire pll_locked;
    wire rst;

    clk_wiz_0 u_clkwiz (
        .clk_in1  (clk),
        .reset    (btnC),
        .clk_out1 (pclk),
        .locked   (pll_locked)
    );

    assign rst = ~pll_locked;

    // -------------------------------------------------------
    // VGA timing
    // -------------------------------------------------------
    wire [9:0] vga_x, vga_y;
    wire       active;
    wire       hsync_int, vsync_int;

    vga_timing u_vga (
        .pclk   (pclk),
        .rst    (rst),
        .x      (vga_x),
        .y      (vga_y),
        .active (active),
        .hsync  (hsync_int),
        .vsync  (vsync_int)
    );

    // -------------------------------------------------------
    // Sobel streaming engine (now outputs both pixels)
    // -------------------------------------------------------
    wire [7:0] sobel_pixel;
    wire [7:0] orig_pixel;

    sobel_stream u_sobel (
        .clk       (pclk),
        .rst       (rst),
        .vga_x     (vga_x),
        .vga_y     (vga_y),
        .active    (active),
        .sobel_out (sobel_pixel),
        .orig_out  (orig_pixel)
    );

    // -------------------------------------------------------
    // Switch mux: sw0=1 -> original, sw0=0 -> sobel
    // Register sw0 on pclk to avoid metastability
    // -------------------------------------------------------
    reg sw0_r1, sw0_r2;  // two-stage synchronizer

    always @(posedge pclk) begin
        if (rst) begin
            sw0_r1 <= 1'b0;
            sw0_r2 <= 1'b0;
        end else begin
            sw0_r1 <= sw0;
            sw0_r2 <= sw0_r1;
        end
    end

    // Select pixel based on synchronized switch
    wire [7:0] display_pixel = sw0_r2 ? orig_pixel : sobel_pixel;

    // -------------------------------------------------------
    // Sync delay to match 4-cycle sobel pipeline
    // -------------------------------------------------------
    reg [3:0] hsync_dly, vsync_dly;

    always @(posedge pclk) begin
        if (rst) begin
            hsync_dly <= 4'b1111;
            vsync_dly <= 4'b1111;
        end else begin
            hsync_dly <= {hsync_dly[2:0], hsync_int};
            vsync_dly <= {vsync_dly[2:0], vsync_int};
        end
    end

    assign Hsync    = hsync_dly[3];
    assign Vsync    = vsync_dly[3];

    // Grayscale output: top 4 bits to each channel
    assign vgaRed   = display_pixel[7:4];
    assign vgaGreen = display_pixel[7:4];
    assign vgaBlue  = display_pixel[7:4];

endmodule
