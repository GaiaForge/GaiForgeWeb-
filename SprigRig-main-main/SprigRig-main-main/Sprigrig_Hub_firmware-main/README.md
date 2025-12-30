# SprigRig Sensor Hub Firmware

STM32G431CBT6 firmware for the SprigRig Sensor Hub.

## Features

- Modbus RTU slave (9600 baud, 8N1)
- 2x 4-20mA analog inputs
- 2x 0-10V analog inputs
- 2x 0-10V analog outputs (for fan speed, LED dimming)
- 4x Digital inputs (for float switches, etc.)
- 2x I2C ports for environmental sensors
- 1x SPI port (expansion)
- DIP switch address selection (1-16)

## Supported I2C Sensors

| Sensor | Type | I2C Address | Driver |
|--------|------|-------------|--------|
| BME280 | Temp/Humidity/Pressure | 0x76, 0x77 | `bme280.c` |
| BME680 | Temp/Humidity/Pressure/Gas (VOC) | 0x76, 0x77 | `bme680.c` |
| BH1750 | Light (Lux) | 0x23, 0x5C | `bh1750.c` |
| SCD40 | CO2/Temp/Humidity | 0x62 | `scd40.c` |
| Atlas EZO-pH | pH | 0x63 (default) | `atlas_ezo.c` |
| Atlas EZO-EC | Electrical Conductivity | 0x64 (default) | `atlas_ezo.c` |

## DIP Switch Address Configuration

The 4-position DIP switch sets the Modbus slave address (1-16). Each hub on the RS485 bus must have a unique address.

Switches are active when in the ON position (towards the switch number).

| SW1 | SW2 | SW3 | SW4 | Binary | Address |
|-----|-----|-----|-----|--------|---------|
| OFF | OFF | OFF | OFF | 0000   | 1 |
| ON  | OFF | OFF | OFF | 0001   | 2 |
| OFF | ON  | OFF | OFF | 0010   | 3 |
| ON  | ON  | OFF | OFF | 0011   | 4 |
| OFF | OFF | ON  | OFF | 0100   | 5 |
| ON  | OFF | ON  | OFF | 0101   | 6 |
| OFF | ON  | ON  | OFF | 0110   | 7 |
| ON  | ON  | ON  | OFF | 0111   | 8 |
| OFF | OFF | OFF | ON  | 1000   | 9 |
| ON  | OFF | OFF | ON  | 1001   | 10 |
| OFF | ON  | OFF | ON  | 1010   | 11 |
| ON  | ON  | OFF | ON  | 1011   | 12 |
| OFF | OFF | ON  | ON  | 1100   | 13 |
| ON  | OFF | ON  | ON  | 1101   | 14 |
| OFF | ON  | ON  | ON  | 1110   | 15 |
| ON  | ON  | ON  | ON  | 1111   | 16 |

**Formula:** Address = SW1×1 + SW2×2 + SW3×4 + SW4×8 + 1

## Register Map

| Register | Description | Access | Units |
|----------|-------------|--------|-------|
| 0 | Channel 1 - 4-20mA Input 1 | R | Raw ADC (0-4095) |
| 1 | Channel 2 - 4-20mA Input 2 | R | Raw ADC (0-4095) |
| 2 | Channel 3 - 0-10V Input 1 | R | Raw ADC (0-4095) |
| 3 | Channel 4 - 0-10V Input 2 | R | Raw ADC (0-4095) |
| 4 | Channel 5 - BME280 #1 Temperature | R | °C × 100 (2350 = 23.50°C) |
| 5 | Channel 6 - BME280 #1 Humidity | R | %RH × 100 (5000 = 50.00%) |
| 6 | Channel 7 - BME280 #2 Temperature | R | °C × 100 |
| 7 | Channel 8 - BME280 #2 Humidity | R | %RH × 100 |
| 8 | Digital Inputs | R | Bitmask (DI1-DI4) |
| 9 | Hub ID | R | 0x5248 ("RH") |
| 10 | Firmware Version | R | Major.Minor |
| 11 | Analog Output 1 (0-10V) | R/W | DAC value (0-4095) |
| 12 | Analog Output 2 (0-10V) | R/W | DAC value (0-4095) |

## I2C Sensor Details

The firmware supports multiple I2C sensors on both I2C ports:
- **I2C1** (PB6/PB7): Primary sensor bus
- **I2C2** (PA8/PA9): Secondary sensor bus

### BME280 / BME680 (Environmental)

