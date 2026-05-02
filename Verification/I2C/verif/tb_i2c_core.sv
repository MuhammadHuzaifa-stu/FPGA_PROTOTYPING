module tb_i2c_core ();
    
    parameter ADDR_WIDTH = 5;
    parameter DATA_WIDTH = 32;

    logic clk;
    logic arst_n;

    pullup (u_i2c_if.sda); // both are pulled-up when no one driving these ports

    i2c_interface #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH )
    ) u_i2c_if (
        .clk   ( clk   ),
        .arst_n( arst_n)
    );

    chu_i2c_core #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH )
    ) u_chu_i2c_core (
        .clk   ( u_i2c_if.DUT.clk   ),
        .arst_n( u_i2c_if.DUT.arst_n),
        .cs    ( u_i2c_if.DUT.cs    ),
        .wr_en ( u_i2c_if.DUT.wr_en ),
        .rd_en ( u_i2c_if.DUT.rd_en ),
        .addr  ( u_i2c_if.DUT.addr  ),
        .wdata ( u_i2c_if.DUT.wdata ),
        .rdata ( u_i2c_if.DUT.rdata ),
        .scl   ( u_i2c_if.DUT.scl   ),
        .sda   ( u_i2c_if.DUT.sda   )
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
        u_i2c_if.DRV.cs    <= '0;
        u_i2c_if.DRV.wr_en <= '0;
        u_i2c_if.DRV.rd_en <= '0;
        u_i2c_if.DRV.addr  <= '0;
        u_i2c_if.DRV.wdata <= '0;
        repeat (5) @(posedge clk); // Wait for 10 clock cycles

        // Example write transaction

        // set frequency to 1000kHz (assuming 100MHz clock, dvsr = 100 => quatr = 25)
        u_i2c_if.DRV.addr  <= 'h00;         // Address for frequency register
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= 'h00000019;   // quatr = 25
        @(posedge clk);

        // Start CMD
        while (!u_i2c_if.DRV.rdata[8])      // back pressure handle 
        begin
            @(posedge clk);    // Wait until ready bit is set
        end
        u_i2c_if.DRV.addr  <= 'h01;         // Address for data & cmd register
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= 'h000000BB;   // cmd = START, data = 0xXX (data XX + write bit)
        @(posedge clk);

        // Write byte
        while (!u_i2c_if.DRV.rdata[8]) 
        begin
            @(posedge clk);
        end
        u_i2c_if.DRV.addr  <= 'h01;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= 'h000001BB;   // cmd = WR_CMD, data = 0xBB (data BB + write bit)
        @(posedge clk);

        // Stop CMD
        while (!u_i2c_if.DRV.rdata[8]) 
        begin
            @(posedge clk);
        end
        u_i2c_if.DRV.addr  <= 'h01;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= 'h00000300;   // cmd = STOP_CMD, data = 0x00 (data XX + write bit)
        
        while (!u_i2c_if.DRV.rdata[8]) 
        begin
            @(posedge clk);
        end
        repeat (5) @(posedge clk); 
        $finish;
    end
endmodule