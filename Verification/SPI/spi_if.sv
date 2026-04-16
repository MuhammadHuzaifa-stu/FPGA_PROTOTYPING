interface spi_if #(
    parameter SPI_DATA_W = 8,
    parameter SPI_DVSR_W = 16
) (
    input  logic clk,
    input  logic arst_n
);

    logic [SPI_DATA_W-1:0] din;
    logic [SPI_DVSR_W-1:0] dvsr;
    logic                  start;
    logic                  cpol;
    logic                  cpha;

    logic [SPI_DATA_W-1:0] dout;
    logic                  rdy;
    logic                  spi_done_tick;

    logic                  sclk;
    logic                  mosi;
    logic                  miso;

    // Driver Clocking Block: Used by the Driver class
    clocking drv_cb @(posedge clk);
        default input #1ns output #1ns;
        output din, dvsr, start, cpol, cpha, miso;
        input  rdy, spi_done_tick;
    endclocking

    // Monitor Clocking Block: Used by the Monitor class
    clocking mon_cb @(posedge clk);
        default input #1ns output #1ns;
        input din, dvsr, start, cpol, cpha, dout, rdy, spi_done_tick, sclk, mosi, miso;
    endclocking

    // Modports: Define the "direction" of signals for different components
    modport DRV (clocking drv_cb, input clk, arst_n);
    modport MON (clocking mon_cb, input clk, arst_n);

endinterface //spi_if