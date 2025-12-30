/**
 * SCD40 CO2 Sensor Driver
 * SprigRig Sensor Hub
 */

#include "scd40.h"

/* Private function prototypes */
static bool SCD40_SendCommand(SCD40_HandleTypeDef *scd, uint16_t cmd);
static bool SCD40_SendCommandWithArg(SCD40_HandleTypeDef *scd, uint16_t cmd, uint16_t arg);
static bool SCD40_ReadResponse(SCD40_HandleTypeDef *scd, uint16_t *data, uint8_t num_words);
static uint8_t SCD40_CalcCRC(uint8_t *data, uint8_t len);

/**
 * Calculate CRC-8 (polynomial 0x31, init 0xFF)
 */
static uint8_t SCD40_CalcCRC(uint8_t *data, uint8_t len) {
    uint8_t crc = 0xFF;

    for (uint8_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (uint8_t bit = 0; bit < 8; bit++) {
            if (crc & 0x80) {
                crc = (crc << 1) ^ 0x31;
            } else {
                crc = crc << 1;
            }
        }
    }

    return crc;
}

/**
 * Send command without arguments
 */
static bool SCD40_SendCommand(SCD40_HandleTypeDef *scd, uint16_t cmd) {
    uint8_t buf[2];
    buf[0] = (cmd >> 8) & 0xFF;
    buf[1] = cmd & 0xFF;

    return HAL_I2C_Master_Transmit(scd->hi2c, scd->address << 1, buf, 2, 100) == HAL_OK;
}

/**
 * Send command with 16-bit argument
 */
static bool SCD40_SendCommandWithArg(SCD40_HandleTypeDef *scd, uint16_t cmd, uint16_t arg) {
    uint8_t buf[5];
    buf[0] = (cmd >> 8) & 0xFF;
    buf[1] = cmd & 0xFF;
    buf[2] = (arg >> 8) & 0xFF;
    buf[3] = arg & 0xFF;
    buf[4] = SCD40_CalcCRC(&buf[2], 2);

    return HAL_I2C_Master_Transmit(scd->hi2c, scd->address << 1, buf, 5, 100) == HAL_OK;
}

/**
 * Read response (multiple 16-bit words with CRC)
 */
static bool SCD40_ReadResponse(SCD40_HandleTypeDef *scd, uint16_t *data, uint8_t num_words) {
    uint8_t buf[num_words * 3];  // Each word is 2 bytes + 1 CRC

    if (HAL_I2C_Master_Receive(scd->hi2c, scd->address << 1, buf, num_words * 3, 100) != HAL_OK) {
        return false;
    }

    // Parse and verify CRC for each word
    for (uint8_t i = 0; i < num_words; i++) {
        uint8_t *word_data = &buf[i * 3];
        uint8_t crc = SCD40_CalcCRC(word_data, 2);

        if (crc != word_data[2]) {
            return false;  // CRC mismatch
        }

        data[i] = ((uint16_t)word_data[0] << 8) | word_data[1];
    }

    return true;
}

/**
 * Initialize SCD40
 */
bool SCD40_Init(SCD40_HandleTypeDef *scd, I2C_HandleTypeDef *hi2c) {
    scd->hi2c = hi2c;
    scd->address = SCD40_ADDR;
    scd->measuring = false;
    scd->co2_ppm = 0;
    scd->temperature_x100 = 0;
    scd->humidity_x100 = 0;

    // Stop any ongoing measurement
    SCD40_StopPeriodicMeasurement(scd);
    HAL_Delay(500);  // Wait for stop to complete

    // Verify communication by reading serial number
    uint16_t serial[3];
    if (!SCD40_GetSerialNumber(scd, serial)) {
        return false;
    }

    return true;
}

/**
 * Start periodic measurement (5 second interval)
 */
bool SCD40_StartPeriodicMeasurement(SCD40_HandleTypeDef *scd) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_START_PERIODIC_MEASUREMENT)) {
        return false;
    }
    scd->measuring = true;
    return true;
}

