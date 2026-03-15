#ifndef _UART_CORE_H_INCLUDED
#define _UART_CORE_H_INCLUDED

#include "chu_io_rw.h"
#include "chu_io_map.h"

class UartCore {
    // register map
    enum {
        RD_DATA_REG    = 0, // --> word address
        DVSR_REG       = 4, // --> word address
        WR_DATA_REG    = 8, // --> word address
        RM_RD_DATA_REG = 12 // --> word address
    };
    // masks
    enum {
        TX_FULL_FIELD = 0x00000200,
        RX_EMPT_FIELD = 0x00000100,
        RX_DATA_FIELD = 0x000000ff
    };
public:
    UartCore(uint32_t core_base_addr);
    // methods
    ~UartCore();
    // basic I/O access
    void set_baud_rate(int baud);
    int rx_fifo_empty();
    int tx_fifo_full();
    void tx_byte(uint8_t byte);
    int rx_byte();
    // display methids --> overloaded
    void disp(char ch);
    void disp(const char *str);
    void disp(int n, int base, int len);
    void disp(int n, int base);
    void disp(int n);
    void disp(double f, int digit);
    void disp(double f);
private:
    uint32_t base_addr;
    int baud_rate;
    void disp_str(const char *str);
};

#endif // _UART_CORE_H_INCLUDED
