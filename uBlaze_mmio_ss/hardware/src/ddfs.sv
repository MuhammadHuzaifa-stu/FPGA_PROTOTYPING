module ddfs # (
    // >>>>>>>>>>>>>>>> visit 19.2.3 topic of the book <<<<<<<<<<<<<<<<
    parameter PHS_WIDTH = 30,
    parameter ENV_WIDTH = 16
) (
    input  logic                  clk,
    input  logic                  arst_n,

    input  logic [PHS_WIDTH-1:0]  fccw,     // the frequency control word to generate the carrier frequency, f
    input  logic [PHS_WIDTH-1:0]  focw,     // the frequency control word to generate the offset frequency, delta_f
    input  logic [PHS_WIDTH-1:0]  phs,      // the phase value corresponding to the desired phase offset, delta_phs
    input  logic [ENV_WIDTH-1:0]  env,      // the envelope, digitized value of A -> S2.14, but limit input range to [-1.0, 1.0] by yourself

    output logic [ENV_WIDTH-1:0]  pcm_out,  // digitized sine wave
    output logic                  pulse_out // square wave
);

    localparam ROM_ADDRW = 8;

    logic        [PHS_WIDTH    -1:0] fcw;
    logic        [PHS_WIDTH    -1:0] pcw;
    logic        [PHS_WIDTH    -1:0] p_reg;
    logic        [PHS_WIDTH    -1:0] p_next;

    logic        [ROM_ADDRW    -1:0] p2a_raddr;

    logic        [ENV_WIDTH    -1:0] amp;
    logic        [ENV_WIDTH    -1:0] pcm_reg;

    logic signed [(2*ENV_WIDTH)-1:0] modu;

    sine_rom # (
        .DATA_WIDTH(ENV_WIDTH),
        .ADDR_WIDTH(ROM_ADDRW)
    ) u_sine_table (
        .clk   (clk      ),
        .arst_n(arst_n   ),
        .addr  (p2a_raddr),
        .data  (amp      )
    );

    always_ff @( posedge clk or negedge arst_n )
    begin
        if (~arst_n) 
        begin
            p_reg   <= '0;
            pcm_reg <= '0;
        end
        else
        begin
            p_reg   <= p_next;
            pcm_reg <= modu[29:14];
        end
    end

    // frequency modulation
    assign fcw       = fccw  + focw;
    // phase accumulation
    assign p_next    = p_reg + fcw;
    // phase modulation
    assign pcw       = p_reg + phs;
    // phase to amplitude mapping address
    assign p2a_raddr = pcw[PHS_WIDTH-1 -: ROM_ADDRW];
    // amplitude modulation
    assign modu      = $signed(amp) * $signed(env);
    assign pcm_out   = pcm_reg;
    assign pulse_out = p_reg[PHS_WIDTH-1];

endmodule