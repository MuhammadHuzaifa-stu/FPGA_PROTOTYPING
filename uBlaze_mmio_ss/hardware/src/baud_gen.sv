/*
Q: Why 16X the baud rate?
A: Considering a start bit. If you only check at 1x the baud rate, you might "miss" the exact moment the line dropped, 
   starting your timer half a bit late.
   With 16x sampling, you are checking the line 16 times per bit. You will "see" the start bit drop within 1/16th of a 
   bit's width, making your timing much more precise.
*/

/*
   The Rule: You never want to read a bit at the beginning or end of its duration because that's when it is most unstable.
   The 16x Solution: 
   1. Once the "Start Bit" is detected, the UART state machine waits for 7 ticks (roughly the middle of the start bit).
   2. It then waits exactly 16 ticks for every following bit.
   3. This ensures you are always reading the data at the 8th tick—exactly in the middle of the bit where the voltage is most stable.
*/
module baud_gen #(
    parameter CLK_FREQ   = 200_000_000,                          // 200MHz
    parameter BAUD_WIDTH = $clog2((CLK_FREQ / (16 * 9600)) - 1)  // count = f / (16 * baud_rate) - 1
) (
    input  logic                  clk,
    input  logic                  arst_n,

    input  logic [BAUD_WIDTH-1:0] dvsr,
    output logic                  baud_tick
);
    
    logic [BAUD_WIDTH-1:0] counter;
    logic [BAUD_WIDTH-1:0] counter_next;

    always_ff @( posedge clk or negedge arst_n ) 
    begin
        if (!arst_n) 
            counter <= '0;
        else
            counter <= counter_next;
    end

    assign counter_next = (counter == dvsr) ? 'd0 : counter + 1;
    assign baud_tick    = (counter == 'd1);    

endmodule