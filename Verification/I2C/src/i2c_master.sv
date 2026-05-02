module i2c_master #(
    parameter I2C_DATA_W = 8,
    parameter I2C_DVSR_W = 16,
    parameter I2C_CMD_W  = 3
) (
    input  logic                  clk,
    input  logic                  arst_n,

    input  logic [I2C_DATA_W-1:0] din,
    input  logic [I2C_DVSR_W-1:0] dvsr, // dvsr = fsys / (4 * fi2c) => dvsr has quater of the period of i2c clock
    input  logic [I2C_CMD_W-1:0]  cmd,
    input  logic                  wr_i2c,
    
    output tri                    scl,
    inout  tri                    sda,

    output logic [I2C_DATA_W-1:0] dout,
    output logic                  rdy,
    output logic                  i2c_done_tick,
    output logic                  ack
);

    // visit chapter no 17 of the book for I2C protocol details and timing diagrams.

    localparam START_CMD   = 3'b000;
    localparam WR_CMD      = 3'b001;
    localparam RD_CMD      = 3'b010;
    localparam STOP_CMD    = 3'b011;
    localparam RESTART_CMD = 3'b100;

    typedef enum { 
        IDLE,
        HOLD,
        START1, START2,
        DATA1, DATA2, DATA3, DATA4,
        DATA_END,
        RESTART,
        STOP1, STOP2
    } state_t;

    state_t                        CS;
    state_t                        NS;

    logic [I2C_DVSR_W-1:0]         c_reg;
    logic [I2C_DVSR_W-1:0]         c_next;
    logic [I2C_DVSR_W-1:0]         qutr;
    logic [I2C_DVSR_W-1:0]         half;

    logic [I2C_DATA_W  :0]         tx_reg;
    logic [I2C_DATA_W  :0]         tx_next;
    logic [I2C_DATA_W  :0]         rx_reg;
    logic [I2C_DATA_W  :0]         rx_next;

    logic [I2C_CMD_W -1:0]         cmd_reg;
    logic [I2C_CMD_W -1:0]         cmd_next;
    logic [I2C_CMD_W   :0]         bit_reg;
    logic [I2C_CMD_W   :0]         bit_next;

    logic                          sda_out;
    logic                          scl_out;
    logic                          sda_reg;
    logic                          scl_reg;
    logic                          data_phs;

    logic                          done_tick_i;
    logic                          rdy_i;
    logic                          into;
    logic                          nack;

    // buffer for SDA & SCL lines
    always_ff @( posedge clk or negedge arst_n )
    begin : sda_scl_buff_blk
        if (!arst_n)
        begin
            sda_reg <= 1'b1;
            scl_reg <= 1'b1;
        end
        else
        begin
            sda_reg <= sda_out;
            scl_reg <= scl_out;
        end
    end

    // only master drives SCL.
    assign scl  = scl_reg ? 1'bz : 1'b0;

    // sda are with pull-upresisters and becomes high when not driven
    // "into" signal asserted when sdatinto master.
    assign into = (data_phs && cmd_reg == RD_CMD && bit_reg < I2C_DATA_W ) || 
                  (data_phs && cmd_reg == WR_CMD && bit_reg == I2C_DATA_W);
    assign sda  = (into || sda_reg) ? 1'bz : 1'b0;

    assign dout = rx_reg[I2C_DATA_W:1];
    assign ack  = rx_reg[0]; // obtained from slave write
    assign nack = din[0];    // used by master in read operation

    always_ff @( posedge clk or negedge arst_n ) 
    begin : state_update_blk
        if (!arst_n)
        begin
            CS      <= IDLE;
            c_reg   <= 'd0;
            bit_reg <= 'd0;
            cmd_reg <= 'd0;
            tx_reg  <= 'd0;
            rx_reg  <= 'd0;
        end
        else
        begin
            CS      <= NS;
            c_reg   <= c_next;
            bit_reg <= bit_next;
            cmd_reg <= cmd_next;
            tx_reg  <= tx_next;
            rx_reg  <= rx_next;
        end
    end

    assign qutr = dvsr;
    assign half = {qutr[I2C_DVSR_W-2:0], 1'b0}; // half = qutr * 2

    always_comb
    begin
        NS          = CS;
        c_next      = c_reg + 'b1;
        bit_next    = bit_reg;
        cmd_next    = cmd_reg;
        tx_next     = tx_reg;
        rx_next     = rx_reg;

        done_tick_i = 1'b0;
        rdy_i       = 1'b0;
        scl_out     = 1'b1;
        sda_out     = 1'b1;
        data_phs    = 1'b0;

        case (CS)
            IDLE : begin
                rdy_i = 1'b1;
                if (wr_i2c && cmd == START_CMD)
                begin
                    NS     = START1;
                    c_next = 'd0;
                end
            end
            START1 : begin
                sda_out = 1'b0;
                if (c_reg == half)
                begin
                    NS     = START2;
                    c_next = 'd0;
                end
            end
            START2 : begin
                sda_out = 1'b0;
                scl_out = 1'b0;
                if (c_reg == qutr)
                begin
                    NS     = HOLD;
                    c_next = 'd0;
                end
            end
            HOLD : begin
                rdy_i   = 1'b1;
                sda_out = 1'b0;
                scl_out = 1'b0;
                if (wr_i2c)
                begin
                    cmd_next = cmd;
                    c_next   = 'd0;
                    case (cmd)
                        RESTART_CMD, START_CMD : begin
                            NS = RESTART;
                        end
                        STOP_CMD : begin
                            NS = STOP1;
                        end
                        default: begin              // red/write byte
                            NS       = DATA1;
                            bit_next = 'd0;
                            tx_next  = {din, nack}; // nack used as NACK in read
                        end 
                    endcase
                end
            end
            DATA1 : begin
                sda_out  = tx_reg[I2C_DATA_W];
                scl_out  = 1'b0;
                data_phs = 1'b1;
                if (c_reg == qutr)
                begin
                    NS     = DATA2;
                    c_next = 'd0;
                end
            end
            DATA2 : begin
                sda_out  = tx_reg[I2C_DATA_W];
                data_phs = 1'b1;
                if (c_reg == qutr)
                begin
                    NS     = DATA3;
                    c_next = 'd0;
                    rx_next = {rx_reg[I2C_DATA_W-1:0], sda}; // shift data in
                end
            end
            DATA3 : begin
                sda_out  = tx_reg[I2C_DATA_W];
                data_phs = 1'b1;
                if (c_reg == qutr)
                begin
                    NS     = DATA4;
                    c_next = 'd0;
                end
            end
            DATA4 : begin
                sda_out  = tx_reg[I2C_DATA_W];
                scl_out  = 1'b0;
                data_phs = 1'b1;
                if (c_reg == qutr)
                begin
                    c_next = 'd0;
                    if (bit_reg == I2C_DATA_W)
                    begin
                        NS          = DATA_END;
                        done_tick_i = 1'b1;
                    end
                    else
                    begin
                        NS       = DATA1;
                        bit_next = bit_reg + 'b1;
                        tx_next  = {tx_reg[I2C_DATA_W-1:0], 1'b0}; // shift data out
                    end
                end                
            end
            DATA_END : begin
                sda_out = 1'b0;
                scl_out = 1'b0;
                if (c_reg == qutr)
                begin
                    NS     = HOLD;
                    c_next = 'd0;
                end
            end
            RESTART : begin
                if (c_reg == half)
                begin
                    NS     = START1;
                    c_next = 'd0;
                end
            end
            STOP1 : begin
                sda_out = 1'b0;
                if (c_reg == half)
                begin
                    NS     = STOP2;
                    c_next = 'd0;
                end
            end
            default : begin // STOP2
                if (c_reg == half)
                begin
                    NS     = IDLE;
                end
            end 
        endcase
    end

    assign i2c_done_tick = done_tick_i;
    assign rdy           = rdy_i;

endmodule

/* <<<<<<<<<<<<<<< EEPROM >>>>>>>>>>>>>>>>>>
    Visit:
    https://octopart.com/datasheet/microchip/AT24C64D-SSHM-T

    in-order to get to know how the protocol with EEPROM works.
*/