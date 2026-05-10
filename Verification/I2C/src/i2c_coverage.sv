module i2c_coverage 
    import i2c_pkg::ADDR_WIDTH;
    import i2c_pkg::DATA_WIDTH;
    import i2c_pkg::I2C_DATA_W;
    import i2c_pkg::I2C_DVSR_W;
    import i2c_pkg::I2C_CMD_W;
    
    import i2c_pkg::START_CMD;
    import i2c_pkg::WR_CMD;
    import i2c_pkg::RD_CMD;
    import i2c_pkg::STOP_CMD;
    import i2c_pkg::RESTART_CMD;

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

(
    input  logic                  clk,
    input  logic                  arst_n,
    // ctrl
    input  logic                  cs,
    input  logic                  wr_en,
    input  logic                  rd_en,
    // data
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic [DATA_WIDTH-1:0] rdata,
    // external signals
    inout  tri                    scl,
    inout  tri                    sda
);
    
    covergroup i2c_cg @(posedge clk);
        
        // only cover the freq when the master is writing to the status register at val/rdy handshake
        cp_freq: coverpoint wdata[I2C_DVSR_W-1:0] iff (cs && wr_en && (addr[0] == 0)) {
            // fsys = 100MHz, dvsr = fsys / (4 * fi2c) => dvsr = 250 for 100kHz
            bins freq_100kHz = {      'hFA};
            bins freq_400kHz = {'h3E, 'h3F}; // dvsr = 62.5 for 400kHz
            bins freq_1MHz   = {      'h19}; // dvsr = 25 for 100kHz
        }

        // only cover the command when the master is writing to the command register at val/rdy handshake
        cp_cmd: coverpoint wdata[I2C_DATA_W +: I2C_CMD_W] iff (cs && wr_en && (addr[0] == 1) && (rdata[I2C_DATA_W] == 1)) {
            bins cmd_start   = {START_CMD  }; 
            bins cmd_wr      = {WR_CMD     };
            bins cmd_rd      = {RD_CMD     };
            bins cmd_stop    = {STOP_CMD   };
            bins cmd_restart = {RESTART_CMD};
        }

        // Was NACK requested on read? (last byte of read)
        cp_read_nack: coverpoint wdata[0] iff (cs && wr_en && (addr[0] == 1) && (wdata[I2C_DATA_W +: I2C_CMD_W] == RD_CMD) && (rdata[I2C_DATA_W] == 1)) {
            bins read_with_ack  = {1'b0};  // mid-burst read
            bins read_with_nack = {1'b1};  // last byte read
        }

        // ACK/NACK received from slave, only cover when rdy is high
        cp_ack: coverpoint rdata[I2C_DATA_W + 1] iff (rdata[I2C_DATA_W] == 1) {
            bins got_ack  = {1'b1};
            bins got_nack = {1'b0};
        }

        // All FSM states visited
        cp_state: coverpoint u_i2c_master.CS {
            bins st_idle     = {    IDLE};
            bins st_hold     = {    HOLD};
            bins st_start1   = {  START1};
            bins st_start2   = {  START2};
            bins st_data1    = {   DATA1};
            bins st_data2    = {   DATA2};
            bins st_data3    = {   DATA3};
            bins st_data4    = {   DATA4};
            bins st_data_end = {DATA_END};
            bins st_restart  = { RESTART};
            bins st_stop1    = {   STOP1};
            bins st_stop2    = {   STOP2};
        }

        // Key state transitions
        cp_trans: coverpoint u_i2c_master.CS {
            bins idle_to_start    = (IDLE     => START1  );
            bins start1_to_start2 = (START1   => START2  );
            bins start2_to_hold   = (START2   => HOLD    );
            bins hold_to_data     = (HOLD     => DATA1   );
            bins data1_to_data2   = (DATA1    => DATA2   );
            bins data2_to_data3   = (DATA2    => DATA3   );
            bins data3_to_data4   = (DATA3    => DATA4   );
            bins data4_to_end     = (DATA4    => DATA_END);
            bins end_to_hold      = (DATA_END => HOLD    );
            bins hold_to_stop     = (HOLD     => STOP1   );
            bins stop1_to_stop2   = (STOP1    => STOP2   );
            bins stop2_to_idle    = (STOP2    => IDLE    );
            bins hold_to_restart  = (HOLD     => RESTART );
            bins restart_to_start = (RESTART  => START1  );
        }

        // cover the combinations of command and frequency
        // cx_cmd_freq: cross cp_cmd, cp_freq;
        // cx_cmd_freq: cross cp_cmd, cp_freq {
        //     ignore_bins unused_400k = binsof(cp_freq.freq_400kHz);
        //     ignore_bins unused_1M   = binsof(cp_freq.freq_1MHz);
        // } --> As setting freq and setting commands are mutually exclusive, this cross will never hit.

        // cover the combinations of command and ACK/NACK
        // cx_cmd_ack: cross cp_cmd, cp_ack;
        cx_cmd_ack: cross cp_cmd, cp_ack {
            // START and STOP are bus conditions — slave never ACKs/NACKs them
            // These combinations are structurally impossible
            ignore_bins start_nack   = binsof(cp_cmd.cmd_start)   && binsof(cp_ack.got_nack);
            ignore_bins stop_nack    = binsof(cp_cmd.cmd_stop)    && binsof(cp_ack.got_nack);
            ignore_bins restart_nack = binsof(cp_cmd.cmd_restart) && binsof(cp_ack.got_nack);
            
            ignore_bins start_ack    = binsof(cp_cmd.cmd_start)   && binsof(cp_ack.got_ack);
            ignore_bins stop_ack     = binsof(cp_cmd.cmd_stop)    && binsof(cp_ack.got_ack);
            ignore_bins restart_ack  = binsof(cp_cmd.cmd_restart) && binsof(cp_ack.got_ack);
        }
    
    endgroup

    i2c_cg i2c_cov = new();


    ///////////////////////////////////////////////
    // COVERAGE REPORT
    ///////////////////////////////////////////////

    final 
    begin
        $display("\n-----------------------");
        $display("--- COVERAGE REPORT ---");
        $display("-----------------------\n");
        $display("Overall______: %0.2f%%", i2c_cov.get_coverage()             );
        $display("freq_________: %0.2f%%", i2c_cov.cp_freq.get_coverage()     );
        $display("cp_cmd_______: %0.2f%%", i2c_cov.cp_cmd.get_coverage()      );
        $display("cp_read_nack_: %0.2f%%", i2c_cov.cp_read_nack.get_coverage());
        $display("cp_ack_______: %0.2f%%", i2c_cov.cp_ack.get_coverage()      );
        $display("cp_state_____: %0.2f%%", i2c_cov.cp_state.get_coverage()    );
        $display("cp_trans_____: %0.2f%%", i2c_cov.cp_trans.get_coverage()    );
        // $display("cx_cmd_freq__: %0.2f%%", i2c_cov.cx_cmd_freq.get_coverage() );
        $display("cx_cmd_ack___: %0.2f%%", i2c_cov.cx_cmd_ack.get_coverage()  );
        $display("-----------------------\n");
    end

endmodule