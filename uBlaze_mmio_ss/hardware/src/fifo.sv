module fifo #( //First Word Fall Through
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    input  logic                  clk,
    input  logic                  arst_n,

    // Write Interface
    input  logic                  wr,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    // Read Interface
    input  logic                  rd,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    logic [ADDR_WIDTH-1:0] ctrl_wr_addr;
    logic [ADDR_WIDTH-1:0] ctrl_rd_addr;
    
    logic [DATA_WIDTH-1:0] rf_rd_data;

    logic                  ctrl_wr_en;
    logic                  ctrl_full;

    assign ctrl_wr_en = wr & !ctrl_full;
    assign full       = ctrl_full;

    fifo_ctrl #(
        .ADDR_WIDTH( ADDR_WIDTH )
    ) u_fifo_ctrl (
        .clk    ( clk          ),
        .arst_n ( arst_n       ),
        .wr_en  ( wr           ),
        .wr_addr( ctrl_wr_addr ),
        .full   ( ctrl_full    ),
        .rd_en  ( rd           ),
        .rd_addr( ctrl_rd_addr ),
        .empty  ( empty        )
    );

    register_file #(
        .DATA_WIDTH( DATA_WIDTH ),
        .ADDR_WIDTH( ADDR_WIDTH )
    ) u_reg_file (
        .clk    ( clk          ),
        .arst_n ( arst_n       ),
        .wr_en  ( ctrl_wr_en   ),
        .wr_data( wr_data      ),
        .wr_addr( ctrl_wr_addr ),
        .rd_addr( ctrl_rd_addr ),
        .rd_data( rf_rd_data   )
    );

    always_ff @( posedge clk or negedge arst_n ) 
    begin
        if (!arst_n)
        begin
            rd_data <= 'd0;
        end
        else if (rd)
        begin
            rd_data <= rf_rd_data;
        end
    end
    
endmodule