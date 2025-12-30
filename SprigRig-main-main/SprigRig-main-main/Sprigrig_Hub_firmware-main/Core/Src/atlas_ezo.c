/**
 * Atlas Scientific EZO Sensor Drivers (pH, EC, ORP, DO, etc.)
 * SprigRig Sensor Hub
 */

#include "atlas_ezo.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/* Private function prototypes */
static bool AtlasEZO_ParseResponse(AtlasEZO_HandleTypeDef *ezo);
static int32_t AtlasEZO_ParseFloat_x1000(const char *str);

/**
 * Parse float string to integer * 1000
 */
static int32_t AtlasEZO_ParseFloat_x1000(const char *str) {
    int32_t result = 0;
    int32_t decimal = 0;
    int decimal_places = 0;
    bool negative = false;
    bool in_decimal = false;

    while (*str == ' ') str++;  // Skip leading spaces

    if (*str == '-') {
        negative = true;
        str++;
    }

    while (*str) {
        if (*str == '.') {
            in_decimal = true;
        } else if (*str >= '0' && *str <= '9') {
            if (in_decimal) {
                if (decimal_places < 3) {
                    decimal = decimal * 10 + (*str - '0');
                    decimal_places++;
                }
            } else {
                result = result * 10 + (*str - '0');
            }
        } else if (*str == ',' || *str == '\r' || *str == '\n') {
            break;  // End of number
        }
        str++;
    }

    // Pad decimal to 3 places
    while (decimal_places < 3) {
        decimal *= 10;
        decimal_places++;
    }

    result = result * 1000 + decimal;
    return negative ? -result : result;
}

/**
 * Parse response based on sensor type
 */
static bool AtlasEZO_ParseResponse(AtlasEZO_HandleTypeDef *ezo) {
    if (ezo->response_code != ATLAS_EZO_RESPONSE_SUCCESS) {
        return false;
    }

    char *ptr = ezo->response;

    switch (ezo->type) {
        case ATLAS_EZO_TYPE_PH:
            ezo->value.ph_x1000 = AtlasEZO_ParseFloat_x1000(ptr);
            break;

        case ATLAS_EZO_TYPE_EC:
            // EC can return multiple comma-separated values: EC,TDS,SAL,SG
            ezo->value.ec_us_cm = AtlasEZO_ParseFloat_x1000(ptr) / 1000;  // Convert back

            // Look for TDS
            ptr = strchr(ptr, ',');
            if (ptr) {
                ptr++;
                ezo->tds_ppm = AtlasEZO_ParseFloat_x1000(ptr) / 1000;

                // Look for salinity
                ptr = strchr(ptr, ',');
                if (ptr) {
                    ptr++;
                    ezo->salinity_ppt_x100 = AtlasEZO_ParseFloat_x1000(ptr) / 10;

                    // Look for specific gravity
                    ptr = strchr(ptr, ',');
                    if (ptr) {
                        ptr++;
                        ezo->specific_gravity_x1000 = AtlasEZO_ParseFloat_x1000(ptr);
                    }
                }
            }
            break;

        case ATLAS_EZO_TYPE_ORP:
            ezo->value.orp_mv = AtlasEZO_ParseFloat_x1000(ptr) / 1000;
            break;

        case ATLAS_EZO_TYPE_DO:
            ezo->value.do_mg_l_x100 = AtlasEZO_ParseFloat_x1000(ptr) / 10;
            break;

        case ATLAS_EZO_TYPE_RTD:
            ezo->value.temp_x100 = AtlasEZO_ParseFloat_x1000(ptr) / 10;
            break;

        default:
            return false;
    }

    return true;
}

/**
 * Initialize Atlas EZO sensor
 */
bool AtlasEZO_Init(AtlasEZO_HandleTypeDef *ezo, I2C_HandleTypeDef *hi2c,
                   uint8_t address, AtlasEZO_Type_t type) {
    ezo->hi2c = hi2c;
    ezo->address = address;
    ezo->type = type;
    ezo->response_len = 0;
    ezo->response_code = 0;
    memset(ezo->response, 0, sizeof(ezo->response));

    // Wake the device (in case it's sleeping)
    AtlasEZO_Wake(ezo);
    HAL_Delay(100);

    // Verify communication by getting info
    char info[32];
    return AtlasEZO_GetInfo(ezo, info, sizeof(info));
}

/**
 * Send command to sensor
 */
bool AtlasEZO_SendCommand(AtlasEZO_HandleTypeDef *ezo, const char *cmd) {
    uint8_t len = strlen(cmd);
    return HAL_I2C_Master_Transmit(ezo->hi2c, ezo->address << 1,
                                   (uint8_t *)cmd, len, 100) == HAL_OK;
}

/**
 * Read response from sensor
 */
