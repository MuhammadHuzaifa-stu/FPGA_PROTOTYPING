module tb_i2c_core ();
    
    import i2c_pkg::ADDR_WIDTH;
    import i2c_pkg::DATA_WIDTH;

    import i2c_pkg::I2C_DATA_W;
    import i2c_pkg::I2C_DVSR_W;
    import i2c_pkg::I2C_CMD_W;

    localparam SLAVE_ADDR = 7'b0000010; // Example slave address (7 bits)

    // Commands
    localparam START_CMD   = 3'b000;
    localparam WR_CMD      = 3'b001;
    localparam RD_CMD      = 3'b010;
    localparam STOP_CMD    = 3'b011;
    localparam RESTART_CMD = 3'b100;

    localparam SLAVE_ADDR_WR = {SLAVE_ADDR, 1'b0}; 
    localparam SLAVE_ADDR_RD = {SLAVE_ADDR, 1'b1}; 

    logic                  clk;
    logic                  arst_n;

    logic                  rdy;
    logic                  ack;

    logic [I2C_DATA_W-1:0] rx_data;
    logic [I2C_DATA_W-1:0] data_wr_arr [0:15];
    logic [I2C_DATA_W-1:0] data_rd_arr [0:15];

    pullup (u_i2c_if.sda);
    pullup (u_i2c_if.scl);

    i2c_interface u_i2c_if (
        .clk   ( clk   ),
        .arst_n( arst_n)
    );

    // slave model
    i2c_slave_model #(
        .SLAVE_ADDR ( SLAVE_ADDR ),
        .DEBUG      ( 0          )
    ) u_i2c_slave_model (
        .scl    ( u_i2c_if.SL.scl    ),
        .sda    ( u_i2c_if.SL.sda    )
    );

    // address = 0: frequency register, address = 1: data & cmd register
    // Considering slave_address = {7b1010110, write_bit = 0 or read_bit = 1}
    chu_i2c_core u_dut (
        .clk   ( u_i2c_if.DUT.clk    ),
        .arst_n( u_i2c_if.DUT.arst_n ),
        .cs    ( u_i2c_if.DUT.cs     ),
        .wr_en ( u_i2c_if.DUT.wr_en  ),
        .rd_en ( u_i2c_if.DUT.rd_en  ),
        .addr  ( u_i2c_if.DUT.addr   ),
        .wdata ( u_i2c_if.DUT.wdata  ), // [31:0] => [data(7:0), cmd(10:8), reserved(31:11)]
        .rdata ( u_i2c_if.DUT.rdata  ), // [31:0] => [data(7:0), rdy(8), ack(9), reserved(31:10)]
        .scl   ( u_i2c_if.DUT.scl    ),
        .sda   ( u_i2c_if.DUT.sda    )
    );

    assign rx_data = u_i2c_if.DRV.rdata[I2C_DATA_W-1:0];
    assign rdy     = u_i2c_if.DRV.rdata[I2C_DATA_W    ]; // ready bit is bit 8 of rdata
    assign ack     = u_i2c_if.DRV.rdata[I2C_DATA_W+1  ]; // ack bit is bit 9 of rdata

    task automatic wait_rdy();
        int timeout = 0;
        
        while (!rdy) 
        begin
            @(posedge clk);
            timeout++;
            if (timeout > 100_000) 
            begin
                $error("wait_rdy TIMEOUT — DUT appears hung at %0t", $time);
                $finish;
            end
        end
    endtask

    //////////////////////////////////////////////
    // helper tasks
    //////////////////////////////////////////////

    task automatic set_freq(
        input logic [DATA_WIDTH-1:0] freq
    );

        u_i2c_if.DRV.addr  <= 'h0000_0000;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= (100_000_000 / (freq << 2)); // Assuming 100MHz clock
        
    endtask

    task automatic start();

        u_i2c_if.DRV.addr  <= 'h0000_0001;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, START_CMD, {(I2C_DATA_W){1'b0}}};

    endtask
    
    task automatic restart();

        u_i2c_if.DRV.addr  <= 'h0000_0001;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, RESTART_CMD, {(I2C_DATA_W){1'b0}}};

    endtask
    
    task automatic stop();

        u_i2c_if.DRV.addr  <= 'h0000_0001;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, STOP_CMD, {(I2C_DATA_W){1'b0}}};

    endtask
    
    task automatic read_byte(
        input logic nack
    );

        u_i2c_if.DRV.addr  <= 'h0000_0001;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, RD_CMD, {(I2C_DATA_W-1){1'b0}}, nack};

    endtask
    
    task automatic write_byte(
        input  logic [I2C_DATA_W-1:0] data
    );

        u_i2c_if.DRV.addr  <= 'h0000_0001;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, WR_CMD, data};

    endtask


    //////////////////////////////////////////////
    // TEST STIMULI
    //////////////////////////////////////////////

    initial 
    begin
        clk = 0;
        forever 
        begin
            #5 clk = ~clk; // 100MHz clock
        end
    end

    initial 
    begin
        arst_n <= 1;
        #5;
        arst_n <= 0;
        #8;
        arst_n <= 1;
    end

    initial 
    begin
        // Initialize data array for burst write (0x00 to 0xFF)
        for (int i = 0; i < 16; i++) 
            data_wr_arr[i] = 15 - i; // Fill with descending values for better visibility (0xFF, 0xFE, ..., 0x00)
    end

    initial 
    begin
        u_i2c_if.DRV.cs    <= '0;
        u_i2c_if.DRV.wr_en <= '0;
        u_i2c_if.DRV.rd_en <= '0;
        u_i2c_if.DRV.addr  <= '0;
        u_i2c_if.DRV.wdata <= '0;

        repeat (5) @(posedge clk); 

        begin
            wait_rdy();

            set_freq(100_000);
            @(posedge clk);
            
            wait_rdy();

            // ====================================================================
            // <<<<<<<<<<<< TEST 1 — Single Byte Write to Address 0x10 >>>>>>>>>>>>
            // ====================================================================

            $display("\n=== TEST 1: Single Byte Write → mem[0x05] = 0xAB ===");

            start();
            @(posedge clk);
            wait_rdy();

            write_byte(SLAVE_ADDR_WR); // slave address + write_bit
            @(posedge clk);
            wait_rdy();

            write_byte(8'h05); // Send Write address
            @(posedge clk);            
            wait_rdy();

            write_byte(8'hAB); // Send actual Data
            @(posedge clk);            
            wait_rdy();

            stop();
            @(posedge clk);
            wait_rdy();
            u_i2c_if.DRV.cs    <= '0;
            u_i2c_if.DRV.wr_en <= '0;

            // Verify directly in BFM memory
            if (u_i2c_slave_model.mem[8'h05] === 8'hAB)
                $display("PASS: BFM mem[0x05] = 0x%02X", u_i2c_slave_model.mem[8'h05]);
            else
                $error("FAIL: BFM mem[0x05] = 0x%02X, expected 0xAB", u_i2c_slave_model.mem[8'h05]);

            repeat(5) @(posedge clk);

            // ====================================================================
            // <<<<<<<<<<<< TEST 2 — Single Byte Read From Address 0x10 >>>>>>>>>>>>
            // ====================================================================

            $display("\n=== TEST 2: Single Byte Read �? mem[0x05] ===");
            start();
            @(posedge clk);
            wait_rdy();

            write_byte(SLAVE_ADDR_WR); // slave address + write_bit
            @(posedge clk);
            wait_rdy();

            write_byte(8'h05); // Send Read Address
            @(posedge clk);
            wait_rdy(); 

            restart();         // Restart
            @(posedge clk);
            wait_rdy();

            write_byte(SLAVE_ADDR_RD); // slave address + read_bit
            @(posedge clk);
            wait_rdy();

            read_byte('d1);    // Read the byte (since last read, send nack to end read)
            @(posedge clk);
            wait_rdy();
            
            stop();
            @(posedge clk);
            wait_rdy();
            u_i2c_if.DRV.cs    <= '0;
            u_i2c_if.DRV.wr_en <= '0;
            
            $display("READ: mem[0x05] = 0x%02X | BFM has: 0x%02X %s", rx_data, u_i2c_slave_model.mem[8'h05], (rx_data === u_i2c_slave_model.mem[8'h05]) ? "PASS" : "FAIL");

            repeat(5) @(posedge clk);

            // ====================================================================
            // <<<<<<<<<<<<<<<<< TEST 3 — Burst Write(Page Write) >>>>>>>>>>>>>>>>>
            // ====================================================================
            
            $display("\n=== TEST 3: Burst Write 16 bytes from addr 0x00 ===");
            start();
            @(posedge clk);
            wait_rdy();

            write_byte(SLAVE_ADDR_WR); // Slave_addr + write_bit
            @(posedge clk);
            wait_rdy();

            write_byte(8'h00); // Start address
            @(posedge clk);
            wait_rdy();

            // burst write 16 bytes (0x00 to 0xFF) to slave memory starting at address 0x00
            for (int i = 0; i < 16; i++) 
            begin
                write_byte(data_wr_arr[i]);
                @(posedge clk);
                wait_rdy();
            end

            stop();
            @(posedge clk);
            wait_rdy();
            u_i2c_if.DRV.cs    <= '0;
            u_i2c_if.DRV.wr_en <= '0;

            // Verify all bytes in BFM memory
            $display("--- Burst Write Verification ---");
            for (int i = 0; i < 16; i++) 
            begin
                if (u_i2c_slave_model.mem[i] === data_wr_arr[i])
                    $display("  PASS: mem[0x%02X] = 0x%02X", i, data_wr_arr[i]);
                else
                    $error("  FAIL: mem[0x%02X] = 0x%02X, expected 0x%02X", i, u_i2c_slave_model.mem[i], data_wr_arr[i]);
            end

            repeat(5) @(posedge clk);

            // ====================================================================
            // <<<<<<<<<<<<<<< TEST 4 — Burst Read(Sequential Read) >>>>>>>>>>>>>>>
            // ====================================================================

            $display("\n=== TEST 4: Burst Read 16 bytes from addr 0x00 ===");

            start();
            @(posedge clk);
            wait_rdy();

            write_byte(SLAVE_ADDR_WR); // Slave_addr + write_bit
            @(posedge clk);
            wait_rdy();

            write_byte(8'h00); // Start address
            @(posedge clk);
            wait_rdy();

            restart();
            @(posedge clk);
            wait_rdy();

            write_byte(SLAVE_ADDR_RD); // Slave_addr + read_bit
            @(posedge clk);
            wait_rdy();

            for (int i = 0; i < 16; i++) 
            begin
                if (i == 15)
                    read_byte('d1);   // For last byte, send nack to end read
                else
                    read_byte('d0);   // master sends ACK (DUT handles automatically)
                @(posedge clk);
                wait_rdy();

                if (i > 0)
                    data_rd_arr[i-1] = u_i2c_if.DRV.rdata[I2C_DATA_W-1:0];
            end

            @(posedge clk);
            wait_rdy();
            data_rd_arr[15] = u_i2c_if.DRV.rdata[I2C_DATA_W-1:0];

            $display("--- Burst Read Verification ---");
            for (int i = 0; i < 16; i++)
                $display("  READ[%0d]: mem[0x%02X] = 0x%02X | BFM = 0x%02X %s", i, i, data_rd_arr[i], u_i2c_slave_model.mem[i], (data_rd_arr[i] === u_i2c_slave_model.mem[i]) ? "PASS":"FAIL");

            stop();
            @(posedge clk);
            wait_rdy();
            u_i2c_if.DRV.cs    <= '0;
            u_i2c_if.DRV.wr_en <= '0;

            repeat(5) @(posedge clk);
        end
        repeat(500) @(posedge clk);

        $finish;
    end

endmodule