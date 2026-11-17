#include <stdio.h>
#include "STM32L432KC.h"
#include "InputProcessing.h"
#include "VehiclePhysics.h"

#define BRAKE_PIN PA0
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

                // Convert heading from radians to degrees
                float headingDegrees = car.heading * 180.0f / PI;

                printf("X: %d | Y: %d | Heading: %d deg\n",
                       (int)car.x,
                       (int)car.y,
                       (int)headingDegrees);
            }
        }
    }
}
