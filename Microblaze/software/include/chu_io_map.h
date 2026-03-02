#ifndef _CHU_IO_MAP_INCLUDED
#define _CHU_IO_MAP_INCLUDED

#ifdef __cpluslpus
extern "C" {
#endif

#define SYS_CLK_FREQ 100

// bridge base address
#define BRIDGE_BASE 0xc0000000

// slot definitation
#define S0_SYS_TIMER 0
#define S1_UART1     1
#define S2_LED       2
#define S3_SW        3

#ifdef __cpluslpus
}
#endif

#endif // _CHU_IO_MAP_INCLUDED