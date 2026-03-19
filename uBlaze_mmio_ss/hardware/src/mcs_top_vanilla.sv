module mcs_top_vanilla 
    import chu_io_pkg::BRIDGE_BASE;
# (
    localparam NUM_SW     = 16,
    localparam NUM_LED    = 6
) (
    input  logic                 sys_clk_p,
    input  logic                 sys_clk_n,
    input  logic                 sys_rstn,

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

    logic                   clk;
    logic                   arst_n;
    logic                   locked;

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

    assign arst_n = locked & sys_rstn;

    // clocking wizard
    clock_wrapper u_clock_gen (
        .CLK_IN1_D_0_clk_n ( sys_clk_n  ),
        .CLK_IN1_D_0_clk_p ( sys_clk_p  ),
        .clk_out1_0        ( clk        ),
        .locked_0          ( locked     ),
        .resetn_0          ( sys_rstn   )
    );

    // uBlaze_MCS
    cpu_wrapper u_cpu_unit (
        .Clk_0             ( clk               ),
        .Reset_0           ( arst_n            ),
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
        .BRG_BASE    ( BRIDGE_BASE  ),
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
        .fp_video_cs       (                   ), // TODO: support video in the future
        .fp_mmio_cs        ( fp_mmio_cs        ),
        .fp_wr             ( fp_wr             ),
        .fp_rd             ( fp_rd             ),
        .fp_addr           ( fp_addr           ),
        .fp_wr_data        ( fp_wr_data        ),
        .fp_rd_data        ( fp_rd_data        )
    );

    // MMIO peripheral
    mmio_sys_vanilla # (
        .N_SW          ( NUM_SW         ),
        .N_LED         ( NUM_LED        ),
        .ADDR_WIDTH    ( MMIO_ADDR_W    ), // [10:5] -> which slot, [4:0] -> which register
        .DATA_WIDTH    ( DATA_WIDTH     ), // since microblaze supports 32-bit data width
        .NUM_SLOT_REGS ( 32             ), // per slot we have 32 registers, each register is of 32-bits wide. 
        .COUNTER_WIDTH ( 48             )
    ) u_mmio_unit (
        .clk        ( clk         ),
        .arst_n     ( arst_n      ),
        // Fpro Bus
        .mmio_cs    ( fp_mmio_cs  ),
        .mmio_wr    ( fp_wr       ),
        .mmio_rd    ( fp_rd       ),

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