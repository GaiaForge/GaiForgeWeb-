/**
 * BME280 Temperature, Humidity, Pressure Sensor Driver
 * SprigRig Sensor Hub
 */

#include "bme280.h"

/* Private function prototypes */
static bool BME280_ReadCalibration(BME280_HandleTypeDef *bme);
static int32_t BME280_CompensateTemp(BME280_HandleTypeDef *bme, int32_t adc_T);
static uint32_t BME280_CompensatePress(BME280_HandleTypeDef *bme, int32_t adc_P);
static uint32_t BME280_CompensateHum(BME280_HandleTypeDef *bme, int32_t adc_H);

/**
 * Read single register
 */
static bool BME280_ReadReg(BME280_HandleTypeDef *bme, uint8_t reg, uint8_t *data) {
    return HAL_I2C_Mem_Read(bme->hi2c, bme->address << 1, reg,
                            I2C_MEMADD_SIZE_8BIT, data, 1, 100) == HAL_OK;
}

/**
 * Read multiple registers
 */
static bool BME280_ReadRegs(BME280_HandleTypeDef *bme, uint8_t reg, uint8_t *data, uint16_t len) {
    return HAL_I2C_Mem_Read(bme->hi2c, bme->address << 1, reg,
                            I2C_MEMADD_SIZE_8BIT, data, len, 100) == HAL_OK;
}

/**
 * Write single register
 */
static bool BME280_WriteReg(BME280_HandleTypeDef *bme, uint8_t reg, uint8_t data) {
    return HAL_I2C_Mem_Write(bme->hi2c, bme->address << 1, reg,
                             I2C_MEMADD_SIZE_8BIT, &data, 1, 100) == HAL_OK;
}

/**
 * Initialize BME280
 */
bool BME280_Init(BME280_HandleTypeDef *bme, I2C_HandleTypeDef *hi2c, uint8_t address) {
    bme->hi2c = hi2c;
    bme->address = address;
    bme->t_fine = 0;

    // Check chip ID
    uint8_t id;
    if (!BME280_ReadID(bme, &id)) {
        return false;
    }
    if (id != BME280_CHIP_ID) {
        return false;
    }

    // Reset the sensor
    if (!BME280_Reset(bme)) {
        return false;
    }

    // Wait for reset to complete
    HAL_Delay(10);

    // Read calibration data
    if (!BME280_ReadCalibration(bme)) {
        return false;
    }

    // Configure with default settings
    // Temp OS x2, Press OS x16, Hum OS x1, Normal mode, Filter x16
    if (!BME280_Configure(bme,
                          BME280_OS_2X,      // Temperature oversampling
                          BME280_OS_16X,     // Pressure oversampling
                          BME280_OS_1X,      // Humidity oversampling
                          BME280_MODE_NORMAL,
                          BME280_FILTER_16,
                          BME280_STANDBY_1000)) {
        return false;
    }

    return true;
}

/**
 * Read chip ID
 */
bool BME280_ReadID(BME280_HandleTypeDef *bme, uint8_t *id) {
    return BME280_ReadReg(bme, BME280_REG_ID, id);
}

/**
 * Soft reset
 */
bool BME280_Reset(BME280_HandleTypeDef *bme) {
    return BME280_WriteReg(bme, BME280_REG_RESET, 0xB6);
}

/**
 * Read calibration data from sensor
 */
