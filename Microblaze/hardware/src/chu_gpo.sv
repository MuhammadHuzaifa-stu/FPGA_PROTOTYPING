module chu_gpo #(
    localparam ADDR_WIDTH = 5,
    localparam DATA_WIDTH = 32,
    localparam OUT_WIDTH  = 6
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
    output logic [OUT_WIDTH -1:0] gpo_out
);

    logic [OUT_WIDTH -1:0] gpo_reg;

    assign rdata   = 'd0;
    assign gpo_out = gpo_reg;

    always_ff @( posedge clk or negedge arst_n ) 
    begin
        if (!arst_n)
        begin
            gpo_reg <= '0;
        end
        else if (cs && wr_en)
        begin
            gpo_reg <= wdata[OUT_WIDTH-1:0];
        end
    end
    
endmodule