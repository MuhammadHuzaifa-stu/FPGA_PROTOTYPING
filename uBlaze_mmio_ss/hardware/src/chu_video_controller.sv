module chu_video_controller 
    import chu_pkg::NUM_VIDEO_SLOTS;
    import chu_pkg::NUM_SLOT_REGS;
    import chu_pkg::FRAME_ADDR_WIDTH;
#(
    parameter  VIDEO_ADDR_WIDTH = 21,
    parameter  VIDEO_DATA_WIDTH = 32
) (
    input  logic                        video_cs,
    input  logic                        video_wr,
    input  logic [VIDEO_ADDR_WIDTH-1:0] video_addr, // [20] -> which frame buffer, 
                                                    // [16:14] -> which video core slot, 
                                                    // [13:0] -> which register in the video core slot
    input  logic [VIDEO_DATA_WIDTH-1:0] video_wr_data,
    // Frame buffer interface
    output logic                        frame_cs,
    output logic                        frame_wr,
    output logic [FRAME_ADDR_WIDTH-1:0] frame_addr,
    output logic [VIDEO_DATA_WIDTH-1:0] frame_wr_data,
    // Video Core slot interface
    output logic [NUM_VIDEO_SLOTS-1 :0] slot_cs_array,
    output logic [NUM_VIDEO_SLOTS-1 :0] slot_mem_wr_array,
    output logic [VIDEO_SLOT_REG-1  :0] slot_reg_addr_array[NUM_VIDEO_SLOTS-1:0],
    output logic [VIDEO_DATA_WIDTH-1:0] slot_wr_data_array [NUM_VIDEO_SLOTS-1:0]
);
    
    logic [$clog2(NUM_VIDEO_SLOTS)-1:0] slot_addr;
    logic [VIDEO_SLOT_REG-1         :0] reg_addr;

    logic [NUM_VIDEO_SLOTS-1 :0]        slot_cs_tmp;
    logic                               slot_cs;

    // Addresses
    assign slot_addr = video_addr[VIDEO_SLOT_REG +: $clog2(NUM_VIDEO_SLOTS)]; // which video core slot -> 0-7
    assign reg_addr  = video_addr[0              +: VIDEO_SLOT_REG];          // which register in the video core slot -> 0-16383
    // CS
    assign frame_cs  = video_cs &  video_addr[VIDEO_ADDR_WIDTH-1];
    assign slot_cs   = video_cs & ~video_addr[VIDEO_ADDR_WIDTH-1];

    always_comb 
    begin
        slot_cs_tmp = '0;
        if (slot_cs)
        begin
            slot_cs_tmp[slot_addr] = 1'b1;
        end
    end

    assign slot_cs_array = slot_cs_tmp;

    // frame buffer
    assign frame_addr    = video_addr[0 +: FRAME_ADDR_WIDTH];
    assign frame_wr      = video_wr;
    assign frame_wr_data = video_wr_data;

    // broadcast to all video slots
    generate
        for (genvar i=0; i<NUM_VIDEO_SLOTS; i++)
        begin
            assign slot_mem_wr_array  [i] = video_wr;
            assign slot_reg_addr_array[i] = reg_addr;
            assign slot_wr_data_array [i] = video_wr_data;
        end
    endgenerate

endmodule