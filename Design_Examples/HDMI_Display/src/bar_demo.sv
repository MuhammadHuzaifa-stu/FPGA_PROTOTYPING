module bar_demo 
    import display_pkg::CD;
    import display_pkg::HT;
    import display_pkg::VT;
(
    input  logic [$clog2(HT):0] x,
    input  logic [$clog2(VT):0] y,

    output logic [CD-1:0]       rgb
);
    
    logic [CD/3 - 1 : 0] up;
    logic [CD/3 - 1 : 0] down;

    logic [CD/3 - 1 : 0] r;
    logic [CD/3 - 1 : 0] g;
    logic [CD/3 - 1 : 0] b;

    assign up   =  x[6:3];
    assign down = ~x[6:3];

    always_comb 
    begin
        // 16 shades of grey
        if (y < 128)
        begin
            r = x[8:5];
            g = x[8:5];
            b = x[8:5];
        end
        // 8 prime colors with 50% intesity
        else if (y < 256)
        begin
            r = {x[8], x[8], 2'b00};
            g = {x[7], x[7], 2'b00};
            b = {x[6], x[6], 2'b00};
        end
        else
        begin
            unique case (x[9:7])
                3'b000: begin
                    r = 4'b1111;
                    g = up;
                    b = 4'b0000;
                end 
                3'b001: begin
                    r = down;
                    g = 4'b1111;
                    b = 4'b0000;
                end 
                3'b010: begin
                    r = 4'b0000;
                    g = 4'b1111;
                    b = up;
                end 
                3'b011: begin
                    r = 4'b0000;
                    g = down;
                    b = 4'b1111;
                end 
                3'b100: begin
                    r = up;
                    g = 4'b0000;
                    b = 4'b1111;
                end 
                3'b101: begin
                    r = 4'b1111;
                    g = 4'b0000;
                    b = down;
                end 
                default: begin
                    r = 4'b1111;
                    g = 4'b1111;
                    b = 4'b1111;
                end
            endcase
        end
    end

    assign rgb = {r, g, b};

endmodule