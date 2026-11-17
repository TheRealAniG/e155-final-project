// VehiclePhysics.c
// Source code for vehicle physics functions

#include "VehiclePhysics.h"
#include <math.h>

// Vehicle physics constants
#define MAX_SPEED       150.0f  // Maximum speed (pixels/s)
#define ACCELERATION    100.0f  // Acceleration (pixels/s^2)
#define BRAKE_DECEL     250.0f  // Braking deceleration (pixels/s^2)
#define DRAG_DECEL      40.0f   // Coasting deceleration (pixels/s^2)
#define TURN_RATE       2.5f    // Maximum turning rate (rad/s)

#define PI              3.14159265f

// Initialize vehicle state
void initVehiclePhysics(CarState *car, float startX, float startY, float startHeading) {
    car->x = startX;
    car->y = startY;
    car->speed = 0.0f;
    car->heading = startHeading;
}

// Update vehicle physics
void updateVehiclePhysics(CarState *car, const ControlInputs *inputs, float dt) {

    // Update heading based on joystick steering
    car->heading += inputs->steering * TURN_RATE * dt;

    // Keep heading between -PI and PI
    if (car->heading > PI) {
        car->heading -= 2.0f * PI;
    } else if (car->heading < -PI) {
        car->heading += 2.0f * PI;
    }

    // Update speed based on throttle and braking
    if (inputs->brakePressed) {
        car->speed -= BRAKE_DECEL * dt;
    } else if (inputs->throttle > 0.05f) {
        car->speed += inputs->throttle * ACCELERATION * dt;
    } else {
        car->speed -= DRAG_DECEL * dt;
    }

    // Limit speed between 0 and MAX_SPEED
    if (car->speed < 0.0f) {
        car->speed = 0.0f;
    } else if (car->speed > MAX_SPEED) {
        car->speed = MAX_SPEED;
    }

    // Update position based on speed and heading
    car->x += car->speed * cosf(car->heading) * dt;
    car->y += car->speed * sinf(car->heading) * dt;
}
