// STM32L432KC_ADC.h
// Header for ADC functions

#ifndef STM32L4_ADC_H
#define STM32L4_ADC_H

#include <stdint.h>
#include <stm32l432xx.h>
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_TIM.h"
#include "STM32L432KC_RCC.h"

///////////////////////////////////////////////////////////////////////////////
// Definitions
///////////////////////////////////////////////////////////////////////////////

// Analog input pins
#define JOYSTICK_X_PIN      PB0
#define JOYSTICK_Y_PIN      PB1
#define THROTTLE_PIN        PA5

// Corresponding ADC1 channels
#define JOYSTICK_X_CHANNEL  15
#define JOYSTICK_Y_CHANNEL  16
#define THROTTLE_CHANNEL    10

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

// Initialize ADC1 for 12-bit analog-to-digital conversion
void initADC(void);

// Arm ADC1 for timer-triggered conversions
void startADC(void);

#endif