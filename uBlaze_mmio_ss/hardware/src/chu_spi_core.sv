module chu_spi_core #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32,
    parameter S          = 2
) (
    input  logic                  clk,
    input  logic                  arst_n,
    // ctrl
    input  logic                  cs,
    input  logic                  wr_en,
    input  logic                  rd_en,
    // data
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata,
    // external signals
    output logic                  spi_sclk,
    output logic                  spi_mosi,
    input  logic                  spi_miso,
    output logic [S-1:0]          spi_ss_n
);

    /*
        system freq = fsys
        spi freq    = fspi
        => there are fsys/fspi system clocks in one spi clock period.
        => spi cycle is composed of two parts, there are fsys / (2 * fspi)  system clocks in P0 or P1

        dvsr = fsys / (2 * fspi) - 1
    */
    localparam SPI_DATA_W = 8;
    localparam SPI_DVSR_W = 16;

    logic                      wr;
    logic                      wr_ss;
    logic                      wr_spi;
    logic                      wr_ctrl;

    logic [1+1+SPI_DVSR_W-1:0] ctrl_reg; // CPHAS(17) + CPOL(16) + DVSR(15-0)

    logic [S-1:0]              ss_n_reg;
    logic [SPI_DVSR_W-1:0]     dvsr;
    logic [SPI_DATA_W-1:0]     spi_out;

    logic                      cpol;
    logic                      cpha;
    logic                      spi_rdy;
    
    spi #(
        .SPI_DATA_W ( SPI_DATA_W ),
        .SPI_DVSR_W ( SPI_DVSR_W )
    ) u_spi (
        .clk           ( clk                   ),
        .arst_n        ( arst_n                ),
        .din           ( wdata[SPI_DATA_W-1:0] ),
        .dvsr          ( dvsr                  ),
        .start         ( wr_spi                ),
        .cpol          ( cpol                  ),
        .cpha          ( cpha                  ),
        .dout          ( spi_out               ),
        .sclk          ( spi_sclk              ),
        .mosi          ( spi_mosi              ),
        .miso          ( spi_miso              ),
        .rdy           ( spi_rdy               ),
        .spi_done_tick (                       )
    );

    always_ff @( posedge clk or negedge arst_n ) 
    begin
        if (!arst_n)
        begin
            ctrl_reg <= 'h0_03E7; // default dvsr = 999(fspi = 50kHz), cpol = 0, cpha = 0
            ss_n_reg <= '1;       // de-assert all slave select signals
        end
        else
        begin
            if (wr_ctrl)
            begin
                ctrl_reg <= wdata[1+1+SPI_DVSR_W-1:0];
            end
            if (wr_ss)
            begin
                ss_n_reg <= wdata[S-1:0];
            end
        end
    end

    assign wr       = cs & wr_en;
    assign wr_ss    = wr & (addr[1:0] == 2'b01);
    assign wr_spi   = wr & (addr[1:0] == 2'b10);
    assign wr_ctrl  = wr & (addr[1:0] == 2'b11);

    assign dvsr     = ctrl_reg[SPI_DVSR_W-1:0];
    assign cpol     = ctrl_reg[SPI_DVSR_W    ];
    assign cpha     = ctrl_reg[SPI_DVSR_W+1  ];

    assign spi_ss_n = ss_n_reg;
    assign rdata    =  {{(DATA_WIDTH-SPI_DATA_W-1){1'b0}}, spi_rdy, spi_out};

/*
Q:  How to use this for the SD Card?
    
A:  To use this specific core with your SD card:
    Select the card: Write 0x00 (or the appropriate bitmask) to addr offset 1.
    Initialize     : Keep dvsr at 999 (default) for the slow 74-clock pulse startup.
    Poll for Ready : Read addr offset 0 and check if Bit 8 is 1.
    Transfer       : Write your CMD0 byte to addr offset 2.
    Deselect       : After the transaction, write 0xFF to offset 1 to release the bus.
*/

endmodule