#include "car_physics.h"
#include <math.h>

static const float wheelbase = CAR_WHEELBASE;

void car_step(CarState *car, DriverInput input, Surface surface, float dt)
{
    float throttle = fminf(1, fmaxf(0, input.throttle));
    float steering = fminf(1, fmaxf(-1, input.steering));
    float drive = surface == GRASS ? 0.5f * CAR_ACCELERATION : CAR_ACCELERATION;
    float drag = surface == GRASS ? 2.0f * CAR_DRAG : CAR_DRAG;
    float acceleration = drive * throttle - drag * car->speed;
    float next_speed = fmaxf(0, car->speed + acceleration * dt);
    float distance = 0.5f * (car->speed + next_speed) * dt;
    float turn = distance * tanf(steering * CAR_STEERING_LIMIT_RAD) / wheelbase;
    float mid_heading = car->heading + 0.5f * turn;
    car->rear_x += distance * cosf(mid_heading);
    car->rear_y += distance * sinf(mid_heading);
    car->heading = remainderf(car->heading + turn, 6.28318530718f);
    car->speed = next_speed;
}

CarPose car_pose(const CarState *car)
{
    float c = cosf(car->heading);
    float s = sinf(car->heading);
    return (CarPose){
        (int)lroundf(car->rear_x + 0.5f * wheelbase * c),
        (int)lroundf(car->rear_y + 0.5f * wheelbase * s),
        (int)lroundf(256 * c), (int)lroundf(256 * s)
    };
}
