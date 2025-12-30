/**
 * SprigRig Sensor Hub Firmware
 * STM32G431CBT6
 */

#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stm32g4xx_hal.h"

/* Exported defines */

// RS485 DE/RE Control - PA1 per netlist
#define RS485_DE_PORT       GPIOA
#define RS485_DE_PIN        GPIO_PIN_1

// DIP Switches (Address Selection) - Active low with pullups
#define DIP_SW1_PORT        GPIOA
#define DIP_SW1_PIN         GPIO_PIN_11  // SW1 pin 8 -> PA11
#define DIP_SW2_PORT        GPIOA
#define DIP_SW2_PIN         GPIO_PIN_12  // SW1 pin 7 -> PA12
#define DIP_SW3_PORT        GPIOA
#define DIP_SW3_PIN         GPIO_PIN_15  // SW1 pin 6 -> PA15
#define DIP_SW4_PORT        GPIOB
#define DIP_SW4_PIN         GPIO_PIN_3   // SW1 pin 5 -> PB3

// Digital Inputs - Active low with pullups
#define DI1_PORT            GPIOC
#define DI1_PIN             GPIO_PIN_13  // J16 -> PC13
#define DI2_PORT            GPIOC
#define DI2_PIN             GPIO_PIN_14  // J17 -> PC14
#define DI3_PORT            GPIOC
#define DI3_PIN             GPIO_PIN_15  // J18 -> PC15
#define DI4_PORT            GPIOA
#define DI4_PIN             GPIO_PIN_10  // J19 -> PA10

// I2C1 (Sensor Bus 1) - PB6/PB7
#define I2C1_SCL_PORT       GPIOB
#define I2C1_SCL_PIN        GPIO_PIN_6
#define I2C1_SDA_PORT       GPIOB
#define I2C1_SDA_PIN        GPIO_PIN_7

// I2C2 (Sensor Bus 2) - PA8/PA9
#define I2C2_SDA_PORT       GPIOA
#define I2C2_SDA_PIN        GPIO_PIN_8
#define I2C2_SCL_PORT       GPIOA
#define I2C2_SCL_PIN        GPIO_PIN_9

// SPI2 (Expansion) - PB12-15
#define SPI2_CS_PORT        GPIOB
#define SPI2_CS_PIN         GPIO_PIN_12
#define SPI2_SCK_PIN        GPIO_PIN_13
#define SPI2_MISO_PIN       GPIO_PIN_14
#define SPI2_MOSI_PIN       GPIO_PIN_15

// ADC Channels - Per STM32G431 datasheet
#define ADC_4_20MA_1_CH     ADC_CHANNEL_1   // PA0 - ADC1_IN1 (J13 via R13)
#define ADC_4_20MA_2_CH     ADC_CHANNEL_15  // PB0 - ADC1_IN15 (J14)
#define ADC_0_10V_1_CH      ADC_CHANNEL_12  // PB1 - ADC1_IN12 (via R12 voltage divider)
#define ADC_0_10V_2_CH      ADC_CHANNEL_11  // PB2 - ADC2_IN12, but ADC1_IN11 on shared ADC1

// DAC Outputs (0-10V)
#define DAC_OUT1_PIN        GPIO_PIN_4      // PA4 - DAC1_OUT1
#define DAC_OUT1_PORT       GPIOA
#define DAC_OUT2_PIN        GPIO_PIN_5      // PA5 - DAC1_OUT2
#define DAC_OUT2_PORT       GPIOA

// Modbus Register Map
#define REG_CHANNEL_1       0   // First sensor channel
#define REG_CHANNEL_2       1
#define REG_CHANNEL_3       2
#define REG_CHANNEL_4       3
#define REG_CHANNEL_5       4
#define REG_CHANNEL_6       5
#define REG_CHANNEL_7       6
#define REG_CHANNEL_8       7
#define REG_DI_STATUS       8   // Digital inputs as bits
#define REG_HUB_ID          9   // Hub identifier
#define REG_FW_VERSION      10  // Firmware version
#define REG_AOUT_1          11  // Analog output 1 (0-10V) - writable
#define REG_AOUT_2          12  // Analog output 2 (0-10V) - writable

// Extended Sensor Map
#define REG_BH1750_LUX_HI   13  // Lux * 100 (High Word)
#define REG_BH1750_LUX_LO   14  // Lux * 100 (Low Word)
#define REG_SCD40_CO2       15  // CO2 ppm
#define REG_SCD40_TEMP      16  // Temp * 100
#define REG_SCD40_HUM       17  // Hum * 100
#define REG_ATLAS_PH        18  // pH * 100
#define REG_ATLAS_EC_HI     19  // EC uS/cm (High Word)
#define REG_ATLAS_EC_LO     20  // EC uS/cm (Low Word)

#define HOLDING_REG_COUNT   32

/* Exported functions */
void Error_Handler(void);

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