static bool BME280_ReadCalibration(BME280_HandleTypeDef *bme) {
    uint8_t calib[26];
    uint8_t calib_h[7];

    // Read temperature and pressure calibration (0x88 - 0xA1)
    if (!BME280_ReadRegs(bme, BME280_REG_CALIB00, calib, 26)) {
        return false;
    }

    // Read humidity calibration (0xE1 - 0xE7)
    if (!BME280_ReadRegs(bme, BME280_REG_CALIB26, calib_h, 7)) {
        return false;
    }

    // Parse calibration data
    bme->calib.dig_T1 = (uint16_t)(calib[1] << 8) | calib[0];
    bme->calib.dig_T2 = (int16_t)(calib[3] << 8) | calib[2];
    bme->calib.dig_T3 = (int16_t)(calib[5] << 8) | calib[4];

    bme->calib.dig_P1 = (uint16_t)(calib[7] << 8) | calib[6];
    bme->calib.dig_P2 = (int16_t)(calib[9] << 8) | calib[8];
    bme->calib.dig_P3 = (int16_t)(calib[11] << 8) | calib[10];
    bme->calib.dig_P4 = (int16_t)(calib[13] << 8) | calib[12];
    bme->calib.dig_P5 = (int16_t)(calib[15] << 8) | calib[14];
    bme->calib.dig_P6 = (int16_t)(calib[17] << 8) | calib[16];
    bme->calib.dig_P7 = (int16_t)(calib[19] << 8) | calib[18];
    bme->calib.dig_P8 = (int16_t)(calib[21] << 8) | calib[20];
    bme->calib.dig_P9 = (int16_t)(calib[23] << 8) | calib[22];

    bme->calib.dig_H1 = calib[25];
    bme->calib.dig_H2 = (int16_t)(calib_h[1] << 8) | calib_h[0];
    bme->calib.dig_H3 = calib_h[2];
    bme->calib.dig_H4 = (int16_t)(calib_h[3] << 4) | (calib_h[4] & 0x0F);
    bme->calib.dig_H5 = (int16_t)(calib_h[5] << 4) | (calib_h[4] >> 4);
    bme->calib.dig_H6 = (int8_t)calib_h[6];

    return true;
}

/**
 * Configure sensor
 */
bool BME280_Configure(BME280_HandleTypeDef *bme,
                      uint8_t temp_os, uint8_t press_os, uint8_t hum_os,
                      uint8_t mode, uint8_t filter, uint8_t standby) {

    // Humidity must be written first (before ctrl_meas)
    uint8_t ctrl_hum = hum_os & 0x07;
    if (!BME280_WriteReg(bme, BME280_REG_CTRL_HUM, ctrl_hum)) {
        return false;
    }

    // Config register (standby time, filter)
    uint8_t config = ((standby & 0x07) << 5) | ((filter & 0x07) << 2);
    if (!BME280_WriteReg(bme, BME280_REG_CONFIG, config)) {
        return false;
    }

    // Ctrl_meas register (temp OS, press OS, mode)
    uint8_t ctrl_meas = ((temp_os & 0x07) << 5) | ((press_os & 0x07) << 2) | (mode & 0x03);
    if (!BME280_WriteReg(bme, BME280_REG_CTRL_MEAS, ctrl_meas)) {
        return false;
    }

    return true;
}

/**
 * Trigger single measurement (forced mode)
 */
bool BME280_TriggerMeasurement(BME280_HandleTypeDef *bme) {
    uint8_t ctrl_meas;
    if (!BME280_ReadReg(bme, BME280_REG_CTRL_MEAS, &ctrl_meas)) {
        return false;
    }

    // Set forced mode (bits 1:0)
    ctrl_meas = (ctrl_meas & 0xFC) | BME280_MODE_FORCED;
    return BME280_WriteReg(bme, BME280_REG_CTRL_MEAS, ctrl_meas);
}

/**
 * Check if measurement is in progress
 */
bool BME280_IsMeasuring(BME280_HandleTypeDef *bme) {
    uint8_t status;
    if (!BME280_ReadReg(bme, BME280_REG_STATUS, &status)) {
        return false;
    }
    return (status & 0x08) != 0; // Bit 3 = measuring
}

/**
 * Read all sensor data and compensate
 */
bool BME280_ReadAll(BME280_HandleTypeDef *bme) {
    uint8_t data[8];

    // Read all data registers (0xF7 - 0xFE)
    if (!BME280_ReadRegs(bme, BME280_REG_PRESS_MSB, data, 8)) {
        return false;
    }

    // Parse raw values (20-bit pressure/temp, 16-bit humidity)
    bme->raw_press = ((int32_t)data[0] << 12) | ((int32_t)data[1] << 4) | (data[2] >> 4);
    bme->raw_temp = ((int32_t)data[3] << 12) | ((int32_t)data[4] << 4) | (data[5] >> 4);
    bme->raw_hum = ((int32_t)data[6] << 8) | data[7];

    // Compensate (temperature must be first - sets t_fine)
    bme->temperature = BME280_CompensateTemp(bme, bme->raw_temp);
    bme->pressure = BME280_CompensatePress(bme, bme->raw_press);
    bme->humidity = BME280_CompensateHum(bme, bme->raw_hum);

    return true;
}

/**
 * Temperature compensation (from BME280 datasheet)
 * Returns temperature in °C * 100
 */
