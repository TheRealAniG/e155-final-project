
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

    while (1) {
        // Read ADC values from DMA buffer
        uint16_t x = adcValues[0];
        uint16_t y = adcValues[1];
        uint16_t throttle = adcValues[2];

        // Print ADC readings
        printf("X: %u | Y: %u | Throttle: %u\n",
               x, y, throttle);

        // Wait approximately 100 ms
        for (int i = 0; i < 100; i++) {
            delay_micros(TIM7, 1000);
        }
    }
}
