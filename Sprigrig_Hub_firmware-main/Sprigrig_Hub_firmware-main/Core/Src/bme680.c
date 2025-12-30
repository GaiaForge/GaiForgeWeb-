/**
 * BME680 Temperature, Humidity, Pressure, Gas Sensor Driver
 * SprigRig Sensor Hub
 */

#include "bme680.h"

/* Lookup table for gas range */
static const uint32_t gas_range_lookup1[16] = {
    2147483647UL, 2147483647UL, 2147483647UL, 2147483647UL,
    2147483647UL, 2126008810UL, 2147483647UL, 2130303777UL,
    2147483647UL, 2147483647UL, 2143188679UL, 2136746228UL,
    2147483647UL, 2126008810UL, 2147483647UL, 2147483647UL
};

static const uint32_t gas_range_lookup2[16] = {
    4096000000UL, 2048000000UL, 1024000000UL, 512000000UL,
    255744255UL, 127110228UL, 64000000UL, 32258064UL,
    16016016UL, 8000000UL, 4000000UL, 2000000UL,
    1000000UL, 500000UL, 250000UL, 125000UL
};

/* Private function prototypes */
static bool BME680_ReadReg(BME680_HandleTypeDef *bme, uint8_t reg, uint8_t *data);
static bool BME680_ReadRegs(BME680_HandleTypeDef *bme, uint8_t reg, uint8_t *data, uint16_t len);
static bool BME680_WriteReg(BME680_HandleTypeDef *bme, uint8_t reg, uint8_t data);
static bool BME680_ReadCalibration(BME680_HandleTypeDef *bme);
static int32_t BME680_CompensateTemp(BME680_HandleTypeDef *bme, int32_t adc_T);
static uint32_t BME680_CompensatePress(BME680_HandleTypeDef *bme, int32_t adc_P);
static uint32_t BME680_CompensateHum(BME680_HandleTypeDef *bme, int32_t adc_H);
static uint32_t BME680_CompensateGas(BME680_HandleTypeDef *bme, uint16_t gas_adc, uint8_t gas_range);
static uint8_t BME680_CalcHeaterRes(BME680_HandleTypeDef *bme, uint16_t target_temp);
static uint8_t BME680_CalcHeaterDur(uint16_t duration_ms);

/**
 * Read single register
 */
static bool BME680_ReadReg(BME680_HandleTypeDef *bme, uint8_t reg, uint8_t *data) {
    return HAL_I2C_Mem_Read(bme->hi2c, bme->address << 1, reg,
                            I2C_MEMADD_SIZE_8BIT, data, 1, 100) == HAL_OK;
}

/**
 * Read multiple registers
 */
static bool BME680_ReadRegs(BME680_HandleTypeDef *bme, uint8_t reg, uint8_t *data, uint16_t len) {
    return HAL_I2C_Mem_Read(bme->hi2c, bme->address << 1, reg,
                            I2C_MEMADD_SIZE_8BIT, data, len, 100) == HAL_OK;
}

/**
 * Write single register
 */
static bool BME680_WriteReg(BME680_HandleTypeDef *bme, uint8_t reg, uint8_t data) {
    return HAL_I2C_Mem_Write(bme->hi2c, bme->address << 1, reg,
                             I2C_MEMADD_SIZE_8BIT, &data, 1, 100) == HAL_OK;
}

/**
 * Initialize BME680
 */
bool BME680_Init(BME680_HandleTypeDef *bme, I2C_HandleTypeDef *hi2c, uint8_t address) {
    bme->hi2c = hi2c;
    bme->address = address;
    bme->t_fine = 0;
    bme->gas_valid = false;
    bme->heat_stable = false;

    // Check chip ID
    uint8_t id;
    if (!BME680_ReadID(bme, &id)) {
        return false;
    }
    if (id != BME680_CHIP_ID) {
        return false;
    }

    // Reset the sensor
    if (!BME680_Reset(bme)) {
        return false;
    }
    HAL_Delay(10);

    // Read calibration data
    if (!BME680_ReadCalibration(bme)) {
        return false;
    }

    // Default configuration
    if (!BME680_Configure(bme, BME680_OS_2X, BME680_OS_16X, BME680_OS_1X, BME680_FILTER_16)) {
        return false;
    }

    // Configure gas heater (300°C for 100ms on profile 0)
    if (!BME680_ConfigureGasHeater(bme, 300, 100, BME680_HEATER_PROFILE_0)) {
        return false;
    }

    return true;
}

