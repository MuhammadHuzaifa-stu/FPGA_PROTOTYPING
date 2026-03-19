#ifndef _TIMER_CORE_H_INCLUDED
#define _TIMER_CORE_H_INCLUDED

#include "chu_io_rw.h"
#include "chu_io_map.h"

class TimerCore {
    // register map
    enum {
        COUNTER_LOWER_REG = 0,  // lower 32-bits of counter --> word address
        COUNTER_UPPER_REG = 4,  // upper 32-bits of counter --> word address
        CTRL_REG          = 8   // control register         --> word address
    };
    // masks
    enum {
        GO_FIELD  = 0x00000001, // bit-0 of control register; enable
        CLR_FIELD = 0x00000002  // bit-1 of control register; clear
    };
public:
    TimerCore(uint32_t core_base_addr);
    ~TimerCore();
    // methods
    void pause();               // pause counter
    void go();                  // resume counter
    void clear();               // clear counter to 0
    uint64_t read_tick();       // read current tick count
    uint64_t read_time();       // read current time in microseconds
    void sleep(uint64_t us);    // sleep for specified microseconds
private:
    uint32_t base_addr;
    uint32_t ctrl;              // current state of control register
};

#endif
