package i2c_pkg;

    // i2c core
    localparam ADDR_WIDTH = 5;
    localparam DATA_WIDTH = 32;
    // i2c master
    localparam I2C_DATA_W = 8;
    localparam I2C_DVSR_W = 16;
    localparam I2C_CMD_W  = 3;
    
    typedef enum { 
        IDLE,
        HOLD,
        START1, START2,
        DATA1, DATA2, DATA3, DATA4,
        DATA_END,
        RESTART,
        STOP1, STOP2
    } state_t;

endpackage