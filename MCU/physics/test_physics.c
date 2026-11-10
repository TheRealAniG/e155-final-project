#include "car_physics.h"
#include <math.h>
#include <stdio.h>

#define CHECK(condition) do { if (!(condition)) { \
    fprintf(stderr, "FAIL line %d: %s\n", __LINE__, #condition); return 1; \
} } while (0)

int main(void)
{
    CarState east = {306, 96, 0, 0};
    for (int i = 0; i < 300; ++i)
        car_step(&east, (DriverInput){0, 1}, ASPHALT, CAR_DT_SECONDS);
    CHECK(east.rear_x > 306 && east.rear_y == 96 && east.heading == 0);

    CarState rest = {306, 96, 0.7f, 0};
    for (int i = 0; i < 300; ++i)
        car_step(&rest, (DriverInput){1, 0}, ASPHALT, CAR_DT_SECONDS);
    CHECK(rest.rear_x == 306 && rest.rear_y == 96);
    CHECK(fabsf(rest.heading - 0.7f) < 1e-6f && rest.speed == 0);

    CarState right = {306, 96, 0, 60};
    for (int i = 0; i < 50; ++i)
        car_step(&right, (DriverInput){0.85f, 0}, ASPHALT, CAR_DT_SECONDS);
    CHECK(right.rear_y > 96 && right.heading > 0);
    CarPose pose = car_pose(&(CarState){306, 96, 0, 0});
    CHECK(pose.center_x == 316 && pose.center_y == 96);
    CHECK(pose.cos_q8 == 256 && pose.sin_q8 == 0);
    puts("PASS: east straight, steering at rest, clockwise right turn, pose conversion");
    return 0;
}
