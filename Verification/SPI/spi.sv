module spi #(
    parameter SPI_DATA_W = 8,
    parameter SPI_DVSR_W = 16
) (
    input  logic                  clk,
    input  logic                  arst_n,

    input  logic [SPI_DATA_W-1:0] din,
    input  logic [SPI_DVSR_W-1:0] dvsr,
    input  logic                  start,
    input  logic                  cpol,
    input  logic                  cpha,

    output logic [SPI_DATA_W-1:0] dout,
    output logic                  rdy,
    output logic                  spi_done_tick,

    output logic                  sclk,
    output logic                  mosi,
    input  logic                  miso
);
    
    // CPOL: The clock polarity is the value of sclk when it is idle, which can be either 0 or 1.
    // CPHA: The clock phase is harder to define. One interpretation is whether a clock
    //       edge is used in driving the first data bit. If cpha is 1, the master drives the bit
    //       at the first transition edge. If cpha is 0, the master drives the bit at the zeroth
    //       transition edge (which means no edge or not the first edge).

    // >>>> Figure 16.4 of the book <<<<

    typedef enum { 
        IDLE,
        CPHA_DELAY,
        P0,
        P1
    } state_t;

    // Mode 0:: cpol=0 , cpha=0
    // Mode 1:: cpol=0 , cpha=1
    // Mode 2:: cpol=1 , cpha=0
    // Mode 3:: cpol=1 , cpha=1

    state_t                        CS;
    state_t                        NS;

    logic                          p_clk;
    logic [SPI_DVSR_W-1:0]         c_reg;
    logic [SPI_DVSR_W-1:0]         c_next;

    logic                          rdy_i;
    logic                          spi_clk_reg;
    logic                          spi_clk_next;
    logic                          spi_done_tick_i;

    logic [$clog2(SPI_DATA_W)-1:0] n_reg;
    logic [$clog2(SPI_DATA_W)-1:0] n_next;

    logic [SPI_DATA_W-1:0]         si_reg;
    logic [SPI_DATA_W-1:0]         so_reg;
    logic [SPI_DATA_W-1:0]         si_next;
    logic [SPI_DATA_W-1:0]         so_next;

    always_ff @( posedge clk or negedge arst_n ) 
    begin : state_update_blk
        if (!arst_n)
        begin
            CS          <= IDLE;
            c_reg       <= 'd0;
            n_reg       <= 'd0;
            si_reg      <= 'd0;
            so_reg      <= 'd0;
            spi_clk_reg <= 'd0;
        end
        else
        begin
            CS          <= NS;
            c_reg       <= c_next;
            n_reg       <= n_next;
            si_reg      <= si_next;
            so_reg      <= so_next;
            spi_clk_reg <= spi_clk_next;
        end
    end

    always_comb 
    begin : ns_blk
        NS              = CS;
        rdy_i           = 1'b0;
        spi_done_tick_i = 1'b0;
        c_next          = c_reg;
        si_next         = si_reg;
        so_next         = so_reg;
        n_next          = n_reg;
        case (CS)
            IDLE: begin
                rdy_i = 1'b1;
                if (start)
                begin
                    so_next = din;
                    n_next  = 'd0;
                    c_next  = 'd0;
                    if (cpha)
                        NS = CPHA_DELAY;
                    else
                        NS = P0;
                end
            end
            CPHA_DELAY: begin
                if (c_reg == dvsr)
                begin
                    NS     = P0;
                    c_next = 'd0;
                end
            end
            P0: begin
                if (c_reg == dvsr)
                begin
                    NS      = P1;
                    c_next  = 'd0;
                    si_next = {si_reg[SPI_DATA_W-2:0], miso};
                end
                else
                begin
                    c_next = c_reg + 1'b1;
                end
            end
            default: begin // P1
                if (c_reg == dvsr)
                begin
                    if (n_reg == SPI_DATA_W-1)
                    begin
                        NS              = IDLE;
                        spi_done_tick_i = 1'b1;
                    end
                    else
                    begin
                        NS      = P0;
                        c_next  = 'd0;
                        n_next  = n_reg + 1'b1;
                        so_next = {so_reg[SPI_DATA_W-2:0], 1'b0};
                    end
                end
                else
                begin
                    c_next = c_reg + 1'b1;
                end
            end 
        endcase
    end

    assign rdy           = rdy_i;
    assign spi_done_tick = spi_done_tick_i;

    // lookahead output decoding
    assign p_clk        = (CS == P1 && ~cpha) || (CS == P0 && cpha);
    assign spi_clk_next = cpol ? ~p_clk : p_clk;

    // output
    assign sclk = spi_clk_reg;
    assign mosi = so_reg[SPI_DATA_W-1];
    assign dout = si_reg;

endmodule