bool AtlasEZO_ReadResponse(AtlasEZO_HandleTypeDef *ezo) {
    uint8_t buf[32];

    if (HAL_I2C_Master_Receive(ezo->hi2c, ezo->address << 1, buf, 32, 100) != HAL_OK) {
        return false;
    }

    ezo->response_code = buf[0];

    if (ezo->response_code == ATLAS_EZO_RESPONSE_SUCCESS) {
        // Copy response string (skip first byte which is response code)
        uint8_t i;
        for (i = 0; i < 31 && buf[i + 1] != 0; i++) {
            ezo->response[i] = buf[i + 1];
        }
        ezo->response[i] = '\0';
        ezo->response_len = i;
        return true;
    }

    return false;
}

/**
 * Send command and wait for response
 */
bool AtlasEZO_SendAndWait(AtlasEZO_HandleTypeDef *ezo, const char *cmd, uint16_t wait_ms) {
    if (!AtlasEZO_SendCommand(ezo, cmd)) {
        return false;
    }

    HAL_Delay(wait_ms);

    return AtlasEZO_ReadResponse(ezo);
}

/**
 * Get device info
 */
bool AtlasEZO_GetInfo(AtlasEZO_HandleTypeDef *ezo, char *info, uint8_t max_len) {
    if (!AtlasEZO_SendAndWait(ezo, "I", 300)) {
        return false;
    }

    strncpy(info, ezo->response, max_len - 1);
    info[max_len - 1] = '\0';
    return true;
}

/**
 * Get device status
 */
bool AtlasEZO_GetStatus(AtlasEZO_HandleTypeDef *ezo, char *reason, float *voltage) {
    if (!AtlasEZO_SendAndWait(ezo, "STATUS", 300)) {
        return false;
    }

    // Response format: ?STATUS,P,5.00 (P=power on, 5.00V)
    char *ptr = strchr(ezo->response, ',');
    if (ptr && reason) {
        *reason = *(ptr + 1);
    }

    ptr = strchr(ptr + 1, ',');
    if (ptr && voltage) {
        *voltage = (float)AtlasEZO_ParseFloat_x1000(ptr + 1) / 1000.0f;
    }

    return true;
}

/**
 * Set I2C address
 */
bool AtlasEZO_SetI2CAddress(AtlasEZO_HandleTypeDef *ezo, uint8_t new_address) {
    char cmd[16];
    snprintf(cmd, sizeof(cmd), "I2C,%d", new_address);

    if (!AtlasEZO_SendAndWait(ezo, cmd, 300)) {
        return false;
    }

    ezo->address = new_address;
    return true;
}

/**
 * Put device to sleep
 */
bool AtlasEZO_Sleep(AtlasEZO_HandleTypeDef *ezo) {
    return AtlasEZO_SendCommand(ezo, "SLEEP");
}

/**
 * Wake device from sleep (any command wakes it)
 */
bool AtlasEZO_Wake(AtlasEZO_HandleTypeDef *ezo) {
    // Send any command to wake - we'll use a simple read
    uint8_t dummy;
    HAL_I2C_Master_Receive(ezo->hi2c, ezo->address << 1, &dummy, 1, 100);
    HAL_Delay(10);
    return true;
}

/**
 * Set LED state
 */
bool AtlasEZO_SetLED(AtlasEZO_HandleTypeDef *ezo, bool on) {
    return AtlasEZO_SendAndWait(ezo, on ? "L,1" : "L,0", 300);
}

/**
 * Get LED state
 */
bool AtlasEZO_GetLED(AtlasEZO_HandleTypeDef *ezo, bool *on) {
    if (!AtlasEZO_SendAndWait(ezo, "L,?", 300)) {
        return false;
    }

    // Response: ?L,1 or ?L,0
    char *ptr = strchr(ezo->response, ',');
    if (ptr) {
        *on = (*(ptr + 1) == '1');
        return true;
    }
    return false;
}

/**
 * Factory reset
 */
bool AtlasEZO_FactoryReset(AtlasEZO_HandleTypeDef *ezo) {
    return AtlasEZO_SendAndWait(ezo, "FACTORY", 300);
}

/**
 * Trigger a reading
 */
bool AtlasEZO_TriggerReading(AtlasEZO_HandleTypeDef *ezo) {
    return AtlasEZO_SendCommand(ezo, "R");
}

/**
 * Read and parse value
 */
bool AtlasEZO_ReadValue(AtlasEZO_HandleTypeDef *ezo) {
    // Trigger reading
    if (!AtlasEZO_SendCommand(ezo, "R")) {
        return false;
    }

    // Wait for reading to complete (900ms is typical max)
    HAL_Delay(900);

    // Read response
    if (!AtlasEZO_ReadResponse(ezo)) {
        return false;
    }

    // Parse the value
    return AtlasEZO_ParseResponse(ezo);
}

