// vga_timing.v
// VGA 640x480 @ 60Hz timing generator (25 MHz pixel clock)
// Horizontal: 640 active + 16 front porch + 96 sync + 48 back porch = 800 total
// Vertical:   480 active +  10 front porch +  2 sync + 33 back porch = 525 total
// Hsync and Vsync are ACTIVE LOW per VGA standard.

module vga_timing (
    input  wire        pclk,    // 25 MHz pixel clock
    input  wire        rst,     // synchronous reset, active high
    output reg  [9:0]  x,       // current horizontal pixel (0..799)
    output reg  [9:0]  y,       // current vertical line    (0..524)
    output wire        active,  // high when in visible region (x<640, y<480)
    output reg         hsync,   // horizontal sync (active low)
    output reg         vsync    // vertical sync   (active low)
);

    // Horizontal timing constants
    localparam H_ACTIVE     = 640;
    localparam H_FP         = 16;   // front porch
    localparam H_SYNC       = 96;   // sync pulse width
    localparam H_BP         = 48;   // back porch
    localparam H_TOTAL      = 800;  // H_ACTIVE+H_FP+H_SYNC+H_BP

    localparam H_SYNC_START = H_ACTIVE + H_FP;           // 656
    localparam H_SYNC_END   = H_ACTIVE + H_FP + H_SYNC;  // 752

    // Vertical timing constants
    localparam V_ACTIVE     = 480;
    localparam V_FP         = 10;
    localparam V_SYNC       = 2;
    localparam V_BP         = 33;
    localparam V_TOTAL      = 525;

    localparam V_SYNC_START = V_ACTIVE + V_FP;            // 490
    localparam V_SYNC_END   = V_ACTIVE + V_FP + V_SYNC;   // 492

    // Pixel counters
    always @(posedge pclk) begin
        if (rst) begin
            x <= 0;
            y <= 0;
        end else begin
            if (x == H_TOTAL - 1) begin
                x <= 0;
                if (y == V_TOTAL - 1)
                    y <= 0;
                else
                    y <= y + 1;
            end else begin
                x <= x + 1;
            end
        end
    end

    // Sync pulse generation (active low)
    always @(posedge pclk) begin
        if (rst) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            hsync <= ~((x >= H_SYNC_START) && (x < H_SYNC_END));
            vsync <= ~((y >= V_SYNC_START) && (y < V_SYNC_END));
        end
    end

    assign active = (x < H_ACTIVE) && (y < V_ACTIVE);

endmodule
