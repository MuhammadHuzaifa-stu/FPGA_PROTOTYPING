module vga_demo
    import display_pkg::CD;
    import display_pkg::HT;
    import display_pkg::VT;
(
    input  logic          clk,
    input  logic [13:0]   sw,

    output logic          video_en,
    output logic          hsync,
    output logic          vsync,
    output logic [CD-1:0] rgb
);

    logic [$clog2(HT):0] hc;
    logic [$clog2(VT):0] vc;

    logic [CD-1:0]       bar_rgb;
    logic [CD-1:0]       back_rgb;
    logic [CD-1:0]       gray_rgb;
    logic [CD-1:0]       color_rgb;
    logic [CD-1:0]       vga_rgb;

    logic                bypass_bar;
    logic                bypass_gray;

    assign back_rgb    = sw[13:2];
    assign bypass_bar  = sw[1];
    assign bypass_gray = sw[0];
    
    bar_demo u_bar (
        .x  ( hc      ),
        .y  ( vc      ),
        .rgb( bar_rgb )
    );

    rgb2gray u_gray (
        .color_rgb( color_rgb ),
        .gray_rgb ( gray_rgb  )
    );

    vga_sync_demo u_sync (
        .clk       ( clk      ),
        .arst_n    ( 1'b1     ),
        .vga_si_rgb( vga_rgb  ),
        .video_en  ( video_en )
        .hsync     ( hsync    ),
        .vsync     ( vsync    ),
        .rgb       ( rgb      ),
        .hc        ( hc       ),
        .vc        ( vc       )
    );

    assign color_rgb = bypass_bar  ? back_rgb  : bar_rgb;
    assign vga_rgb   = bypass_gray ? color_rgb : gray_rgb;

endmodule