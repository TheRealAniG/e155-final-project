// VehiclePhysics.h
// Header for vehicle physics functions

#ifndef VEHICLE_PHYSICS_H
#define VEHICLE_PHYSICS_H

#include "InputProcessing.h"

// Current vehicle state
typedef struct {
    float x;          // Horizontal position (pixels)
    float y;          // Vertical position (pixels)
    float speed;      // Forward speed (pixels/second)
    float heading;    // Vehicle orientation (radians)
} CarState;

// Initialize vehicle position and orientation
void initVehiclePhysics(CarState *car, float startX, float startY, float startHeading);

// Update vehicle position, speed, and heading
void updateVehiclePhysics(CarState *car, const ControlInputs *inputs, float dt);

#endif
