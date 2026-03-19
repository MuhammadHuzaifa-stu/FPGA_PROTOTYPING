module uart_tx #(
    parameter DBIT    = 8,
    parameter SB_TICK = 16 // 1 stop bit -> 16
                           // 1.5 stop bit -> 24
                           // 2 stop bit -> 32
) (
    input  logic                  clk,
    input  logic                  arst_n,

    input  logic                  baud_tick,
    input  logic                  tx_start,
    input  logic [DBIT-1:0]       din,

    output logic                  tx,
    output logic                  tx_done_tick
);
    
    typedef enum { 
        IDLE, START, DATA, STOP
    } state_t;

    state_t CS;
    state_t NS;

    logic [$clog2(SB_TICK)-1:0]      s_reg; // 4-bits for counting to 16 (SB_TICK)
    logic [$clog2(SB_TICK)-1:0]      s_next;

    logic [$clog2(DBIT)   -1:0]      n_reg; // 3-bits for counting to 8 (DBIT)
    logic [$clog2(DBIT)   -1:0]      n_next;

    logic [DBIT-1:0]                 b_reg;
    logic [DBIT-1:0]                 b_next;

    logic                            tx_reg;
    logic                            tx_next;
    
    always_ff @( posedge clk or negedge arst_n ) 
    begin : state_blk
        if (!arst_n)
        begin
            CS     <= IDLE;
            s_reg  <= '0;
            n_reg  <= '0;
            b_reg  <= '0;
            tx_reg <= 1'b1; // Idle state of UART line is HIGH
        end
        else
        begin
            CS     <= NS;
            s_reg  <= s_next;
            n_reg  <= n_next;
            b_reg  <= b_next;
            tx_reg <= tx_next;
        end
    end

    always_comb 
    begin : output_blk
        NS           = CS;
        s_next       = s_reg;
        n_next       = n_reg;
        b_next       = b_reg;
        tx_next      = tx_reg;
        tx_done_tick = 1'b0;

        case (CS)
            IDLE: begin
                tx_next = 1'b1; // Line is idle (HIGH)
                if (tx_start)
                begin
                    NS     = START;
                    b_next = din; // Load data to be transmitted
                    s_next = '0;
                    n_next = '0;
                end
            end
            START: begin
                tx_next = 1'b0; // Start bit is LOW
                if (baud_tick)
                begin
                    if (s_reg == (SB_TICK - 1)) // Wait for full start bit duration
                    begin
                        NS     = DATA;
                        s_next = '0;
                    end
                    else
                        s_next = s_reg + 1;
                end
            end
            DATA: begin
                tx_next = b_reg[0]; // Transmit LSB first
                if (baud_tick)
                begin
                    if (s_reg == (SB_TICK - 1)) // Wait for full bit duration
                    begin
                        s_next = '0;
                        b_next = {1'b0, b_reg[DBIT-1:1]}; // Shift right to get next bit
                        if (n_reg == (DBIT - 1)) // Last data bit transmitted
                        begin
                            NS     = STOP;
                            tx_next = 1'b1; // Stop bit is HIGH
                        end
                        else
                            n_next = n_reg + 1;
                    end
                    else
                        s_next = s_reg + 1;
                end
            end
            STOP: begin
                tx_next = 1'b1; // Stop bit is HIGH
                if (baud_tick)
                begin
                    if (s_reg == (SB_TICK - 1)) // Wait for full stop bit duration
                    begin
                        NS           = IDLE;
                        tx_done_tick = 1'b1; // Indicate transmission is done
                    end
                    else
                        s_next = s_reg + 1;
                end
            end 
            default: NS = IDLE; 
        endcase
    end

    assign tx = tx_reg;

endmodule