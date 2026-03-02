module chu_uart #(
    localparam ADDR_WIDTH    = 5,
    localparam DATA_WIDTH    = 32
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

endmodule