static int32_t BME280_CompensateTemp(BME280_HandleTypeDef *bme, int32_t adc_T) {
    int32_t var1, var2, T;

    var1 = ((((adc_T >> 3) - ((int32_t)bme->calib.dig_T1 << 1))) *
            ((int32_t)bme->calib.dig_T2)) >> 11;

    var2 = (((((adc_T >> 4) - ((int32_t)bme->calib.dig_T1)) *
              ((adc_T >> 4) - ((int32_t)bme->calib.dig_T1))) >> 12) *
            ((int32_t)bme->calib.dig_T3)) >> 14;

    bme->t_fine = var1 + var2;
    T = (bme->t_fine * 5 + 128) >> 8;

    return T;
}

/**
 * Pressure compensation (from BME280 datasheet)
 * Returns pressure in Pa
 */
static uint32_t BME280_CompensatePress(BME280_HandleTypeDef *bme, int32_t adc_P) {
    int64_t var1, var2, p;

    var1 = ((int64_t)bme->t_fine) - 128000;
    var2 = var1 * var1 * (int64_t)bme->calib.dig_P6;
    var2 = var2 + ((var1 * (int64_t)bme->calib.dig_P5) << 17);
    var2 = var2 + (((int64_t)bme->calib.dig_P4) << 35);
    var1 = ((var1 * var1 * (int64_t)bme->calib.dig_P3) >> 8) +
           ((var1 * (int64_t)bme->calib.dig_P2) << 12);
    var1 = (((((int64_t)1) << 47) + var1)) * ((int64_t)bme->calib.dig_P1) >> 33;

    if (var1 == 0) {
        return 0;
    }

    p = 1048576 - adc_P;
    p = (((p << 31) - var2) * 3125) / var1;
    var1 = (((int64_t)bme->calib.dig_P9) * (p >> 13) * (p >> 13)) >> 25;
    var2 = (((int64_t)bme->calib.dig_P8) * p) >> 19;

    p = ((p + var1 + var2) >> 8) + (((int64_t)bme->calib.dig_P7) << 4);

    return (uint32_t)(p >> 8);
}

/**
 * Humidity compensation (from BME280 datasheet)
 * Returns humidity in %RH * 1024
 */
static uint32_t BME280_CompensateHum(BME280_HandleTypeDef *bme, int32_t adc_H) {
    int32_t v_x1_u32r;

    v_x1_u32r = (bme->t_fine - ((int32_t)76800));

    v_x1_u32r = (((((adc_H << 14) - (((int32_t)bme->calib.dig_H4) << 20) -
                   (((int32_t)bme->calib.dig_H5) * v_x1_u32r)) +
                  ((int32_t)16384)) >> 15) *
                (((((((v_x1_u32r * ((int32_t)bme->calib.dig_H6)) >> 10) *
                     (((v_x1_u32r * ((int32_t)bme->calib.dig_H3)) >> 11) +
                      ((int32_t)32768))) >> 10) + ((int32_t)2097152)) *
                  ((int32_t)bme->calib.dig_H2) + 8192) >> 14));

    v_x1_u32r = (v_x1_u32r - (((((v_x1_u32r >> 15) * (v_x1_u32r >> 15)) >> 7) *
                               ((int32_t)bme->calib.dig_H1)) >> 4));

    v_x1_u32r = (v_x1_u32r < 0) ? 0 : v_x1_u32r;
    v_x1_u32r = (v_x1_u32r > 419430400) ? 419430400 : v_x1_u32r;

    return (uint32_t)(v_x1_u32r >> 12);
}

/**
 * Get temperature in °C * 100 (e.g., 2350 = 23.50°C)
 */
int16_t BME280_GetTemperature_x100(BME280_HandleTypeDef *bme) {
    return (int16_t)bme->temperature;
}

/**
 * Get humidity in %RH * 100 (e.g., 5000 = 50.00%)
 */
uint16_t BME280_GetHumidity_x100(BME280_HandleTypeDef *bme) {
    // humidity is in %RH * 1024, convert to * 100
    return (uint16_t)((bme->humidity * 100) >> 10);
}

/**
 * Get pressure in Pa (e.g., 101325 Pa = 1013.25 hPa)
 */
uint32_t BME280_GetPressure_Pa(BME280_HandleTypeDef *bme) {
    return bme->pressure;
}
