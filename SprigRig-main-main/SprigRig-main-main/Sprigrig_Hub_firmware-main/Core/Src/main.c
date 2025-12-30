/**
 * SprigRig Sensor Hub Firmware
 * STM32G431CBT6
 *
 * Main application entry point
 */

#include "main.h"
#include "modbus.h"
#include "sensor_hub.h"

/* Private variables */
ADC_HandleTypeDef hadc1;
DAC_HandleTypeDef hdac1;
I2C_HandleTypeDef hi2c1;
I2C_HandleTypeDef hi2c2;
SPI_HandleTypeDef hspi2;
UART_HandleTypeDef huart2;

Modbus_HandleTypeDef modbus;

/* Private function prototypes */
static void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_ADC1_Init(void);
static void MX_DAC1_Init(void);
static void MX_I2C1_Init(void);
static void MX_I2C2_Init(void);
static void MX_SPI2_Init(void);
static void MX_USART2_UART_Init(void);

/**
 * Main entry point
 */
int main(void) {
    /* MCU Configuration */
    HAL_Init();
    SystemClock_Config();

    /* Initialize peripherals */
    MX_GPIO_Init();
    MX_ADC1_Init();
    MX_DAC1_Init();
    MX_I2C1_Init();
    MX_I2C2_Init();
    MX_SPI2_Init();
    MX_USART2_UART_Init();

    /* Initialize Sensor Hub */
    SensorHub_Config_t hub_config = {
        .hadc = &hadc1,
        .hdac = &hdac1,
        .hi2c1 = &hi2c1,
        .hi2c2 = &hi2c2,
        .hspi2 = &hspi2
    };
    SensorHub_Init(&hub_config);

    /* Read Modbus address from DIP switches */
    uint8_t modbus_address = SensorHub_ReadAddress();

    /* Initialize Modbus slave */
    Modbus_Init(&modbus, &huart2,
                RS485_DE_PORT, RS485_DE_PIN,
                modbus_address,
                SensorHub_GetRegisters(),
                SensorHub_GetRegisterCount());

    /* Register write callback for analog outputs */
    Modbus_SetWriteCallback(&modbus, SensorHub_OnRegisterWrite);

    /* Main loop */
    uint32_t last_update = 0;

    while (1) {
        /* Poll Modbus for incoming requests */
        Modbus_Poll(&modbus);

        /* Update sensor readings every 100ms */
        uint32_t now = HAL_GetTick();
        if (now - last_update >= 100) {
            last_update = now;
            SensorHub_Update();
        }
    }
}

/**
 * System Clock Configuration
 * Configure for 170MHz using HSI
 */
static void SystemClock_Config(void) {
    RCC_OscInitTypeDef RCC_OscInitStruct = {0};
    RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

    /* Configure the main internal regulator output voltage */
    HAL_PWREx_ControlVoltageScaling(PWR_REGULATOR_VOLTAGE_SCALE1_BOOST);

    /* Initializes the RCC Oscillators */
    RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
    RCC_OscInitStruct.HSIState = RCC_HSI_ON;
    RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
    RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
    RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
    RCC_OscInitStruct.PLL.PLLM = RCC_PLLM_DIV4;
    RCC_OscInitStruct.PLL.PLLN = 85;
    RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
    RCC_OscInitStruct.PLL.PLLQ = RCC_PLLQ_DIV2;
    RCC_OscInitStruct.PLL.PLLR = RCC_PLLR_DIV2;

    if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) {
        Error_Handler();
    }

    /* Initializes the CPU, AHB and APB buses clocks */
    RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK |
                                  RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
    RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
    RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
    RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
    RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

    if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_4) != HAL_OK) {
        Error_Handler();
    }
}

/**
 * GPIO Initialization
 */
