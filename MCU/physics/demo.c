#include "car_physics.h"
#include <stdio.h>

/* Desktop only. Do not add this file to the STM32 project. */
#define DEMO_TURN_STEERING 0.85f

static void step_script(CarState *car, int tick)
{
    DriverInput input = {
        .steering = tick >= 200 && tick < 250 ? DEMO_TURN_STEERING : 0,
        .throttle = tick < 250 ? 1 : 0
    };
    car_step(car, input, ASPHALT, CAR_DT_SECONDS);
}

int main(void)
{
    CarState car = {.rear_x = 306, .rear_y = 96};
    FILE *poses = fopen("poses.txt", "w");
    if (!poses) { perror("poses.txt"); return 1; }

    // Export at 60 Hz using the most recent completed 100 Hz physics step.
    int tick = 0;
    for (int frame = 0; frame < 180; ++frame) {
        while (tick < frame * 100 / 60) {
            step_script(&car, tick);
            ++tick;
        }
        CarPose pose = car_pose(&car);
        if (fprintf(poses, "%d %d %d %d\n", pose.center_x, pose.center_y,
                    pose.cos_q8, pose.sin_q8) < 0) {
            perror("write poses.txt");
            fclose(poses);
            return 1;
        }
        if (frame % 30 == 0)
            printf("%.1f s: center (%d, %d), speed %.1f px/s\n",
                   frame / 60.0, pose.center_x, pose.center_y, car.speed);
    }
    /* Finish all 300 updates; exported frames cover [0, 3) seconds. */
    while (tick < 300) step_script(&car, tick++);
    CarPose pose = car_pose(&car);
    printf("3.0 s: center (%d, %d), rear (%.2f, %.2f), speed %.1f px/s, heading %.3f rad\n",
           pose.center_x, pose.center_y, car.rear_x, car.rear_y,
           car.speed, car.heading);
    if (fclose(poses) != 0) { perror("close poses.txt"); return 1; }
    puts("Wrote 180 frames to poses.txt (60 Hz, latest completed 10 ms step).");
    return 0;
}
