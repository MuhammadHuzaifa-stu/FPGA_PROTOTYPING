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
    static int16_t last_sleep_time = -1;   // to check the previous state of the speed control switches
    static uint8_t               i =  0;
    static bool            forward = true; // direction of the chase (true for right, false for left)

    int s;
    int sleep_time;

    int8_t up;
    int8_t dwn;

    s = sw_p->read();
    // switch_0: when 1 right most LED lit.
    // switch_1-switch_5: controls the speed of the LED lit.
    sleep_time = 1000 + ((s & 0x03E) << 4);

    // ONLY print if the speed actually changed
    if (sleep_time != last_sleep_time) {
        uart.disp("chasing led - speed changed to: ");
        uart.disp(sleep_time);
        uart.disp("ms\n\r");
        last_sleep_time = sleep_time; // Update the "memory"
    }

    if (s & 0x01) {
        led_p->write(0x01);
        i = 0;
    } else {
        up  = i + 1;
        dwn = i - 1;

        // 1. Turn ON current LED
        led_p->write(1, i);
        sleep_ms(sleep_time);
        
        // 2. Turn OFF current LED before moving
        led_p->write(0, i);

        // 3. Update index and direction
        if (forward) {
            if (i >= n - 1) {
                forward = false;
                i = dwn;
            } 
            else i = up;
        } else {
            if (i <= 0) {
                forward = true;
                i = up;
            }
            else i = dwn;
        }
    }
}

// collision LED
void collision_led(GpoCore *led_p, GpiCore *sw_p) {
    // Static variables stay in memory between function calls
    static int8_t pos1 = 0, pos2 = 5;       // Positions (0 to 5)
    static int8_t dir1 = 1, dir2 = -1;      // Directions (1 is right, -1 is left)

    static uint64_t last_tick1 = 0;         // Last time LED 1 moved
    static uint64_t last_tick2 = 0;         // Last time LED 2 moved

    int        s = sw_p->read();
    uint64_t now = now_ms();                // Get current system time

    // 1. Initialization (Switches 0 and 1)
    if (s & 0x01) { // SW0: Reset LED 1 to rightmost
        pos1 = 0; 
        dir1 =  1; 
    }
    if (s & 0x02) { // SW1: Reset LED 2 to leftmost
        pos2 = 5; 
        dir2 = -1; 
    }

    // 2. Speed Calculation (Independent)
    uint16_t speed1 = 1000 + ((s & 0x003C) << 4);   // low: 1000 -> High: 1000 + 60 x 16 = 1960
    uint16_t speed2 = 1000 + (s & 0x03C0);          // low: 1000 -> High: 1000 + 60 x 16 = 1960

    // 3. Independent LED 1 Logic
    if (now - last_tick1 > speed1) {
        int8_t next1 = pos1 + dir1;
        
        if (next1 < 0 || next1 > 5) {
            dir1 = -dir1;
        } else {
            pos1 = next1;
        }
        last_tick1 = now;
    }

    // 4. Independent LED 2 Logic
    if (now - last_tick2 > speed2) {
        int8_t next2 = pos2 + dir2;
        // Collision or Boundary check
        if (next2 < 0 || next2 > 5) {
            dir2 = -dir2;
        } else {
            pos2 = next2;
        }
        last_tick2 = now;
    }

    // 5. Update Hardware (Write both bits to the 6 LEDs)
    // We create a bitmask: (1 shifted to pos1) ORed with (1 shifted to pos2)
    led_p->write((1 << pos2) | (1 << pos1));
}

// instantiate witch, led
GpoCore led(get_slot_addr(BRIDGE_BASE, S2_LED));
GpiCore sw(get_slot_addr(BRIDGE_BASE, S3_SW));

int main() {
    while(1) {
        timer_check(&led);
        led_check(&led, 6);
        sw_check(&led, &sw);
        uart_check();
        debug("main - switch value / up time : ", sw.read(), now_ms());

        // >>>>>>>>>> CHASING LED TEST <<<<<<<<<<
        // chasing_led(&led, &sw, 6);
        // >>>>>>>>>> COLLISION LED TEST <<<<<<<<<<
        // collision_led(&led, &sw, 6);

    }
}
