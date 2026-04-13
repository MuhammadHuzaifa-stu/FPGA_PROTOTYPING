#ifndef _SPI_CORE_H_INCLUDED
#define _SPI_CORE_H_INCLUDED

#include "chu_init.h"

class SpiCore {
public:
    enum {
        RD_DATA_REG    = 0,
        SS_REG         = 4,
        WRITE_DATA_REG = 8,
        CTRL_REG       = 12
    };
    enum {
        READY_FIELD   = 0x0100,
        RX_DATA_FIELD = 0x00FF
    };
    SpiCore(uint32_t core_base_addr) ;
    ~SpiCore();
    int ready();
    void set_freq(int freq);
    void set_mode(int icpol, int icpha);;
    void write_ss_n(uint32_t data);
    void write_ss_n(int bit_val, int bit_pos);
    void assert_ss(int n);
    void deassert_ss(int n);
    uint8_t transfer(uint8_t wr_data);
private:
    uint32_t base_addr;
    uint32_t ss_n_data;
    uint16_t dvsr;
    int cpol;
    int cpha;
};

#endif /* _SPI_CORE_H_INCLUDED */