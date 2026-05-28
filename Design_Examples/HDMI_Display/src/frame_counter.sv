module frame_counter #(
    parameter HMAX = 640,
    parameter VMAX = 480
) (
    input  logic                    clk,
    input  logic                    arst_n,

    input  logic                    sync_clr,

    output logic [$clog2(HMAX):0]   hcount,
    output logic [$clog2(VMAX):0]   vcount,
    output logic                    frame_start,
    output logic                    frame_end
);

    logic [$clog2(HMAX):0] hc_next;
    logic [$clog2(HMAX):0] hc_reg;
    logic [$clog2(VMAX):0] vc_next;
    logic [$clog2(VMAX):0] vc_reg;

    always_ff @(posedge clk or negedge arst_n) 
    begin
        if (!arst_n) 
        begin
            hc_reg <= 0;
            vc_reg <= 0;
        end
        else if (sync_clr)
        begin
            hc_reg <= 0;
            vc_reg <= 0;
        end 
        else 
        begin
            hc_reg <= hc_next;
            vc_reg <= vc_next;
        end
    end

    always_comb 
    begin
        if (hc_reg == HMAX - 1)
        begin
            hc_next = 0;
        end
        else
        begin
            hc_next = hc_reg + 1;
        end
    end

    always_comb 
    begin
        if (hc_reg == HMAX - 1)
        begin
            if (vc_reg == VMAX - 1)
            begin
                vc_next = 0;
            end
            else
            begin
                vc_next = vc_reg + 1;
            end
        end
        else
        begin
            vc_next = vc_reg;
        end    
    end

    assign hcount      = hc_reg;
    assign vcount      = vc_reg;
    assign frame_start = (hc_reg == 0) && (vc_reg == 0);
    assign frame_end   = (hc_reg == HMAX - 1) && (vc_reg == VMAX - 1);

endmodule