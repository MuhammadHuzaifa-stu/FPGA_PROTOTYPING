module tb_i2c_core ();
    
    import i2c_pkg::ADDR_WIDTH;
    import i2c_pkg::DATA_WIDTH;

    import i2c_pkg::I2C_DATA_W;
    import i2c_pkg::I2C_DVSR_W;
    import i2c_pkg::I2C_CMD_W;

    localparam SLAVE_ADDR = 7'b1010110; // Example slave address (7 bits)

    // Commands
    localparam START_CMD   = 3'b000;
    localparam WR_CMD      = 3'b001;
    localparam RD_CMD      = 3'b010;
    localparam STOP_CMD    = 3'b011;
    localparam RESTART_CMD = 3'b100;

    logic clk;
    logic arst_n;

    logic rdy;
    logic ack;

    logic [I2C_DATA_W-1:0] rx_data;

    pullup (u_i2c_if.sda); // both are pulled-up when no one driving these ports
    pullup (u_i2c_if.scl); // both are pulled-up when no one driving these ports

    i2c_interface u_i2c_if (
        .clk   ( clk   ),
        .arst_n( arst_n)
    );

    // slave model
    i2c_slave_model #(
        .SLAVE_ADDR ( SLAVE_ADDR )
    ) u_i2c_slave_model (
        .clk    ( u_i2c_if.SL.clk    ),
        .arst_n ( u_i2c_if.SL.arst_n ),
        .scl    ( u_i2c_if.SL.scl    ),
        .sda    ( u_i2c_if.SL.sda    )
    );

    // address = 0: frequency register, address = 1: data & cmd register
    // Considering slave_address = {7b1010110, write_bit = 0 or read_bit = 1}
    chu_i2c_core u_dut (
        .clk   ( u_i2c_if.DUT.clk   ),
        .arst_n( u_i2c_if.DUT.arst_n),
        .cs    ( u_i2c_if.DUT.cs    ),
        .wr_en ( u_i2c_if.DUT.wr_en ),
        .rd_en ( u_i2c_if.DUT.rd_en ),
        .addr  ( u_i2c_if.DUT.addr  ),
        .wdata ( u_i2c_if.DUT.wdata ), // [31:0] => [data(7:0), cmd(10:8), reserved(31:11)]
        .rdata ( u_i2c_if.DUT.rdata ), // [31:0] => [data(7:0), rdy(8), ack(9), reserved(31:10)]
        .scl   ( u_i2c_if.DUT.scl   ),
        .sda   ( u_i2c_if.DUT.sda   )
    );

    assign rdy = u_i2c_if.DRV.rdata[I2C_DATA_W  ]; // ready bit is bit 8 of rdata
    assign ack = u_i2c_if.DRV.rdata[I2C_DATA_W+1]; // ack bit is bit 9 of rdata

    task automatic wait_rdy();
        while (!rdy) 
        begin
            @(posedge clk);
        end
    endtask

    task automatic set_freq(input logic [DATA_WIDTH-1:0] freq);

        u_i2c_if.DRV.addr  <= 'h0000_0000;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= (100_000_000 / (freq << 2)); // Assuming 100MHz clock

    endtask

    task automatic start();

        u_i2c_if.DRV.addr  <= 'h0000_0001;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        // u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, START_CMD, SLAVE_ADDR, read};
        u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, START_CMD, {(I2C_DATA_W){1'b0}}};

    endtask
    
    task automatic restart();

        u_i2c_if.DRV.addr  <= 'h0000_0001;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        // u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, RESTART_CMD, SLAVE_ADDR, read};
        u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, RESTART_CMD, {(I2C_DATA_W){1'b0}}};

    endtask
    
    task automatic stop();

        u_i2c_if.DRV.addr  <= 'h0000_0001;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, STOP_CMD, {(I2C_DATA_W){1'b0}}};

    endtask
    
    task automatic read_byte(
        input  logic [I2C_DATA_W-1:0] address                 
    );

        u_i2c_if.DRV.addr  <= 'h0000_0001;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, RD_CMD, address};

    endtask
    
    task automatic write_byte(
        input  logic [I2C_DATA_W-1:0] data
    );

        u_i2c_if.DRV.addr  <= 'h0000_0001;
        u_i2c_if.DRV.wr_en <= '1;
        u_i2c_if.DRV.cs    <= '1;
        u_i2c_if.DRV.wdata <= {{(DATA_WIDTH - I2C_CMD_W - I2C_DATA_W){1'b0}}, WR_CMD, data};

    endtask

    task automatic Driver();
        
    endtask

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk; // 100MHz clock
        end
    end

    initial begin
        arst_n <= 1;
        #5;
        arst_n <= 0;
        #8;
        arst_n <= 1;
    end

    initial begin
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
            
            // TEST: Write 0x57 to Register 0x03
            // 1. start
            // 2. slave_address + write_bit
            // 3. send index pointer (0x03)
            // 4. send actual data (0x57)
            $display("TEST: Writing 0x57 to Register 0x03");
            wait_rdy();
            start();          // 1. start
            @(posedge clk);

            wait_rdy();
            write_byte(8'hAC); // 2. slave address + write_bit
            @(posedge clk);
            wait_rdy();

            wait_rdy();
            write_byte(8'h03); // 3. Send Index Pointer
            @(posedge clk);
            wait_rdy();
            
            wait_rdy();
            write_byte(8'h57); // 4. Send actual Data
            @(posedge clk);
            wait_rdy();
            
            wait_rdy();
            stop();
            @(posedge clk);
            wait_rdy();

            $display("TEST: Reading back from Register 0x03");
            // TEST: Read back from Register 0x03
            // 1. start
            // 2. slave_address + write_bit
            // 3. send index pointer (0x03)
            // 4. restart
            // 5. slave_address + read_bit
            // 6. read actual data
            wait_rdy();
            start();          // 1. Start
            @(posedge clk);
            wait_rdy();

            wait_rdy();
            write_byte(8'hAC); // 2. slave address + write_bit
            @(posedge clk);
            wait_rdy();

            wait_rdy();
            write_byte(8'h03); // 3. Send Index Pointer
            @(posedge clk);
            wait_rdy();
            
            wait_rdy(); 
            restart();        // 4. Restart
            @(posedge clk);
            wait_rdy();

            wait_rdy();
            write_byte(8'hAD); // 5. slave address + read_bit
            @(posedge clk);
            wait_rdy();
            
            wait_rdy();
            read_byte(8'h00); // 6. Read the byte
            @(posedge clk);
            wait_rdy();
            rx_data = u_i2c_if.DRV.rdata[I2C_DATA_W-1:0];
            
            wait_rdy(); 
            stop();
            @(posedge clk);
            wait_rdy();
            
            if(rx_data == 8'h57) $display("SUCCESS: Read matched Write!");
            
        end
        $finish;
    end

endmodule