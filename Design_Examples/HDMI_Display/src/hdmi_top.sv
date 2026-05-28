module hdmi_top 
    import display_pkg::CD;
(    
    input  logic          sys_clk_p,
    input  logic          sys_clk_n,
    input  logic          sys_rstn,

    input  logic [13:0]   sw,

    output logic          hdmi_clk_p,   // differential clock 
    output logic          hdmi_clk_n,
    output logic          hdmi_data0_p, // Blue  + syncs 
    output logic          hdmi_data0_n,
    output logic          hdmi_data1_p, // Green 
    output logic          hdmi_data1_n,
    output logic          hdmi_data2_p, // Red 
    output logic          hdmi_data2_n
);

    logic          clk_25MHz;
    logic          clk_125MHz;

    logic          hsync;
    logic          vsync;
    logic [CD-1:0] rgb;

    logic          video_en;
    logic [9:0]    TMDs_blue;
    logic [9:0]    TMDs_green;
    logic [9:0]    TMDs_red;

    // clocking_wizard
    // input: 100MHz differential clock
    // outputs: 25MHz for pixel clock, 100MHz for logic, 250MHz for TMDS serialization 
    clk_wiz_0 u_clk_wiz (
        .clk_in1_p  ( sys_clk_p  ),
        .clk_in1_n  ( sys_clk_n  ), 
        .resetn     ( sys_rstn   ),
        .clk_25MHz  ( clk_25MHz  ),
        .clk_125MHz ( clk_125MHz )
    );

    // RGB generator for VGA demo
    vga_demo u_vga_demo (
        .clk      ( clk_25MHz  ),
        .sw       ( sw         ),
        .video_en ( video_en   ),
        .hsync    ( hsync      ),
        .vsync    ( vsync      ),
        .rgb      ( rgb        ) 
    );

    ///////////////////////////////////////
    // TMDs
    ///////////////////////////////////////

    tmds_encoder_dvi u_tmds_encoder_dvi_b (
        .clk_pix ( clk_25MHz                        ),
        .rst_pix ( sys_rstn                         ),
        .data_in ( {rgb[0 +: CD/3], rgb[0 +: CD/3]} ), // Blue
        .ctrl_in ( {vsync, hsync}                   ), // control data: vsync and hsync
        .de      ( video_en                         ), // data enable: always on for demo
        .tmds    ( TMDs_blue                        )  // TMDS data for Blue channel
    );

    tmds_encoder_dvi u_tmds_encoder_dvi_g (
        .clk_pix ( clk_25MHz                              ),
        .rst_pix ( sys_rstn                               ),
        .data_in ( {rgb[CD/3 +: CD/3], rgb[CD/3 +: CD/3]} ), // Green
        .ctrl_in ( 2'b00                                  ),
        .de      ( video_en                               ),
        .tmds    ( TMDs_green                             )  // TMDS data for Green channel
    );

    tmds_encoder_dvi u_tmds_encoder_dvi_r (
        .clk_pix ( clk_25MHz                                  ),
        .rst_pix ( sys_rstn                                   ),
        .data_in ( {rgb[2*CD/3 +: CD/3], rgb[2*CD/3 +: CD/3]} ), // Red
        .ctrl_in ( 2'b00                                      ),
        .de      ( video_en                                   ),
        .tmds    ( TMDs_red                                   )  // TMDS data for Red channel
    );

    ///////////////////////////////////////
    // OSERDES
    ///////////////////////////////////////

    

endmodule