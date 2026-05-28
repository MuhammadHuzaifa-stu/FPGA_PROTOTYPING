// TMDS Encoder for DVI - no sound
module tmds_encoder_dvi
#(
    parameter DATA_WIDTH  = 8
) (
    input  logic                  clk_pix,
    input  logic                  rst_pix,
    input  logic [DATA_WIDTH-1:0] data_in,  // colour data
    input  logic [1:0]            ctrl_in,  // control data
    input  logic                  de,       // data enable

    output logic [9:0]            tmds      // encoded TMDS data
);

    // select basic encoding based on the ones in the input data
    logic [$clog2(DATA_WIDTH+1)-1:0] data_1s;
    logic                            use_xnor;
    
    always_comb 
    begin
        data_1s = '0;

        for (int i=0; i<DATA_WIDTH; i=i+1) 
        begin
            // data_1s = data_in[0] + data_in[1] + data_in[2] + ... + data_in[DATA_WIDTH-1]
            data_1s = data_1s + data_in[i];
        end

        use_xnor = (data_1s > DATA_WIDTH/2) || ((data_1s == DATA_WIDTH/2) && (data_in[0] == 0));
    end
     
    // encode colour data with xor/xnor
    integer              i;
    logic [DATA_WIDTH:0] enc_qm;

    always_comb 
    begin
        enc_qm[0] = data_in[0];

        for (i=0; i<DATA_WIDTH-1; i++) 
        begin
            enc_qm[i+1] = (use_xnor) ? (enc_qm[i] ~^ data_in[i+1]) : (enc_qm[i] ^ data_in[i+1]);
        end

        enc_qm[DATA_WIDTH] = (use_xnor) ? 0 : 1;
    end

    // disparity in encoded data for DC balancing: needs to cover -8 to +8
    logic signed [DATA_WIDTH/2:0] ones; 
    logic signed [DATA_WIDTH/2:0] zeros; 
    logic signed [DATA_WIDTH/2:0] balance;

    always_comb 
    begin
        ones = '0;

        for (i=0; i<DATA_WIDTH; i++)
        begin
            // ones = enc_qm[0] + enc_qm[1] + enc_qm[2] + enc_qm[3] + ... + enc_qm[DATA_WIDTH-1]
            ones = ones + enc_qm[i];
        end

        zeros   = DATA_WIDTH - ones;
        balance = ones - zeros;
    end

    // record ongoing DC bias
    logic signed [DATA_WIDTH/2:0] bias;

    always_ff @(posedge clk_pix) 
    begin
        if (de == 0) 
        begin  // send control data in blanking interval
            case (ctrl_in)  // ctrl sequences (always have 7 transitions)
                2'b00:   tmds <= 10'b1101010100;
                2'b01:   tmds <= 10'b0010101011;
                2'b10:   tmds <= 10'b0101010100;
                default: tmds <= 10'b1010101011;
            endcase
            bias <= 5'sb00000;
        end 
        else 
        begin  // send pixel colour data (at most 5 transitions)
            if (bias == 0 || balance == 0) 
            begin  // no prior bias or disparity
                if (enc_qm[DATA_WIDTH] == 0) 
                begin
                    tmds[9:0] <= {2'b10, ~enc_qm[7:0]};
                    bias      <= bias - balance;
                end 
                else 
                begin
                    tmds[9:0] <= {2'b01, enc_qm[7:0]};
                    bias <= bias + balance;
                end
            end
            else if ((bias > 0 && balance > 0) || (bias < 0 && balance < 0)) 
            begin
                tmds[9:0] <= {1'b1, enc_qm[8], ~enc_qm[7:0]};
                bias      <= bias + {3'b0, enc_qm[8], 1'b0} - balance;
            end 
            else 
            begin
                tmds[9:0] <= {1'b0, enc_qm[8], enc_qm[7:0]};
                bias      <= bias - {3'b0, ~enc_qm[8], 1'b0} + balance;
            end
        end

        if (!rst_pix) 
        begin
            tmds <= 10'b1101010100;  // equivalent to ctrl 2'b00
            bias <= 5'sb00000;
        end
    end

endmodule