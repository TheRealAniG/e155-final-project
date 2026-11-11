// STM32L432KC_ADC.c
// Source code for ADC functions


#include "STM32L432KC_ADC.h"


void initADC(void){
    // Enable Port
    gpioEnable(GPIO_PORT_A);
    gpioEnable(GPIO_PORT_B);

    // Configure analog input pins
    pinMode(JOYSTICK_X_PIN, GPIO_ANALOG);
    pinMode(JOYSTICK_Y_PIN, GPIO_ANALOG);
    pinMode(THROTTLE_PIN, GPIO_ANALOG);

    // Enable ADC peripheral clock
    RCC->AHB2ENR |= RCC_AHB2ENR_ADCEN;

    // Configure ADC clock to HCLK / 4 (20 MHz)
    ADC1_COMMON->CCR &= ~ADC_CCR_CKMODE;
    ADC1_COMMON->CCR |= (0b11 << ADC_CCR_CKMODE_Pos);

    // Enable TIM7 clock and initialize timer
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM7EN;
    initTIM(TIM7);

    // Exit ADC deep-power-down mode
    ADC1->CR &= ~ADC_CR_DEEPPWD;

    // Enable ADC voltage regulator
    ADC1->CR |= ADC_CR_ADVREGEN;

    // Wait for ADC voltage regulator to stabilize
    delay_micros(TIM7, 30);

    // Select single-ended calibration
    ADC1->CR &= ~ADC_CR_ADCALDIF;

    // Start ADC calibration
    ADC1->CR |= ADC_CR_ADCAL;

    // Wait for calibration to complete
    while (ADC1->CR & ADC_CR_ADCAL);

    // Wait at least 4 ADC clock cycles after calibration
    delay_micros(TIM7, 2);

    // Clear ADC ready flag
    ADC1->ISR = ADC_ISR_ADRDY;

    // Enable ADC
    ADC1->CR |= ADC_CR_ADEN;

    // Wait for ADC to be ready
    while (!(ADC1->ISR & ADC_ISR_ADRDY));

    // Configure ADC for 12-bit resolution
    ADC1->CFGR &= ~ADC_CFGR_RES;

    // Joystick X: PB0, ADC channel 15
    ADC1->SMPR2 &= ~ADC_SMPR2_SMP15;
    ADC1->SMPR2 |= (0b110 << ADC_SMPR2_SMP15_Pos);

    // Joystick Y: PB1, ADC channel 16
    ADC1->SMPR2 &= ~ADC_SMPR2_SMP16;
    ADC1->SMPR2 |= (0b110 << ADC_SMPR2_SMP16_Pos);

    // Throttle: PA5, ADC channel 10
    ADC1->SMPR2 &= ~ADC_SMPR2_SMP10;
    ADC1->SMPR2 |= (0b110 << ADC_SMPR2_SMP10_Pos);

    // Configure sequence length for 3 conversions
    ADC1->SQR1 &= ~ADC_SQR1_L;
    ADC1->SQR1 |= (0b0010 << ADC_SQR1_L_Pos);

    // First conversion: Joystick X (channel 15)
    ADC1->SQR1 &= ~ADC_SQR1_SQ1;
    ADC1->SQR1 |= (JOYSTICK_X_CHANNEL << ADC_SQR1_SQ1_Pos);

    // Second conversion: Joystick Y (channel 16)
    ADC1->SQR1 &= ~ADC_SQR1_SQ2;
    ADC1->SQR1 |= (JOYSTICK_Y_CHANNEL << ADC_SQR1_SQ2_Pos);

    // Third conversion: Throttle (channel 10)
    ADC1->SQR1 &= ~ADC_SQR1_SQ3;
    ADC1->SQR1 |= (THROTTLE_CHANNEL << ADC_SQR1_SQ3_Pos);

    // Disable continuous conversion mode
    ADC1->CFGR &= ~ADC_CFGR_CONT;

    // Select TIM6_TRGO as ADC trigger source
    ADC1->CFGR &= ~ADC_CFGR_EXTSEL;
    ADC1->CFGR |= (0b1101 << ADC_CFGR_EXTSEL_Pos);

    // Enable rising-edge triggering
    ADC1->CFGR &= ~ADC_CFGR_EXTEN;
    ADC1->CFGR |= (0b01 << ADC_CFGR_EXTEN_Pos);

    // Enable ADC DMA requests
    ADC1->CFGR |= ADC_CFGR_DMAEN;

    // Enable circular DMA request mode
    ADC1->CFGR |= ADC_CFGR_DMACFG;
}

void startADC(void) {
    ADC1->CR |= ADC_CR_ADSTART;
}