/**
 * Start low power periodic measurement (30 second interval)
 */
bool SCD40_StartLowPowerPeriodicMeasurement(SCD40_HandleTypeDef *scd) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_START_LOW_POWER_PERIODIC)) {
        return false;
    }
    scd->measuring = true;
    return true;
}

/**
 * Stop periodic measurement
 */
bool SCD40_StopPeriodicMeasurement(SCD40_HandleTypeDef *scd) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_STOP_PERIODIC_MEASUREMENT)) {
        return false;
    }
    scd->measuring = false;
    return true;
}

/**
 * Perform single shot measurement (takes ~5 seconds)
 */
bool SCD40_MeasureSingleShot(SCD40_HandleTypeDef *scd) {
    return SCD40_SendCommand(scd, SCD40_CMD_MEASURE_SINGLE_SHOT);
}

/**
 * Check if data is ready
 */
bool SCD40_IsDataReady(SCD40_HandleTypeDef *scd) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_GET_DATA_READY_STATUS)) {
        return false;
    }

    HAL_Delay(1);

    uint16_t status;
    if (!SCD40_ReadResponse(scd, &status, 1)) {
        return false;
    }

    // Lower 11 bits indicate data ready if non-zero
    return (status & 0x07FF) != 0;
}

/**
 * Read measurement data
 */
bool SCD40_ReadMeasurement(SCD40_HandleTypeDef *scd) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_READ_MEASUREMENT)) {
        return false;
    }

    HAL_Delay(1);

    uint16_t data[3];
    if (!SCD40_ReadResponse(scd, data, 3)) {
        return false;
    }

    scd->raw_co2 = data[0];
    scd->raw_temp = data[1];
    scd->raw_hum = data[2];

    // Convert raw values
    scd->co2_ppm = scd->raw_co2;

    // Temperature: -45 + 175 * raw / 65535 (in °C)
    // For x100: -4500 + 17500 * raw / 65535
    int32_t temp = -4500 + ((int32_t)scd->raw_temp * 17500) / 65535;
    scd->temperature_x100 = (int16_t)temp;

    // Humidity: 100 * raw / 65535 (in %RH)
    // For x100: 10000 * raw / 65535
    scd->humidity_x100 = (uint16_t)(((uint32_t)scd->raw_hum * 10000) / 65535);

    return true;
}

/**
 * Set temperature offset for self-heating compensation
 */
bool SCD40_SetTemperatureOffset(SCD40_HandleTypeDef *scd, uint16_t offset_x100) {
    // Convert to sensor format: offset * 65535 / 17500
    uint16_t raw_offset = (uint16_t)(((uint32_t)offset_x100 * 65535) / 17500);
    return SCD40_SendCommandWithArg(scd, SCD40_CMD_SET_TEMPERATURE_OFFSET, raw_offset);
}

/**
 * Get temperature offset
 */
bool SCD40_GetTemperatureOffset(SCD40_HandleTypeDef *scd, uint16_t *offset_x100) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_GET_TEMPERATURE_OFFSET)) {
        return false;
    }

    HAL_Delay(1);

    uint16_t raw_offset;
    if (!SCD40_ReadResponse(scd, &raw_offset, 1)) {
        return false;
    }

    *offset_x100 = (uint16_t)(((uint32_t)raw_offset * 17500) / 65535);
    return true;
}

/**
 * Set sensor altitude (for pressure compensation)
 */
bool SCD40_SetSensorAltitude(SCD40_HandleTypeDef *scd, uint16_t altitude_m) {
    return SCD40_SendCommandWithArg(scd, SCD40_CMD_SET_SENSOR_ALTITUDE, altitude_m);
}

/**
 * Get sensor altitude
 */
bool SCD40_GetSensorAltitude(SCD40_HandleTypeDef *scd, uint16_t *altitude_m) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_GET_SENSOR_ALTITUDE)) {
        return false;
    }

    HAL_Delay(1);

    return SCD40_ReadResponse(scd, altitude_m, 1);
}

/**
 * Set ambient pressure for compensation (can be used during measurement)
 */