static void MX_GPIO_Init(void) {
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    /* GPIO Ports Clock Enable */
    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();
    __HAL_RCC_GPIOC_CLK_ENABLE();

    /* Configure RS485 DE/RE pin */
    GPIO_InitStruct.Pin = RS485_DE_PIN;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(RS485_DE_PORT, &GPIO_InitStruct);
    HAL_GPIO_WritePin(RS485_DE_PORT, RS485_DE_PIN, GPIO_PIN_RESET); // Start in RX mode

    /* Configure DIP Switch pins (inputs with pull-up) */
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_PULLUP;

    GPIO_InitStruct.Pin = DIP_SW1_PIN;
    HAL_GPIO_Init(DIP_SW1_PORT, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = DIP_SW2_PIN;
    HAL_GPIO_Init(DIP_SW2_PORT, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = DIP_SW3_PIN;
    HAL_GPIO_Init(DIP_SW3_PORT, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = DIP_SW4_PIN;
    HAL_GPIO_Init(DIP_SW4_PORT, &GPIO_InitStruct);

    /* Configure Digital Input pins (inputs with pull-up) */
    GPIO_InitStruct.Pin = DI1_PIN;
    HAL_GPIO_Init(DI1_PORT, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = DI2_PIN;
    HAL_GPIO_Init(DI2_PORT, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = DI3_PIN;
    HAL_GPIO_Init(DI3_PORT, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = DI4_PIN;
    HAL_GPIO_Init(DI4_PORT, &GPIO_InitStruct);
}

/**
 * ADC1 Initialization
 */
static void MX_ADC1_Init(void) {
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    __HAL_RCC_ADC12_CLK_ENABLE();

    /* Configure ADC GPIO pins */
    // PA0 - ADC1_IN1 (4-20mA #1)
    // PB0 - ADC1_IN15 (4-20mA #2)
    // PB1 - ADC1_IN12 (0-10V #1)
    // PB2 - ADC1_IN11 (0-10V #2)

    GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
    GPIO_InitStruct.Pull = GPIO_NOPULL;

    GPIO_InitStruct.Pin = GPIO_PIN_0;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    /* Configure ADC */
    hadc1.Instance = ADC1;
    hadc1.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV4;
    hadc1.Init.Resolution = ADC_RESOLUTION_12B;
    hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
    hadc1.Init.GainCompensation = 0;
    hadc1.Init.ScanConvMode = ADC_SCAN_DISABLE;
    hadc1.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
    hadc1.Init.LowPowerAutoWait = DISABLE;
    hadc1.Init.ContinuousConvMode = DISABLE;
    hadc1.Init.NbrOfConversion = 1;
    hadc1.Init.DiscontinuousConvMode = DISABLE;
    hadc1.Init.ExternalTrigConv = ADC_SOFTWARE_START;
    hadc1.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
    hadc1.Init.DMAContinuousRequests = DISABLE;
    hadc1.Init.Overrun = ADC_OVR_DATA_OVERWRITTEN;
    hadc1.Init.OversamplingMode = DISABLE;

    if (HAL_ADC_Init(&hadc1) != HAL_OK) {
        Error_Handler();
    }
}

/**
 * I2C1 Initialization (PB6=SCL, PB7=SDA)
 */
static void MX_I2C1_Init(void) {
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    __HAL_RCC_I2C1_CLK_ENABLE();

    /* Configure I2C1 GPIO pins */
    GPIO_InitStruct.Pin = GPIO_PIN_6 | GPIO_PIN_7;
    GPIO_InitStruct.Mode = GPIO_MODE_AF_OD;
    GPIO_InitStruct.Pull = GPIO_NOPULL; // External pull-ups on board
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    GPIO_InitStruct.Alternate = GPIO_AF4_I2C1;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    /* Configure I2C1 */
    hi2c1.Instance = I2C1;
    hi2c1.Init.Timing = 0x30A0A7FB; // 100kHz @ 170MHz
    hi2c1.Init.OwnAddress1 = 0;
    hi2c1.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
    hi2c1.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
    hi2c1.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
    hi2c1.Init.NoStretchMode = I2C_NOSTRETCH_DISABLE;

    if (HAL_I2C_Init(&hi2c1) != HAL_OK) {
        Error_Handler();
    }
}

/**
 * I2C2 Initialization (PA8=SDA, PA9=SCL)
 */
static void MX_I2C2_Init(void) {
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    __HAL_RCC_I2C2_CLK_ENABLE();

    /* Configure I2C2 GPIO pins */
    GPIO_InitStruct.Pin = GPIO_PIN_8 | GPIO_PIN_9;
    GPIO_InitStruct.Mode = GPIO_MODE_AF_OD;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    GPIO_InitStruct.Alternate = GPIO_AF4_I2C2;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    /* Configure I2C2 */
    hi2c2.Instance = I2C2;
    hi2c2.Init.Timing = 0x30A0A7FB;
    hi2c2.Init.OwnAddress1 = 0;
    hi2c2.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
    hi2c2.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
    hi2c2.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
    hi2c2.Init.NoStretchMode = I2C_NOSTRETCH_DISABLE;

    if (HAL_I2C_Init(&hi2c2) != HAL_OK) {
        Error_Handler();
    }
}

/**
 * DAC1 Initialization (PA4=OUT1, PA5=OUT2)
 * Used for 0-10V analog outputs
 */
static void MX_DAC1_Init(void) {
    GPIO_InitTypeDef GPIO_InitStruct = {0};
    DAC_ChannelConfTypeDef sConfig = {0};

    __HAL_RCC_DAC1_CLK_ENABLE();

    /* Configure DAC GPIO pins as analog */
    GPIO_InitStruct.Pin = GPIO_PIN_4 | GPIO_PIN_5;
    GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    /* Configure DAC */
    hdac1.Instance = DAC1;
    if (HAL_DAC_Init(&hdac1) != HAL_OK) {
        Error_Handler();
    }

    /* Configure DAC channel 1 (PA4) */
    sConfig.DAC_HighFrequency = DAC_HIGH_FREQUENCY_INTERFACE_MODE_AUTOMATIC;
    sConfig.DAC_DMADoubleDataMode = DISABLE;
    sConfig.DAC_SignedFormat = DISABLE;
    sConfig.DAC_SampleAndHold = DAC_SAMPLEANDHOLD_DISABLE;
    sConfig.DAC_Trigger = DAC_TRIGGER_NONE;
    sConfig.DAC_OutputBuffer = DAC_OUTPUTBUFFER_ENABLE;
    sConfig.DAC_ConnectOnChipPeripheral = DAC_CHIPCONNECT_EXTERNAL;
    sConfig.DAC_UserTrimming = DAC_TRIMMING_FACTORY;

    if (HAL_DAC_ConfigChannel(&hdac1, &sConfig, DAC_CHANNEL_1) != HAL_OK) {
        Error_Handler();
    }

    /* Configure DAC channel 2 (PA5) */
    if (HAL_DAC_ConfigChannel(&hdac1, &sConfig, DAC_CHANNEL_2) != HAL_OK) {
        Error_Handler();
    }

    /* Start DAC channels */
    HAL_DAC_Start(&hdac1, DAC_CHANNEL_1);
    HAL_DAC_Start(&hdac1, DAC_CHANNEL_2);

    /* Set initial output to 0V */
    HAL_DAC_SetValue(&hdac1, DAC_CHANNEL_1, DAC_ALIGN_12B_R, 0);
    HAL_DAC_SetValue(&hdac1, DAC_CHANNEL_2, DAC_ALIGN_12B_R, 0);
}

/**
 * SPI2 Initialization
 */
static void MX_SPI2_Init(void) {
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    __HAL_RCC_SPI2_CLK_ENABLE();

    /* Configure SPI2 GPIO pins */
    // PB13 = SCK, PB14 = MISO, PB15 = MOSI, PB12 = CS (manual)
    GPIO_InitStruct.Pin = GPIO_PIN_13 | GPIO_PIN_14 | GPIO_PIN_15;
    GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    GPIO_InitStruct.Alternate = GPIO_AF5_SPI2;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    // CS pin as GPIO output
    GPIO_InitStruct.Pin = GPIO_PIN_12;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
    HAL_GPIO_WritePin(GPIOB, GPIO_PIN_12, GPIO_PIN_SET);

    /* Configure SPI2 */
    hspi2.Instance = SPI2;
    hspi2.Init.Mode = SPI_MODE_MASTER;
    hspi2.Init.Direction = SPI_DIRECTION_2LINES;
    hspi2.Init.DataSize = SPI_DATASIZE_8BIT;
    hspi2.Init.CLKPolarity = SPI_POLARITY_LOW;
    hspi2.Init.CLKPhase = SPI_PHASE_1EDGE;
    hspi2.Init.NSS = SPI_NSS_SOFT;
    hspi2.Init.BaudRatePrescaler = SPI_BAUDRATEPRESCALER_32;
    hspi2.Init.FirstBit = SPI_FIRSTBIT_MSB;
    hspi2.Init.TIMode = SPI_TIMODE_DISABLE;
    hspi2.Init.CRCCalculation = SPI_CRCCALCULATION_DISABLE;

    if (HAL_SPI_Init(&hspi2) != HAL_OK) {
        Error_Handler();
    }
}

/**
 * USART2 Initialization (RS485 for Modbus)
 * PA2 = TX, PA3 = RX
 */
static void MX_USART2_UART_Init(void) {
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    __HAL_RCC_USART2_CLK_ENABLE();

    /* Configure USART2 GPIO pins */
    GPIO_InitStruct.Pin = GPIO_PIN_2 | GPIO_PIN_3;
    GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    GPIO_InitStruct.Alternate = GPIO_AF7_USART2;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    /* Configure USART2 */
    huart2.Instance = USART2;
    huart2.Init.BaudRate = 9600;
    huart2.Init.WordLength = UART_WORDLENGTH_8B;
    huart2.Init.StopBits = UART_STOPBITS_1;
    huart2.Init.Parity = UART_PARITY_NONE;
    huart2.Init.Mode = UART_MODE_TX_RX;
    huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
    huart2.Init.OverSampling = UART_OVERSAMPLING_16;
    huart2.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
    huart2.Init.ClockPrescaler = UART_PRESCALER_DIV1;

    if (HAL_UART_Init(&huart2) != HAL_OK) {
        Error_Handler();
    }

    /* Enable UART RX interrupt */
    HAL_NVIC_SetPriority(USART2_IRQn, 0, 0);
    HAL_NVIC_EnableIRQ(USART2_IRQn);
}

/**
 * Error Handler
 */
void Error_Handler(void) {
    __disable_irq();
    while (1) {
        // Optionally toggle an LED here
    }
}

#ifdef USE_FULL_ASSERT
void assert_failed(uint8_t *file, uint32_t line) {
    // User can add their own implementation
}
#endif
