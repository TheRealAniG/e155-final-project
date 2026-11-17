// InputProcessing.c
// Source code for input processing functions

#include "InputProcessing.h"

#define JOYSTICK_CENTER   2048.0f
#define JOYSTICK_DEADZONE 0.05f
#define ADC_MAX           4095.0f

// Normalize joystick readings to approximately -1.0 to +1.0
static float normalizeJoystick(uint16_t rawValue) {
    float normalized = ((float)rawValue - JOYSTICK_CENTER) / JOYSTICK_CENTER;

    // Ignore small movements near the center
    if (normalized > -JOYSTICK_DEADZONE && normalized < JOYSTICK_DEADZONE) {
        return 0.0f;
    }

    return normalized;
}

// Normalize throttle readings from 0.0 to 1.0
static float normalizeThrottle(uint16_t rawValue) {
    return (float)rawValue / ADC_MAX;
}

// Process sensor inputs
ControlInputs processInputs(uint16_t rawX, uint16_t rawY, uint16_t rawThrottle, bool brakePressed) {

    ControlInputs inputs;

    inputs.steering = normalizeJoystick(rawX);
    inputs.joystickY = normalizeJoystick(rawY);
    inputs.throttle = normalizeThrottle(rawThrottle);
    inputs.brakePressed = brakePressed;

    return inputs;
}
