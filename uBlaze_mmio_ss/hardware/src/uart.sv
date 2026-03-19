module uart #(
    parameter CLK_FREQ   = 200_000_000,                          // 200MHz
    parameter FIFO_WIDTH = 2,
    parameter DBIT       = 8,
    parameter SB_TICK    = 16,                                   // 1 stop bit -> 16
                                                                 // 1.5 stop bit -> 24
                                                                 // 2 stop bit -> 32
    parameter BAUD_WIDTH = $clog2((CLK_FREQ / (16 * 9600)) - 1)  // count = f / (16 * baud_rate) - 1

) (
    input  logic                   clk,
    input  logic                   arst_n,

    input  logic                   rd_uart,
    input  logic                   wr_uart,
    input  logic [DBIT-1:0]        wdata,
    input  logic [BAUD_WIDTH-1:0]  baud_dvsr,

    input  logic                   rx,
    output logic                   rx_empty,

    output logic                   tx,
    output logic                   tx_full,
    output logic [DBIT-1:0]        rdata
);

    logic            tick;
    logic            rx_done_tick;
    logic            tx_done_tick;
    logic            tx_empty;
    logic            tx_fifo_not_empty;
    logic [DBIT-1:0] tx_fifo_dout;
    logic [DBIT-1:0] rx_data_out;
    
    baud_gen #(
        .CLK_FREQ( CLK_FREQ ),
        .BAUD_WIDTH( BAUD_WIDTH )
    ) u_baud_gen (
        .clk      ( clk       ),
        .arst_n   ( arst_n    ),
        .dvsr     ( baud_dvsr ),
        .baud_tick( tick      )
    );

    // Reciever
    fifo #(
        .DATA_WIDTH( DBIT       ),
        .ADDR_WIDTH( FIFO_WIDTH )
    ) u_rx_fifo (
        .clk      ( clk          ),
        .arst_n   ( arst_n       ),
        .wr       ( rx_done_tick ),
        .wr_data  ( rx_data_out  ),
        .full     (              ),
        .empty    ( rx_empty     ),
        .rd       ( rd_uart      ),
        .rd_data  ( rdata        )
    );

    uart_rx #(
        .DBIT   ( DBIT    ),
        .SB_TICK( SB_TICK )
    ) u_uart_rx (
        .clk           ( clk          ),
        .arst_n        ( arst_n       ),
        .baud_tick     ( tick         ),
        .rx            ( rx           ),
        .dout          ( rx_data_out  ),
        .rx_done_tick  ( rx_done_tick )
    );

    // Transmitter
    fifo #(
        .DATA_WIDTH( DBIT       ),
        .ADDR_WIDTH( FIFO_WIDTH )
    ) u_tx_fifo (
        .clk      ( clk          ),
        .arst_n   ( arst_n       ),
        .wr       ( wr_uart      ),
        .wr_data  ( wdata        ),
        .full     ( tx_full      ),
        .empty    ( tx_empty     ),
        .rd       ( tx_done_tick ),
        .rd_data  ( tx_fifo_dout )
    );

    uart_tx #(
        .DBIT   ( DBIT    ),
        .SB_TICK( SB_TICK )
    ) u_uart_tx (
        .clk           ( clk               ),
        .arst_n        ( arst_n            ),
        .baud_tick     ( tick              ),
        .tx_start      ( tx_fifo_not_empty ),
        .din           ( tx_fifo_dout      ),
        .tx            ( tx                ),
        .tx_done_tick  ( tx_done_tick      )
    );

    assign tx_fifo_not_empty = !tx_empty;

endmodule