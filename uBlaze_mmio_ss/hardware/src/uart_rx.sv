module uart_rx #(
    parameter DBIT    = 8,
    parameter SB_TICK = 16 // 1 stop bit -> 16
                           // 1.5 stop bit -> 24
                           // 2 stop bit -> 32
) (
    input  logic                  clk,
    input  logic                  arst_n,

    input  logic                  rx,
    input  logic                  baud_tick,

    output logic [DBIT-1:0]       dout,
    output logic                  rx_done_tick
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

    always_ff @( posedge clk or negedge arst_n ) 
    begin: state_blk
        if (!arst_n)
        begin
            CS    <= IDLE;
            s_reg <= '0;
            n_reg <= '0;
            b_reg <= '0;
        end
        else
        begin
            CS    <= NS;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
        end
    end

    always_comb 
    begin: NS_blk
        NS           = CS;
        s_next       = s_reg;
        n_next       = n_reg;
        b_next       = b_reg;
        rx_done_tick = 1'b0;

        case (CS)
            IDLE: begin
                if (!rx)
                begin
                    NS     = START;
                    s_next = '0;
                end
            end
            START: begin
                if (baud_tick)
                begin
                    if (s_reg == (SB_TICK/2 - 1)) // 7
                    begin
                        NS     = DATA;
                        s_next = '0;
                        n_next = '0;
                    end
                    else
                        s_next = s_reg + 1;
                end
            end
            DATA: begin
                if (baud_tick)
                begin
                    if (s_reg == (SB_TICK - 1)) // 15
                    begin
                        s_next = '0;
                        b_next = {rx, b_reg[DBIT-1:1]}; // Shift right and insert new bit at MSB
                        if (n_reg == (DBIT - 1)) // 7
                        begin
                            NS = STOP;
                        end
                        else
                            n_next = n_reg + 1;
                    end
                    else
                        s_next = s_reg + 1;
                end
            end
            STOP: begin
                if (baud_tick)
                begin
                    if (s_reg == (SB_TICK - 1)) // 15
                    begin
                        NS           = IDLE;
                        rx_done_tick = 1'b1;
                    end
                    else
                        s_next = s_reg + 1;
                end
            end 
            default: NS = IDLE;
        endcase
    end

    assign dout = b_reg;

endmodule