module chu_mmio_controller #(
    parameter  MMIO_ADDR_WIDTH = 21, // [10:5] -> which slot, [4:0] -> which register
    parameter  MMIO_DATA_WIDTH = 32, // since microblaze supports 32-bit data width
    parameter  NUM_SLOTS       = 64, // we have 0-63 slots, -> slot0: timer, slot1: uart, slot2: gpo, slot3: gpi
    parameter  NUM_SLOT_REGS   = 32, // per slot we have 32 registers, each register is of 32-bits wide. 
    localparam SLOT_ADDR_WIDTH = $clog2(NUM_SLOT_REGS),
    localparam NUM_SLOT_WIDTH  = $clog2(NUM_SLOTS)
) (
    // Fpro bus
    input  logic                       clk,
    input  logic                       arst_n,

    input  logic                       mmio_cs,
    input  logic                       mmio_wr,
    input  logic                       mmio_rd,

    input  logic [MMIO_ADDR_WIDTH-1:0] mmio_addr,
    input  logic [MMIO_DATA_WIDTH-1:0] mmio_wdata,
    output logic [MMIO_DATA_WIDTH-1:0] mmio_rdata,
    // Slot interface
    output logic [NUM_SLOTS-1:0]       slot_cs_array,
    output logic [NUM_SLOTS-1:0]       slot_wr_array,
    output logic [NUM_SLOTS-1:0]       slot_rd_array,
    output logic [SLOT_ADDR_WIDTH-1:0] slot_reg_addr_array[NUM_SLOTS-1:0],
    input  logic [MMIO_DATA_WIDTH-1:0] slot_rdata_array   [NUM_SLOTS-1:0],
    output logic [MMIO_DATA_WIDTH-1:0] slot_wdata_array   [NUM_SLOTS-1:0]
);

    logic [NUM_SLOT_WIDTH-1 :0] slot_addr;
    logic [SLOT_ADDR_WIDTH-1:0] reg_addr;

    assign slot_addr = mmio_addr[SLOT_ADDR_WIDTH +: NUM_SLOT_WIDTH ]; // which slot     -> 0-63
    assign reg_addr  = mmio_addr[0               +: SLOT_ADDR_WIDTH]; // which register -> 0-31

    always_comb 
    begin : slot_cs_ctrl_blk
        slot_cs_array = 'd0;
        if (mmio_cs) 
        begin
            slot_cs_array[slot_addr] = 1'b1;
        end
    end

    generate
        for (genvar i=0; i<NUM_SLOTS; i++)
        begin
            always_comb 
            begin : slot_ctrl_blk
                slot_wr_array      [i] = mmio_wr;
                slot_rd_array      [i] = mmio_rd;
                slot_reg_addr_array[i] = reg_addr;
                slot_wdata_array   [i] = mmio_wdata;
            end
        end
    endgenerate

    assign mmio_rdata = slot_rdata_array[slot_addr];

endmodule