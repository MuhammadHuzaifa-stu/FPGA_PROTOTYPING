module register_file #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    input  logic                  clk,
    input  logic                  arst_n,

    input  logic                  wr_en,
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic [DATA_WIDTH-1:0] wr_data,

    input  logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [DATA_WIDTH-1:0] rd_data
);
    //     Descending                 Ascending
    logic [DATA_WIDTH-1:0] reg_file [0:2**ADDR_WIDTH-1];

    always_ff @( posedge clk or negedge arst_n ) 
    begin
        if (!arst_n)
        begin
            for (int i = 0; i < 2**ADDR_WIDTH; i++) 
            begin
                reg_file[i] <= '0;
            end
        end 
        else if (wr_en)
        begin
            reg_file[wr_addr] <= wr_data;
        end
    end

    assign rd_data = reg_file[rd_addr];

endmodule