//FOR WRITE----------------------------------------------

/*START
Master-to-slave: device address, R/W# = 0 (0xAA)
Master-to-slave: register index (0x03)
Master-to-slave: register data (0x57)
STOP*/

//FOR READ-----------------------------------------------

/*START
Master-to-slave: device address, R/W# = 0 (0xAA)
Master-to-slave: register index (0x03)
RESTART
Master-to-slave: device address, R/W# = 1 (0xAB)
Slave-to-master (not acked): register data (0x57)
STOP*/

module i2c_slave_model # (
    parameter [6:0] SLAVE_ADDR = 7'b101_0110
) (
    input logic clk,
    input logic arst_n,

    input logic scl,
    inout tri   sda
);

    typedef enum { 
        STATE_IDLE      = 0,     // idle
        STATE_DEV_ADDR  = 1,     // the slave addr match
        STATE_READ      = 2,     // the op=read
        STATE_IDX_PTR   = 3,     // get the index of inner-register
        STATE_WRITE     = 4      // write the data in the reg
    } state_t;

    state_t           state;
    
    logic             start_detect;
    logic             start_resetter;

    logic             stop_detect;
    logic             stop_resetter;

    logic [3:0]       bit_counter;         // (from 0 to 8) 9counters -> one byte=8bits and one ack=1bit
    logic [7:0]       input_shift;
    logic             master_ack;

    logic [7:0]       sl_reg[0:255]; // slave_reg

    logic [7:0]       output_shift;
    logic             output_control;
    logic [7:0]       index_pointer;

    logic             start_rst;
    logic             stop_rst;

    logic             lsb_bit;
    logic             ack_bit;

    logic             address_detect;
    logic             read_write_bit;
    logic             write_strobe;

    assign start_rst      = ~arst_n || start_resetter; // detect the START for one cycle
    assign stop_rst       = ~arst_n || stop_resetter;  // detect the STOP for one cycle

    assign lsb_bit        = (bit_counter == 4'h7) && !start_detect; // the 8bits one byte data
    assign ack_bit        = (bit_counter == 4'h8) && !start_detect; // the 9bites ack 

    assign address_detect = input_shift[7:1] == SLAVE_ADDR;       // the input address match the slave
    assign read_write_bit = input_shift[0];                       // the write or read operation

    assign write_strobe   = (state == STATE_WRITE) && ack_bit;    // write state and finish one byte=8bits

    assign sda            = output_control ? 1'bz : 1'b0;

    //---------------detect the start--------------
    always @(posedge start_rst or negedge sda)
    begin
        if (start_rst)
        begin
            start_detect <= 1'b0;
        end
        else
        begin
            start_detect <= scl;
        end
    end

    always @ (negedge arst_n or posedge scl)
    begin
        if (~arst_n)
        begin
            start_resetter <= 1'b0;
        end
        else
        begin
            start_resetter <= start_detect;
        end
    end
    //the START just last for one cycle of scl

    //---------------detect the stop---------------
    always @ (posedge stop_rst or posedge sda)
    begin   
        if (stop_rst)
        begin
            stop_detect <= 1'b0;
        end
        else
        begin
            stop_detect <= scl;
        end
    end

    always @ (negedge arst_n or posedge scl)
    begin   
        if (~arst_n)
        begin
            stop_resetter <= 1'b0;
        end
        else
        begin
            stop_resetter <= stop_detect;
        end
    end
    //the STOP just last for one cycle of scl
    //don't need to check the RESTART,due to: a START before it is STOP,it's START; 
    //                                        a START before it is START,it's RESTART;
    //the RESET and START combine can be recognise the RESTART,but it's doesn't matter

    //---------------latch the data---------------
    always @ (negedge scl)
    begin
        if (ack_bit || start_detect)
        begin
            bit_counter <= 4'h0;
        end
        else
        begin
            bit_counter <= bit_counter + 4'h1;
        end
    end
    //counter to 9(from 0 to 8), one byte=8bits and one ack 

    always @ (posedge scl)
    begin
        if (!ack_bit)
        begin
            input_shift <= {input_shift[6:0], sda};
        end
    end
    //at posedge scl the data is stable,the input_shift get one byte=8bits

    //------------slave-to-master transfer---------
    always @ (posedge scl)
    begin
        if (ack_bit)
        begin
            master_ack <= ~sda;//the ack sda is low
        end
    end
    //the 9th bits= ack if the sda=1'b0 it's a ACK, 

    //------------state machine--------------------
    always @ (negedge arst_n or negedge scl)//jcyuan comment
    begin
        if (~arst_n)
        begin
            state <= STATE_IDLE;
        end
        else if (start_detect)
        begin
            state <= STATE_DEV_ADDR;
        end
        else if (ack_bit)//at the 9th cycle and change the state by ACK
        begin
            case (state)
                STATE_IDLE: begin
                    state <= STATE_IDLE;
                end
                STATE_DEV_ADDR: begin
                    if (!address_detect) // addr don't match
                    begin
                        state <= STATE_IDLE;
                    end
                    else if (read_write_bit) // addr match and operation is read
                    begin
                        state <= STATE_READ;
                    end
                    else // addr match and operation is write
                    begin
                        state <= STATE_IDX_PTR;
                    end
                end
                STATE_READ: begin
                    if (master_ack) // get the master ack
                    begin
                        state <= STATE_READ;
                    end 
                    else // no master ack ready to STOP
                    begin
                        state <= STATE_IDLE;
                    end
                end
                STATE_IDX_PTR: begin
                    state <= STATE_WRITE; // get the index and ready to write 
                end
                default: begin // STATE_WRITE
                    state <= STATE_WRITE; // when the state is write the state 
                end
            endcase
        end
        //if don't write and master send a stop,need to jump idle
        //the stop_detect is the next cycle of ACK
        else if(stop_detect)
        begin
            state <= STATE_IDLE;
        end  
    end

    //------------Register transfers---------------

    //-------------------for index----------------
    always @ (negedge arst_n or negedge scl)
    begin
        if (~arst_n)
        begin
            index_pointer <= 8'h00;
        end
        else if (stop_detect)
        begin
            index_pointer <= 8'h00;
        end
        else if (ack_bit) // at the 9th bit -ack, the input_shift has one bytes
        begin
            if (state == STATE_IDX_PTR) //at the state get the inner-register index
            begin
                index_pointer <= input_shift;
            end
            else // ready for next read/write;bulk transfer of a block of data 
            begin
                index_pointer <= index_pointer + 8'h01;
            end
        end
    end

    //----------------for write---------------------------
    //we only define 4 registers for operation
    always @ (negedge arst_n or negedge scl)
    begin
        if (~arst_n)
        begin
            for (int i=0; i<(1 << 8); i=i+1)
            begin
                sl_reg[i] <= 8'h00;
            end
        end // the moment the input_shift has one byte=8bits
        else if (write_strobe)
        begin
            for (int i=0; i<(1 << 8); i=i+1)
            begin
                if (i == index_pointer)
                begin
                    sl_reg[i] <= input_shift; 
                end
            end
        end
    end

    //------------------------for read-----------------------
    always @ (negedge scl)
    begin   
        if (lsb_bit)//at one byte that can be load the output_shift
        begin
            output_shift <= sl_reg[index_pointer];
        end
        else
        begin
            output_shift <= {output_shift[6:0], 1'b0};
        end
        //once the shift it,after 8 times the output_shift=8'b0
        //the 9th bit is 0 for the RESTART for address match slave ACK 
    end

    //------------Output driver--------------------

    always @ (negedge arst_n or negedge scl)
    begin   
        if (~arst_n)
        begin
            output_control <= 1'b1;
        end
        else if (start_detect)
        begin
            output_control <= 1'b1;
        end
        else if (lsb_bit)
        begin   
            output_control <= ~(((state == STATE_DEV_ADDR) && address_detect) || (state == STATE_IDX_PTR) || (state == STATE_WRITE)); 
            //when operation is wirte 
            //addr match gen ACK,the index get gen ACK,and write data gen ACK
        end
        else if (ack_bit)
        begin
            // Deliver the first bit of the next slave-to-master
            // transfer, if applicable.
            if (((state == STATE_READ) && master_ack) || ((state == STATE_DEV_ADDR) && address_detect && read_write_bit))
            begin
                output_control <= output_shift[7];
            end
            //for the RESTART and send the addr ACK for 1'b0
            //for the read and master ack both slave is pull down
            else
            begin
                output_control <= 1'b1;
            end
        end
        else if (state == STATE_READ) // for read send output shift to sda
        begin
            output_control <= output_shift[7];
        end
        else
        begin
            output_control <= 1'b1;
        end
    end

endmodule