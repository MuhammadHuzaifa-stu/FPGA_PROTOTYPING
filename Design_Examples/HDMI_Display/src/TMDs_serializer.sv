module tmds_serializer 
(
    input  logic        clk_pixel,   // 25  MHz
    input  logic        clk_5x,      // 125 MHz
    input  logic        rst,         // active HIGH for OSERDES

    input  logic [9:0]  tmds_word,   // from tmds_encoder_dvi

    output logic        tmds_p,      // to HDMI connector
    output logic        tmds_n
);

    logic serial_out;  // between OSERDES and OBUFDS
    logic shift1;      // chain between slave and master
    logic shift2;      // chain between slave and master

    // MASTER: handles bits [7:0]
    OSERDESE2 #(
        .DATA_RATE_OQ   ("DDR"        ),  // DDR = use both edges of CLK
        .DATA_RATE_TQ   ("DDR"        ),  // tristate not used, doesn't matter
        .DATA_WIDTH     (10           ),  // 10-bit TMDS word
        .SERDES_MODE    ("MASTER"     ),  // this instance is master
        .TRISTATE_WIDTH (1            ),  // not using tristate
        .INIT_OQ        (1'b0         ),
        .INIT_TQ        (1'b0         ),
        .SRVAL_OQ       (1'b0         ),
        .SRVAL_TQ       (1'b0         ),
        .TBYTE_CTL      ("FALSE"      ),  // no tristate byte
        .TBYTE_SRC      ("FALSE"      )
    ) u_master (
        .OQ        ( serial_out      ), // ← serial data out
        // don't used outputs
        .OFB       (                 ), // leave open
        .SHIFTOUT1 (                 ), // leave open (master doesn't drive these)
        .SHIFTOUT2 (                 ), // leave open
        .TQ        (                 ), // leave open
        .TFB       (                 ), // leave open
        .TBYTEOUT  (                 ), // leave open

        .CLK       ( clk_5x          ), // 125 MHz fast clock
        .CLKDIV    ( clk_pixel       ), // 25  MHz slow clock

        .D1        ( tmds_word[0]    ), // LSB first
        .D2        ( tmds_word[1]    ),
        .D3        ( tmds_word[2]    ),
        .D4        ( tmds_word[3]    ),
        .D5        ( tmds_word[4]    ),
        .D6        ( tmds_word[5]    ),
        .D7        ( tmds_word[6]    ),
        .D8        ( tmds_word[7]    ),
        // shift chain: receives bits [9:8] from slave
        .SHIFTIN1  ( shift1          ), // <-- from slave's SHIFTOUT1
        .SHIFTIN2  ( shift2          ), // <-- from slave's SHIFTOUT2
        // control: all disabled
        .OCE       ( 1'b1            ), // always enable output
        .RST       ( rst             ), // active HIGH reset
        .T1        ( 1'b0            ),
        .T2        ( 1'b0            ),
        .T3        ( 1'b0            ),
        .T4        ( 1'b0            ),
        .TCE       ( 1'b0            ),
        .TBYTEIN   ( 1'b0            )
    );

    //------------------------------------------------------
    // SLAVE: handles bits [9:8]
    // NOTE: slave OQ is NOT used — data flows through
    //       SHIFTOUT → master's SHIFTIN
    //------------------------------------------------------
    OSERDESE2 #(
        .DATA_RATE_OQ   ("DDR"        ),
        .DATA_RATE_TQ   ("DDR"        ),
        .DATA_WIDTH     (10           ),
        .SERDES_MODE    ("SLAVE"      ),  // this instance is slave
        .TRISTATE_WIDTH (1            ),
        .INIT_OQ        (1'b0         ),
        .INIT_TQ        (1'b0         ),
        .SRVAL_OQ       (1'b0         ),
        .SRVAL_TQ       (1'b0         ),
        .TBYTE_CTL      ("FALSE"      ),
        .TBYTE_SRC      ("FALSE"      )
    ) u_slave (
        // outputs: shift chain to master
        .SHIFTOUT1 ( shift1          ), // --> master's SHIFTIN1
        .SHIFTOUT2 ( shift2          ), // --> master's SHIFTIN2
        // outputs not used on slave
        .OQ        (                 ), // slave OQ unused
        .OFB       (                 ),
        .TQ        (                 ),
        .TFB       (                 ),
        .TBYTEOUT  (                 ),
        // same clocks as master
        .CLK       ( clk_5x          ),
        .CLKDIV    ( clk_pixel       ),
        // data inputs
        // D1, D2 unused in slave
        .D1        ( 1'b0            ),
        .D2        ( 1'b0            ),
        // D3, D4 carry bits [9:8]
        .D3        ( tmds_word[8]    ),
        .D4        ( tmds_word[9]    ),
        // D5-D8 unused
        .D5        ( 1'b0            ),
        .D6        ( 1'b0            ),
        .D7        ( 1'b0            ),
        .D8        ( 1'b0            ),
        // slave shiftin unused
        .SHIFTIN1  ( 1'b0            ),
        .SHIFTIN2  ( 1'b0            ),
        // control
        .OCE       ( 1'b1            ),
        .RST       ( rst             ),
        .T1        ( 1'b0            ),
        .T2        ( 1'b0            ),
        .T3        ( 1'b0            ),
        .T4        ( 1'b0            ),
        .TCE       ( 1'b0            ),
        .TBYTEIN   ( 1'b0            )
    );

    // Convert single-ended serial to differential
    OBUFDS #(
        .IOSTANDARD ("TMDS_33"  ),  // tells Vivado this is HDMI/DVI
        .SLEW       ("SLOW"     )
    ) u_obufds (
        .I  ( serial_out ), // single ended in
        .O  ( tmds_p     ), // positive differential out
        .OB ( tmds_n     )  // negative differential out
    );

endmodule