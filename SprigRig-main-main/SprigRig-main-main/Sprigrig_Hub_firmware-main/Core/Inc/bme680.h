/**
 * BME680 Temperature, Humidity, Pressure, Gas Sensor Driver
 * SprigRig Sensor Hub
 *
 * I2C Interface
 * Default address: 0x76 (SDO to GND) or 0x77 (SDO to VCC)
 */

#ifndef __BME680_H
#define __BME680_H

#include "stm32g4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* I2C Addresses */
#define BME680_ADDR_LOW     0x76    // SDO to GND
#define BME680_ADDR_HIGH    0x77    // SDO to VCC

/* Chip ID */
#define BME680_CHIP_ID      0x61

/* Register addresses */
#define BME680_REG_STATUS       0x73
#define BME680_REG_RESET        0xE0
#define BME680_REG_ID           0xD0
#define BME680_REG_CONFIG       0x75
#define BME680_REG_CTRL_MEAS    0x74
#define BME680_REG_CTRL_HUM     0x72
#define BME680_REG_CTRL_GAS_1   0x71
#define BME680_REG_CTRL_GAS_0   0x70
#define BME680_REG_GAS_WAIT_0   0x64
#define BME680_REG_RES_HEAT_0   0x5A
#define BME680_REG_IDAC_HEAT_0  0x50
#define BME680_REG_GAS_R_LSB    0x2B
#define BME680_REG_GAS_R_MSB    0x2A
#define BME680_REG_HUM_LSB      0x26
#define BME680_REG_HUM_MSB      0x25
#define BME680_REG_TEMP_XLSB    0x24
#define BME680_REG_TEMP_LSB     0x23
#define BME680_REG_TEMP_MSB     0x22
#define BME680_REG_PRESS_XLSB   0x21
#define BME680_REG_PRESS_LSB    0x20
#define BME680_REG_PRESS_MSB    0x1F
#define BME680_REG_MEAS_STATUS  0x1D

/* Calibration registers */
#define BME680_REG_COEFF1       0x89    // 25 bytes
#define BME680_REG_COEFF2       0xE1    // 16 bytes

/* Oversampling settings */
#define BME680_OS_SKIP          0x00
#define BME680_OS_1X            0x01
#define BME680_OS_2X            0x02
#define BME680_OS_4X            0x03
#define BME680_OS_8X            0x04
#define BME680_OS_16X           0x05

/* Mode settings */
#define BME680_MODE_SLEEP       0x00
#define BME680_MODE_FORCED      0x01

/* Filter settings */
#define BME680_FILTER_OFF       0x00
#define BME680_FILTER_2         0x01
#define BME680_FILTER_4         0x02
#define BME680_FILTER_8         0x03
#define BME680_FILTER_16        0x04
#define BME680_FILTER_32        0x05
#define BME680_FILTER_64        0x06
#define BME680_FILTER_128       0x07

/* Gas heater profile selection */
#define BME680_HEATER_PROFILE_0 0x00
#define BME680_HEATER_PROFILE_1 0x01
#define BME680_HEATER_PROFILE_2 0x02

/* Calibration data structure */
typedef struct {
    // Temperature
    uint16_t par_t1;
    int16_t  par_t2;
    int8_t   par_t3;

    // Pressure
    uint16_t par_p1;
    int16_t  par_p2;
    int8_t   par_p3;
    int16_t  par_p4;
    int16_t  par_p5;
    int8_t   par_p6;
    int8_t   par_p7;
    int16_t  par_p8;
    int16_t  par_p9;
    uint8_t  par_p10;

    // Humidity
    uint16_t par_h1;
    uint16_t par_h2;
    int8_t   par_h3;
    int8_t   par_h4;
    int8_t   par_h5;
    uint8_t  par_h6;
    int8_t   par_h7;

    // Gas
    int8_t   par_gh1;
    int16_t  par_gh2;
    int8_t   par_gh3;

    // Heater range
    uint8_t  res_heat_range;
    int8_t   res_heat_val;
    int8_t   range_sw_err;
} BME680_CalibData_t;

/* BME680 handle structure */
typedef struct {
    I2C_HandleTypeDef *hi2c;
    uint8_t address;
    BME680_CalibData_t calib;
    int32_t t_fine;

    // Raw readings
    int32_t raw_temp;
    int32_t raw_press;
    int32_t raw_hum;
    uint16_t raw_gas;
    uint8_t gas_range;

    // Compensated readings
    int32_t temperature;    // °C * 100
    uint32_t pressure;      // Pa
    uint32_t humidity;      // %RH * 1000
    uint32_t gas_resistance; // Ohms

    // Gas measurement valid
    bool gas_valid;
    bool heat_stable;
} BME680_HandleTypeDef;

/* Function prototypes */
bool BME680_Init(BME680_HandleTypeDef *bme, I2C_HandleTypeDef *hi2c, uint8_t address);
bool BME680_Reset(BME680_HandleTypeDef *bme);
bool BME680_ReadID(BME680_HandleTypeDef *bme, uint8_t *id);

bool BME680_Configure(BME680_HandleTypeDef *bme,
                      uint8_t temp_os, uint8_t press_os, uint8_t hum_os,
                      uint8_t filter);

bool BME680_ConfigureGasHeater(BME680_HandleTypeDef *bme,
                               uint16_t target_temp_c,
                               uint16_t duration_ms,
                               uint8_t profile);

bool BME680_TriggerMeasurement(BME680_HandleTypeDef *bme, bool enable_gas);
bool BME680_IsMeasuring(BME680_HandleTypeDef *bme);
bool BME680_ReadAll(BME680_HandleTypeDef *bme);

/* Get compensated values */
int16_t BME680_GetTemperature_x100(BME680_HandleTypeDef *bme);
uint16_t BME680_GetHumidity_x100(BME680_HandleTypeDef *bme);
uint32_t BME680_GetPressure_Pa(BME680_HandleTypeDef *bme);
uint32_t BME680_GetGasResistance(BME680_HandleTypeDef *bme);
bool BME680_IsGasValid(BME680_HandleTypeDef *bme);

#endif /* __BME680_H */