Temperature, humidity, and pressure sensors. BME680 adds gas/VOC sensing.

```
BME280/680    Hub I2C Port
----------    ------------
VCC     →     3.3V
GND     →     GND
SCL     →     SCL
SDA     →     SDA
SDO     →     GND (0x76) or VCC (0x77)
CSB     →     VCC (I2C mode)
```

**BME680 Gas Sensor:** Returns gas resistance in Ohms. Higher resistance = cleaner air. Typical baseline ~50-200kΩ in clean air.

### BH1750 (Light Sensor)

Digital ambient light sensor with 1-65535 lux range.

```
BH1750        Hub I2C Port
------        ------------
VCC     →     3.3V
GND     →     GND
SCL     →     SCL
SDA     →     SDA
ADDR    →     GND (0x23) or VCC (0x5C)
```

### SCD40 (CO2 Sensor)

Photoacoustic NDIR CO2 sensor with temperature and humidity.

```
SCD40         Hub I2C Port
-----         ------------
VCC     →     3.3V
GND     →     GND
SCL     →     SCL
SDA     →     SDA
```

**Measurement:** 5-second interval in periodic mode. CO2 range: 400-5000 ppm.

### Atlas Scientific EZO (pH / EC)

Industrial-grade water quality sensors for hydroponics and aquaponics.

```
EZO Circuit   Hub I2C Port
-----------   ------------
VCC     →     3.3V (or 5V)
GND     →     GND
SCL     →     SCL (via level shifter if 5V)
SDA     →     SDA (via level shifter if 5V)
```

**I2C Mode:** EZO circuits ship in UART mode. To switch to I2C:
1. Disconnect VCC
2. Short TX to GND (for pH) or PGND (for EC)
3. Reconnect VCC
4. Wait for LED to turn blue
5. Remove short

**Default Addresses:** pH=0x63, EC=0x64, ORP=0x62, DO=0x61

**Calibration:** Use `AtlasEZO_pH_CalMid()`, `AtlasEZO_pH_CalLow()`, `AtlasEZO_pH_CalHigh()` for pH. Use `AtlasEZO_EC_CalDry()`, `AtlasEZO_EC_CalLow()`, `AtlasEZO_EC_CalHigh()` for EC.

## ADC Conversion

### 4-20mA (with 150Ω shunt)
```
Current (mA) = (ADC_Value - 745) * 16 / 2978 + 4
```

### 0-10V (with 22k/10k divider)
```
Voltage (V) = ADC_Value * 10 / 3878
```

## Analog Outputs (0-10V)

The hub has 2 analog outputs for controlling devices like:
- Variable speed fans (AC Infinity, inline fans)
- LED dimming (Mars Hydro, HLG)
- Motorized dampers
- Variable speed pumps

### Circuit
- STM32 DAC (0-3.3V) → Op-amp (gain 3x) → 0-10V output
- Op-amp: MCP6002 powered by 12V rail
- Resistors: 10kΩ input, 20kΩ feedback (gain = 1 + 20k/10k = 3)

### Control via Modbus
Write to register 11 or 12 using Function 0x06 (Write Single Register):
```
Value = (desired_voltage / 10.0) * 4095
```

Examples:
| Voltage | DAC Value |
|---------|-----------|
| 0V | 0 |
| 2.5V | 1024 |
| 5V | 2048 |
| 7.5V | 3072 |
| 10V | 4095 |

For percentage control (0-100%):
```
Value = (percent / 100.0) * 4095
```

## Building

### Option 1: STM32CubeIDE
1. Import project into STM32CubeIDE
2. Build and flash

### Option 2: Command Line (ARM GCC)
```bash
make
```

### Option 3: PlatformIO
```bash
pio run
pio run --target upload
```

## Flashing

Connect ST-Link to SWD header:
- Pin 1: 3.3V
- Pin 2: SWDIO (PA13)
- Pin 3: SWCLK (PA14)
- Pin 4: GND

```bash
# Using st-flash
st-flash write build/firmware.bin 0x8000000

# Using OpenOCD
openocd -f interface/stlink.cfg -f target/stm32g4x.cfg -c "program build/firmware.elf verify reset exit"
```

## Pin Assignments

