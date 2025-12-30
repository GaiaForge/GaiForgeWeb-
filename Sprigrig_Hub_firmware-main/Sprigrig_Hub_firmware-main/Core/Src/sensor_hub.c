/**
 * Sensor Hub - Main Application Logic
 * SprigRig Sensor Hub
 */

#include "sensor_hub.h"
#include "main.h"
#include "bme280.h"

/* Private variables */
static SensorHub_Config_t *hub_config;
static uint16_t holding_registers[HOLDING_REG_COUNT];

/* I2C Sensors */
static BME280_HandleTypeDef bme280_1;
static BME280_HandleTypeDef bme280_2;
static bool bme280_1_present = false;
static bool bme280_2_present = false;

/* ADC calibration values */
// For 4-20mA with 150Ω shunt: V = I * R
// At 4mA:  V = 0.004 * 150 = 0.6V
// At 20mA: V = 0.020 * 150 = 3.0V
// ADC: 12-bit, 3.3V reference
// At 0.6V:  ADC = (0.6 / 3.3) * 4095 = 745
// At 3.0V:  ADC = (3.0 / 3.3) * 4095 = 3723

#define ADC_4MA_VALUE       745
#define ADC_20MA_VALUE      3723
#define ADC_CURRENT_SPAN    (ADC_20MA_VALUE - ADC_4MA_VALUE)

// For 0-10V with voltage divider (22k/10k):
// Vout = Vin * (10k / 32k) = Vin * 0.3125
// At 0V:  ADC = 0
// At 10V: Vout = 3.125V, ADC = (3.125 / 3.3) * 4095 = 3878

#define ADC_0V_VALUE        0
#define ADC_10V_VALUE       3878
#define ADC_VOLTAGE_SPAN    (ADC_10V_VALUE - ADC_0V_VALUE)

/* Firmware version */
#define FW_VERSION_MAJOR    1
#define FW_VERSION_MINOR    0
#define FW_VERSION          ((FW_VERSION_MAJOR << 8) | FW_VERSION_MINOR)

/**
 * Initialize Sensor Hub
 */
void SensorHub_Init(SensorHub_Config_t *config) {
    hub_config = config;

    // Clear registers
    for (int i = 0; i < HOLDING_REG_COUNT; i++) {
        holding_registers[i] = 0;
    }

    // Set static registers
    holding_registers[REG_HUB_ID] = 0x5248;  // "RH" for SpRig Hub
    holding_registers[REG_FW_VERSION] = FW_VERSION;

    // Calibrate ADC if available
    if (hub_config->hadc) {
        HAL_ADCEx_Calibration_Start(hub_config->hadc, ADC_SINGLE_ENDED);
    }

    // Initialize BME280 on I2C1 (try both addresses)
    if (hub_config->hi2c1) {
        if (BME280_Init(&bme280_1, hub_config->hi2c1, BME280_ADDR_LOW)) {
            bme280_1_present = true;
        } else if (BME280_Init(&bme280_1, hub_config->hi2c1, BME280_ADDR_HIGH)) {
            bme280_1_present = true;
        }
    }

    // Initialize BME280 on I2C2 (try both addresses)
    if (hub_config->hi2c2) {
        if (BME280_Init(&bme280_2, hub_config->hi2c2, BME280_ADDR_LOW)) {
            bme280_2_present = true;
        } else if (BME280_Init(&bme280_2, hub_config->hi2c2, BME280_ADDR_HIGH)) {
            bme280_2_present = true;
        }
    }
}

/**
 * Read Modbus address from DIP switches
 * Switches are active-low (pulled up, switch closes to GND)
 * Returns address 1-16 (binary value + 1)
 */
uint8_t SensorHub_ReadAddress(void) {
    uint8_t address = 0;

    // Read each switch (inverted because active-low)
    if (HAL_GPIO_ReadPin(DIP_SW1_PORT, DIP_SW1_PIN) == GPIO_PIN_RESET) {
        address |= 0x01;
    }
    if (HAL_GPIO_ReadPin(DIP_SW2_PORT, DIP_SW2_PIN) == GPIO_PIN_RESET) {
        address |= 0x02;
    }
    if (HAL_GPIO_ReadPin(DIP_SW3_PORT, DIP_SW3_PIN) == GPIO_PIN_RESET) {
        address |= 0x04;
    }
    if (HAL_GPIO_ReadPin(DIP_SW4_PORT, DIP_SW4_PIN) == GPIO_PIN_RESET) {
        address |= 0x08;
    }

    // Add 1 so address range is 1-16 (all OFF = 1, all ON = 16)
    return address + 1;
}

