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
    gpioEnable(GPIO_PORT_B);

    // SCK: PB3, AF5
    pinMode(SPI_SCK_PIN, GPIO_ALT);
    GPIOB->AFR[0] &= ~GPIO_AFRL_AFSEL3_Msk;
    GPIOB->AFR[0] |= (SPI_AF << GPIO_AFRL_AFSEL3_Pos);

    // MOSI: PB5, AF5
    pinMode(SPI_MOSI_PIN, GPIO_ALT);
    GPIOB->AFR[0] &= ~GPIO_AFRL_AFSEL5_Msk;
    GPIOB->AFR[0] |= (SPI_AF << GPIO_AFRL_AFSEL5_Pos);

    // MISO: PA6, AF5
    pinMode(SPI_MISO_PIN, GPIO_ALT);
    GPIOA->AFR[0] &= ~GPIO_AFRL_AFSEL6_Msk;
    GPIOA->AFR[0] |= (SPI_AF << GPIO_AFRL_AFSEL6_Pos);

    // Set CE pin high initially
    digitalWrite(SPI_CE_PIN, PIO_HIGH);
    // Configure CE (PA8) to GPIO output
    pinMode(SPI_CE_PIN, GPIO_OUTPUT);

    
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


void spiSendCarState(int16_t x, int16_t y, int16_t cosQ8, int16_t sinQ8) {

    // Construct 10-byte SPI packet
    uint8_t packet[10] = {
        0xA5,                              // Start marker
        (uint8_t)((uint16_t)x >> 8),       // X high byte
        (uint8_t)x,                        // X low byte
        (uint8_t)((uint16_t)y >> 8),       // Y high byte
        (uint8_t)y,                        // Y low byte
        (uint8_t)((uint16_t)cosQ8 >> 8),   // Cosine high byte
        (uint8_t)cosQ8,                    // Cosine low byte
        (uint8_t)((uint16_t)sinQ8 >> 8),   // Sine high byte
        (uint8_t)sinQ8,                    // Sine low byte
        0x00                               // Checksum placeholder
    };

    // Calculate XOR checksum
    for (int i = 0; i < 9; i++) {
        packet[9] ^= packet[i];
    }

    // Select FPGA (active-low CS)
    digitalWrite(SPI_CE_PIN, PIO_LOW);

    // Transmit packet
    for (int i = 0; i < 10; i++) {
        spiSendReceive((char)packet[i]);
    }

    // Wait until transmission is complete
    while (SPI1->SR & SPI_SR_BSY);

    // Deselect FPGA
    digitalWrite(SPI_CE_PIN, PIO_HIGH);
}
