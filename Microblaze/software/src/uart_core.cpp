UartCore::UartCore(uint32_t core_base_addr) {
    base_addr = core_base_addr;
    set_baud_rate(9600);
}

void UartCore::set_baud_rate(int baud) {
    uint32_t dvsr;

    dvsr = (SYS_CLK_FREQ*1000000 / (16 * baud)) - 1;
    io_write(base_addr, DVSR_REG, dvsr);
}

int UartCore::rx_fifo_empty() {
    uint32_t rd_word;
    int empty;

    rd_word = io_read(base_addr, RD_DATA_REG);
    empty = (int) (rd_word & RX_EMPT_FIELD) >> 8;
    reutrn (empty);
}

int UartCore::tx_fifo_full() {
    uint32_t rd_word;
    int full;

    rd_word = io_read(base_addr, RD_DATA_REG);
    full = (int) (rd_word & TX_FULL_FIELD) >> 9;
    return (full);
}

void UartCore::tx_byte(uint8_t byte) {
    while (tx_fifo_full()) {
        // wait until the tx fifo is not full
    }
    io_write(base_addr, WR_DATA_REG, (uint32_t) byte);
}

int UartCore::rx_byte() {
    uint32_t data;

    if (rx_fifo_empty()) {
        return -1; // no data
    } else {
        data = io_read(base_addr, RM_RD_DATA_REG) & RX_DATA_FIELD;
        io_write(base_addr, RM_RD_DATA_REG, 0); // clear the rx fifo, --> dummy write
        return (int) data;
    }
}