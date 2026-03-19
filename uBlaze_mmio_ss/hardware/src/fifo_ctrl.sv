module fifo_ctrl #(
    parameter ADDR_WIDTH = 4
)(
    input  logic                   clk,
    input  logic                   arst_n,
    
    // Write Interface
    input  logic                   wr_en,
    output logic [ADDR_WIDTH-1:0]  wr_addr,
    output logic                   full,
    
    // Read Interface
    input  logic                   rd_en,
    output logic [ADDR_WIDTH-1:0]  rd_addr,
    output logic                   empty
);

    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] wr_ptr_next;
    logic [ADDR_WIDTH-1:0] wr_ptr_succ;
    
    logic [ADDR_WIDTH-1:0] rd_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr_next;
    logic [ADDR_WIDTH-1:0] rd_ptr_succ;

    logic                  full_logic;
    logic                  full_next;
    
    logic                  empty_logic;
    logic                  empty_next;

    always_ff @( posedge clk or negedge arst_n ) 
    begin
        if (!arst_n)
        begin
            wr_ptr      <= 'd0;
            rd_ptr      <= 'd0;
            full_logic  <= 'd0;
            empty_logic <= 'd1;
        end
        else
        begin
            wr_ptr      <= wr_ptr_next;
            rd_ptr      <= rd_ptr_next;
            full_logic  <= full_next;
            empty_logic <= empty_next;
        end
    end

    always_comb 
    begin
        wr_ptr_succ = wr_ptr + 'd1;
        rd_ptr_succ = rd_ptr + 'd1;

        wr_ptr_next = wr_ptr;
        rd_ptr_next = rd_ptr;
        full_next   = full_logic;
        empty_next  = empty_logic;
        case ({wr_en, rd_en})
            2'b01 :begin //read
                if (!empty_logic)
                begin
                    rd_ptr_next = rd_ptr_succ;
                    full_next   = 'd0;
                    if (rd_ptr_succ == wr_ptr)
                    begin
                        empty_next = 'd1;
                    end
                end
            end 
            2'b10 :begin //write
                if (!full_logic)
                begin
                    wr_ptr_next = wr_ptr_succ;
                    empty_next  = 'd0;
                    if (wr_ptr_succ == rd_ptr)
                    begin
                        full_next = 'd1;
                    end
                end
            end 
            2'b11 :begin //write and read
                wr_ptr_next = wr_ptr_succ;
                rd_ptr_next = rd_ptr_succ;
            end 
            default: ; // 2'b00 null operation
        endcase
    end

    assign wr_addr = wr_ptr;
    assign rd_addr = rd_ptr;
    assign full    = full_logic;
    assign empty   = empty_logic;

endmodule