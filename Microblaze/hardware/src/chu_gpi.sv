module chu_gpi #(
    localparam ADDR_WIDTH = 5,
    localparam DATA_WIDTH = 32,
    localparam IN_WIDTH   = 16
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
    // external signal
    output logic [IN_WIDTH  -1:0] gpi_in
);

    logic [IN_WIDTH -1:0] gpi_reg;

    assign rdata[IN_WIDTH-1:0]          = gpi_reg;
    assign rdata[DATA_WIDTH-1:IN_WIDTH] = 'd0;

    always_ff @( posedge clk or negedge arst_n ) 
    begin
        if (!arst_n)
        begin
            gpi_reg <= '0;
        end
        else if (cs && rd_en)
        begin
            gpi_reg <= gpi_in;
        end
    end
    
endmodule