module chu_uart #(
    parameter CLK_FREQ      = 200_000_000,  // 200MHz
    parameter ADDR_WIDTH    = 5,
    parameter DATA_WIDTH    = 32,
    parameter FIFO_DEPTH_W  = 8
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

    output logic                  uart_tx,
    input  logic                  uart_rx
);

    // count = f / (16 * baud_rate) - 1
    localparam BAUD_WIDTH = $clog2((CLK_FREQ / (16 * 9600)) - 1);  
    localparam DBIT       = 8;
    localparam SB_TICK    = 16;                                   // 1 stop bit -> 16
                                                                  // 1.5 stop bit -> 24
                                                                  // 2 stop bit -> 32

    logic                  wr_uart;
    logic                  rd_uart;

    logic                  tx_full;
    logic                  rx_empty;

    logic                  wr_dvsr;
    logic [BAUD_WIDTH-1:0] dvsr_reg;

    logic [DBIT      -1:0] rdata_uart;

    uart #(
        .CLK_FREQ  ( CLK_FREQ     ),
        .DBIT      ( DBIT         ),
        .SB_TICK   ( SB_TICK      ),
        .FIFO_WIDTH( FIFO_DEPTH_W )
    ) u_uart (
        .clk      ( clk             ),
        .arst_n   ( arst_n          ),
        .rd_uart  ( rd_uart         ),
        .wr_uart  ( wr_uart         ),
        .wdata    ( wdata[DBIT-1:0] ),
        .baud_dvsr( dvsr_reg        ),
        .rx       ( uart_rx         ),
        .rx_empty ( rx_empty        ),
        .tx       ( uart_tx         ),
        .tx_full  ( tx_full         ),
        .rdata    ( rdata_uart      )
    );

    always_ff @( posedge clk or negedge arst_n ) 
    begin
        if(!arst_n)
            dvsr_reg <= 'd0;
        else if (wr_dvsr)
            dvsr_reg <= wdata[BAUD_WIDTH-1:0];
    end

    // register 0: read only, status reg
    // register 1: write only, baud rate divisor
    // register 2: write only, data reg
    // register 3: read only, data reg

    assign wr_dvsr = (cs & wr_en & (addr[1:0] == 2'b01));
    assign wr_uart = (cs & wr_en & (addr[1:0] == 2'b10));
    assign rd_uart = (cs & rd_en & (addr[1:0] == 2'b11));

    assign rdata   = {{(DATA_WIDTH-1-1-1){1'b0}}, tx_full, rx_empty, rdata_uart}; 

endmodule