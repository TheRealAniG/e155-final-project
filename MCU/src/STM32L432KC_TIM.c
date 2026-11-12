// STM32F401RE_TIM.c
// TIM functions

#include "STM32L432KC_TIM.h"

void initTIM(TIM_TypeDef * TIMx){
  // Set prescaler to give 1 us time base
  uint32_t psc_div = (uint32_t) ((SystemCoreClock/1e6));

  // Set prescaler division factor
  TIMx->PSC = (psc_div - 1);
  // Generate an update event to update prescaler value
  TIMx->EGR |= 1;
  // Enable counter
  TIMx->CR1 |= 1; // Set CEN = 1
}

void delay_micros(TIM_TypeDef * TIMx, uint32_t us){
  if (us == 0) return;

  TIMx->ARR = us - 1;// Set timer max count
  TIMx->EGR |= 1;     // Force update
  TIMx->SR &= ~(0x1); // Clear UIF
  TIMx->CNT = 0;      // Reset count

  while(!(TIMx->SR & 1)); // Wait for UIF to go high
}

void initTIM6ADC(void){
    // Enable TIM6 peripheral clock
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM6EN;

    // Disable TIM6 during configuration
    TIM6->CR1 &= ~TIM_CR1_CEN;

    // Set prescaler for 1 us timer ticks (80 MHz / 80 = 1 MHz)
    TIM6->PSC = 79;

    // Set auto-reload for 1 ms period (1000 ticks)
    TIM6->ARR = 999;

    // Select update event as trigger output (TRGO)
    TIM6->CR2 &= ~TIM_CR2_MMS;
    TIM6->CR2 |= (0b010 << TIM_CR2_MMS_Pos);

    // Generate update event to load prescaler
    TIM6->EGR |= TIM_EGR_UG;

    // Clear update interrupt flag
    TIM6->SR &= ~TIM_SR_UIF;
}

void startTIM6ADC(void){
    // Start TIM6 to generate ADC triggers
    TIM6->CR1 |= TIM_CR1_CEN;
}