/**
 * Read chip ID
 */
bool BME680_ReadID(BME680_HandleTypeDef *bme, uint8_t *id) {
    return BME680_ReadReg(bme, BME680_REG_ID, id);
}

/**
 * Soft reset
 */
bool BME680_Reset(BME680_HandleTypeDef *bme) {
    return BME680_WriteReg(bme, BME680_REG_RESET, 0xB6);
}

/**
 * Read calibration data
 */
static bool BME680_ReadCalibration(BME680_HandleTypeDef *bme) {
    uint8_t coeff1[25];
    uint8_t coeff2[16];

    if (!BME680_ReadRegs(bme, BME680_REG_COEFF1, coeff1, 25)) {
        return false;
    }
    if (!BME680_ReadRegs(bme, BME680_REG_COEFF2, coeff2, 16)) {
        return false;
    }

    // Temperature calibration
    bme->calib.par_t1 = (uint16_t)(coeff2[9] << 8) | coeff2[8];
    bme->calib.par_t2 = (int16_t)(coeff1[2] << 8) | coeff1[1];
    bme->calib.par_t3 = (int8_t)coeff1[3];

    // Pressure calibration
    bme->calib.par_p1 = (uint16_t)(coeff1[6] << 8) | coeff1[5];
    bme->calib.par_p2 = (int16_t)(coeff1[8] << 8) | coeff1[7];
    bme->calib.par_p3 = (int8_t)coeff1[9];
    bme->calib.par_p4 = (int16_t)(coeff1[12] << 8) | coeff1[11];
    bme->calib.par_p5 = (int16_t)(coeff1[14] << 8) | coeff1[13];
    bme->calib.par_p6 = (int8_t)coeff1[16];
    bme->calib.par_p7 = (int8_t)coeff1[15];
    bme->calib.par_p8 = (int16_t)(coeff1[20] << 8) | coeff1[19];
    bme->calib.par_p9 = (int16_t)(coeff1[22] << 8) | coeff1[21];
    bme->calib.par_p10 = coeff1[23];

    // Humidity calibration
    bme->calib.par_h1 = (uint16_t)(coeff2[2] << 4) | (coeff2[1] & 0x0F);
    bme->calib.par_h2 = (uint16_t)(coeff2[0] << 4) | (coeff2[1] >> 4);
    bme->calib.par_h3 = (int8_t)coeff2[3];
    bme->calib.par_h4 = (int8_t)coeff2[4];
    bme->calib.par_h5 = (int8_t)coeff2[5];
    bme->calib.par_h6 = coeff2[6];
    bme->calib.par_h7 = (int8_t)coeff2[7];

    // Gas calibration
    bme->calib.par_gh1 = (int8_t)coeff2[14];
    bme->calib.par_gh2 = (int16_t)(coeff2[13] << 8) | coeff2[12];
    bme->calib.par_gh3 = (int8_t)coeff2[15];

    // Read heater calibration
    uint8_t temp;
    if (!BME680_ReadReg(bme, 0x02, &temp)) {
        return false;
    }
    bme->calib.res_heat_range = (temp >> 4) & 0x03;

    if (!BME680_ReadReg(bme, 0x00, &temp)) {
        return false;
    }
    bme->calib.res_heat_val = (int8_t)temp;

    if (!BME680_ReadReg(bme, 0x04, &temp)) {
        return false;
    }
    bme->calib.range_sw_err = ((int8_t)temp) / 16;

    return true;
}

/**
 * Configure sensor
 */
