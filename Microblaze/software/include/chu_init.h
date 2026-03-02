// library
#include "chu_io_rw.h"
#include "chu_io_map.h"
#include "timer_core.h"
#include "uart_core.h"

// mask uart visible by other code
extern UartCore uart;

// define timer and uart slots
#define TIMER_SLOT S0_SYS_TIMER // slot 0
#define UART_SLOT  S1_UART1     // slot 1

// timing functions
unsigned long long now_us();
unsigned long long now_ms();
void sleep_us(unsigned long int t);
void sleep_ms(unsigned long int t);

// define debug function
void debug_off();
void debug_on(const char* str, int n1, int n2);

#ifndef _DEBUG
#define debug(str, n1, n2) debug_off()
#endif

#ifdef _DEBUG
#define debug(str, n1, n2) debug_on(str, n1, n2)
#endif

// low level bit-manipulation macros
#define bit_set(data, n) ((data) |= (1UL << (n)))
#define bit_clear(data, n) ((data) &= ~(1UL << (n)))
#define bit_toggle(data, n) ((data) ^= (1UL << (n)))
#define bit_read(data, n) (((data) >> (n)) & 0x01)
#define bit_write(data, n, bitvalue) \\
    (bitvalue ? bit_set(data, n) : bit_clear(data, n))
#define bit(n) (1UL << (n))

#endif