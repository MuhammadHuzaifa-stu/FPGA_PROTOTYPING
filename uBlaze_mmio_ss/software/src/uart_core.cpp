#include "uart_core.h"
#include "chu_io_rw.h"
#include "chu_io_map.h"

UartCore::UartCore(uint32_t core_base_addr) {
    base_addr = core_base_addr;
    set_baud_rate(9600);
}

UartCore::~UartCore() {}

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
    return (empty);
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
        // wait until the tx fifo is not full --> called polling
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

// DISPLAY Methods
void UartCore::disp_str(const char* str) {
    while ((uint8_t) *str) {
        tx_byte((uint8_t) *str);
        str++;
    }
}

void UartCore::disp(char ch) {
    tx_byte((uint8_t) ch);
}

void UartCore::disp(const char* str) {
    disp_str(str);
}

void UartCore::disp(int n, int base, int len) {
    char buf[33]; // enough for 32 bits + null terminator
    char *str, ch, sign;
    int i, rem;
    unsigned int un;

    // error check
    if (base != 2 && base != 8 && base != 16)
        base = 10;
    if (len > 32) // error check
        len = 32;
    // handle -ive decimal
    if (base == 10 && n < 0) {
        un = (unsigned) -n;
        sign = '-';
    } else {
        un = (unsigned) n;
        sign = ' ';
    }
    // convert to string
    i = 0;
    str = &buf[33];
    *str = '\0';
    do {
        str--;
        rem = un % base;
        un = un / base;
        if (rem < 10)
            ch = (char) rem + '0';
        else
            ch = (char) rem - 10 + 'a';
        *str = ch;
        i++;
    } while (un);
    // attach - sign for neg decimal number
    if (sign == '-') {
        str--;
        *str = sign;
        i++;
    }
    // pad with blank if needed
    while (i < len) {
        str--;
        *str = ' ';
        i++;
    }
    // display the string
    disp_str(str);
}

void UartCore::disp(int n, int base) {
    disp(n, base, 0);
}

void UartCore::disp(int n) {
    disp(n, 10, 0);
}

void UartCore::disp(double f, int digit) {
    double fa, frac;
    int i, n, i_part;

    // obtain abs value of f
    fa = f;
    if (f < 0.0) {
        fa = -f;
        disp_str("-"); // display - sign for negative number
    }
    // obtain integer part
    i_part = (int) fa;
    disp(i_part); // display integer part
    disp_str("."); // display decimal point
    // obtain fractional part
    frac = fa - (double) i_part;
    // display fractional part
    for (n = 0; n < digit; n++) {
        frac = frac * 10.0;
        i = (int) frac;
        disp(i);
        frac = frac - i;
    }
}

void UartCore::disp(double f) {
    disp(f, 3);
}
