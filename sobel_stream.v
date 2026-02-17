// sobel_stream.v - UPDATED
// Added orig_out port to pass through the original pixel
// with the same pipeline delay as sobel_out

module sobel_stream (
    input  wire        clk,
    input  wire        rst,
    input  wire [9:0]  vga_x,
    input  wire [9:0]  vga_y,
    input  wire        active,
    output reg  [7:0]  sobel_out,
    output reg  [7:0]  orig_out    // NEW: original pixel, pipeline-matched
);

    // Image coordinates (320x240) = VGA >> 1
    wire [8:0] img_x = vga_x[9:1];
    wire [8:0] img_y = vga_y[9:1];

    // -------------------------------------------------------
    // Running row-base address: row_base = img_y * 320
    // -------------------------------------------------------
    reg [16:0] row_base;
    reg  [8:0] prev_img_y;

    always @(posedge clk) begin
        if (rst) begin
            row_base   <= 0;
            prev_img_y <= 9'd1;
        end else if (active) begin
            if (img_y != prev_img_y) begin
                prev_img_y <= img_y;
                row_base   <= ({img_y, 8'b0} + {img_y, 6'b0});
            end
        end
    end

    // -------------------------------------------------------
    // ROM interface
    // -------------------------------------------------------
    wire [16:0] rom_addr = row_base + {8'b0, img_x};

    wire [7:0] rom_dout;
    img_rom_320x240 u_rom (
        .clk  (clk),
        .addr (rom_addr),
        .dout (rom_dout)
    );

    // -------------------------------------------------------
    // Line buffers
    // -------------------------------------------------------
    reg [8:0] wr_ptr;
    reg       wr_en;
    reg [7:0] lb0_din;
    reg [8:0] lb0_waddr;

    wire [7:0] lb0_dout, lb1_dout;

    line_buffer u_lb0 (
        .clk   (clk),
        .we    (wr_en),
        .waddr (lb0_waddr),
        .din   (lb0_din),
        .raddr (img_x),
        .dout  (lb0_dout)
    );

    line_buffer u_lb1 (
        .clk   (clk),
        .we    (wr_en),
        .waddr (wr_ptr),
        .din   (rom_dout),
        .raddr (img_x),
        .dout  (lb1_dout)
    );

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr    <= 0;
            wr_en     <= 0;
            lb0_waddr <= 0;
            lb0_din   <= 0;
        end else begin
            wr_en     <= active;
            wr_ptr    <= img_x;
            lb0_din   <= lb1_dout;
            lb0_waddr <= wr_ptr;
        end
    end

    // -------------------------------------------------------
    // 3x3 shift register window
    // -------------------------------------------------------
    reg [7:0] r0_p0, r0_p1, r0_p2;
    reg [7:0] r1_p0, r1_p1, r1_p2;
    reg [7:0] r2_p0, r2_p1, r2_p2;

    always @(posedge clk) begin
        if (rst) begin
            r0_p0<=0; r0_p1<=0; r0_p2<=0;
            r1_p0<=0; r1_p1<=0; r1_p2<=0;
            r2_p0<=0; r2_p1<=0; r2_p2<=0;
        end else if (active) begin
            r0_p0 <= r0_p1; r0_p1 <= r0_p2; r0_p2 <= lb0_dout;
            r1_p0 <= r1_p1; r1_p1 <= r1_p2; r1_p2 <= lb1_dout;
            r2_p0 <= r2_p1; r2_p1 <= r2_p2; r2_p2 <= rom_dout;
        end
    end

    // -------------------------------------------------------
    // Sobel computation
    // -------------------------------------------------------
    reg signed [10:0] gx, gy;
    reg        [10:0] abs_gx, abs_gy;
    reg        [11:0] mag;

    always @(posedge clk) begin
        if (rst) begin
            gx <= 0; gy <= 0;
        end else begin
            gx <= ( - $signed({3'b0, r0_p0})
                    + $signed({3'b0, r0_p2})
                    - ($signed({3'b0, r1_p0}) <<< 1)
                    + ($signed({3'b0, r1_p2}) <<< 1)
                    - $signed({3'b0, r2_p0})
                    + $signed({3'b0, r2_p2}) );

            gy <= (   $signed({3'b0, r0_p0})
                    + ($signed({3'b0, r0_p1}) <<< 1)
                    + $signed({3'b0, r0_p2})
                    - $signed({3'b0, r2_p0})
                    - ($signed({3'b0, r2_p1}) <<< 1)
                    - $signed({3'b0, r2_p2}) );
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            abs_gx <= 0; abs_gy <= 0; mag <= 0;
        end else begin
            abs_gx <= gx[10] ? (~gx[10:0] + 1'b1) : gx[10:0];
            abs_gy <= gy[10] ? (~gy[10:0] + 1'b1) : gy[10:0];
            mag    <= {1'b0, abs_gx} + {1'b0, abs_gy};
        end
    end

    // -------------------------------------------------------
    // Pipeline delay for border, active, AND original pixel
    // 4-stage pipeline to match sobel latency
    // -------------------------------------------------------
    reg [3:0] border_pipe;
    reg [3:0] active_pipe;

    // NEW: 4-stage pipeline for original pixel (rom_dout)
    // to match the 4-cycle sobel pipeline delay
    reg [7:0] orig_pipe_0, orig_pipe_1, orig_pipe_2, orig_pipe_3;

    wire border_now = (img_x == 0) || (img_x == 319) ||
                      (img_y == 0) || (img_y == 239);

    always @(posedge clk) begin
        if (rst) begin
            border_pipe  <= 4'b0;
            active_pipe  <= 4'b0;
            orig_pipe_0  <= 8'h00;
            orig_pipe_1  <= 8'h00;
            orig_pipe_2  <= 8'h00;
            orig_pipe_3  <= 8'h00;
        end else begin
            border_pipe  <= {border_pipe[2:0], border_now};
            active_pipe  <= {active_pipe[2:0], active};
            // Shift original pixel through pipeline
            orig_pipe_0  <= rom_dout;
            orig_pipe_1  <= orig_pipe_0;
            orig_pipe_2  <= orig_pipe_1;
            orig_pipe_3  <= orig_pipe_2;
        end
    end

    wire is_border     = border_pipe[3];
    wire is_active_out = active_pipe[3];

    // -------------------------------------------------------
    // Final outputs
    // -------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            sobel_out <= 8'h00;
            orig_out  <= 8'h00;
        end else if (!is_active_out) begin
            sobel_out <= 8'h00;
            orig_out  <= 8'h00;
        end else if (is_border) begin
            sobel_out <= 8'h00;
            orig_out  <= orig_pipe_3; // border still shows original
        end else begin
            // Clamp Sobel magnitude to 8 bits
            sobel_out <= mag[11:8] ? 8'hFF : mag[7:0];
            orig_out  <= orig_pipe_3;
        end
    end

endmodule