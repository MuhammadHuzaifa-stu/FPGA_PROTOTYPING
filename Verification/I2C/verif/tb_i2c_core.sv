module tb_i2c_core ();
    
    parameter ADDR_WIDTH = 5;
    parameter DATA_WIDTH = 32;

    logic clk;
    logic arst_n;

    logic                  cs;
    logic                  wr_en;
    logic                  rd_en;

    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;

    tri                    scl;
    tri                    sda;

    pullup (sda); // both are pulled-up when no one driving these ports
    pullup (scl); // both are pulled-up when no one driving these ports

    chu_i2c_core #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH )
    ) u_chu_i2c_core (
        .clk   ( clk   ),
        .arst_n( arst_n),
        .cs    ( cs    ),
        .wr_en ( wr_en ),
        .rd_en ( rd_en ),
        .addr  ( addr  ),
        .wdata ( wdata ),
        .rdata ( rdata ),
        .scl   ( scl   ),
        .sda   ( sda   )
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk; // 100MHz clock
        end
    end

    initial begin
        arst_n = 0;
        #1;
        arst_n = 1;
    end

    initial begin
        cs    <= '0;
        wr_en <= '0;
        rd_en <= '0;
        addr  <= '0;
        wdata <= '0;
        repeat (5) @(posedge clk); // Wait for 10 clock cycles

        // Example write transaction

        // set frequency to 1000kHz (assuming 100MHz clock, dvsr = 100 => quatr = 25)
        addr  <= 'h00;         // Address for frequency register
        wr_en <= '1;
        cs    <= '1;
        wdata <= 'h00000019;   // quatr = 25
        @(posedge clk);

        // Start CMD
        while (!rdata[8])      // back pressure handle 
        begin
            @(posedge clk);    // Wait until ready bit is set
        end
        addr  <= 'h01;         // Address for data & cmd register
        wr_en <= '1;
        cs    <= '1;
        wdata <= 'h000000BB;   // cmd = START, data = 0xXX (data XX + write bit)
        @(posedge clk);

        // Write byte
        while (!rdata[8]) 
        begin
            @(posedge clk);
        end
        addr  <= 'h01;
        wr_en <= '1;
        cs    <= '1;
        wdata <= 'h000001BB;   // cmd = WR_CMD, data = 0xBB (data BB + write bit)
        @(posedge clk);

        // Stop CMD
        while (!rdata[8]) 
        begin
            @(posedge clk);
        end
        addr  <= 'h01;
        wr_en <= '1;
        cs    <= '1;
        wdata <= 'h00000300;   // cmd = STOP_CMD, data = 0x00 (data XX + write bit)
        
        while (!rdata[8]) 
        begin
            @(posedge clk);
        end
        repeat (5) @(posedge clk); 
        $finish;
    end
endmodule