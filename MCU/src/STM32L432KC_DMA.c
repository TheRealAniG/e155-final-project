// STM32L432KC_DMA.c
// Source code for DMA functions

#include "STM32L432KC_DMA.h"

volatile uint16_t adcValues[ADC_NUM_CHANNELS];

void initDMA(void){
    // Enable DMA1 peripheral clock
    RCC->AHB1ENR |= RCC_AHB1ENR_DMA1EN;

    // Disable DMA1 Channel 1 before configuration
    DMA1_Channel1->CCR &= ~DMA_CCR_EN;

    // Set peripheral address to ADC1 data register
    DMA1_Channel1->CPAR = (uint32_t)&ADC1->DR;

    // Set memory address to ADC values buffer
    DMA1_Channel1->CMAR = (uint32_t)adcValues;

    // Set number of data transfers to 3 ADC readings
    DMA1_Channel1->CNDTR = ADC_NUM_CHANNELS;

    // Configure peripheral-to-memory transfers
    DMA1_Channel1->CCR &= ~DMA_CCR_DIR;

    // Disable peripheral address incrementing
    DMA1_Channel1->CCR &= ~DMA_CCR_PINC;

    // Enable memory address incrementing
    DMA1_Channel1->CCR |= DMA_CCR_MINC;

    // Set peripheral data size to 16 bits
    DMA1_Channel1->CCR &= ~DMA_CCR_PSIZE;
    DMA1_Channel1->CCR |= (0b01 << DMA_CCR_PSIZE_Pos);

    // Set memory data size to 16 bits
    DMA1_Channel1->CCR &= ~DMA_CCR_MSIZE;
    DMA1_Channel1->CCR |= (0b01 << DMA_CCR_MSIZE_Pos);

    // Enable circular mode
    DMA1_Channel1->CCR |= DMA_CCR_CIRC;

    // Set DMA Channel 1 priority to high
    DMA1_Channel1->CCR &= ~DMA_CCR_PL;
    DMA1_Channel1->CCR |= (0b10 << DMA_CCR_PL_Pos);

    // Select ADC1 as the request source for DMA1 Channel 1
    DMA1_CSELR->CSELR &= ~DMA_CSELR_C1S;

    // Enable DMA1 Channel 1
    DMA1_Channel1->CCR |= DMA_CCR_EN;
}