/**
 * SCD40 CO2 Sensor Driver
 * SprigRig Sensor Hub
 *
 * I2C Interface
 * Fixed address: 0x62
 */

#ifndef __SCD40_H
#define __SCD40_H

#include "stm32g4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* I2C Address (fixed) */
#define SCD40_ADDR              0x62

/* Commands */
#define SCD40_CMD_START_PERIODIC_MEASUREMENT        0x21B1
#define SCD40_CMD_READ_MEASUREMENT                  0xEC05
#define SCD40_CMD_STOP_PERIODIC_MEASUREMENT         0x3F86
#define SCD40_CMD_SET_TEMPERATURE_OFFSET            0x241D
#define SCD40_CMD_GET_TEMPERATURE_OFFSET            0x2318
#define SCD40_CMD_SET_SENSOR_ALTITUDE               0x2427
#define SCD40_CMD_GET_SENSOR_ALTITUDE               0x2322
#define SCD40_CMD_SET_AMBIENT_PRESSURE              0xE000
#define SCD40_CMD_PERFORM_FORCED_RECALIBRATION      0x362F
#define SCD40_CMD_SET_AUTOMATIC_SELF_CALIBRATION    0x2416
#define SCD40_CMD_GET_AUTOMATIC_SELF_CALIBRATION    0x2313
#define SCD40_CMD_START_LOW_POWER_PERIODIC          0x21AC
#define SCD40_CMD_GET_DATA_READY_STATUS             0xE4B8
#define SCD40_CMD_PERSIST_SETTINGS                  0x3615
#define SCD40_CMD_GET_SERIAL_NUMBER                 0x3682
#define SCD40_CMD_PERFORM_SELF_TEST                 0x3639
#define SCD40_CMD_PERFORM_FACTORY_RESET             0x3632
#define SCD40_CMD_REINIT                            0x3646
#define SCD40_CMD_MEASURE_SINGLE_SHOT               0x219D
#define SCD40_CMD_MEASURE_SINGLE_SHOT_RHT_ONLY      0x2196

/* SCD40 handle structure */
typedef struct {
    I2C_HandleTypeDef *hi2c;
    uint8_t address;
    bool measuring;

    // Raw readings
    uint16_t raw_co2;
    uint16_t raw_temp;
    uint16_t raw_hum;

    // Converted readings
    uint16_t co2_ppm;           // CO2 in ppm
    int16_t temperature_x100;   // Temperature in °C * 100
    uint16_t humidity_x100;     // Relative humidity in %RH * 100
} SCD40_HandleTypeDef;

/* Function prototypes */
bool SCD40_Init(SCD40_HandleTypeDef *scd, I2C_HandleTypeDef *hi2c);
bool SCD40_StartPeriodicMeasurement(SCD40_HandleTypeDef *scd);
bool SCD40_StartLowPowerPeriodicMeasurement(SCD40_HandleTypeDef *scd);
bool SCD40_StopPeriodicMeasurement(SCD40_HandleTypeDef *scd);
bool SCD40_MeasureSingleShot(SCD40_HandleTypeDef *scd);

bool SCD40_IsDataReady(SCD40_HandleTypeDef *scd);
bool SCD40_ReadMeasurement(SCD40_HandleTypeDef *scd);

bool SCD40_SetTemperatureOffset(SCD40_HandleTypeDef *scd, uint16_t offset_x100);
bool SCD40_GetTemperatureOffset(SCD40_HandleTypeDef *scd, uint16_t *offset_x100);
bool SCD40_SetSensorAltitude(SCD40_HandleTypeDef *scd, uint16_t altitude_m);
bool SCD40_GetSensorAltitude(SCD40_HandleTypeDef *scd, uint16_t *altitude_m);
bool SCD40_SetAmbientPressure(SCD40_HandleTypeDef *scd, uint16_t pressure_hpa);

bool SCD40_PerformForcedRecalibration(SCD40_HandleTypeDef *scd, uint16_t target_co2_ppm, uint16_t *frc_correction);
bool SCD40_SetAutomaticSelfCalibration(SCD40_HandleTypeDef *scd, bool enabled);
bool SCD40_GetAutomaticSelfCalibration(SCD40_HandleTypeDef *scd, bool *enabled);

bool SCD40_PersistSettings(SCD40_HandleTypeDef *scd);
bool SCD40_GetSerialNumber(SCD40_HandleTypeDef *scd, uint16_t serial[3]);
bool SCD40_PerformSelfTest(SCD40_HandleTypeDef *scd, bool *passed);
bool SCD40_PerformFactoryReset(SCD40_HandleTypeDef *scd);
bool SCD40_Reinit(SCD40_HandleTypeDef *scd);

/* Get values */
uint16_t SCD40_GetCO2(SCD40_HandleTypeDef *scd);
int16_t SCD40_GetTemperature_x100(SCD40_HandleTypeDef *scd);
uint16_t SCD40_GetHumidity_x100(SCD40_HandleTypeDef *scd);

#endif /* __SCD40_H */
