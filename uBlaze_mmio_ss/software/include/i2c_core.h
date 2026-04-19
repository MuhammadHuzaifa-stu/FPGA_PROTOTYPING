#ifndef _I2C_CORE_H_INCLUDED
#define _I2C_CORE_H_INCLUDED

#include "chu_init.h"

class I2cCore {
    enum {
        DVSR_REG = 0,
        WR_REG   = 4,
        RD_REG   = 8
    };
    // command to I2C controller
    enum {
        I2C_START_CMD   = 0x00 << 8,
        I2C_WR_CMD      = 0x01 << 8,
        I2C_RD_CMD      = 0x02 << 8,
        I2C_STOP_CMD    = 0x03 << 8,
        I2C_RESTART_CMD = 0x04 << 8
    };
public:
    I2cCore(uint32_t core_base_addr);
    ~I2cCore();
    void set_freq(int freq);
    int ready();
    void start();
    void restart();
    void stop();
    int write_byte(uint8_t data);
    uint8_t read_byte(int last);
    int read_transaction(uint8_t dev, uint8_t *bytes, int num, int repeat);
    int write_transaction(uint8_t dev, uint8_t *bytes, int num, int repeat);
private:
    uint32_t base_addr;
};
#endif /* _I2C_CORE_H_INCLUDED */