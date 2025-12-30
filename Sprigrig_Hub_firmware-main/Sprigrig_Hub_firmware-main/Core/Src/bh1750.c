/**
 * BH1750 Digital Light Sensor Driver
 * SprigRig Sensor Hub
 */

#include "bh1750.h"

/* Private function prototypes */
static bool BH1750_WriteCmd(BH1750_HandleTypeDef *bh, uint8_t cmd);
static bool BH1750_ReadData(BH1750_HandleTypeDef *bh, uint8_t *data, uint16_t len);

/**
 * Write command to sensor
 */
static bool BH1750_WriteCmd(BH1750_HandleTypeDef *bh, uint8_t cmd) {
    return HAL_I2C_Master_Transmit(bh->hi2c, bh->address << 1, &cmd, 1, 100) == HAL_OK;
}

/**
 * Read data from sensor
 */
static bool BH1750_ReadData(BH1750_HandleTypeDef *bh, uint8_t *data, uint16_t len) {
    return HAL_I2C_Master_Receive(bh->hi2c, bh->address << 1, data, len, 100) == HAL_OK;
}

/**
 * Initialize BH1750
 */
bool BH1750_Init(BH1750_HandleTypeDef *bh, I2C_HandleTypeDef *hi2c, uint8_t address) {
    bh->hi2c = hi2c;
    bh->address = address;
    bh->mode = BH1750_CONT_H_RES_MODE;
    bh->mtreg = BH1750_MTREG_DEFAULT;
    bh->raw_value = 0;
    bh->lux_x100 = 0;

    // Power on
    if (!BH1750_PowerOn(bh)) {
        return false;
    }

    // Reset
    if (!BH1750_Reset(bh)) {
        return false;
    }

    // Set default mode (continuous high resolution)
    if (!BH1750_SetMode(bh, BH1750_CONT_H_RES_MODE)) {
        return false;
    }

    return true;
}

/**
 * Reset sensor
 */
bool BH1750_Reset(BH1750_HandleTypeDef *bh) {
    return BH1750_WriteCmd(bh, BH1750_RESET);
}

/**
 * Power on sensor
 */
bool BH1750_PowerOn(BH1750_HandleTypeDef *bh) {
    return BH1750_WriteCmd(bh, BH1750_POWER_ON);
}

/**
 * Power down sensor
 */
bool BH1750_PowerDown(BH1750_HandleTypeDef *bh) {
    return BH1750_WriteCmd(bh, BH1750_POWER_DOWN);
}

/**
 * Set measurement mode
 */
bool BH1750_SetMode(BH1750_HandleTypeDef *bh, uint8_t mode) {
    if (!BH1750_WriteCmd(bh, mode)) {
        return false;
    }
    bh->mode = mode;
    return true;
}

/**
 * Set measurement time register (sensitivity adjustment)
 * Higher values = higher sensitivity, longer measurement time
 */
bool BH1750_SetMTReg(BH1750_HandleTypeDef *bh, uint8_t mtreg) {
    if (mtreg < BH1750_MTREG_MIN || mtreg > BH1750_MTREG_MAX) {
        return false;
    }

    // Write high bits (01000_MT[7:5])
    uint8_t high = 0x40 | (mtreg >> 5);
    if (!BH1750_WriteCmd(bh, high)) {
        return false;
    }

    // Write low bits (011_MT[4:0])
    uint8_t low = 0x60 | (mtreg & 0x1F);
    if (!BH1750_WriteCmd(bh, low)) {
        return false;
    }

    bh->mtreg = mtreg;

    // Need to set mode again after changing MTReg
    return BH1750_SetMode(bh, bh->mode);
}

/**
 * Trigger one-time measurement
 */
bool BH1750_TriggerMeasurement(BH1750_HandleTypeDef *bh) {
    uint8_t mode;

    // Convert continuous mode to one-time mode if needed
    switch (bh->mode) {
        case BH1750_CONT_H_RES_MODE:
            mode = BH1750_ONE_H_RES_MODE;
            break;
        case BH1750_CONT_H_RES_MODE2:
            mode = BH1750_ONE_H_RES_MODE2;
            break;
        case BH1750_CONT_L_RES_MODE:
            mode = BH1750_ONE_L_RES_MODE;
            break;
        default:
            mode = bh->mode;
            break;
    }

    return BH1750_WriteCmd(bh, mode);
}

/**
 * Read light measurement
 */
bool BH1750_ReadLight(BH1750_HandleTypeDef *bh) {
    uint8_t data[2];

    if (!BH1750_ReadData(bh, data, 2)) {
        return false;
    }

    // Raw value is 16-bit big-endian
    bh->raw_value = ((uint16_t)data[0] << 8) | data[1];

    // Convert to lux
    // Formula: lux = raw / 1.2 (for default MTReg=69)
    // Adjusted for MTReg: lux = raw / 1.2 * (69 / mtreg)
    // For H-Resolution Mode2 (0.5 lx), divide by 2
    // To get lux * 100: lux_x100 = raw * 100 / 1.2 * (69 / mtreg)

    uint32_t lux_x100;

    // Calculate: raw * 100 * 69 / (1.2 * mtreg)
    // = raw * 6900 / (1.2 * mtreg)
    // = raw * 5750 / mtreg
    lux_x100 = ((uint32_t)bh->raw_value * 5750) / bh->mtreg;

    // For Mode2, the resolution is 0.5 lx, so divide by 2
    if (bh->mode == BH1750_CONT_H_RES_MODE2 || bh->mode == BH1750_ONE_H_RES_MODE2) {
        lux_x100 /= 2;
    }

    bh->lux_x100 = lux_x100;

    return true;
}

/**
 * Get light level in lux * 100
 */
uint32_t BH1750_GetLux_x100(BH1750_HandleTypeDef *bh) {
    return bh->lux_x100;
}

/**
 * Get light level in lux
 */
uint16_t BH1750_GetLux(BH1750_HandleTypeDef *bh) {
    return (uint16_t)(bh->lux_x100 / 100);
}