/**
 * Read digital inputs
 * Returns bitmask: bit0=DI1, bit1=DI2, bit2=DI3, bit3=DI4
 */
uint8_t SensorHub_ReadDigitalInputs(void) {
    uint8_t inputs = 0;

    // Active-low (pulled up, switch closes to GND)
    if (HAL_GPIO_ReadPin(DI1_PORT, DI1_PIN) == GPIO_PIN_RESET) {
        inputs |= 0x01;
    }
    if (HAL_GPIO_ReadPin(DI2_PORT, DI2_PIN) == GPIO_PIN_RESET) {
        inputs |= 0x02;
    }
    if (HAL_GPIO_ReadPin(DI3_PORT, DI3_PIN) == GPIO_PIN_RESET) {
        inputs |= 0x04;
    }
    if (HAL_GPIO_ReadPin(DI4_PORT, DI4_PIN) == GPIO_PIN_RESET) {
        inputs |= 0x08;
    }

    return inputs;
}

/**
 * Read ADC value for a specific channel
 */
static uint16_t SensorHub_ReadADC(uint32_t channel) {
    if (!hub_config->hadc) {
        return 0;
    }

    ADC_ChannelConfTypeDef sConfig = {0};
    sConfig.Channel = channel;
    sConfig.Rank = ADC_REGULAR_RANK_1;
    sConfig.SamplingTime = ADC_SAMPLETIME_47CYCLES_5;
    sConfig.SingleDiff = ADC_SINGLE_ENDED;
    sConfig.OffsetNumber = ADC_OFFSET_NONE;

    if (HAL_ADC_ConfigChannel(hub_config->hadc, &sConfig) != HAL_OK) {
        return 0;
    }

    HAL_ADC_Start(hub_config->hadc);
    if (HAL_ADC_PollForConversion(hub_config->hadc, 10) == HAL_OK) {
        uint16_t value = HAL_ADC_GetValue(hub_config->hadc);
        HAL_ADC_Stop(hub_config->hadc);
        return value;
    }

    HAL_ADC_Stop(hub_config->hadc);
    return 0;
}

/**
 * Read 4-20mA input
 * channel: 0 or 1
 * Returns raw ADC value (0-4095)
 */
uint16_t SensorHub_ReadADC_4_20mA(uint8_t channel) {
    uint32_t adc_channel;

    switch (channel) {
        case 0:
            adc_channel = ADC_CHANNEL_1;  // PA0
            break;
        case 1:
            adc_channel = ADC_CHANNEL_15; // PB0
            break;
        default:
            return 0;
    }

    return SensorHub_ReadADC(adc_channel);
}

/**
 * Read 0-10V input
 * channel: 0 or 1
 * Returns raw ADC value (0-4095)
 */
uint16_t SensorHub_ReadADC_0_10V(uint8_t channel) {
    uint32_t adc_channel;

    switch (channel) {
        case 0:
            adc_channel = ADC_CHANNEL_12; // PB1 - ADC1_IN12
            break;
        case 1:
            adc_channel = ADC_CHANNEL_11; // PB2 - ADC1_IN11 (Note: PB2 is ADC2_IN12, but also ADC1_IN11)
            break;
        default:
            return 0;
    }

    return SensorHub_ReadADC(adc_channel);
}

/**
 * Convert ADC value to current (mA * 100)
 * Returns current in units of 0.01mA (e.g., 400 = 4.00mA, 2000 = 20.00mA)
 */
uint16_t SensorHub_ConvertCurrent_mA_x100(uint16_t adc_value) {
    // Clamp to valid range
    if (adc_value < ADC_4MA_VALUE) {
        adc_value = ADC_4MA_VALUE;
    }
    if (adc_value > ADC_20MA_VALUE) {
        adc_value = ADC_20MA_VALUE;
    }

    // Linear interpolation: 4mA to 20mA
    // current_mA = 4 + (adc - ADC_4MA) * 16 / ADC_SPAN
    // Multiply by 100 for 0.01mA resolution
    uint32_t current_x100 = 400 + ((uint32_t)(adc_value - ADC_4MA_VALUE) * 1600) / ADC_CURRENT_SPAN;

    return (uint16_t)current_x100;
}

/**
 * Convert ADC value to voltage (mV)
 * Returns voltage in millivolts (e.g., 5000 = 5.000V)
 */