bool SCD40_SetAmbientPressure(SCD40_HandleTypeDef *scd, uint16_t pressure_hpa) {
    return SCD40_SendCommandWithArg(scd, SCD40_CMD_SET_AMBIENT_PRESSURE, pressure_hpa);
}

/**
 * Perform forced recalibration
 * Must be performed with sensor exposed to known CO2 concentration for >3 minutes
 */
bool SCD40_PerformForcedRecalibration(SCD40_HandleTypeDef *scd, uint16_t target_co2_ppm, uint16_t *frc_correction) {
    if (!SCD40_SendCommandWithArg(scd, SCD40_CMD_PERFORM_FORCED_RECALIBRATION, target_co2_ppm)) {
        return false;
    }

    HAL_Delay(400);  // FRC takes 400ms

    uint16_t result;
    if (!SCD40_ReadResponse(scd, &result, 1)) {
        return false;
    }

    if (result == 0xFFFF) {
        return false;  // FRC failed
    }

    *frc_correction = result - 0x8000;  // Signed offset
    return true;
}

/**
 * Enable/disable automatic self-calibration (ASC)
 */
bool SCD40_SetAutomaticSelfCalibration(SCD40_HandleTypeDef *scd, bool enabled) {
    return SCD40_SendCommandWithArg(scd, SCD40_CMD_SET_AUTOMATIC_SELF_CALIBRATION, enabled ? 1 : 0);
}

/**
 * Get automatic self-calibration status
 */
bool SCD40_GetAutomaticSelfCalibration(SCD40_HandleTypeDef *scd, bool *enabled) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_GET_AUTOMATIC_SELF_CALIBRATION)) {
        return false;
    }

    HAL_Delay(1);

    uint16_t status;
    if (!SCD40_ReadResponse(scd, &status, 1)) {
        return false;
    }

    *enabled = (status != 0);
    return true;
}

/**
 * Persist settings to EEPROM
 */
bool SCD40_PersistSettings(SCD40_HandleTypeDef *scd) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_PERSIST_SETTINGS)) {
        return false;
    }
    HAL_Delay(800);  // Takes 800ms
    return true;
}

/**
 * Get serial number
 */
bool SCD40_GetSerialNumber(SCD40_HandleTypeDef *scd, uint16_t serial[3]) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_GET_SERIAL_NUMBER)) {
        return false;
    }

    HAL_Delay(1);

    return SCD40_ReadResponse(scd, serial, 3);
}

/**
 * Perform self-test
 */
bool SCD40_PerformSelfTest(SCD40_HandleTypeDef *scd, bool *passed) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_PERFORM_SELF_TEST)) {
        return false;
    }

    HAL_Delay(10000);  // Self-test takes 10 seconds

    uint16_t result;
    if (!SCD40_ReadResponse(scd, &result, 1)) {
        return false;
    }

    *passed = (result == 0);
    return true;
}

/**
 * Perform factory reset
 */
bool SCD40_PerformFactoryReset(SCD40_HandleTypeDef *scd) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_PERFORM_FACTORY_RESET)) {
        return false;
    }
    HAL_Delay(1200);  // Takes 1200ms
    return true;
}

/**
 * Reinitialize sensor
 */
bool SCD40_Reinit(SCD40_HandleTypeDef *scd) {
    if (!SCD40_SendCommand(scd, SCD40_CMD_REINIT)) {
        return false;
    }
    HAL_Delay(20);
    return true;
}

/**
 * Get CO2 concentration in ppm
 */
uint16_t SCD40_GetCO2(SCD40_HandleTypeDef *scd) {
    return scd->co2_ppm;
}

/**
 * Get temperature in °C * 100
 */
int16_t SCD40_GetTemperature_x100(SCD40_HandleTypeDef *scd) {
    return scd->temperature_x100;
}

/**
 * Get humidity in %RH * 100
 */
uint16_t SCD40_GetHumidity_x100(SCD40_HandleTypeDef *scd) {
    return scd->humidity_x100;
}
