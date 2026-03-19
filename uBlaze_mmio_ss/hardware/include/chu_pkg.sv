package chu_io_pkg;
    
    localparam SYS_CLK_FREQ = 100_000_000; // 100MHz

    localparam BRIDGE_BASE  = 32'hc000_0000;

    localparam S0_SYS_TIMER = 0;
    localparam S1_UART1     = 1;
    localparam S2_LED       = 2;
    localparam S3_SW        = 3;

    localparam NUM_SLOTS    = 64; // we have 0-63 slots, -> slot0: timer, slot1: uart, slot2: gpo, slot3: gpi
    localparam SLOTS_USED   = 4;

endpackage