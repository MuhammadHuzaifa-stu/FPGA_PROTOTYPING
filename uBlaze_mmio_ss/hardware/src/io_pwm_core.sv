module io_pwm_core #(
    parameter R          = 10, // resolution of PWM
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter NUM_PWM    = 8
) (
    input  logic                  clk,
    input  logic                  arst_n,

    input  logic                  cs,
    input  logic                  wr_en,
    input  logic                  rd_en,

    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata,

    output logic [NUM_PWM-1:0]    pwm_out
);

/*
    For more details Refer to the chapter-14 of the book "FPGA Prototyping by SystemVerilog Examples".
    14.2.2 onwards        
*/

    // 2D array to hold duty cycle values for each PWM channel
    logic [R  :0]          duty_2d_arr [NUM_PWM-1:0]; 
    logic                  duty_arr_en;
    logic                  dvsr_en;
    logic [DATA_WIDTH-1:0] dvsr_reg;

    logic [R  :0]          d_ext; // to achieve 0-100% duty cycle range
    logic [R-1:0]          d_reg;
    logic [R-1:0]          d_next;

    logic [DATA_WIDTH-1:0] q_reg;
    logic [DATA_WIDTH-1:0] q_next;

    logic [NUM_PWM-1:0]    pwm_reg;
    logic [NUM_PWM-1:0]    pwm_next;

    logic                  tick; // indicates the end of one PWM cycle

    // MSB of addr indicates duty cycle register
    assign duty_arr_en = cs && wr_en && addr[ADDR_WIDTH-1]; 
    assign dvsr_en     = cs && wr_en && (addr == 'd0);

    always_ff @(posedge clk or negedge arst_n) 
    begin : dvsr_reg_blk
        if (!arst_n)
        begin
            dvsr_reg <= 'd0;
        end 
        else if (dvsr_en)
        begin
            dvsr_reg <= wdata;
        end
    end

    always_ff @(posedge clk or negedge arst_n) 
    begin : duty_cycle_reg_array
        if (!arst_n)
        begin
            for (int i = 0; i < NUM_PWM; i++) 
            begin
                duty_2d_arr[i] <= 'd0;
            end
        end 
        else if (duty_arr_en)
        begin
            duty_2d_arr[addr[ADDR_WIDTH-3:0]] <= wdata[R:0];
        end
    end        

    always_ff @(posedge clk or negedge arst_n) 
    begin : duty_cycle_reg
        if (!arst_n) 
        begin
            d_reg   <= 'd0;
            q_reg   <= 'd0;
            pwm_reg <= 1'b0;
        end 
        else 
        begin
            d_reg   <= d_next;
            q_reg   <= q_next;
            pwm_reg <= pwm_next;
        end
    end

    // prescale counter
    assign q_next   = (q_reg == dvsr_reg) ? 'd0 : q_reg + 'd1;
    assign tick     = q_reg == 'd0;
    // duty cycle counter
    assign d_next   = tick ? d_reg + 'd1 : d_reg;
    assign d_ext    = {1'b0, d_reg};

    generate
        for (genvar i = 0; i < NUM_PWM; i++)
            assign pwm_next[i] = d_ext < duty_2d_arr[i];
    endgenerate

    assign pwm_out  = pwm_reg;
    assign rdata    = 'd0; // read operation is not supported

endmodule