bool BME680_Configure(BME680_HandleTypeDef *bme,
                      uint8_t temp_os, uint8_t press_os, uint8_t hum_os,
                      uint8_t filter) {
    // Set humidity oversampling
    if (!BME680_WriteReg(bme, BME680_REG_CTRL_HUM, hum_os & 0x07)) {
        return false;
    }

    // Set filter
    uint8_t config = (filter & 0x07) << 2;
    if (!BME680_WriteReg(bme, BME680_REG_CONFIG, config)) {
        return false;
    }

    // Set temp and pressure oversampling (sleep mode)
    uint8_t ctrl_meas = ((temp_os & 0x07) << 5) | ((press_os & 0x07) << 2) | BME680_MODE_SLEEP;
    if (!BME680_WriteReg(bme, BME680_REG_CTRL_MEAS, ctrl_meas)) {
        return false;
    }

    return true;
}

/**
 * Calculate heater resistance register value
 */
static uint8_t BME680_CalcHeaterRes(BME680_HandleTypeDef *bme, uint16_t target_temp) {
    int32_t var1, var2, var3, var4, var5;
    int32_t heatr_res_x100;
    uint8_t heatr_res;

    if (target_temp > 400) {
        target_temp = 400;
    }

    var1 = (((int32_t)bme->calib.par_gh1) * 1000) / 16;
    var2 = (((int32_t)bme->calib.par_gh2 + (int32_t)bme->calib.par_gh3 *
            (int32_t)bme->temperature / 1000) * 1000) / 256000;
    var3 = ((int32_t)target_temp * 1000 - ((int32_t)bme->temperature * 10));
    var4 = (int32_t)bme->calib.res_heat_val * 10000 + var1 + var2 * var3 / 10;
    var5 = (var4 / ((4 * bme->calib.res_heat_range + 1) * 256));
    heatr_res_x100 = var5 * 31;
    heatr_res = (uint8_t)((heatr_res_x100 + 50) / 100);

    return heatr_res;
}

/**
 * Calculate heater duration register value
 */
static uint8_t BME680_CalcHeaterDur(uint16_t duration_ms) {
    uint8_t dur;

    if (duration_ms >= 0xFC0) {
        dur = 0xFF;
    } else {
        uint8_t factor = 0;
        while (duration_ms > 0x3F) {
            duration_ms = duration_ms >> 2;
            factor++;
        }
        dur = (uint8_t)(duration_ms + (factor << 6));
    }

    return dur;
}

/**
 * Configure gas heater
 */
bool BME680_ConfigureGasHeater(BME680_HandleTypeDef *bme,
                               uint16_t target_temp_c,
                               uint16_t duration_ms,
                               uint8_t profile) {
    // Calculate heater resistance
    uint8_t heatr_res = BME680_CalcHeaterRes(bme, target_temp_c);
    if (!BME680_WriteReg(bme, BME680_REG_RES_HEAT_0 + profile, heatr_res)) {
        return false;
    }

    // Calculate heater duration
    uint8_t heatr_dur = BME680_CalcHeaterDur(duration_ms);
    if (!BME680_WriteReg(bme, BME680_REG_GAS_WAIT_0 + profile, heatr_dur)) {
        return false;
    }

    // Select heater profile
    uint8_t ctrl_gas_1;
    if (!BME680_ReadReg(bme, BME680_REG_CTRL_GAS_1, &ctrl_gas_1)) {
        return false;
    }
    ctrl_gas_1 = (ctrl_gas_1 & 0xF0) | (profile & 0x0F);
    if (!BME680_WriteReg(bme, BME680_REG_CTRL_GAS_1, ctrl_gas_1)) {
        return false;
    }

    return true;
}

/**
 * Trigger measurement (forced mode)
 */
bool BME680_TriggerMeasurement(BME680_HandleTypeDef *bme, bool enable_gas) {
    // Enable/disable gas measurement
    uint8_t ctrl_gas_1;
    if (!BME680_ReadReg(bme, BME680_REG_CTRL_GAS_1, &ctrl_gas_1)) {
        return false;
    }
    if (enable_gas) {
        ctrl_gas_1 |= 0x10;  // Run gas conversion
    } else {
        ctrl_gas_1 &= ~0x10;
    }
    if (!BME680_WriteReg(bme, BME680_REG_CTRL_GAS_1, ctrl_gas_1)) {
        return false;
    }

    // Read current ctrl_meas and set forced mode
    uint8_t ctrl_meas;
    if (!BME680_ReadReg(bme, BME680_REG_CTRL_MEAS, &ctrl_meas)) {
        return false;
    }
    ctrl_meas = (ctrl_meas & 0xFC) | BME680_MODE_FORCED;
    if (!BME680_WriteReg(bme, BME680_REG_CTRL_MEAS, ctrl_meas)) {
        return false;
    }

    return true;
}

