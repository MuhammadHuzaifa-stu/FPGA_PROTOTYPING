#include "gpio_core.h"
#include "chu_io_rw.h"
#include "chu_io_map.h"

GpoCore::GpoCore(uint32_t core_base_addr) {
    base_addr = core_base_addr;
    wr_data   = 0;
}

GpoCore::~GpoCore() {}

void GpoCore::write(uint32_t data) {
    wr_data = data;
    io_write(base_addr, DATA_REG, wr_data);
}

void GpoCore::write(int bit_value, int bit_pos) {
    bit_write(wr_data, bit_pos, bit_value);
    io_write(base_addr, DATA_REG, wr_data);
}

// GpiCore class implementation
GpiCore::GpiCore(uint32_t core_base_addr) {
    base_addr = core_base_addr;
}

GpiCore::~GpiCore() {}

uint32_t GpiCore::read() {
    return io_read(base_addr, DATA_REG);
}

int GpiCore::read(int bit_pos) {
    uint32_t rd_data = io_read(base_addr, DATA_REG);
    return (int bit_read(rd_data, bit_pos));
}

PwmCore::PwmCore(uint32_t core_base_addr) {
    base_addr = core_base_addr;
    set_freq(1000); // default frequency: 1 kHz 
}

PwmCore::~PwmCore() {}

void PwmCore::set_freq(int freq) {
    uint32_t dvsr;
    dvsr = (uint32_t) SYS_CLK_FREQ * 1000000 / MAX / freq; // divisor = clock / resolution / frequency
    io_write(base_addr, DVSR_REG, dvsr);
}

void PwmCore::set_duty(int duty, int channel) {
    uint32_t d;

    if (duty > MAX) {
        d = MAX;
    } else {
        d = duty;
    }
    io_write(base_addr, DUTY_REG_BASE + channel * 4, d); // ch * 4 ? -> word address
}

void PwmCore::set_duty(double f, int channel) {
    int duty;

    duty = (int) (f * MAX);

    set_duty(duty, channel);
}