// i2c_assertions.sv
module i2c_assertions
    import i2c_pkg::*;
(
    input logic        clk,
    input logic        arst_n,
    input logic        scl,
    input logic        sda
);

    // START assertion
    property p_valid_start;
        @(posedge clk) disable iff (!arst_n)

        $fell(sda) && (u_i2c_master.CS === START1) |-> scl === 1;
    endproperty
    ap_start: assert property(p_valid_start)
        else $error("SVA FAIL: START invalid at %0t\n\n", $time);

    // data stability check
    property p_sda_stable;
        @(posedge clk) disable iff (!arst_n)
        // SCL is high AND master is in a DATA state (not START/STOP/IDLE)
        ((scl === 1'b1) && ((u_i2c_master.CS === DATA2) || (u_i2c_master.CS === DATA3))) |-> $stable(sda);
    endproperty
    ap_sda_stable: assert property(p_sda_stable)
        else $error("SVA FAIL: SDA unstable during DATA at %0t\n\n", $time);

    // SCL must be LOW when SDA changes during data phase
    property p_data_change_on_scl_low;
        @(posedge clk) disable iff (!arst_n)

        (($fell(sda) || $rose(sda)) && ((u_i2c_master.CS === DATA1) || (u_i2c_master.CS === DATA4))) |-> scl === 0;
    endproperty
    ap_data_on_low: assert property(p_data_change_on_scl_low)
        else $error("SVA FAIL: SDA changed while SCL HIGH at %0t\n\n", $time);

    // STOP assertion  
    property p_valid_stop;
        @(posedge clk) disable iff (!arst_n)

        $rose(sda) && (u_i2c_master.CS === STOP2) |-> scl === 1;
    endproperty
    ap_stop: assert property(p_valid_stop)
        else $error("SVA FAIL: STOP invalid at %0t\n\n", $time);

    // After STOP, bus must be free (both SDA and SCL high) before next START
    property p_bus_free_after_stop;
        @(posedge clk) disable iff (!arst_n)

        $past(u_i2c_master.CS === STOP2) && (u_i2c_master.CS === IDLE) |-> (scl && sda);
    endproperty
    ap_bus_free: assert property(p_bus_free_after_stop)
        else $error("SVA FAIL: Bus not free after STOP at %0t\n\n", $time);

endmodule