/**
 * Check if measurement is in progress
 */
bool BME680_IsMeasuring(BME680_HandleTypeDef *bme) {
    uint8_t status;
    if (!BME680_ReadReg(bme, BME680_REG_MEAS_STATUS, &status)) {
        return false;
    }
    return (status & 0x20) != 0;  // Bit 5 = measuring
}

/**
 * Read all measurements
 */
bool BME680_ReadAll(BME680_HandleTypeDef *bme) {
    uint8_t data[15];

    // Read all data registers (0x1D to 0x2B)
    if (!BME680_ReadRegs(bme, BME680_REG_MEAS_STATUS, data, 15)) {
        return false;
    }

    // Check if new data is available
    if ((data[0] & 0x80) == 0) {
        return false;  // No new data
    }

    // Parse raw values
    bme->raw_press = ((int32_t)data[2] << 12) | ((int32_t)data[3] << 4) | (data[4] >> 4);
    bme->raw_temp = ((int32_t)data[5] << 12) | ((int32_t)data[6] << 4) | (data[7] >> 4);
    bme->raw_hum = ((int32_t)data[8] << 8) | data[9];

    // Gas data
    bme->raw_gas = ((uint16_t)data[13] << 2) | (data[14] >> 6);
    bme->gas_range = data[14] & 0x0F;
    bme->gas_valid = (data[14] & 0x20) != 0;
    bme->heat_stable = (data[14] & 0x10) != 0;

    // Compensate (temperature must be first)
    bme->temperature = BME680_CompensateTemp(bme, bme->raw_temp);
    bme->pressure = BME680_CompensatePress(bme, bme->raw_press);
    bme->humidity = BME680_CompensateHum(bme, bme->raw_hum);

    if (bme->gas_valid && bme->heat_stable) {
        bme->gas_resistance = BME680_CompensateGas(bme, bme->raw_gas, bme->gas_range);
    } else {
        bme->gas_resistance = 0;
    }

    return true;
}

/**
 * Temperature compensation
 */
static int32_t BME680_CompensateTemp(BME680_HandleTypeDef *bme, int32_t adc_T) {
    int64_t var1, var2, var3;
    int32_t calc_temp;

    var1 = ((int32_t)adc_T >> 3) - ((int32_t)bme->calib.par_t1 << 1);
    var2 = (var1 * (int32_t)bme->calib.par_t2) >> 11;
    var3 = ((var1 >> 1) * (var1 >> 1)) >> 12;
    var3 = (var3 * ((int32_t)bme->calib.par_t3 << 4)) >> 14;
    bme->t_fine = (int32_t)(var2 + var3);
    calc_temp = (bme->t_fine * 5 + 128) >> 8;

    return calc_temp;
}

/**
 * Pressure compensation
 */
static uint32_t BME680_CompensatePress(BME680_HandleTypeDef *bme, int32_t adc_P) {
    int32_t var1, var2, var3;
    int32_t press_comp;

    var1 = (bme->t_fine >> 1) - 64000;
    var2 = ((((var1 >> 2) * (var1 >> 2)) >> 11) * (int32_t)bme->calib.par_p6) >> 2;
    var2 = var2 + ((var1 * (int32_t)bme->calib.par_p5) << 1);
    var2 = (var2 >> 2) + ((int32_t)bme->calib.par_p4 << 16);
    var1 = (((((var1 >> 2) * (var1 >> 2)) >> 13) * ((int32_t)bme->calib.par_p3 << 5)) >> 3) +
           (((int32_t)bme->calib.par_p2 * var1) >> 1);
    var1 = var1 >> 18;
    var1 = ((32768 + var1) * (int32_t)bme->calib.par_p1) >> 15;
    press_comp = 1048576 - adc_P;
    press_comp = (int32_t)((press_comp - (var2 >> 12)) * ((uint32_t)3125));

    if (press_comp >= 0x40000000) {
        press_comp = ((press_comp / (uint32_t)var1) << 1);
    } else {
        press_comp = ((press_comp << 1) / (uint32_t)var1);
    }

    var1 = ((int32_t)bme->calib.par_p9 * (int32_t)(((press_comp >> 3) * (press_comp >> 3)) >> 13)) >> 12;
    var2 = ((int32_t)(press_comp >> 2) * (int32_t)bme->calib.par_p8) >> 13;
    var3 = ((int32_t)(press_comp >> 8) * (int32_t)(press_comp >> 8) * (int32_t)(press_comp >> 8) *
            (int32_t)bme->calib.par_p10) >> 17;

    press_comp = (int32_t)(press_comp) + ((var1 + var2 + var3 + ((int32_t)bme->calib.par_p7 << 7)) >> 4);

    return (uint32_t)press_comp;
}

