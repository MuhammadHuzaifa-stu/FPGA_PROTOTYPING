interface i2c_interface 
    import i2c_pkg::ADDR_WIDTH;
    import i2c_pkg::DATA_WIDTH;
(
    input  logic clk,
    input  logic arst_n
);

    logic                  cs;
    logic                  wr_en;
    logic                  rd_en;

    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;

    tri                    scl;
    tri                    sda;

    modport DUT (
        input  clk,
        input  arst_n,
        input  cs,
        input  wr_en,
        input  rd_en,
        input  addr,
        input  wdata,

        output rdata,

        inout  scl,
        inout  sda
    );

    modport SL (
        input  scl,
        inout  sda
    );

    modport DRV (
        input  clk,
        input  arst_n,

        output cs,
        output wr_en,
        output rd_en,
        output addr,
        output wdata,

        input  rdata,

        inout  sda,
        inout  scl
    );

    modport MON (
        input  clk,
        input  arst_n,

        input  cs,
        input  wr_en,
        input  rd_en,
        input  addr,
        input  wdata,

        input  rdata,

        input  sda,
        input  scl
    );

endinterface