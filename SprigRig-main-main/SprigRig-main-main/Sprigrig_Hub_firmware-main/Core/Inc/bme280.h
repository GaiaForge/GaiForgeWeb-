/**
 * BME280 Temperature, Humidity, Pressure Sensor Driver
 * SprigRig Sensor Hub
 *
 * I2C Interface
 * Default address: 0x76 (SDO to GND) or 0x77 (SDO to VCC)
 */

#ifndef __BME280_H
#define __BME280_H

#include "stm32g4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* I2C Addresses */
#define BME280_ADDR_LOW     0x76    // SDO to GND
#define BME280_ADDR_HIGH    0x77    // SDO to VCC

/* Register addresses */
#define BME280_REG_ID           0xD0
#define BME280_REG_RESET        0xE0
#define BME280_REG_CTRL_HUM     0xF2
#define BME280_REG_STATUS       0xF3
#define BME280_REG_CTRL_MEAS    0xF4
#define BME280_REG_CONFIG       0xF5
#define BME280_REG_PRESS_MSB    0xF7
#define BME280_REG_PRESS_LSB    0xF8
#define BME280_REG_PRESS_XLSB   0xF9
#define BME280_REG_TEMP_MSB     0xFA
#define BME280_REG_TEMP_LSB     0xFB
#define BME280_REG_TEMP_XLSB    0xFC
#define BME280_REG_HUM_MSB      0xFD
#define BME280_REG_HUM_LSB      0xFE

/* Calibration data registers */
#define BME280_REG_CALIB00      0x88    // T1-T3, P1-P9
#define BME280_REG_CALIB26      0xE1    // H1-H6

/* Chip ID */
#define BME280_CHIP_ID          0x60

/* Oversampling settings */
#define BME280_OS_SKIP          0x00
#define BME280_OS_1X            0x01
#define BME280_OS_2X            0x02
#define BME280_OS_4X            0x03
#define BME280_OS_8X            0x04
#define BME280_OS_16X           0x05

/* Mode settings */
#define BME280_MODE_SLEEP       0x00
#define BME280_MODE_FORCED      0x01
#define BME280_MODE_NORMAL      0x03

/* Filter settings */
#define BME280_FILTER_OFF       0x00
#define BME280_FILTER_2         0x01
#define BME280_FILTER_4         0x02
#define BME280_FILTER_8         0x03
#define BME280_FILTER_16        0x04

/* Standby time (normal mode) */
#define BME280_STANDBY_0_5      0x00    // 0.5ms
#define BME280_STANDBY_62_5     0x01    // 62.5ms
#define BME280_STANDBY_125      0x02    // 125ms
#define BME280_STANDBY_250      0x03    // 250ms
#define BME280_STANDBY_500      0x04    // 500ms
#define BME280_STANDBY_1000     0x05    // 1000ms
#define BME280_STANDBY_10       0x06    // 10ms
#define BME280_STANDBY_20       0x07    // 20ms

/* Calibration data structure */
typedef struct {
    uint16_t dig_T1;
    int16_t  dig_T2;
    int16_t  dig_T3;

    uint16_t dig_P1;
    int16_t  dig_P2;
    int16_t  dig_P3;
    int16_t  dig_P4;
    int16_t  dig_P5;
    int16_t  dig_P6;
    int16_t  dig_P7;
    int16_t  dig_P8;
    int16_t  dig_P9;

    uint8_t  dig_H1;
    int16_t  dig_H2;
    uint8_t  dig_H3;
    int16_t  dig_H4;
    int16_t  dig_H5;
    int8_t   dig_H6;
} BME280_CalibData_t;

/* BME280 handle structure */
typedef struct {
    I2C_HandleTypeDef *hi2c;
    uint8_t address;
    BME280_CalibData_t calib;
    int32_t t_fine;     // Fine temperature for compensation

    // Last readings (raw)
    int32_t raw_temp;
    int32_t raw_press;
    int32_t raw_hum;

    // Compensated readings
    int32_t temperature;    // °C * 100 (e.g., 2350 = 23.50°C)
    uint32_t pressure;      // Pa (e.g., 101325 = 1013.25 hPa)
    uint32_t humidity;      // %RH * 1024 (e.g., 51200 = 50.0%)
} BME280_HandleTypeDef;

/* Function prototypes */
bool BME280_Init(BME280_HandleTypeDef *bme, I2C_HandleTypeDef *hi2c, uint8_t address);
bool BME280_Reset(BME280_HandleTypeDef *bme);
bool BME280_ReadID(BME280_HandleTypeDef *bme, uint8_t *id);

bool BME280_Configure(BME280_HandleTypeDef *bme,
                      uint8_t temp_os, uint8_t press_os, uint8_t hum_os,
                      uint8_t mode, uint8_t filter, uint8_t standby);

bool BME280_ReadAll(BME280_HandleTypeDef *bme);
bool BME280_TriggerMeasurement(BME280_HandleTypeDef *bme);
bool BME280_IsMeasuring(BME280_HandleTypeDef *bme);

/* Get compensated values */
int16_t BME280_GetTemperature_x100(BME280_HandleTypeDef *bme);  // °C * 100
uint16_t BME280_GetHumidity_x100(BME280_HandleTypeDef *bme);    // %RH * 100
uint32_t BME280_GetPressure_Pa(BME280_HandleTypeDef *bme);      // Pa

#endif /* __BME280_H */