/**
 * Humidity compensation
 */
static uint32_t BME680_CompensateHum(BME680_HandleTypeDef *bme, int32_t adc_H) {
    int32_t var1, var2, var3, var4, var5, var6;
    int32_t temp_scaled;
    int32_t calc_hum;

    temp_scaled = (bme->t_fine * 5 + 128) >> 8;
    var1 = (int32_t)(adc_H - ((int32_t)((int32_t)bme->calib.par_h1 * 16))) -
           (((temp_scaled * (int32_t)bme->calib.par_h3) / 100) >> 1);
    var2 = ((int32_t)bme->calib.par_h2 *
            (((temp_scaled * (int32_t)bme->calib.par_h4) / 100) +
             (((temp_scaled * ((temp_scaled * (int32_t)bme->calib.par_h5) / 100)) >> 6) / 100) +
             (int32_t)(1 << 14))) >> 10;
    var3 = var1 * var2;
    var4 = (int32_t)bme->calib.par_h6 << 7;
    var4 = ((var4) + ((temp_scaled * (int32_t)bme->calib.par_h7) / 100)) >> 4;
    var5 = ((var3 >> 14) * (var3 >> 14)) >> 10;
    var6 = (var4 * var5) >> 1;
    calc_hum = (((var3 + var6) >> 10) * 1000) >> 12;

    if (calc_hum > 100000) {
        calc_hum = 100000;
    } else if (calc_hum < 0) {
        calc_hum = 0;
    }

    return (uint32_t)calc_hum;
}

/**
 * Gas resistance compensation
 */
static uint32_t BME680_CompensateGas(BME680_HandleTypeDef *bme, uint16_t gas_adc, uint8_t gas_range) {
    int64_t var1;
    uint64_t var2;
    int64_t var3;
    uint32_t calc_gas_res;

    var1 = (int64_t)((1340 + (5 * (int64_t)bme->calib.range_sw_err)) *
                      ((int64_t)gas_range_lookup1[gas_range])) >> 16;
    var2 = (((int64_t)((int64_t)gas_adc << 15) - (int64_t)(16777216)) + var1);
    var3 = (((int64_t)gas_range_lookup2[gas_range] * (int64_t)var1) >> 9);
    calc_gas_res = (uint32_t)((var3 + ((int64_t)var2 >> 1)) / (int64_t)var2);

    return calc_gas_res;
}

/**
 * Get temperature in °C * 100
 */
int16_t BME680_GetTemperature_x100(BME680_HandleTypeDef *bme) {
    return (int16_t)bme->temperature;
}

/**
 * Get humidity in %RH * 100
 */
uint16_t BME680_GetHumidity_x100(BME680_HandleTypeDef *bme) {
    return (uint16_t)(bme->humidity / 10);  // Convert from x1000 to x100
}

/**
 * Get pressure in Pa
 */
uint32_t BME680_GetPressure_Pa(BME680_HandleTypeDef *bme) {
    return bme->pressure;
}

/**
 * Get gas resistance in Ohms
 */
uint32_t BME680_GetGasResistance(BME680_HandleTypeDef *bme) {
    return bme->gas_resistance;
}

/**
 * Check if gas measurement is valid
 */
bool BME680_IsGasValid(BME680_HandleTypeDef *bme) {
    return bme->gas_valid && bme->heat_stable;
}
