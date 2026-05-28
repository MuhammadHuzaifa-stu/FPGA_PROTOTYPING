package display_pkg;
    
    parameter CD  = 12; // color depth: 4 + 4 + 4

    // vga 640 x 480 sync parameters
    localparam HD = 640; // horizontal display area
    localparam HF = 16;  // horizontal front porch
    localparam HB = 48;  // horizontal back porch
    localparam HR = 96;  // horizontal sync pulse (retrace)
    localparam HT = HD + HF + HB + HR; // 800

    localparam VD = 480; // vertical display area
    localparam VF = 10;  // vertical front porch
    localparam VB = 33;  // vertical back porch
    localparam VR = 2;   // vertical sync pulse (retrace)
    localparam VT = VD + VF + VB + VR; // 525

endpackage