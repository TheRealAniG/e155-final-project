// InputProcessing.h
// Header for Input Processing functions

#ifndef INPUT_PROCESSING_H
#define INPUT_PROCESSING_H

#include <stdint.h>
#include <stdbool.h>

// Normalized controller inputs
typedef struct {
    float steering;       // -1.0 (left) to 1.0 (right)
    float joystickY;      // -1.0 to 1.0
    float throttle;       // 0.0 to 1.0
    bool brakePressed;    // True when brake button is pressed
} ControlInputs;

// Convert raw ADC and GPIO readings into normalized inputs
ControlInputs processInputs(uint16_t rawX, uint16_t rawY, uint16_t rawThrottle, bool brakePressed);

#endif
