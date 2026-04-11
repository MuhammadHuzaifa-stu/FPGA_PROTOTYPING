module mmio_sys_vanilla 
    import chu_io_pkg::SYS_CLK_FREQ;
    import chu_io_pkg::SLOTS_USED;
    import chu_io_pkg::S0_SYS_TIMER;
    import chu_io_pkg::S1_UART1;
    import chu_io_pkg::S2_LED;
    import chu_io_pkg::S3_SW;
    import chu_io_pkg::S4_USER;
    import chu_io_pkg::S5_ADC;
    import chu_io_pkg::S6_PWM;
    import chu_io_pkg::S7_BTN;
    import chu_io_pkg::S8_SS;
    import chu_io_pkg::PWM_RESOLTUIN;
    import chu_io_pkg::PWM_CHANNELS;
    import chu_io_pkg::NUM_SLOTS;
    import chu_io_pkg::SPI_SLAVES;
# (
    parameter N_SW          = 16,
    parameter N_LED         = 6,
    parameter ADDR_WIDTH    = 21, // [10:5] -> which slot, [4:0] -> which register
    parameter DATA_WIDTH    = 32, // since microblaze supports 32-bit data width
    parameter NUM_SLOT_REGS = 32, // per slot we have 32 registers, each register is of 32-bits wide. 
    parameter COUNTER_WIDTH = 48
) (
    input  logic                  clk,
    input  logic                  arst_n,
    // Fpro Bus
    input  logic                  mmio_cs,
    input  logic                  mmio_wr,
    input  logic                  mmio_rd,

    input  logic [ADDR_WIDTH-1:0] mmio_addr,
    input  logic [DATA_WIDTH-1:0] mmio_wdata,
    output logic [DATA_WIDTH-1:0] mmio_rdata,
    // Switches and LEDs
    input  logic [N_SW -1:0]      sw,
    output logic [N_LED-1:0]      led,
    // UART
    output logic                  uart_tx,
    input  logic                  uart_rx,
    // SPI
    output logic                  spi_clk,
    output logic                  mosi,
    input  logic                  miso,
    output logic [SPI_SLAVES-1:0] ss_n
);

    localparam SLOT_ADDR_WIDTH = $clog2(NUM_SLOT_REGS);
    localparam DBIT            = 8; // data bit width for uart
    localparam SYS_CLK         = SYS_CLK_FREQ; // 100MHz

    logic [NUM_SLOTS-1:0]       slot_cs_array;
    logic [NUM_SLOTS-1:0]       slot_wr_array;
    logic [NUM_SLOTS-1:0]       slot_rd_array;
    logic [SLOT_ADDR_WIDTH-1:0] slot_reg_addr_array[NUM_SLOTS-1:0];
    logic [DATA_WIDTH-1:0]      slot_rdata_array   [NUM_SLOTS-1:0];
    logic [DATA_WIDTH-1:0]      slot_wdata_array   [NUM_SLOTS-1:0];
    
    logic [N_LED-1:0]           gpo;
    logic [PWM_CHANNELS-1:0]    pwm;
    
    logic                  spi_sclk;
    logic                  spi_mosi;
    logic                  spi_miso;
    logic [SPI_SLAVES-1:0] spi_ss_n;

    assign led = sw[N_SW - 1] ? pwm[N_LED-1:0] : gpo; // if MSB switch is ON, then connect PWM to LEDs, else connect GPO to LEDs

    // mmio_controller
    chu_mmio_controller # (
        .MMIO_ADDR_WIDTH ( ADDR_WIDTH      ),
        .MMIO_DATA_WIDTH ( DATA_WIDTH      ),
        .NUM_SLOTS       ( NUM_SLOTS       ),
        .NUM_SLOT_REGS   ( NUM_SLOT_REGS   )
    ) u_ctrl_unit (
        .clk                 ( clk                 ),
        .arst_n              ( arst_n              ),
        .mmio_cs             ( mmio_cs             ),
        .mmio_wr             ( mmio_wr             ),
        .mmio_rd             ( mmio_rd             ),
        .mmio_addr           ( mmio_addr           ),
        .mmio_wdata          ( mmio_wdata          ),
        .mmio_rdata          ( mmio_rdata          ),
        .slot_cs_array       ( slot_cs_array       ),
        .slot_wr_array       ( slot_wr_array       ),
        .slot_rd_array       ( slot_rd_array       ),
        .slot_reg_addr_array ( slot_reg_addr_array ),
        .slot_rdata_array    ( slot_rdata_array    ),
        .slot_wdata_array    ( slot_wdata_array    )  
    );

    // Slot0: Timer
    chu_timer # (
        .ADDR_WIDTH    ( SLOT_ADDR_WIDTH ),
        .DATA_WIDTH    ( DATA_WIDTH      ),
        .COUNTER_WIDTH ( COUNTER_WIDTH   )
    ) u_timer_slot0 (
        .clk    ( clk                               ), 
        .arst_n ( arst_n                            ),
        .cs     ( slot_cs_array      [S0_SYS_TIMER] ),
        .wr_en  ( slot_wr_array      [S0_SYS_TIMER] ),
        .rd_en  ( slot_rd_array      [S0_SYS_TIMER] ),
        .addr   ( slot_reg_addr_array[S0_SYS_TIMER] ),
        .wdata  ( slot_wdata_array   [S0_SYS_TIMER] ),
        .rdata  ( slot_rdata_array   [S0_SYS_TIMER] )
    );

    // Slot1: UART
    chu_uart #(
        .ADDR_WIDTH   ( SLOT_ADDR_WIDTH ),
        .DATA_WIDTH   ( DATA_WIDTH      ),
        .CLK_FREQ     ( SYS_CLK         ), // 100MHz
        .FIFO_DEPTH_W ( 2               )
    ) u_uart_slot1 (
        .clk     ( clk                           ), 
        .arst_n  ( arst_n                        ),
        .cs      ( slot_cs_array      [S1_UART1] ),
        .wr_en   ( slot_wr_array      [S1_UART1] ),
        .rd_en   ( slot_rd_array      [S1_UART1] ),
        .addr    ( slot_reg_addr_array[S1_UART1] ),
        .wdata   ( slot_wdata_array   [S1_UART1] ),
        .rdata   ( slot_rdata_array   [S1_UART1] ),
        .uart_tx ( uart_tx                       ),
        .uart_rx ( uart_rx                       )
    );

    // Slot2: GPO (LED)
    chu_gpo #(
        .ADDR_WIDTH ( SLOT_ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH      ),
        .OUT_WIDTH  ( N_LED           )
    ) u_led_slot2 (
        .clk     ( clk                         ),
        .arst_n  ( arst_n                      ),
        .cs      ( slot_cs_array      [S2_LED] ),
        .wr_en   ( slot_wr_array      [S2_LED] ),
        .rd_en   ( slot_rd_array      [S2_LED] ),
        .addr    ( slot_reg_addr_array[S2_LED] ),
        .wdata   ( slot_wdata_array   [S2_LED] ),
        .rdata   ( slot_rdata_array   [S2_LED] ),
        .gpo_out ( gpo                         )
    );

    // Slot3: GPI (SW)
    chu_gpi #(
        .ADDR_WIDTH ( SLOT_ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH      ),
        .IN_WIDTH   ( N_SW            )
    ) u_sw_slot3 (
        .clk    ( clk                        ),
        .arst_n ( arst_n                     ),
        .cs     ( slot_cs_array      [S3_SW] ),
        .wr_en  ( slot_wr_array      [S3_SW] ),
        .rd_en  ( slot_rd_array      [S3_SW] ),
        .addr   ( slot_reg_addr_array[S3_SW] ),
        .wdata  ( slot_wdata_array   [S3_SW] ),
        .rdata  ( slot_rdata_array   [S3_SW] ),
        .gpi_in ( sw                         )
    );

    // Slot6: PWM
    chu_io_pwm_core #(
        .R          ( PWM_RESOLTUIN   ),
        .DATA_WIDTH ( DATA_WIDTH      ),
        .ADDR_WIDTH ( SLOT_ADDR_WIDTH ),
        .NUM_PWM    ( PWM_CHANNELS    )
    ) u_pwm_slot6 (
        .clk    ( clk                         ),
        .arst_n ( arst_n                      ),
        .cs     ( slot_cs_array      [S6_PWM] ),
        .wr_en  ( slot_wr_array      [S6_PWM] ),
        .rd_en  ( slot_rd_array      [S6_PWM] ),
        .addr   ( slot_reg_addr_array[S6_PWM] ),
        .wdata  ( slot_wdata_array   [S6_PWM] ),
        .rdata  ( slot_rdata_array   [S6_PWM] ),
        .pwm_out( pwm                         )
    );

    // Slot9: SPI
    chu_spi_core #(
        .ADDR_WIDTH ( SLOT_ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH      ),
        .S          ( SPI_SLAVES      ) // support up to 1 SPI slaves
    ) u_spi_slot9 (
        .clk      ( clk                         ),
        .arst_n   ( arst_n                      ),
        .cs       ( slot_cs_array      [S9_SPI] ),
        .wr_en    ( slot_wr_array      [S9_SPI] ),
        .rd_en    ( slot_rd_array      [S9_SPI] ),
        .addr     ( slot_reg_addr_array[S9_SPI] ),
        .wdata    ( slot_wdata_array   [S9_SPI] ),
        .rdata    ( slot_rdata_array   [S9_SPI] ),
        .spi_sclk ( spi_sclk                    ),
        .spi_mosi ( spi_mosi                    ),
        .spi_miso ( spi_miso                    ),
        .spi_ss_n ( spi_ss_n                    )
    );
    
    assign slot_rdata_array[S4_USER] = 'd0; // Not used yet
    assign slot_rdata_array[S5_ADC ] = 'd0; // Not used yet
    assign slot_rdata_array[S7_BTN ] = 'd0; // Not used yet
    assign slot_rdata_array[S8_SS  ] = 'd0; // Not used yet

    // assign zero's to remaining unsed slots to avoid latches
    generate

        for (genvar i=SLOTS_USED; i<NUM_SLOTS; i++)
        begin
            always_comb 
            begin : unused_slot_blk
                slot_rdata_array[i] = 'd0;
            end
        end

    endgenerate

endmodule