/**
 * Set temperature compensation
 */
bool AtlasEZO_SetTemperature(AtlasEZO_HandleTypeDef *ezo, int16_t temp_x100) {
    char cmd[16];
    snprintf(cmd, sizeof(cmd), "T,%d.%02d", temp_x100 / 100, abs(temp_x100 % 100));
    return AtlasEZO_SendAndWait(ezo, cmd, 300);
}

/**
 * Get temperature compensation value
 */
bool AtlasEZO_GetTemperature(AtlasEZO_HandleTypeDef *ezo, int16_t *temp_x100) {
    if (!AtlasEZO_SendAndWait(ezo, "T,?", 300)) {
        return false;
    }

    // Response: ?T,25.00
    char *ptr = strchr(ezo->response, ',');
    if (ptr) {
        *temp_x100 = (int16_t)(AtlasEZO_ParseFloat_x1000(ptr + 1) / 10);
        return true;
    }
    return false;
}

/* ==================== pH Specific Functions ==================== */

/**
 * pH mid-point calibration (usually pH 7)
 */
bool AtlasEZO_pH_CalMid(AtlasEZO_HandleTypeDef *ezo, uint16_t ph_x100) {
    char cmd[16];
    snprintf(cmd, sizeof(cmd), "CAL,MID,%d.%02d", ph_x100 / 100, ph_x100 % 100);
    return AtlasEZO_SendAndWait(ezo, cmd, 900);
}

/**
 * pH low-point calibration (usually pH 4)
 */
bool AtlasEZO_pH_CalLow(AtlasEZO_HandleTypeDef *ezo, uint16_t ph_x100) {
    char cmd[16];
    snprintf(cmd, sizeof(cmd), "CAL,LOW,%d.%02d", ph_x100 / 100, ph_x100 % 100);
    return AtlasEZO_SendAndWait(ezo, cmd, 900);
}

/**
 * pH high-point calibration (usually pH 10)
 */
bool AtlasEZO_pH_CalHigh(AtlasEZO_HandleTypeDef *ezo, uint16_t ph_x100) {
    char cmd[16];
    snprintf(cmd, sizeof(cmd), "CAL,HIGH,%d.%02d", ph_x100 / 100, ph_x100 % 100);
    return AtlasEZO_SendAndWait(ezo, cmd, 900);
}

/**
 * Clear pH calibration
 */
bool AtlasEZO_pH_CalClear(AtlasEZO_HandleTypeDef *ezo) {
    return AtlasEZO_SendAndWait(ezo, "CAL,CLEAR", 300);
}

/**
 * Query pH calibration status
 */
bool AtlasEZO_pH_CalQuery(AtlasEZO_HandleTypeDef *ezo, uint8_t *cal_points) {
    if (!AtlasEZO_SendAndWait(ezo, "CAL,?", 300)) {
        return false;
    }

    // Response: ?CAL,0 or ?CAL,1 or ?CAL,2 or ?CAL,3
    char *ptr = strchr(ezo->response, ',');
    if (ptr) {
        *cal_points = (uint8_t)atoi(ptr + 1);
        return true;
    }
    return false;
}

/**
 * Get pH slope information
 */
bool AtlasEZO_pH_GetSlope(AtlasEZO_HandleTypeDef *ezo, int16_t *acid_slope, int16_t *base_slope, int16_t *zero_point) {
    if (!AtlasEZO_SendAndWait(ezo, "SLOPE,?", 300)) {
        return false;
    }

    // Response: ?SLOPE,99.7,100.3,-0.89
    char *ptr = strchr(ezo->response, ',');
    if (ptr) {
        *acid_slope = (int16_t)(AtlasEZO_ParseFloat_x1000(ptr + 1) / 10);
        ptr = strchr(ptr + 1, ',');
        if (ptr) {
            *base_slope = (int16_t)(AtlasEZO_ParseFloat_x1000(ptr + 1) / 10);
            ptr = strchr(ptr + 1, ',');
            if (ptr) {
                *zero_point = (int16_t)(AtlasEZO_ParseFloat_x1000(ptr + 1) / 10);
                return true;
            }
        }
    }
    return false;
}

/**
 * Get pH value * 1000
 */
int32_t AtlasEZO_pH_GetValue_x1000(AtlasEZO_HandleTypeDef *ezo) {
    return ezo->value.ph_x1000;
}

/**
 * Get pH value * 100
 */
uint16_t AtlasEZO_pH_GetValue_x100(AtlasEZO_HandleTypeDef *ezo) {
    return (uint16_t)(ezo->value.ph_x1000 / 10);
}

/* ==================== EC Specific Functions ==================== */

/**
 * Set EC probe type (K value)
 */
