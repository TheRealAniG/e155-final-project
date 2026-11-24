#include <stdio.h>
#include "STM32L432KC.h"
#include "InputProcessing.h"
#include "VehiclePhysics.h"
#include <math.h>


#define BRAKE_PIN PA10
#define PHYSICS_DT 0.001f
#define PI 3.14159265f


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

    // Initialize brake button
    gpioEnable(GPIO_PORT_A);
    pinMode(BRAKE_PIN, GPIO_INPUT);
    pinResistor(BRAKE_PIN, GPIO_PULL_UP);

    // Initialize ADC, DMA, and timer
    initADC();
    initDMA();
    initTIM6ADC();
    initSPI(4, 0, 0);

    // Initialize vehicle at (96, 96), facing right
    CarState car;
    initVehiclePhysics(&car, 96.0f, 96.0f, 0.0f);

    // Start ADC sampling
    startADC();
    startTIM6ADC();

    // Allow initial ADC readings to become available
    delay_micros(TIM7, 10000);

    int updateCount = 0;

    while (1) {

        // Run physics once per TIM6 update
        if (tim6UpdateReady()) {

            // Read brake button (active LOW)
            bool brakePressed = (digitalRead(BRAKE_PIN) == 0);

            // Process ADC and GPIO inputs
            ControlInputs inputs = processInputs(
                adcValues[0],
                adcValues[1],
                adcValues[2],
                brakePressed
            );

            // Update vehicle physics
            updateVehiclePhysics(&car, &inputs, PHYSICS_DT);

            updateCount++;

            // Print every 100 physics updates
            
            if (updateCount >= 100) {
                updateCount = 0;

                float headingDegrees = car.heading * 180.0f / PI;

                printf("X: %d | Y: %d | Heading: %d deg | Speed: %d\n",
                       (int)car.x,
                       (int)car.y,
                       (int)headingDegrees,
                       (int)car.speed);

                // SPI test transmission


                // Send test vehicle state over SPI
                spiSendCarState(
                    (int16_t)car.x,
                    (int16_t)car.y,
                    (int16_t)(cosf(car.heading) * 256.0f),
                    (int16_t)(sinf(car.heading) * 256.0f)
                );
            }
        }
    }
}
