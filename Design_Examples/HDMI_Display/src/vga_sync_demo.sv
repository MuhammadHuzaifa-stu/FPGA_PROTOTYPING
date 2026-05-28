module vga_sync_demo 
    import display_pkg::CD;

    import display_pkg::HD;
    import display_pkg::HF;
    import display_pkg::HB;
    import display_pkg::HR;
    import display_pkg::HT;

    import display_pkg::VD;
    import display_pkg::VF;
    import display_pkg::VB;
    import display_pkg::VR;
    import display_pkg::VT;

(
    input  logic                  clk,
    input  logic                  arst_n,
    // stream input 
    input  logic [CD-1:0]         vga_si_rgb,
    // to vga monitor
    output logic                  video_en,
    output logic                  hsync,
    output logic                  vsync,
    output logic [CD-1:0]         rgb,
    // frame counter output
    output logic [$clog2(HT):0]   hc,
    output logic [$clog2(VT):0]   vc
);

    logic [1:0]            q_reg;
    logic                  tick_25MHz;

    logic [$clog2(HT):0]   x;
    logic [$clog2(VT):0]   y;

    logic                  hsync_i;
    logic                  vsync_i;
    logic                  video_on_i;

    logic                  hsync_reg;
    logic                  vsync_reg;
    logic [CD-1:0]         rgb_reg;

    // generate 25MHz tick from 100MHz input clock
    always_ff @(posedge clk or negedge arst_n) 
    begin
        if(!arst_n)
        begin
            q_reg <= 0;
        end
        else
        begin
            q_reg <= q_reg + 1;
        end
    end

    assign tick_25MHz = (q_reg == 2'b11);

    frame_counter #(
        .HMAX(HT),
        .VMAX(VT)
    ) u_frame_counter (
        .clk         ( clk        ),
        .arst_n      ( arst_n     ),
        .incr        ( tick_25MHz ),
        .sync_clr    ( 1'b0       ), // never clear sync
        .hcount      ( x          ),
        .vcount      ( y          ),
        .frame_start (            ),
        .frame_end   (            )
    );

    // horixontal sync: decoding
    assign hsync_i = (x >= (HD + HF)) && (x <= (HD + HF + HR - 1)) ? 0 : 1;
    // vertical sync: decoding
    assign vsync_i = (y >= (VD + VF)) && (y <= (VD + VF + VR - 1)) ? 0 : 1;
    // NOTE: Since HB and VB are related to CRT (required time to move back 
    //       physically), they do not affect the sync signal. Only HR and VR 
    //       matter for sync.

    // display on/off
    assign video_on_i = (x < HD) && (y < VD);

    //buffered output to vga monitor
    always_ff @(posedge clk or negedge arst_n) 
    begin
        vsync_reg <= vsync_i;
        hsync_reg <= hsync_i;
        if (video_on_i)
        begin
            rgb_reg <= vga_si_rgb;
        end
        else
        begin
            rgb_reg <= 0; // black when video off
        end
    end

    //output
    assign hsync    = hsync_reg;
    assign vsync    = vsync_reg;
    assign rgb      = rgb_reg;
    assign hc       = x;
    assign vc       = y;
    assign video_en = video_on_i;

endmodule