module rgb2gray
    import display_pkg::CD;
(
    input  logic [CD-1:0] color_rgb,
    output logic [CD-1:0] gray_rgb
);
    
    localparam RW = 8'h35;
    localparam GW = 8'hb8;
    localparam BW = 8'h12;

    logic [CD/3-1:0] r;
    logic [CD/3-1:0] g;
    logic [CD/3-1:0] b;
    logic [CD/3-1:0] gray;
    logic [CD  -1:0] gray12;

    assign r = color_rgb[8 +: CD/3];
    assign g = color_rgb[4 +: CD/3];
    assign b = color_rgb[0 +: CD/3];

    assign gray12   = r * RW + g * GW + b * BW;
    assign gray     = gray12[8 +: CD/3];
    assign gray_rgb = {gray, gray, gray};

endmodule