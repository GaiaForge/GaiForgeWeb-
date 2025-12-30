/**
 * Sensor Hub - Main Application Logic
 * SprigRig Sensor Hub
 */

#ifndef __SENSOR_HUB_H
#define __SENSOR_HUB_H

#include "stm32g4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* Channel types */
typedef enum {
    CHANNEL_NONE = 0,
    CHANNEL_4_20MA,
    CHANNEL_0_10V,
    CHANNEL_I2C,
    CHANNEL_SPI,
    CHANNEL_DIGITAL
} ChannelType_t;

/* Sensor Hub configuration */
typedef struct {
    ADC_HandleTypeDef *hadc;
    DAC_HandleTypeDef *hdac;
    I2C_HandleTypeDef *hi2c1;
    I2C_HandleTypeDef *hi2c2;
    SPI_HandleTypeDef *hspi2;
} SensorHub_Config_t;

/* Function prototypes */
void SensorHub_Init(SensorHub_Config_t *config);
void SensorHub_Update(void);

uint8_t SensorHub_ReadAddress(void);
uint16_t SensorHub_ReadADC_4_20mA(uint8_t channel);
uint16_t SensorHub_ReadADC_0_10V(uint8_t channel);
uint8_t SensorHub_ReadDigitalInputs(void);

uint16_t* SensorHub_GetRegisters(void);
uint16_t SensorHub_GetRegisterCount(void);

/* Analog output functions (0-10V) */
void SensorHub_SetAnalogOutput(uint8_t channel, uint16_t value);
void SensorHub_OnRegisterWrite(uint16_t reg_addr, uint16_t value);

/* Conversion helpers */
uint16_t SensorHub_ConvertCurrent_mA_x100(uint16_t adc_value);  // Returns mA * 100
uint16_t SensorHub_ConvertVoltage_mV(uint16_t adc_value);        // Returns mV

#endif /* __SENSOR_HUB_H */
