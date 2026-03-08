module mcs_top_vanilla #(
    parameter  BRG_BASE   = 32'hc000_0000 // defualt base address for the bridge
    localparam NUM_SW     = 16,
    localparam NUM_LED    = 6
) (
    input  logic                 clk,
    input  logic                 arst_n,

    // switches & LEDs
    input  logic [NUM_SW -1:0]   sw,
    output logic [NUM_LED-1:0]   led,

    // uart
    input logic                  uart_rx,
    output logic                 uart_tx
);

    localparam ADDR_WIDTH  = 32;
    localparam DATA_WIDTH  = 32;
    localparam BYTE_EN     = DATA_WIDTH / 8;
    localparam MMIO_ADDR_W = 21;

    // MCS IO bus
    logic                   IO_0_addr_strobe;
    logic                   IO_0_read_strobe;
    logic                   IO_0_write_strobe;
    logic [BYTE_EN   -1:0]  IO_0_byte_enable;
    logic [ADDR_WIDTH-1:0]  IO_0_address;

    logic [DATA_WIDTH-1:0]  IO_0_write_data;
    logic [DATA_WIDTH-1:0]  IO_0_read_data;
    logic                   IO_0_ready;

    // Fpro bus
    logic                   fp_mmio_cs;
    logic                   fp_wr;
    logic                   fp_rd;
    logic [MMIO_ADDR_W-1:0] fp_addr;
    logic [DATA_WIDTH -1:0] fp_wr_data;
    logic [DATA_WIDTH -1:0] fp_rd_data;

    // uBlaze_MCS
    uBlaze_MCS_wrapper u_cpu_unit (
        .clk_in1_0         ( clk               ),
        .reset_rtl_0       ( arst_n            ),
        .IO_0_addr_strobe  ( IO_0_addr_strobe  ),
        .IO_0_address      ( IO_0_address      ),
        .IO_0_byte_enable  ( IO_0_byte_enable  ),
        .IO_0_read_data    ( IO_0_read_data    ),
        .IO_0_read_strobe  ( IO_0_read_strobe  ),
        .IO_0_ready        ( IO_0_ready        ),
        .IO_0_write_data   ( IO_0_write_data   ),
        .IO_0_write_strobe ( IO_0_write_strobe )
    );

    // Bridge
    chu_mcs_bridge #(
        .BRG_BASE    ( BRG_BASE     ),
        .DATA_WIDTH  ( DATA_WIDTH   ),
        .BYTE_EN     ( BYTE_EN      ),
        .MMIO_ADDR_W ( MMIO_ADDR_W  )
    ) u_bridge_unit (
        // ublaze MCS IO bus
        .IO_0_addr_strobe  ( IO_0_addr_strobe  ),
        .IO_0_read_strobe  ( IO_0_read_strobe  ),
        .IO_0_write_strobe ( IO_0_write_strobe ),
        .IO_0_byte_enable  ( IO_0_byte_enable  ),
        .IO_0_address      ( IO_0_address      ),
        .IO_0_write_data   ( IO_0_write_data   ),
        .IO_0_read_data    ( IO_0_read_data    ),
        .IO_0_ready        ( IO_0_ready        ),
        // Fpro bus
        .fp_video_cs       ( 'b0               ), // TODO: support video in the future
        .fp_mmio_cs        ( fp_mmio_cs        ),
        .fp_wr             ( fp_wr             ),
        .fp_rd             ( fp_rd             ),
        .fp_addr           ( fp_addr           ),
        .fp_wr_data        ( fp_wr_data        ),
        .fp_rd_data        ( fp_rd_data        )
    );

    // MMIO peripheral
    mmio_sys_vanilla # (
        N_SW          ( NUM_SW         ),
        N_LED         ( NUM_LED        ),
        ADDR_WIDTH    ( ADDR_WIDTH     ), // [10:5] -> which slot, [4:0] -> which register
        DATA_WIDTH    ( DATA_WIDTH     ), // since microblaze supports 32-bit data width
        NUM_SLOTS     ( SLOTS_USED     ), // we have 0-63 slots, -> slot0: timer, slot1: uart, slot2: gpo, slot3: gpi
        NUM_SLOT_REGS ( 32             ), // per slot we have 32 registers, each register is of 32-bits wide. 
        COUNTER_WIDTH ( 48             )
    ) u_mmio_unit (
        .clk        ( clk         ),
        .arst_n     ( arst_n      ),
        // Fpro Bus
        .mmio_cs    ( fp_mmio_cs  ),
        .mmio_wr    ( fp__wr      ),
        .mmio_rd    ( fp__rd      ),

        .mmio_addr  ( fp_addr     ),
        .mmio_wdata ( fp_wr_data  ),
        .mmio_rdata ( fp_rd_data  ),
        // Switches and LEDs
        .sw         ( sw          ),
        .led        ( led         ),
        // UART
        .uart_tx    ( uart_tx     ),
        .uart_rx    ( uart_rx     )
    );

endmodule