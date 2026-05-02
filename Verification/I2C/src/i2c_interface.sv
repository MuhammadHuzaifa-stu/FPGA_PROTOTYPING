interface i2c_interface #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32
) (
    input  logic clk,
    input  logic arst_n
);

    logic                  cs;
    logic                  wr_en;
    logic                  rd_en;

    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;

    logic                  scl;
    tri                    sda;

    // clocking drv_cb @(posedge clk);
    //     default input #1ns output #1ns;
    //     output din, dvsr, start, cpol, cpha, miso;
    //     input  rdy, spi_done_tick;
    // endclocking

    // clocking mon_cb @(posedge clk);
    //     default input #1ns output #1ns;
    //     input din, dvsr, start, cpol, cpha, dout, rdy, spi_done_tick, sclk, mosi, miso;
    // endclocking

    // Modports: Define the "direction" of signals for different components
    // modport DRV (clocking drv_cb, input clk, arst_n);
    // modport MON (clocking mon_cb, input clk, arst_n);

    modport DUT (
        input  clk,
        input  arst_n,
        input  cs,
        input  wr_en,
        input  rd_en,
        input  addr,
        input  wdata,

        output rdata,

        output scl,
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
        input  scl
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