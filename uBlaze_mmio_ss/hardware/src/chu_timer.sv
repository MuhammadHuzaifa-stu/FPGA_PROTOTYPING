module chu_timer #(
    parameter ADDR_WIDTH    = 5,
    parameter DATA_WIDTH    = 32,
    parameter COUNTER_WIDTH = 48
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
    output logic [DATA_WIDTH-1:0] rdata
);

    logic [COUNTER_WIDTH-1:0] counter_reg;
    logic                     ctrl_reg;
    logic                     wr;
    logic                     clr;
    logic                     go;

    always_ff @( posedge clk or negedge arst_n ) 
    begin : counter_blk
        if (!arst_n)
        begin
            counter_reg <= '0;
        end
        else if (clr)
        begin
            counter_reg <= '0;
        end
        else if (go)
        begin
            counter_reg <= counter_reg + 1;
        end
    end

    always_ff @( posedge clk or negedge arst_n ) 
    begin : ctrl_reg_blk
        if (!arst_n)
        begin
            ctrl_reg <= '0;
        end
        else if (wr)
        begin
            ctrl_reg <= wdata[0];
        end
    end

    assign wr  = wr_en && cs && (addr[1:0] == 2'b10);
    assign clr = wr && wdata[1];
    assign go  = ctrl_reg;

    assign rdata = (addr[0]) ? {{(COUNTER_WIDTH-DATA_WIDTH){1'b0}}, counter_reg[COUNTER_WIDTH-1:DATA_WIDTH]} 
                             : counter_reg[DATA_WIDTH-1:0];

endmodule