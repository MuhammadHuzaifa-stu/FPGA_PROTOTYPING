module tb_i2c_core ();
    
    import i2c_pkg::ADDR_WIDTH;
    import i2c_pkg::DATA_WIDTH;

    import i2c_pkg::I2C_DATA_W;
    import i2c_pkg::I2C_DVSR_W;
    import i2c_pkg::I2C_CMD_W;

    import i2c_pkg::IDLE;
    import i2c_pkg::HOLD;
    import i2c_pkg::START1;
    import i2c_pkg::START2;
    import i2c_pkg::DATA1;
    import i2c_pkg::DATA2;
    import i2c_pkg::DATA3;
    import i2c_pkg::DATA4;
    import i2c_pkg::DATA_END;
    import i2c_pkg::RESTART;
    import i2c_pkg::STOP1;
    import i2c_pkg::STOP2;

    import i2c_pkg::START_CMD;
    import i2c_pkg::WR_CMD;
    import i2c_pkg::RD_CMD;
    import i2c_pkg::STOP_CMD;
    import i2c_pkg::RESTART_CMD;

    localparam SLAVE_ADDR = 7'b0000010; // Example slave address (7 bits)

    localparam SLAVE_ADDR_WR = {SLAVE_ADDR, 1'b0}; 
    localparam SLAVE_ADDR_RD = {SLAVE_ADDR, 1'b1}; 
    localparam MEM_DEPTH     = 16;

    logic                  clk;
    logic                  arst_n;
    logic                  cs;
    logic                  wr_en;
    logic                  rd_en;
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;
    tri                    scl;
    tri                    sda;

    logic                  rdy;
    logic                  ack;
    logic                  done;

    int                    rd_cnt;
    int                    rd_tr_cmpl;

    logic [I2C_DATA_W-1:0] rx_data;
    logic [I2C_DATA_W-1:0] data_wr_arr [0:MEM_DEPTH-1];
    logic [I2C_DATA_W-1:0] data_rd_arr [0:MEM_DEPTH-1];

    logic [I2C_DATA_W-1:0] rand_addr;
    logic [I2C_DATA_W-1:0] rand_data;

    pullup (sda);
    pullup (scl);

    // slave model
    i2c_slave_model #(
        .SLAVE_ADDR ( SLAVE_ADDR ),
        .DEBUG      ( 1          ),
        .MEM_DEPTH  ( MEM_DEPTH  )
    ) u_i2c_slave_model (
        .scl    ( scl ),
        .sda    ( sda )
    );

    // address = 0: frequency register, address = 1: data & cmd register
    // Considering slave_address = {7b1010110, write_bit = 0 or read_bit = 1}
    chu_i2c_core u_dut (
        .clk   ( clk    ),
        .arst_n( arst_n ),
        .cs    ( cs     ),
        .wr_en ( wr_en  ),
        .rd_en ( rd_en  ),
        .addr  ( addr   ),
        .wdata ( wdata  ), // [31:0] => [data(7:0), cmd(10:8), reserved(31:11)]
        .rdata ( rdata  ), // [31:0] => [data(7:0), rdy(8), ack(9), reserved(31:10)]
        .scl   ( scl    ),
        .sda   ( sda    )
    );

    //////////////////////////////////////////////
    // coverage
    //////////////////////////////////////////////

    `ifdef VCS
        bind tb_i2c_core.u_dut i2c_coverage u_cov_bind (
            .clk   ( clk    ),
            .arst_n( arst_n ),
            .cs    ( cs     ),
            .wr_en ( wr_en  ),
            .rd_en ( rd_en  ),
            .addr  ( addr   ),
            .wdata ( wdata  ),
            .rdata ( rdata  ),
            .scl   ( scl    ),
            .sda   ( sda    )
        );
    `endif

    //////////////////////////////////////////////
    // assertions
    //////////////////////////////////////////////

    `ifdef VCS
        bind tb_i2c_core.u_dut i2c_assertions u_assert_bind (
            .clk   ( clk    ),
            .arst_n( arst_n ),
            .scl   ( scl    ),
            .sda   ( sda    )
        );
    `endif

    assign rx_data = rdata[I2C_DATA_W-1:0];
    assign rdy     = rdata[I2C_DATA_W    ]; // ready bit is bit 8 of rdata
    assign ack     = rdata[I2C_DATA_W+1  ]; // ack bit is bit 9 of rdata
    assign done    = rdata[I2C_DATA_W+1+1]; // done bit is bit 10 of rdata

    //////////////////////////////////////////////
    // helper tasks
    //////////////////////////////////////////////

    // Wait for bus to actually go idle between tests
    task automatic wait_bus_idle();
        int timeout = 0;
        
        while (u_dut.u_i2c_master.CS != IDLE) 
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

    function automatic bfm_mem_rst();
        
        for (int i=0; i<MEM_DEPTH; i++)
            u_i2c_slave_model.mem[i] = $urandom_range((1 << I2C_DATA_W) - 1, 0);

    endfunction

    task automatic desert_cs_wren();
        
        cs    <= 'd0;
        wr_en <= 'd0;

    endtask

    task automatic set_freq(
        input logic [DATA_WIDTH-1:0] freq
    );

        addr  <= 'h0000_0000;
        wr_en <= '1;
        cs    <= '1;
        wdata <= (100_000_000 / (freq << 2)); // Assuming 100MHz clock
        
    endtask

    task automatic start();

        addr  <= 'h0000_0001;
        wr_en <= '1;
        cs    <= '1;
        wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, START_CMD, {(I2C_DATA_W){1'b0}}};

    endtask
    
    task automatic restart();

        addr  <= 'h0000_0001;
        wr_en <= '1;
        cs    <= '1;
        wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, RESTART_CMD, {(I2C_DATA_W){1'b0}}};

    endtask
    
    task automatic stop();

        addr  <= 'h0000_0001;
        wr_en <= '1;
        cs    <= '1;
        wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, STOP_CMD, {(I2C_DATA_W){1'b0}}};

    endtask
    
    task automatic read_byte(
        input logic nack
    );

        addr  <= 'h0000_0001;
        wr_en <= '1;
        cs    <= '1;
        wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, RD_CMD, {(I2C_DATA_W-1){1'b0}}, nack};

    endtask
    
    task automatic write_byte(
        input  logic [I2C_DATA_W-1:0] data
    );

        addr  <= 'h0000_0001;
        wr_en <= '1;
        cs    <= '1;
        wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, WR_CMD, data};

    endtask

    task automatic write_transaction(
        input logic [I2C_DATA_W-1:0] data [],
        input logic [I2C_DATA_W-1:0] addr,
        input int                    num_bytes,
        input logic                  re_start 
    );

        start();
        @(posedge clk);
        wait_rdy();

        write_byte(SLAVE_ADDR_WR);
        @(posedge clk);
        wait_rdy();

        write_byte(addr);
        @(posedge clk);
        wait_rdy();

        for (int i = 0; i < num_bytes; i++)
        begin
            write_byte(data[i]);
            @(posedge clk);
            wait_rdy();
        end

        if (re_start)
        begin
            restart();
            @(posedge clk);
            wait_rdy();
        end
        else
        begin
            stop();
            @(posedge clk);
            wait_rdy();
        end

    endtask

    task automatic read_transaction(
        input int   num_bytes,
        input logic re_start,
        ref   int   j,
        ref   int   rd_tr_done
    );

        rd_tr_done = 0;

        write_byte(SLAVE_ADDR_RD);
        @(posedge clk);
        wait_rdy();

        for (j = 0; j < (num_bytes-1); j++)
        begin
            read_byte('d0); // ACK after each byte except last
            @(posedge clk);
            wait_rdy();
        end

        read_byte('d1); // NACK after last byte to end read
        @(posedge clk);
        wait_rdy();
        rd_tr_done = 1;

        if (re_start)
        begin
            restart();
            @(posedge clk);
            wait_rdy();
        end
        else
        begin
            stop();
            @(posedge clk);
            wait_rdy();
        end
        
    endtask

    //////////////////////////////////////////////
    // TEST STIMULI
    //////////////////////////////////////////////

    initial 
    begin
        clk <= 0;
        forever 
        begin
            #5 clk <= ~clk; // 100MHz clock
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
            data_wr_arr[i] = MEM_DEPTH - 1 - i; // Fill with descending values for better visibility (0xFF, 0xFE, ..., 0x00)
    end

    initial 
    begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_i2c_core);

        `ifdef VCS
            $fsdbDumpfile("debug.fsdb");
            $fsdbDumpvars(0, tb_i2c_core, "+all");
        `endif
    end

    initial 
    begin
        cs        <= '0;
        wr_en     <= '0;
        rd_en     <= '0;
        addr      <= '0;
        wdata     <= '0;
        rand_addr <= '0;
        rand_data <= '0;

        repeat (5) @(posedge clk); 

        wait_rdy();
        
        set_freq(100_000);
        @(posedge clk);
        $display("\nI2C Frequency set to 100 kHz...");
        wait_rdy();

        // ====================================================
        // <<<<<<<<<<<< TEST 1 — Single Byte Write >>>>>>>>>>>>
        // ====================================================

        $display("\n=================================");
        $display("=== TEST 1: Single Byte Write ===");
        $display("=================================");

        bfm_mem_rst();
        // Send Write address
        rand_addr = $urandom_range(((1 << $clog2(MEM_DEPTH)) - 1) , 0);
        // Send actual Data
        rand_data = $urandom_range(((1 << I2C_DATA_W) - 1) , 0); 
        write_transaction('{rand_data}, rand_addr, 1, 0);
        // Deassert after full test — safe because rdy=1 at this point
        desert_cs_wren();

        // Verify directly in BFM memory
        $display("\n--- TEST STATUS ---");
        if (u_i2c_slave_model.mem[rand_addr] === rand_data)
            $display("PASS: BFM mem[0x%02X] = 0x%02X", rand_addr, u_i2c_slave_model.mem[rand_addr]);
        else
            $error("FAIL: BFM mem[0x%02X] = 0x%02X, expected 0x%02X", rand_addr, u_i2c_slave_model.mem[rand_addr], rand_data);

        wait_bus_idle();

        // ===================================================
        // <<<<<<<<<<<< TEST 2 — Single Byte Read >>>>>>>>>>>>
        // ===================================================

        $display("\n================================");
        $display("=== TEST 2: Single Byte Read ===");
        $display("================================");

        bfm_mem_rst();
        // Send Read Address
        rand_addr = $urandom_range(((1 << $clog2(MEM_DEPTH)) - 1) , 0);
        write_transaction('{8'h00}, rand_addr, 0, 1); // Write the address to read from
        read_transaction(1, 0, rd_cnt, rd_tr_cmpl); // Read 1 byte
        // Deassert after full test — safe because rdy=1 at this point
        desert_cs_wren();
        
        // Verify directly in BFM memory
        $display("\n--- TEST STATUS ---");
        $display(" %sREAD: mem[0x%02X] = 0x%02X | BFM has: 0x%02X", (rx_data === u_i2c_slave_model.mem[rand_addr]) ? "PASS: " : "FAIL: ", rand_addr, rx_data, u_i2c_slave_model.mem[rand_addr]);

        wait_bus_idle();

        // ====================================================================
        // <<<<<<<<<<<<<<<<< TEST 3 — Burst Write(Page Write) >>>>>>>>>>>>>>>>>
        // ====================================================================
        
        $display("\n===================================================");
        $display("=== TEST 3: Burst Write %0d bytes from addr 0x00 ===", MEM_DEPTH);
        $display("===================================================");

        bfm_mem_rst();

        write_transaction(data_wr_arr, 8'h00, MEM_DEPTH, 0);
        // Deassert after full test — safe because rdy=1 at this point
        desert_cs_wren();

        // Verify all bytes in BFM memory
        $display("\n--- TEST STATUS ---");
        for (int i = 0; i < MEM_DEPTH; i++) 
        begin
            if (u_i2c_slave_model.mem[i] === data_wr_arr[i])
                $display("PASS: mem[0x%02X] = 0x%02X", i, data_wr_arr[i]);
            else
                $error("FAIL: mem[0x%02X] = 0x%02X, expected 0x%02X", i, u_i2c_slave_model.mem[i], data_wr_arr[i]);
        end

        wait_bus_idle();

        // ====================================================================
        // <<<<<<<<<<<<<<< TEST 4 — Burst Read(Sequential Read) >>>>>>>>>>>>>>>
        // ====================================================================

        $display("\n==================================================");
        $display("=== TEST 4: Burst Read %0d bytes from addr 0x00 ===", MEM_DEPTH);
        $display("==================================================");

        bfm_mem_rst();

        write_transaction('{8'h00}, 8'h00, 0, 1); // Write the start address to read from

        fork
            read_transaction(MEM_DEPTH, 0, rd_cnt, rd_tr_cmpl); // Read MEM_DEPTH bytes sequentially
            forever 
            begin
                if (done && (rd_cnt > 0))
                    data_rd_arr[rd_cnt - 1 + rd_tr_cmpl] = rx_data;
                @(posedge clk);
            end        
        join_any
        disable fork; // Stop the forever loop once read_transaction is done
        // Deassert after full test — safe because rdy=1 at this point
        desert_cs_wren();

        // Verify all bytes in BFM memory
        $display("\n--- TEST STATUS ---");
        for (int i = 0; i < MEM_DEPTH; i++)
            $display("%sREAD[%0d]: mem[0x%02X] = 0x%02X | BFM = 0x%02X", (data_rd_arr[i] === u_i2c_slave_model.mem[i]) ? "PASS: " : "FAIL: ", i, i, data_rd_arr[i], u_i2c_slave_model.mem[i]);

        @(posedge clk);
        wait_rdy();
        wait_bus_idle();

        $display("\n==================================================");
        $display("=== ALL TESTS COMPLETED -- CHECK RESULTS ABOVE ===");
        $display("==================================================\n");
        repeat(5000) @(posedge clk);

        $finish;
    end

endmodule