| Function | Pin | STM32 Pin |
|----------|-----|-----------|
| RS485 TX | PA2 | USART2_TX |
| RS485 RX | PA3 | USART2_RX |
| RS485 DE/RE | PA1 | GPIO |
| 4-20mA #1 | PA0 | ADC1_IN1 |
| 4-20mA #2 | PB0 | ADC1_IN15 |
| 0-10V In #1 | PB1 | ADC1_IN12 |
| 0-10V In #2 | PB2 | ADC1_IN11 |
| 0-10V Out #1 | PA4 | DAC1_OUT1 |
| 0-10V Out #2 | PA5 | DAC1_OUT2 |
| I2C1 SCL | PB6 | I2C1_SCL |
| I2C1 SDA | PB7 | I2C1_SDA |
| I2C2 SCL | PA9 | I2C2_SCL |
| I2C2 SDA | PA8 | I2C2_SDA |
| SPI2 SCK | PB13 | SPI2_SCK |
| SPI2 MISO | PB14 | SPI2_MISO |
| SPI2 MOSI | PB15 | SPI2_MOSI |
| SPI2 CS | PB12 | GPIO |
| DI1 | PC13 | GPIO |
| DI2 | PC14 | GPIO |
| DI3 | PC15 | GPIO |
| DI4 | PA10 | GPIO |
| DIP SW1 | PA11 | GPIO |
| DIP SW2 | PA12 | GPIO |
| DIP SW3 | PA15 | GPIO |
| DIP SW4 | PB3 | GPIO |
| SWDIO | PA13 | SWD |
| SWCLK | PA14 | SWD |

## Driver Files

```
Core/
├── Inc/
│   ├── main.h          # Pin definitions and register map
│   ├── sensor_hub.h    # Main application header
│   ├── modbus.h        # Modbus RTU protocol
│   ├── bme280.h        # BME280 temp/humidity/pressure
│   ├── bme680.h        # BME680 temp/humidity/pressure/gas
│   ├── bh1750.h        # BH1750 light sensor
│   ├── scd40.h         # SCD40 CO2 sensor
│   └── atlas_ezo.h     # Atlas EZO pH/EC sensors
└── Src/
    ├── main.c          # Main entry point
    ├── sensor_hub.c    # Sensor reading and register management
    ├── modbus.c        # Modbus RTU implementation
    ├── bme280.c        # BME280 driver
    ├── bme680.c        # BME680 driver
    ├── bh1750.c        # BH1750 driver
    ├── scd40.c         # SCD40 driver
    └── atlas_ezo.c     # Atlas EZO driver (pH and EC)
```

## Example Usage

```c
#include "bme680.h"
#include "bh1750.h"
#include "scd40.h"
#include "atlas_ezo.h"

// Sensor handles
BME680_HandleTypeDef bme680;
BH1750_HandleTypeDef light;
SCD40_HandleTypeDef co2;
AtlasEZO_HandleTypeDef ph;
AtlasEZO_HandleTypeDef ec;

void sensors_init(void) {
    // Environmental sensor
    BME680_Init(&bme680, &hi2c1, BME680_ADDR_LOW);

    // Light sensor
    BH1750_Init(&light, &hi2c1, BH1750_ADDR_LOW);

    // CO2 sensor
    SCD40_Init(&co2, &hi2c1);
    SCD40_StartPeriodicMeasurement(&co2);

    // Water quality sensors
    AtlasEZO_Init(&ph, &hi2c2, ATLAS_EZO_PH_ADDR, ATLAS_EZO_TYPE_PH);
    AtlasEZO_Init(&ec, &hi2c2, ATLAS_EZO_EC_ADDR, ATLAS_EZO_TYPE_EC);
}

void sensors_read(void) {
    // BME680
    BME680_TriggerMeasurement(&bme680, true);
    HAL_Delay(200);
    BME680_ReadAll(&bme680);
    int16_t temp = BME680_GetTemperature_x100(&bme680);  // °C * 100
    uint16_t hum = BME680_GetHumidity_x100(&bme680);     // %RH * 100
    uint32_t gas = BME680_GetGasResistance(&bme680);    // Ohms

    // Light
    BH1750_ReadLight(&light);
    uint16_t lux = BH1750_GetLux(&light);

    // CO2
    if (SCD40_IsDataReady(&co2)) {
        SCD40_ReadMeasurement(&co2);
        uint16_t ppm = SCD40_GetCO2(&co2);
    }

    // pH
    AtlasEZO_ReadValue(&ph);
    uint16_t ph_x100 = AtlasEZO_pH_GetValue_x100(&ph);  // pH * 100

    // EC
    AtlasEZO_ReadValue(&ec);
    int32_t ec_us = AtlasEZO_EC_GetEC(&ec);  // µS/cm
}
```

## License

MIT
