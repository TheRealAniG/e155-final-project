
#include <stdio.h>
#include "STM32L432KC.h"

// Redirect printf output to debug terminal
int _write(int file, char *ptr, int len) {
    for (int i = 0; i < len; i++) {
        ITM_SendChar(*ptr++);
    }
    return len;
}

int main(void) {
    // Configure system clock
    configureFlash();
    configureClock();

    // Initialize peripherals
    initADC();
    initDMA();
    initTIM6ADC();

    // Start ADC sampling
    startADC();
    startTIM6ADC();

    // Allow ADC/DMA to collect initial readings
    delay_micros(TIM7, 10000);

    // Initialize min and max with the first reading
    uint16_t throttleMin = adcValues[2];
    uint16_t throttleMax = adcValues[2];

    while (1) {
        // Collect approximately 100 ms of readings
        for (int i = 0; i < 100; i++) {
            uint16_t throttle = adcValues[2];

            // Ignore unexpected zero readings
            if (throttle != 0) {
                if (throttle < throttleMin) {
                    throttleMin = throttle;
                }

                if (throttle > throttleMax) {
                    throttleMax = throttle;
                }
            }

            delay_micros(TIM7, 1000);
        }

        // Print current throttle and recorded extremes
        printf("Throttle: %u | Min: %u | Max: %u\n",
               adcValues[2], throttleMin, throttleMax);
    }
}