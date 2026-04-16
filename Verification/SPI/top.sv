module top ();
    
    localparam SPI_DATA_W = 8,
    localparam SPI_DVSR_W = 16

    logic clk;
    logic arst_n;

    initial begin
        clk <= 1'b0;
        forever #5 clk <= ~clk; // 100MHz clock
    end

    initial begin
        arst_n <= 1'b1;
        #1;
        arst_n <= 1'b0;
        #10;
        arst_n <= 1'b1;
    end

    spi_if # (
        .SPI_DATA_W ( SPI_DATA_W ),
        .SPI_DVSR_W ( SPI_DVSR_W )
    ) u_spi_if (
        .clk    ( clk    ),
        .arst_n ( arst_n )
    );

    spi # (
        .SPI_DATA_W ( SPI_DATA_W ),
        .SPI_DVSR_W ( SPI_DVSR_W )
    ) u_spi (
        .clk           ( clk                    ),
        .arst_n        ( arst_n                 ),
        .din           ( u_spi_if.din           ),
        .dvsr          ( u_spi_if.dvsr          ),
        .start         ( u_spi_if.start         ),
        .cpol          ( u_spi_if.cpol          ),
        .cpha          ( u_spi_if.cpha          ),
        .dout          ( u_spi_if.dout          ),
        .rdy           ( u_spi_if.rdy           ),
        .spi_done_tick ( u_spi_if.spi_done_tick ),
        .sclk          ( u_spi_if.sclk          ),
        .mosi          ( u_spi_if.mosi          ),
        .miso          ( u_spi_if.miso          )
    );

    initial begin
        $display("--- SPI Verification Environment Starting ---");
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top);
    end

endmodule