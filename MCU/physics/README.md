# Desktop physics milestone

Reuses the extracted starter. `car_physics.c` and `.h` are portable C;
`demo.c` and `test_physics.c` each have a desktop-only main. The SEGGER
project explicitly lists its separate `main.c`; do not add either desktop
entry point to that project. No ADC or FPGA files are changed.

From the repository root in Windows PowerShell, using the installed MSYS2
UCRT64 GCC (if GCC is absent from PATH, replace `gcc` with
`& 'C:\msys64\ucrt64\bin\gcc.exe'`):

```powershell
Set-Location MCU/physics
gcc -std=c11 -Wall -Wextra -Werror -pedantic -O2 car_physics.c demo.c -o demo.exe -lm
gcc -std=c11 -Wall -Wextra -Werror -pedantic -O2 car_physics.c test_physics.c -o test_physics.exe -lm
.\test_physics.exe
.\demo.exe
(Get-Content poses.txt).Count
```

The final command should print 180. Run from this directory so `poses.txt`
lands here. The demo overwrites this generated file on each run.

```text
scripted input -> 100 Hz rear-axle bicycle model -> center/Q8 conversion
                                                    |
                                              60 Hz poses.txt
```

State is floating-point rear-axle x/y in pixels, speed in pixels/second,
and heading in radians. East is zero; positive heading is clockwise because
screen y increases down. Inputs are clamped to steering [-1,1], throttle [0,1].
For each fixed dt=0.01 seconds:

```text
acceleration = drive * throttle - drag * speed
next_speed = max(0, speed + acceleration * dt)
distance = (speed + next_speed) / 2 * dt
turn = distance * tan(steering * steering_limit) / wheelbase
rear_x += distance * cos(heading + turn/2)
rear_y += distance * sin(heading + turn/2)
heading = wrap(heading + turn)
speed = next_speed
```

This uses midpoint heading for the translation. A stopped car with no throttle
has zero distance and turn, regardless of steering. For display, assume the
sprite center lies halfway between axles: add `(wheelbase/2) * (cos, sin)` to
the rear position. Only the exported pose is rounded, using `lroundf`;
rotation coefficients are `round(256*cos(heading))`, `round(256*sin(heading))`.
The model has no lateral slip or collision response.

Tune wheelbase, steering limit, acceleration, and linear drag in
`car_physics.h`. The retained surface argument supports the starter's grass
coefficients, but this demo always uses asphalt; there is no surface detection.

The track in `FPGA/rtl/race_scene.sv` is the outer rectangle [48,592) x
[48,432) minus the infield [144,496) x [144,336). Start rear (306,96),
heading 0, speed 0, hence sprite center (316,96). Full throttle runs from
0 to 2.5 s. Steering is zero until 2 s, +0.85 from 2 to 2.5 s, then zero
while coasting until 3 s. No position or heading is scripted.

For a second run change `DEMO_TURN_STEERING` in `demo.c` from `0.85f` to
`0.80f`, then rebuild and run. This produces a wider right turn.

The simulation completes 300 physics updates. Frame n samples the latest
completed tick at floor(n*100/60), with no interpolation. Thus the 180
headerless rows cover nominal frame times 0 through 179/60 seconds; the
printed 3.0 s state is beyond the last exported frame. Sampling age is less
than 10 ms. Each row is `center_x center_y cos_q8 sin_q8`.

Verified with GCC on Windows: zero steering keeps y=96 exactly when heading
east, steering at rest preserves pose, positive steering increases y and
heading, and east-facing pose conversion gives (316,96,256,0).
Default run samples:

| Time (s) | Center (px) | Speed (px/s) |
|---|---|---|
| 0.0 | (316,96) | 0.0 |
| 2.0 | (521,96) | 155.9 |
| 2.5 | (560,158) | 165.4 |
| 3.0 | (557,223) | 100.1 |

The output was checked for 180 rows of four integers. FPGA simulation,
firmware integration, and live input remain later milestones.
