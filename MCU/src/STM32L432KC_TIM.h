// STM32F401RE_TIM.h
// Header for TIM functions

#ifndef STM32L4_TIM_H
#define STM32L4_TIM_H

#include <stdint.h> // Include stdint header
#include <stm32l432xx.h>  // CMSIS device library include
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_RCC.h"


///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void initTIM(TIM_TypeDef * TIMx);

void delay_micros(TIM_TypeDef * TIMx, uint32_t us);

// Initialize TIM6 to trigger ADC1 at 1 kHz
void initTIM6ADC(void);

#endif