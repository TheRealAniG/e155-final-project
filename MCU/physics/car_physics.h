#ifndef CAR_PHYSICS_H
#define CAR_PHYSICS_H

/* Screen-space units: pixels, seconds, radians. Tune these for both builds. */
#define CAR_DT_SECONDS 0.01f
#define CAR_WHEELBASE 20.0f
#define CAR_STEERING_LIMIT_RAD 0.45f
#define CAR_ACCELERATION 180.0f
#define CAR_DRAG 1.0f

typedef struct {
    float rear_x, rear_y;  // pixels, measured at rear axle
    float heading;        // radians clockwise from screen right
    float speed;          // pixels per second
} CarState;

typedef struct {
    float steering;       // -1 left to +1 right
    float throttle;       // 0 to 1
} DriverInput;

typedef enum { ASPHALT, GRASS } Surface;

typedef struct {
    int center_x, center_y;
    int cos_q8, sin_q8;
} CarPose;

void car_step(CarState *car, DriverInput input, Surface surface, float dt);
CarPose car_pose(const CarState *car);
#endif
