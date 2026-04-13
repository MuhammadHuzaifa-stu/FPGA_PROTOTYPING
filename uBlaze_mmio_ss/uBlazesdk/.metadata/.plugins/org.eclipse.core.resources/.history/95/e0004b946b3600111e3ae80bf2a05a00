#include "chu_init.h"
#include "chu_io_rw.h"
#include "chu_io_map.h"

class GpoCore {
    // register map
    enum {
        DATA_REG = 0 // data register
    };
public:
    GpoCore(uint32_t core_base_addr);       // constructor
    ~GpoCore();                             // destructor; not used
    // methods
    void write(uint32_t data);              // write a 32-bit word
    void write(int bit_value, int bit_pos); // write 1-bit
private:
    uint32_t base_addr;
    uint32_t wr_data;                       //same as GPO core data reg 
};

class GpiCore {
    // register map
    enum {
        DATA_REG = 0 // data register
    };
public:
    GpiCore(uint32_t core_base_addr);       // constructor
    ~GpiCore();                             // destructor; not used 
    // methods
    uint32_t read();                        // read a 32-bit word
    int read(int bit_pos);                  // read 1-bit
private:
    uint32_t base_addr;
};

class PwmCore {
    // register map
    enum {
        DVSR_REG      = 0x00; // word address
        DUTY_REG_BASE = 0x40; // word address
    };
    enum {
        RESOLUTION_BITS = 10;
        MAX             = 1 << RESOLUTION_BITS;
    };
public:
    PwmCore(uint32_t core_base_addr);       // constructor
    ~PwmCore();                             // destructor; not used
    // methods
    void set_freq(int freq);              ;
    void set_duty(int duty, int channel);      // duty: 0 ~ 1023; ch: 0 ~ 8
    void set_duty(double f, int channel);     // f: 0.0 ~ 1.0; ch: 0 ~ 8
private:
    uint32_t base_addr;
};