class TimerCore {
    // register map
    enum {
        COUNTER_LOWER_REG = 0,  // lower 32-bits of counter
        COUNTER_UPPER_REG = 1,  // upper 32-bits of counter
        CTRL_REG          = 2   // control register
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