module chu_mcs_bridge #(
    parameter  BRG_BASE    = 32'hc000_0000, // defualt base address for the bridge
    parameter  DATA_WIDTH  = 32,
    parameter  BYTE_EN     = DATA_WIDTH / 8,
    parameter  MMIO_ADDR_W = 21
) (
    // ublaze MCS IO bus
    input  logic                    IO_0_addr_strobe,
    input  logic                    IO_0_read_strobe,
    input  logic                    IO_0_write_strobe,
    input  logic [BYTE_EN   -1:0]   IO_0_byte_enable,
    input  logic [DATA_WIDTH-1:0]   IO_0_address,
    input  logic [DATA_WIDTH-1:0]   IO_0_write_data,
    output logic [DATA_WIDTH-1:0]   IO_0_read_data,
    output logic                    IO_0_ready,

    // Fpro bus
    output logic                    fp_video_cs,
    output logic                    fp_mmio_cs,
    output logic                    fp_wr,
    output logic                    fp_rd,
    output logic [MMIO_ADDR_W-1:0]  fp_addr,
    output logic [DATA_WIDTH -1:0]  fp_wr_data,
    input  logic [DATA_WIDTH -1:0]  fp_rd_data
);

    logic                    mcs_bridge_en;
    logic [DATA_WIDTH-1-2:0] word_addr; 

    assign word_addr      = IO_0_address[DATA_WIDTH-1:2]; // word aligned address
    assign mcs_bridge_en  = (IO_0_address[DATA_WIDTH-1:MMIO_ADDR_W+2+1] == BRG_BASE[DATA_WIDTH-1:MMIO_ADDR_W+2+1]);

    // [22:0] -> 23-bit byte address. [22:2] -> 21-bit word address. [23] -> select video or mmio
    assign fp_video_cs    = mcs_bridge_en && (IO_0_address[MMIO_ADDR_W+2] == 'b1);
    assign fp_mmio_cs     = mcs_bridge_en && (IO_0_address[MMIO_ADDR_W+2] == 'b0);
    assign fp_addr        = word_addr[MMIO_ADDR_W-1:0];

    assign fp_wr          = IO_0_write_strobe;
    assign fp_rd          = IO_0_read_strobe;
    assign IO_0_ready     = 'b1; // always ready

    assign fp_wr_data     = IO_0_write_data;
    assign IO_0_read_data = fp_rd_data;

    /*
    
    From the master’s perspective, after it initiates a read or write operation, 
    
    - IO_Ready is asserted immediately in the next rising edge of the clock. 
    This implies that operation is completed in one clock cycle and involves 
    no handshaking mechanism. 
    
    - IO_Addr_Strobe signal is not checked since we assume that MCS I/O module 
    always asserts it in a read or write operation. 
    
    - IO_Byte_Enable signal is also not used since we assume that the I/O 
    transaction is always performed on a word basis, as defined in the 
    chu_io_rw.h
    
    */

endmodule