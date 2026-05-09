module i2c_slave_model (scl, sda);

	parameter SLAVE_ADDR = 7'b101_0110; // 7'h56
    parameter DEBUG      = 1'b1; 

	input scl;
	inout sda;

	reg [7:0] mem [0:15]; // initiate memory
	reg [3:0] mem_adr;   // memory address
	reg [7:0] mem_do;    // memory DATA output

	reg sta, d_sta;
	reg sto, d_sto;

	reg [7:0] sr;        // 8bit shift register
	reg       rw;        // read/write direction

	wire      my_adr;    // my address called ??
	wire      i2c_reset; // i2c-statemachine reset
	reg [2:0] bit_cnt;   // 3bit downcounter
	wire      acc_done;  // 8bits transfered
	reg       ld;        // load downcounter

	reg       sda_o;     // sda-drive level
	wire      sda_dly;   // delayed version of sda

	// statemachine declaration
    typedef enum logic [2:0] { 
        IDLE        = 3'b000,
        SLAVE_ACK   = 3'b001,
        GET_MEM_ADR = 3'b010,
        GMA_ACK     = 3'b011,
        DATA        = 3'b100,
        DATA_ACK    = 3'b101
    } state_t;

	state_t state; // synopsys enum_state

	initial
	begin
        sda_o = 1'b1;
        state = IDLE;
        for (int i=0; i<16; i=i+1)
            mem[i] = 8'h00;
    end

	// generate shift register
	always @(posedge scl)
	    sr <= #1 {sr[6:0],sda};

	//detect my_address
	assign my_adr = (sr[7:1] == SLAVE_ADDR);
	// FIXME: This should not be a generic assign, but rather
	// qualified on address transfer phase and probably reset by stop

	//generate bit-counter
	always @(posedge scl)
        if(ld)
            bit_cnt <= #1 3'b111;
        else
            bit_cnt <= #1 bit_cnt - 3'h1;

	//generate access done signal
	assign acc_done = !(|bit_cnt);

	// generate delayed version of sda
	// this model assumes a hold time for sda after the falling edge of scl.
	// According to the Phillips i2c spec, there s/b a 0 ns hold time for sda
	// with regards to scl. If the DATA changes coincident with the clock, the
	// acknowledge is missed
	// Fix by Michael Sosnoski
	assign #1 sda_dly = sda;

	//detect start condition
	always @(negedge sda)
        if(scl)
	    begin
	        sta   <= #1 1'b1;
            d_sta <= #1 1'b0;
            sto   <= #1 1'b0;

	        if(DEBUG)
	          $display("DEBUG_I2C_SLAVE: Start Condition Detected at %t", $time);
	    end
	    else
	        sta <= #1 1'b0;

	always @(posedge scl)
	    d_sta <= #1 sta;

	// detect stop condition
	always @(posedge sda)
	    if(scl)
	    begin
            sta <= #1 1'b0;
            sto <= #1 1'b1;

            if(DEBUG)
                $display("DEBUG_I2C_SLAVE: Stop Condition Detected at %t", $time);
	    end
	    else
	        sto <= #1 1'b0;

	//generate i2c_reset signal
	assign i2c_reset = sta || sto;

	// generate statemachine
	always @(negedge scl or posedge sto)
	    if (sto || (sta && !d_sta) )
	    begin
            state <= #1 IDLE; // reset statemachine

            sda_o <= #1 1'b1;
            ld    <= #1 1'b1;
	    end
	    else
	    begin
	        // initial settings
	        sda_o <= #1 1'b1;
	        ld    <= #1 1'b0;

	        case(state) // synopsys full_case parallel_case
	            IDLE: // IDLE state
	                if (acc_done && my_adr)
	                begin
	                    state <= #1 SLAVE_ACK;
	                    rw <= #1 sr[0];
	                    sda_o <= #1 1'b0; // generate i2c_ack

	                    #2;
	                    if(DEBUG && rw)
	                        $display("DEBUG_I2C_SLAVE: Command Byte Received (READ) at %t", $time);
	                    if(DEBUG && !rw)
	                        $display("DEBUG_I2C_SLAVE: Command Byte Received (WRITE) at %t", $time);

	                    if(rw)
	                    begin
                            mem_do <= #1 mem[mem_adr];

                            if(DEBUG)
                            begin
                                #2 $display("DEBUG_I2C_SLAVE: Data Block READ %x from Address %x (1)", mem_do, mem_adr);
                                // #2 $display("DEBUG i2c_slave; memcheck [0]=%x, [1]=%x, [2]=%x", mem[4'h0], mem[4'h1], mem[4'h2]);
                            end
                        end
	                end

	            SLAVE_ACK:
	              begin
	                    if(rw)
	                    begin
	                        state <= #1 DATA;
	                        sda_o <= #1 mem_do[7];
	                    end
	                    else
	                        state <= #1 GET_MEM_ADR;

	                    ld    <= #1 1'b1;
	              end

	            GET_MEM_ADR: // wait for memory address
	                if(acc_done)
	                begin
	                    state <= #1 GMA_ACK;
	                    mem_adr <= #1 sr; // store memory address
	                    sda_o <= #1 !(sr <= 15); // generate i2c_ack, for valid address

	                    if(DEBUG)
	                        #2 $display("DEBUG_I2C_SLAVE: Address Received. Addr=%x, Ack=%b", sr, sda_o);
	                end

	            GMA_ACK:
                begin
                    state <= #1 DATA;
                    ld    <= #1 1'b1;
                end

	            DATA: // receive or drive DATA
                begin
                    if(rw)
	                    sda_o <= #1 mem_do[7];

                    if(acc_done)
	                begin
                        state <= #1 DATA_ACK;
                        mem_adr <= #2 mem_adr + 8'h1;
                        sda_o <= #1 (rw && (mem_adr <= 15) ); // send ack on write, receive ack on read

                        if(rw)
                        begin
                            #3 mem_do <= mem[mem_adr];

                            if(DEBUG)
                            #5 $display("DEBUG_I2C_SLAVE: Data Block READ %x from Address %x (2)", mem_do, mem_adr);
                        end

                        if(!rw)
                        begin
                            mem[mem_adr] <= #1 sr; // store DATA in memory

                            if(DEBUG)
                            #2 $display("DEBUG_I2C_SLAVE: Data Block WRITE %x to Address %x", sr, mem_adr);
                        end
                    end
	              end

	            DATA_ACK:
                begin
                    ld <= #1 1'b1;

                    if(rw)
                        if(sr[0]) // read operation && master send NACK
                        begin
                            state <= #1 IDLE;
                            sda_o <= #1 1'b1;
                        end
                        else
                        begin
                            state <= #1 DATA;
                            sda_o <= #1 mem_do[7];
                        end
                    else
                    begin
                        state <= #1 DATA;
                        sda_o <= #1 1'b1;
                    end
                end
	        endcase
	    end

	// read DATA from memory
	always @(posedge scl)
	    if(!acc_done && rw)
	        mem_do <= #1 {mem_do[6:0], 1'b1}; // insert 1'b1 for host ack generation

	// generate tri-states
	assign sda = sda_o ? 1'bz : 1'b0;

	//
	// Timing checks
	//

	wire tst_sto = sto;
	wire tst_sta = sta;

	specify
        specparam   normal_scl_low  = 4700,
                    normal_scl_high = 4000,
                    normal_tsu_sta  = 4700,
                    normal_thd_sta  = 4000,
                    normal_tsu_sto  = 4000,
                    normal_tbuf     = 4700,

                    // below fast parameters are definde but not used in this model
                    fast_scl_low  = 1300,
                    fast_scl_high =  600,
                    fast_tsu_sta  = 1300,
                    fast_thd_sta  =  600,
                    fast_tsu_sto  =  600,
                    fast_tbuf     = 1300;

        // $width monitors how long a signal stays in a state after a transition:
        $width(negedge scl, normal_scl_low);  // SCL low  pulse must be ≥ 4700ps
        $width(posedge scl, normal_scl_high); // SCL high pulse must be ≥ 4000ps

        // $setup & Hold Time Checks:
        $setup(posedge scl, negedge sda &&& scl, normal_tsu_sta); // setup start
        $setup(negedge sda &&& scl, negedge scl, normal_thd_sta); // hold start
        $setup(posedge scl, posedge sda &&& scl, normal_tsu_sto); // setup stop

        $setup(posedge tst_sta, posedge tst_sto, normal_tbuf); // stop to start time
	endspecify

endmodule