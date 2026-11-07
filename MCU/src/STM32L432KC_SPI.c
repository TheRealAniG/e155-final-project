// STM32L432KC_SPI.c
// Anirudh Gupta
// anirgupta@hmc.edu
// 10/21/26
// Source code for SPI functions


#include "STM32L432KC_SPI.h"


void initSPI(int br, int cpol, int cpha) {
    // Implementation of SPI initialization

     // Enable port
    gpioEnable(GPIO_PORT_A);

    // Configure SCK (PA5) to AF5
    pinMode(SPI_SCK_PIN, GPIO_ALT);
    GPIOA->AFR[0] &= ~GPIO_AFRL_AFSEL5_Msk;
    GPIOA->AFR[0] |= (SPI_AF << GPIO_AFRL_AFSEL5_Pos);

    // Configure MISO (PA6) to AF5
    pinMode(SPI_MISO_PIN, GPIO_ALT);
    GPIOA->AFR[0] &= ~GPIO_AFRL_AFSEL6_Msk;
    GPIOA->AFR[0] |= (SPI_AF << GPIO_AFRL_AFSEL6_Pos);

    // Configure MOSI (PA12) to AF5
    pinMode(SPI_MOSI_PIN, GPIO_ALT);
    GPIOA->AFR[1] &= ~GPIO_AFRH_AFSEL12_Msk;
    GPIOA->AFR[1] |= (SPI_AF << GPIO_AFRH_AFSEL12_Pos);

    // Configure CE (PA8) to GPIO output
    pinMode(SPI_CE_PIN, GPIO_OUTPUT);
    // Set CE pin low initially
    digitalWrite(SPI_CE_PIN, PIO_LOW);
    
    // Enable SPI1 clock
    RCC->APB2ENR |= RCC_APB2ENR_SPI1EN;

    // Disable SPI before configuration
    SPI1->CR1 &= ~SPI_CR1_SPE;

    // Configure clock rate using baud rate divisor
    SPI1->CR1 &= ~SPI_CR1_BR;
    SPI1->CR1 |= (br << SPI_CR1_BR_Pos);
    
    // Configure clock polarity
    SPI1->CR1 &= ~SPI_CR1_CPOL;
    SPI1->CR1 |= (cpol << SPI_CR1_CPOL_Pos);

    // Configure clock phase
    SPI1->CR1 &= ~SPI_CR1_CPHA;
    SPI1->CR1 |= (cpha << SPI_CR1_CPHA_Pos);

    // Set data frame size to 8 bits
    SPI1->CR2 &= ~SPI_CR2_DS;
    SPI1->CR2 |= (0b0111 << SPI_CR2_DS_Pos);
    
    // Set FIFO reception threshold to 8 bits
    SPI1->CR2 &= ~SPI_CR2_FRXTH;
    SPI1->CR2 |= (1 << SPI_CR2_FRXTH_Pos);

    // MSB is sent first
    SPI1->CR1 &= ~SPI_CR1_LSBFIRST;
    SPI1->CR1 |= (0 << SPI_CR1_LSBFIRST_Pos); 

    // Configure NSS software management
    SPI1->CR1 &= ~SPI_CR1_SSM;
    SPI1->CR1 |= (1 << SPI_CR1_SSM_Pos);
    SPI1->CR1 &= ~SPI_CR1_SSI;
    SPI1->CR1 |= (1 << SPI_CR1_SSI_Pos);

    // Set to master mode
    SPI1->CR1 &= ~SPI_CR1_MSTR;
    SPI1->CR1 |= (1 << SPI_CR1_MSTR_Pos);

    // Enable SPI
    SPI1->CR1 |= (1 << SPI_CR1_SPE_Pos);
}


char spiSendReceive(char send) {
    // Implementation of SPI send and receive
    
    // Wait for the transmit buffer to be empty
    while (!(SPI1->SR & SPI_SR_TXE));

    // Write one byte
    *((volatile char *) (&SPI1->DR)) = send;

    // Wait for the receive buffer to be not empty
    while (!(SPI1->SR & SPI_SR_RXNE));

    // Read one byte
    return *((volatile char *) (&SPI1->DR));
}