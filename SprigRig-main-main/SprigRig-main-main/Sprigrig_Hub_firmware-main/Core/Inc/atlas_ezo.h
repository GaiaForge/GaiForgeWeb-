/**
 * Atlas Scientific EZO Sensor Drivers (pH, EC, ORP, DO, etc.)
 * SprigRig Sensor Hub
 *
 * I2C Interface
 * Default addresses: pH=0x63, EC=0x64, ORP=0x62, DO=0x61
 */

#ifndef __ATLAS_EZO_H
#define __ATLAS_EZO_H

#include "stm32g4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* Default I2C Addresses */
#define ATLAS_EZO_PH_ADDR       0x63
#define ATLAS_EZO_EC_ADDR       0x64
#define ATLAS_EZO_ORP_ADDR      0x62
#define ATLAS_EZO_DO_ADDR       0x61
#define ATLAS_EZO_RTD_ADDR      0x66

/* Response codes */
#define ATLAS_EZO_RESPONSE_SUCCESS      1
#define ATLAS_EZO_RESPONSE_FAILED       2
#define ATLAS_EZO_RESPONSE_PENDING      254
#define ATLAS_EZO_RESPONSE_NO_DATA      255

/* Sensor types */
typedef enum {
    ATLAS_EZO_TYPE_PH,
    ATLAS_EZO_TYPE_EC,
    ATLAS_EZO_TYPE_ORP,
    ATLAS_EZO_TYPE_DO,
    ATLAS_EZO_TYPE_RTD
} AtlasEZO_Type_t;

/* Atlas EZO handle structure */
typedef struct {
    I2C_HandleTypeDef *hi2c;
    uint8_t address;
    AtlasEZO_Type_t type;
    char response[32];
    uint8_t response_len;
    uint8_t response_code;

    // Parsed values (type-dependent)
    union {
        int32_t ph_x1000;           // pH * 1000 (e.g., 7123 = 7.123 pH)
        int32_t ec_us_cm;           // EC in µS/cm
        int32_t orp_mv;             // ORP in mV
        int32_t do_mg_l_x100;       // DO in mg/L * 100
        int32_t temp_x100;          // Temperature in °C * 100
    } value;

    // Additional EC parameters
    uint32_t tds_ppm;               // Total dissolved solids (ppm)
    uint32_t salinity_ppt_x100;     // Salinity (ppt * 100)
    uint32_t specific_gravity_x1000; // Specific gravity * 1000
} AtlasEZO_HandleTypeDef;

/* Common functions */
bool AtlasEZO_Init(AtlasEZO_HandleTypeDef *ezo, I2C_HandleTypeDef *hi2c,
                   uint8_t address, AtlasEZO_Type_t type);
bool AtlasEZO_SendCommand(AtlasEZO_HandleTypeDef *ezo, const char *cmd);
bool AtlasEZO_ReadResponse(AtlasEZO_HandleTypeDef *ezo);
bool AtlasEZO_SendAndWait(AtlasEZO_HandleTypeDef *ezo, const char *cmd, uint16_t wait_ms);

/* Device info */
bool AtlasEZO_GetInfo(AtlasEZO_HandleTypeDef *ezo, char *info, uint8_t max_len);
bool AtlasEZO_GetStatus(AtlasEZO_HandleTypeDef *ezo, char *reason, float *voltage);
bool AtlasEZO_SetI2CAddress(AtlasEZO_HandleTypeDef *ezo, uint8_t new_address);

/* Sleep/Wake */
bool AtlasEZO_Sleep(AtlasEZO_HandleTypeDef *ezo);
bool AtlasEZO_Wake(AtlasEZO_HandleTypeDef *ezo);

/* LED control */
bool AtlasEZO_SetLED(AtlasEZO_HandleTypeDef *ezo, bool on);
bool AtlasEZO_GetLED(AtlasEZO_HandleTypeDef *ezo, bool *on);

/* Factory reset */
bool AtlasEZO_FactoryReset(AtlasEZO_HandleTypeDef *ezo);

/* Reading */
bool AtlasEZO_TriggerReading(AtlasEZO_HandleTypeDef *ezo);
bool AtlasEZO_ReadValue(AtlasEZO_HandleTypeDef *ezo);

/* Temperature compensation (for pH, EC, DO) */
bool AtlasEZO_SetTemperature(AtlasEZO_HandleTypeDef *ezo, int16_t temp_x100);
bool AtlasEZO_GetTemperature(AtlasEZO_HandleTypeDef *ezo, int16_t *temp_x100);

/* ==================== pH Specific ==================== */

/* pH Calibration */
bool AtlasEZO_pH_CalMid(AtlasEZO_HandleTypeDef *ezo, uint16_t ph_x100);
bool AtlasEZO_pH_CalLow(AtlasEZO_HandleTypeDef *ezo, uint16_t ph_x100);
bool AtlasEZO_pH_CalHigh(AtlasEZO_HandleTypeDef *ezo, uint16_t ph_x100);
bool AtlasEZO_pH_CalClear(AtlasEZO_HandleTypeDef *ezo);
bool AtlasEZO_pH_CalQuery(AtlasEZO_HandleTypeDef *ezo, uint8_t *cal_points);

/* pH Slope */
bool AtlasEZO_pH_GetSlope(AtlasEZO_HandleTypeDef *ezo, int16_t *acid_slope, int16_t *base_slope, int16_t *zero_point);

/* Get pH value */
int32_t AtlasEZO_pH_GetValue_x1000(AtlasEZO_HandleTypeDef *ezo);
uint16_t AtlasEZO_pH_GetValue_x100(AtlasEZO_HandleTypeDef *ezo);

/* ==================== EC Specific ==================== */

/* EC Probe type (K value) */
bool AtlasEZO_EC_SetProbeType(AtlasEZO_HandleTypeDef *ezo, uint16_t k_x100);
bool AtlasEZO_EC_GetProbeType(AtlasEZO_HandleTypeDef *ezo, uint16_t *k_x100);

/* EC Calibration */
bool AtlasEZO_EC_CalDry(AtlasEZO_HandleTypeDef *ezo);
bool AtlasEZO_EC_CalSingle(AtlasEZO_HandleTypeDef *ezo, uint32_t value_us);
bool AtlasEZO_EC_CalLow(AtlasEZO_HandleTypeDef *ezo, uint32_t value_us);
bool AtlasEZO_EC_CalHigh(AtlasEZO_HandleTypeDef *ezo, uint32_t value_us);
bool AtlasEZO_EC_CalClear(AtlasEZO_HandleTypeDef *ezo);
bool AtlasEZO_EC_CalQuery(AtlasEZO_HandleTypeDef *ezo, uint8_t *cal_points);

/* EC Output parameters */
bool AtlasEZO_EC_SetOutput(AtlasEZO_HandleTypeDef *ezo, bool ec, bool tds, bool sal, bool sg);

/* Get EC values */
int32_t AtlasEZO_EC_GetEC(AtlasEZO_HandleTypeDef *ezo);           // µS/cm
uint32_t AtlasEZO_EC_GetTDS(AtlasEZO_HandleTypeDef *ezo);          // ppm
uint32_t AtlasEZO_EC_GetSalinity_x100(AtlasEZO_HandleTypeDef *ezo); // ppt * 100
uint32_t AtlasEZO_EC_GetSG_x1000(AtlasEZO_HandleTypeDef *ezo);     // specific gravity * 1000

#endif /* __ATLAS_EZO_H */
