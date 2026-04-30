module sine_rom #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  arst_n,

    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data
);

    logic [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];
    logic [DATA_WIDTH-1:0] data_reg;

    initial 
    begin
        $readmemh("C:/FPGA_PROTOTYPING/uBlaze_mmio_ss/hardware/src/sine_table.txt", rom);
    end

    always_ff @( posedge clk or negedge arst_n ) 
    begin
        if (~arst_n) 
        begin
            data_reg <= '0;
        end 
        else 
        begin
            data_reg <= rom[addr];
        end
    end

    assign data = data_reg;

endmodule