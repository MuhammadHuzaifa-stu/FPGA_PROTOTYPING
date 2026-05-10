module chu_i2c_core 
    import i2c_pkg::ADDR_WIDTH;
    import i2c_pkg::DATA_WIDTH;
    import i2c_pkg::I2C_DATA_W;
    import i2c_pkg::I2C_DVSR_W;
    import i2c_pkg::I2C_CMD_W;
(
    input  logic clk,
    input  logic arst_n,
    // ctrl
    input  logic                  cs,
    input  logic                  wr_en,
    input  logic                  rd_en,
    // data
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic [DATA_WIDTH-1:0] rdata,
    // external signals
    inout  tri                    scl,
    inout  tri                    sda
);

    logic [I2C_DVSR_W-1:0]         dvsr_reg;
    logic [I2C_DATA_W-1:0]         dout;

    logic                          wr_i2c;
    logic                          wr_dvsr;

    logic                          rdy;
    logic                          ack;

    i2c_master #(
        .I2C_DATA_W ( I2C_DATA_W ),
        .I2C_DVSR_W ( I2C_DVSR_W ),
        .I2C_CMD_W  ( I2C_CMD_W  )
    ) u_i2c_master (
        .clk           ( clk                            ),
        .arst_n        ( arst_n                         ),
        .din           ( wdata[I2C_DATA_W-1:0]          ),
        .dvsr          ( dvsr_reg                       ),
        .cmd           ( wdata[I2C_DATA_W +: I2C_CMD_W] ),
        .wr_i2c        ( wr_i2c                         ),
        .scl           ( scl                            ),
        .sda           ( sda                            ),
        .dout          ( dout                           ),
        .rdy           ( rdy                            ),
        .i2c_done_tick (                                ),
        .ack           ( ack                            )
    );

    always_ff @( posedge clk or negedge arst_n ) 
    begin
        if ( !arst_n ) 
        begin
            dvsr_reg <= '0;
        end
        else
        begin
            if (wr_dvsr)
            begin
                dvsr_reg <= wdata[I2C_DVSR_W-1:0];
            end
        end
    end
    // decoding
    assign wr_dvsr = cs && wr_en && ~addr[0]; // addr 0 is for DVSR
    assign wr_i2c  = cs && wr_en &&  addr[0]; // addr 1 is for I2C command and data
    // read data
    assign rdata   = {{(DATA_WIDTH-I2C_DATA_W-1-1){1'b0}}, ack, rdy, dout};

endmodule