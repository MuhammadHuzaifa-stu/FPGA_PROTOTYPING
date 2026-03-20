#define _DEBUG

#include "chu_init.h"
#include "gpio_core.h"
#include "uart_core.h"
#include "timer_core.h"

void timer_check(GpoCore *led_p) {
    int i;

    for (i=0; i<5; i++) {
        led_p->write(0x003f);
        sleep_ms(500);
        led_p->write(0x0000);
        sleep_ms(500);
        debug("timer check - (loop #)/now: ", i, now_ms());
    }
}

void led_check(GpoCore *led_p, int n) {
    int i;

    for (i=0; i<n; i++) {
        led_p->write(1, i);
        sleep_ms(2000);
        led_p->write(0, i);
        sleep_ms(2000);
        debug("led check - (loop #)/now: ", i, now_ms());
    }
}

void sw_check(GpoCore *led_p, GpiCore *sw_p) {
    int i, s;

    s = sw_p->read();
    for (i=0; i<50; i++) {
        led_p->write(s);
        sleep_ms(200);
        led_p->write(0);
        sleep_ms(200);
        debug("sw check - (loop #)/now: ", i, now_ms());
    }
}

void uart_check() {
    static int loop = 0;

    uart.disp("uart test #");
    uart.disp(loop);
    uart.disp("\n\r");
    loop++;
}

// chasing LED
void chasing_led(GpoCore *led_p, GpiCore *sw_p, int n) {
    static int last_sleep_time = -1;
    int i, s;
    int sleep_time;

    s = sw_p->read();
    // switch_0: when 1 right most LED lit.
    // switch_1-switch_5: controls the speed of the LED lit.
    if      (s & 0x00000020) sleep_time = 1800;
    else if (s & 0x00000010) sleep_time = 1600;
    else if (s & 0x00000008) sleep_time = 1400;
    else if (s & 0x00000004) sleep_time = 1200;
    else if (s & 0x00000002) sleep_time = 1000;
    else                     sleep_time = 2000;

    // ONLY print if the speed actually changed
    if (sleep_time != last_sleep_time) {
        uart.disp("chasing led - speed changed to: ");
        uart.disp(sleep_time);
        uart.disp("ms\n\r");
        last_sleep_time = sleep_time; // Update the "memory"
    }

    if (s & 0x00000001) {
        led_p->write(0x0001);
    } else {
        for (i=0; i<n; i++) {
            led_p->write(1, i);
            if (i != n-1) sleep_ms(sleep_time);
            led_p->write(0, i);
            // sleep_ms(sleep_time);
            // debug("led check - (loop #)/now: ", i, now_ms());
        }
        for (i=n-1; i>=0; i--) {
            led_p->write(1, i);
            if (i != 0) sleep_ms(sleep_time);
            led_p->write(0, i);
            // sleep_ms(sleep_time);
            // debug("led check - (loop #)/now: ", i, now_ms());
        }

    }
}

// instantiate witch, led
GpoCore led(get_slot_addr(BRIDGE_BASE, S2_LED));
GpiCore sw(get_slot_addr(BRIDGE_BASE, S3_SW));

int main() {
    while(1) {
        // timer_check(&led);
        // led_check(&led, 6);
        // sw_check(&led, &sw);
        // uart_check();
        debug("Entring main loop - now: ms / us, ", now_ms(), now_us());
        chasing_led(&led, &sw, 6);
        // debug("main - switch value / up time : ", sw.read(), now_ms());
    }
}