uint16_t SensorHub_ConvertVoltage_mV(uint16_t adc_value) {
    // Linear: 0V to 10V maps to 0 to ADC_10V_VALUE
    // voltage_mV = adc * 10000 / ADC_10V_VALUE
    uint32_t voltage_mv = ((uint32_t)adc_value * 10000) / ADC_10V_VALUE;

    if (voltage_mv > 10000) {
        voltage_mv = 10000;
    }

    return (uint16_t)voltage_mv;
}

/**
 * Update all sensor readings and populate Modbus registers
 * Call this periodically from main loop
 */
void SensorHub_Update(void) {
    // Channel 1-2: 4-20mA inputs (store as raw ADC or converted value)
    // For compatibility with SprigRig app, store raw 16-bit value
    // The app applies calibration on its side
    holding_registers[REG_CHANNEL_1] = SensorHub_ReadADC_4_20mA(0);
    holding_registers[REG_CHANNEL_2] = SensorHub_ReadADC_4_20mA(1);

    // Channel 3-4: 0-10V inputs
    holding_registers[REG_CHANNEL_3] = SensorHub_ReadADC_0_10V(0);
    holding_registers[REG_CHANNEL_4] = SensorHub_ReadADC_0_10V(1);

    // Channel 5-6: BME280 sensors on I2C
    // Channel 5: Temperature (°C * 100) from BME280 #1
    // Channel 6: Humidity (%RH * 100) from BME280 #1
    if (bme280_1_present) {
        if (BME280_ReadAll(&bme280_1)) {
            holding_registers[REG_CHANNEL_5] = (uint16_t)BME280_GetTemperature_x100(&bme280_1);
            holding_registers[REG_CHANNEL_6] = BME280_GetHumidity_x100(&bme280_1);
        }
    }

    // Channel 7-8: BME280 sensor #2 on I2C2
    // Channel 7: Temperature (°C * 100) from BME280 #2
    // Channel 8: Humidity (%RH * 100) from BME280 #2
    if (bme280_2_present) {
        if (BME280_ReadAll(&bme280_2)) {
            holding_registers[REG_CHANNEL_7] = (uint16_t)BME280_GetTemperature_x100(&bme280_2);
            holding_registers[REG_CHANNEL_8] = BME280_GetHumidity_x100(&bme280_2);
        }
    }

    // Digital inputs status
    holding_registers[REG_DI_STATUS] = SensorHub_ReadDigitalInputs();
}

/**
 * Get pointer to holding registers (for Modbus)
 */
uint16_t* SensorHub_GetRegisters(void) {
    return holding_registers;
}

/**
 * Get number of holding registers
 */
uint16_t SensorHub_GetRegisterCount(void) {
    return HOLDING_REG_COUNT;
}

/**
 * Set analog output value (0-10V)
 * channel: 0 or 1
 * value: 0-4095 (12-bit DAC value)
 *        0 = 0V, 4095 = 3.3V (scaled to ~10V by op-amp)
 *
 * With gain of 3 (20k/10k feedback):
 *   DAC 0    -> 0V output
 *   DAC 4095 -> 3.3V * 3 = 9.9V output
 *
 * To set specific voltage: value = (voltage_V / 10.0) * 4095
 * Or use value in 0.1% increments: value = (percent_x10 * 4095) / 1000
 */
void SensorHub_SetAnalogOutput(uint8_t channel, uint16_t value) {
    if (!hub_config->hdac) {
        return;
    }

    // Clamp to 12-bit range
    if (value > 4095) {
        value = 4095;
    }

    switch (channel) {
        case 0:
            HAL_DAC_SetValue(hub_config->hdac, DAC_CHANNEL_1, DAC_ALIGN_12B_R, value);
            break;
        case 1:
            HAL_DAC_SetValue(hub_config->hdac, DAC_CHANNEL_2, DAC_ALIGN_12B_R, value);
            break;
        default:
            break;
    }
}

/**
 * Callback for Modbus register writes
 * Called when a register value is written via Modbus
 */
void SensorHub_OnRegisterWrite(uint16_t reg_addr, uint16_t value) {
    switch (reg_addr) {
        case REG_AOUT_1:
            SensorHub_SetAnalogOutput(0, value);
            break;
        case REG_AOUT_2:
            SensorHub_SetAnalogOutput(1, value);
            break;
        default:
            // Ignore writes to other registers (read-only)
            break;
    }
}