bool AtlasEZO_EC_SetProbeType(AtlasEZO_HandleTypeDef *ezo, uint16_t k_x100) {
    char cmd[16];
    snprintf(cmd, sizeof(cmd), "K,%d.%02d", k_x100 / 100, k_x100 % 100);
    return AtlasEZO_SendAndWait(ezo, cmd, 300);
}

/**
 * Get EC probe type
 */
bool AtlasEZO_EC_GetProbeType(AtlasEZO_HandleTypeDef *ezo, uint16_t *k_x100) {
    if (!AtlasEZO_SendAndWait(ezo, "K,?", 300)) {
        return false;
    }

    char *ptr = strchr(ezo->response, ',');
    if (ptr) {
        *k_x100 = (uint16_t)(AtlasEZO_ParseFloat_x1000(ptr + 1) / 10);
        return true;
    }
    return false;
}

/**
 * EC dry calibration
 */
bool AtlasEZO_EC_CalDry(AtlasEZO_HandleTypeDef *ezo) {
    return AtlasEZO_SendAndWait(ezo, "CAL,DRY", 900);
}

/**
 * EC single-point calibration
 */
bool AtlasEZO_EC_CalSingle(AtlasEZO_HandleTypeDef *ezo, uint32_t value_us) {
    char cmd[20];
    snprintf(cmd, sizeof(cmd), "CAL,%lu", (unsigned long)value_us);
    return AtlasEZO_SendAndWait(ezo, cmd, 900);
}

/**
 * EC low-point calibration
 */
bool AtlasEZO_EC_CalLow(AtlasEZO_HandleTypeDef *ezo, uint32_t value_us) {
    char cmd[20];
    snprintf(cmd, sizeof(cmd), "CAL,LOW,%lu", (unsigned long)value_us);
    return AtlasEZO_SendAndWait(ezo, cmd, 900);
}

/**
 * EC high-point calibration
 */
bool AtlasEZO_EC_CalHigh(AtlasEZO_HandleTypeDef *ezo, uint32_t value_us) {
    char cmd[20];
    snprintf(cmd, sizeof(cmd), "CAL,HIGH,%lu", (unsigned long)value_us);
    return AtlasEZO_SendAndWait(ezo, cmd, 900);
}

/**
 * Clear EC calibration
 */
bool AtlasEZO_EC_CalClear(AtlasEZO_HandleTypeDef *ezo) {
    return AtlasEZO_SendAndWait(ezo, "CAL,CLEAR", 300);
}

/**
 * Query EC calibration status
 */
bool AtlasEZO_EC_CalQuery(AtlasEZO_HandleTypeDef *ezo, uint8_t *cal_points) {
    if (!AtlasEZO_SendAndWait(ezo, "CAL,?", 300)) {
        return false;
    }

    char *ptr = strchr(ezo->response, ',');
    if (ptr) {
        *cal_points = (uint8_t)atoi(ptr + 1);
        return true;
    }
    return false;
}

/**
 * Set EC output parameters
 */
bool AtlasEZO_EC_SetOutput(AtlasEZO_HandleTypeDef *ezo, bool ec, bool tds, bool sal, bool sg) {
    char cmd[20];
    snprintf(cmd, sizeof(cmd), "O,EC,%d", ec ? 1 : 0);
    if (!AtlasEZO_SendAndWait(ezo, cmd, 300)) return false;

    snprintf(cmd, sizeof(cmd), "O,TDS,%d", tds ? 1 : 0);
    if (!AtlasEZO_SendAndWait(ezo, cmd, 300)) return false;

    snprintf(cmd, sizeof(cmd), "O,S,%d", sal ? 1 : 0);
    if (!AtlasEZO_SendAndWait(ezo, cmd, 300)) return false;

    snprintf(cmd, sizeof(cmd), "O,SG,%d", sg ? 1 : 0);
    if (!AtlasEZO_SendAndWait(ezo, cmd, 300)) return false;

    return true;
}

/**
 * Get EC value in µS/cm
 */
int32_t AtlasEZO_EC_GetEC(AtlasEZO_HandleTypeDef *ezo) {
    return ezo->value.ec_us_cm;
}

/**
 * Get TDS value in ppm
 */
uint32_t AtlasEZO_EC_GetTDS(AtlasEZO_HandleTypeDef *ezo) {
    return ezo->tds_ppm;
}

/**
 * Get salinity in ppt * 100
 */
uint32_t AtlasEZO_EC_GetSalinity_x100(AtlasEZO_HandleTypeDef *ezo) {
    return ezo->salinity_ppt_x100;
}

/**
 * Get specific gravity * 1000
 */
uint32_t AtlasEZO_EC_GetSG_x1000(AtlasEZO_HandleTypeDef *ezo) {
    return ezo->specific_gravity_x1000;
}
