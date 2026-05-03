//=============================================================================
// I2C Slave Bus Functional Model (BFM)
// Supports: 7-bit addressing, Standard (100kHz) / Fast (400kHz) modes
//=============================================================================

module i2c_slave_bfm #(
    parameter SLAVE_ADDR = 7'h56,   // 7-bit slave address
    parameter MEM_DEPTH  = 256,     // Internal memory depth
    parameter DATA_WIDTH = 8        // Data width in bits
)(
    input  tri scl,                   // Serial Clock Line
    inout  tri sda                    // Serial Data Line
);

    // Internal Signals
    logic scl_in;
    logic sda_in;
    logic sda_out;
    logic sda_oe;    // Output enable (active high → drive low)

    assign scl_in = scl;
    assign sda_in = sda;
    assign sda    = sda_oe ? 1'b0 : 1'bz; // Open-drain: drive 0 or release

    // Internal Memory & Registers
    logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    logic [DATA_WIDTH-1:0] mem_addr;       // Internal register/memory pointer
    logic [DATA_WIDTH-1:0] shift_reg;      // Shift register for TX/RX
    logic [DATA_WIDTH-1:0] rx_data;
    logic [DATA_WIDTH-1:0] tx_data;

    integer bit_cnt;                       // Bit counter (7 downto 0)

    // State Machine Definition
    typedef enum logic [3:0] {
        IDLE,
        START,
        ADDR,
        REG_ADDR,
        WRITE_DATA,
        READ_DATA,
        STOP
    } state_t;

    state_t state, next_state;

    logic rw_bit;           // 0=Write, 1=Read
    logic addr_match;       // Address matched flag
    logic start_det;        // START condition detected
    logic stop_det;         // STOP condition detected
    logic rep_start_det;    // Repeated START detected

    // START / STOP Condition Detection (SDA edge while SCL=HIGH)
    always @(negedge sda_in) 
    begin
        if (scl_in === 1'b1) 
        begin
            start_det    = 1'b1;
            stop_det     = 1'b0;
            $display("[I2C_SLAVE @ %0t] START condition detected", $time);
        end
    end

    always @(posedge sda_in) 
    begin
        if (scl_in === 1'b1) 
        begin
            stop_det     = 1'b1;
            start_det    = 1'b0;
            $display("[I2C_SLAVE @ %0t] STOP condition detected", $time);
        end
    end

    // Main BFM State Machine (SCL-triggered)
    initial begin
        sda_oe     = 1'b0;
        sda_out    = 1'b1;
        bit_cnt    = 7;
        state      = IDLE;
        addr_match = 0;

        // Initialize memory
        foreach (mem[i]) mem[i] = i;

        forever begin
            @(posedge scl_in or posedge start_det or posedge stop_det);

            //--- STOP: return to IDLE ---
            if (stop_det) 
            begin
                stop_det = 0;
                state    = IDLE;
                sda_oe   = 0;
                $display("[I2C_SLAVE @ %0t] → IDLE (STOP)", $time);
                disable fork;
            end

            //--- START: begin address phase ---
            else if (start_det) 
            begin
                start_det  = 0;
                state      = ADDR;
                bit_cnt    = 7;
                shift_reg  = '0;
                sda_oe     = 0;
                $display("[I2C_SLAVE @ %0t] → ADDR phase", $time);
            end

            //--- Normal SCL posedge: sample data ---
            else 
            begin
                case (state)

                    // ADDR: Receive 7-bit address + R/W bit (8 clocks total)
                    ADDR: begin
                        shift_reg = {shift_reg[6:0], sda_in};
                        if (bit_cnt == 0) begin
                            rw_bit     = shift_reg[0];
                            addr_match = (shift_reg[7:1] == SLAVE_ADDR);

                            @(negedge scl_in);          // negedge-8: ACK
                            if (addr_match) begin
                                sda_oe = 1'b1;
                                @(negedge scl_in);      // negedge-9: release ACK

                                if (rw_bit) 
                                begin
                                    // ✅ Fix 1: load mem BEFORE driving any bit
                                    tx_data   = mem[mem_addr];
                                    shift_reg = tx_data;
                                    sda_oe    = 1'b0;   // release ACK

                                    // ✅ Fix 2: drive all 8 bits inline, no return to forever loop
                                    for (int b = 7; b >= 0; b--) begin
                                        sda_oe = (shift_reg[7] == 1'b0);    // drive MSB first
                                        shift_reg = {shift_reg[6:0], 1'b0};
                                        @(negedge scl_in);                  // hold until next negedge
                                    end

                                    // READ ACK inline
                                    sda_oe = 1'b0;              // release SDA to master
                                    @(posedge scl_in);          // sample master ACK/NACK

                                    if (sda_in == 1'b0) 
                                    begin   // master ACK → more bytes
                                        mem_addr++;
                                        state = READ_DATA;      // continue burst
                                        bit_cnt = 7;
                                        shift_reg = mem[mem_addr]; // ← preload next byte
                                    end 
                                    else 
                                    begin              // master NACK → done
                                        state = IDLE;
                                    end

                                end 
                                else 
                                begin
                                    sda_oe    = 1'b0;
                                    shift_reg = '0;
                                    state     = REG_ADDR;
                                    bit_cnt   = 7;
                                end

                            end 
                            else 
                            begin
                                sda_oe = 1'b0;
                                state  = IDLE;
                            end
                        end 
                        else 
                        begin
                            bit_cnt--;
                        end
                    end

                    // REG_ADDR: Receive memory/register address byte
                    REG_ADDR: begin
                        shift_reg = {shift_reg[6:0], sda_in};
                        if (bit_cnt == 0) 
                        begin
                            mem_addr = shift_reg;
                            $display("[I2C_SLAVE @ %0t] REG_ADDR rcvd: 0x%02X", $time, mem_addr);
                            @(negedge scl_in);
                            sda_oe = 1'b1;
                            @(negedge scl_in);
                            sda_oe    = 1'b0;
                            shift_reg = '0;
                            state     = WRITE_DATA;
                            bit_cnt = 7;
                        end 
                        else 
                        begin
                            bit_cnt--;
                        end
                    end

                    // WRITE_DATA: Receive 8-bit data byte from master
                    WRITE_DATA: begin
                        shift_reg = {shift_reg[6:0], sda_in};
                        if (bit_cnt == 0) 
                        begin
                            rx_data        = shift_reg;
                            mem[mem_addr]  = rx_data;
                            $display("[I2C_SLAVE @ %0t] WRITE: mem[0x%02X] ← 0x%02X", $time, mem_addr, rx_data);
                            mem_addr++;    // Auto-increment for burst writes
                            @(negedge scl_in);
                            sda_oe = 1'b1;
                            @(negedge scl_in);
                            sda_oe    = 1'b0;
                            shift_reg = '0;
                            state     = WRITE_DATA;
                            bit_cnt = 7;
                        end 
                        else 
                        begin
                            bit_cnt--;
                        end
                    end

                    // READ_DATA: Transmit 8-bit data byte to master (MSB first)
                    READ_DATA: begin
                        // shift_reg already preloaded with mem[mem_addr] from ACK phase
                        for (int b = 7; b >= 0; b--) 
                        begin
                            sda_oe    = (shift_reg[7] == 1'b0);
                            shift_reg = {shift_reg[6:0], 1'b0};
                            @(negedge scl_in);
                        end

                        // READ ACK
                        sda_oe = 1'b0;
                        @(posedge scl_in);

                        if (sda_in == 1'b0) 
                        begin
                            mem_addr++;
                            shift_reg = mem[mem_addr];   // ← preload next before looping
                            state     = READ_DATA;
                            bit_cnt   = 7;
                        end 
                        else 
                        begin
                            state = IDLE;
                        end
                    end

                    default: state = IDLE;
                endcase
            end
        end
    end

    // Timeout Watchdog (optional, 10ms bus timeout)
    time last_activity;
    always @(posedge scl_in or posedge start_det) last_activity = $time;

    initial forever begin
        #10_000_000; // 10ms
        if (state != IDLE && ($time - last_activity) > 10_000_000) 
        begin
            $display("[I2C_SLAVE @ %0t] WARNING: Bus timeout! Resetting to IDLE.", $time);
            state  = IDLE;
            sda_oe = 0;
        end
    end

    // Debug Task: Dump memory contents
    task dump_memory(input int start_addr, input int end_addr);
        $display("=== I2C Slave Memory Dump [0x%02X - 0x%02X] ===", start_addr, end_addr);
        for (int i = start_addr; i <= end_addr; i++)
            $display("  mem[0x%02X] = 0x%02X", i, mem[i]);
    endtask

endmodule