// InputProcessing.c
// Source code for Input Processing functions

#include "InputProcessing.h"

#define JOYSTICK_X_MIN 0.0f
#define JOYSTICK_X_MAX 4080.0f
#define JOYSTICK_Y_MIN 0.0f
#define JOYSTICK_Y_MAX 4073.0f

#define JOYSTICK_DEADZONE 0.05f

#define THROTTLE_MIN 475.0f
#define THROTTLE_MAX 3533.0f

// Limit a value to a specified range
static float limitRange(float value, float min, float max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

// Normalize joystick readings from -1.0 to +1.0
static float normalizeJoystick(uint16_t rawValue, float min, float max) {
    float normalized = 2.0f * ((float)rawValue - min) / (max - min) - 1.0f;

    normalized = limitRange(normalized, -1.0f, 1.0f);

    // Ignore small movements near the center
    if (normalized > -JOYSTICK_DEADZONE && normalized < JOYSTICK_DEADZONE) {
        return 0.0f;
    }

    return normalized;
}

// Normalize throttle readings from 0.0 to 1.0
static float normalizeThrottle(uint16_t rawValue) {
    float normalized = ((float)rawValue - THROTTLE_MIN) / (THROTTLE_MAX - THROTTLE_MIN);

    return limitRange(normalized, 0.0f, 1.0f);
}

// Process sensor inputs
ControlInputs processInputs(uint16_t rawX, uint16_t rawY, uint16_t rawThrottle, bool brakePressed) {

    ControlInputs inputs;

    inputs.steering = normalizeJoystick(rawX, JOYSTICK_X_MIN, JOYSTICK_X_MAX);
    inputs.joystickY = normalizeJoystick(rawY, JOYSTICK_Y_MIN, JOYSTICK_Y_MAX);
    inputs.throttle = normalizeThrottle(rawThrottle);
    inputs.brakePressed = brakePressed;

    return inputs;
}
