/**
 * BH1750 Digital Light Sensor Driver
 * SprigRig Sensor Hub
 *
 * I2C Interface
 * Default address: 0x23 (ADDR pin LOW) or 0x5C (ADDR pin HIGH)
 */

#ifndef __BH1750_H
#define __BH1750_H

#include "stm32g4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* I2C Addresses */
#define BH1750_ADDR_LOW     0x23    // ADDR pin to GND
#define BH1750_ADDR_HIGH    0x5C    // ADDR pin to VCC

/* Commands */
#define BH1750_POWER_DOWN           0x00
#define BH1750_POWER_ON             0x01
#define BH1750_RESET                0x07

/* Measurement modes */
#define BH1750_CONT_H_RES_MODE      0x10    // Continuous H-Resolution Mode (1 lx resolution, 120ms)
#define BH1750_CONT_H_RES_MODE2     0x11    // Continuous H-Resolution Mode2 (0.5 lx resolution, 120ms)
#define BH1750_CONT_L_RES_MODE      0x13    // Continuous L-Resolution Mode (4 lx resolution, 16ms)
#define BH1750_ONE_H_RES_MODE       0x20    // One Time H-Resolution Mode
#define BH1750_ONE_H_RES_MODE2      0x21    // One Time H-Resolution Mode2
#define BH1750_ONE_L_RES_MODE       0x23    // One Time L-Resolution Mode

/* Measurement time register (for sensitivity adjustment) */
#define BH1750_MTREG_DEFAULT        69      // Default MT value
#define BH1750_MTREG_MIN            31
#define BH1750_MTREG_MAX            254

/* BH1750 handle structure */
typedef struct {
    I2C_HandleTypeDef *hi2c;
    uint8_t address;
    uint8_t mode;
    uint8_t mtreg;
    uint16_t raw_value;
    uint32_t lux_x100;      // Lux * 100 for 0.01 lux resolution
} BH1750_HandleTypeDef;

/* Function prototypes */
bool BH1750_Init(BH1750_HandleTypeDef *bh, I2C_HandleTypeDef *hi2c, uint8_t address);
bool BH1750_Reset(BH1750_HandleTypeDef *bh);
bool BH1750_PowerOn(BH1750_HandleTypeDef *bh);
bool BH1750_PowerDown(BH1750_HandleTypeDef *bh);

bool BH1750_SetMode(BH1750_HandleTypeDef *bh, uint8_t mode);
bool BH1750_SetMTReg(BH1750_HandleTypeDef *bh, uint8_t mtreg);

bool BH1750_TriggerMeasurement(BH1750_HandleTypeDef *bh);
bool BH1750_ReadLight(BH1750_HandleTypeDef *bh);

/* Get values */
uint32_t BH1750_GetLux_x100(BH1750_HandleTypeDef *bh);
uint16_t BH1750_GetLux(BH1750_HandleTypeDef *bh);

#endif /* __BH1750_H */
