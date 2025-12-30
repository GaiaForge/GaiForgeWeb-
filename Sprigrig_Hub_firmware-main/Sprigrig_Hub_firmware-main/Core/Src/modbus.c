/**
 * Modbus RTU Slave Implementation
 * SprigRig Sensor Hub
 */

#include "modbus.h"
#include <string.h>

/* Private function prototypes */
static void Modbus_SetDE(Modbus_HandleTypeDef *mb, bool transmit);
static void Modbus_SendResponse(Modbus_HandleTypeDef *mb, uint16_t length);
static void Modbus_SendException(Modbus_HandleTypeDef *mb, uint8_t function, uint8_t exception);
static void Modbus_ProcessFrame(Modbus_HandleTypeDef *mb);
static void Modbus_HandleReadHoldingRegisters(Modbus_HandleTypeDef *mb);
static void Modbus_HandleWriteSingleRegister(Modbus_HandleTypeDef *mb);

/* CRC16 lookup table (Modbus polynomial 0xA001) */
static const uint16_t crc_table[256] = {
    0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,
    0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,
    0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,
    0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,
    0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40,
    0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,
    0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641,
    0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,
    0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240,
    0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,
    0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,
    0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,
    0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41,
    0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,
    0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640,
    0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,
    0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240,
    0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,
    0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41,
    0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,
    0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41,
    0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
    0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640,
    0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,
    0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241,
    0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,
    0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40,
    0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,
    0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40,
    0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,
    0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641,
    0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040
};

/**
 * Calculate CRC16 for Modbus
 */
uint16_t Modbus_CRC16(uint8_t *data, uint16_t length) {
    uint16_t crc = 0xFFFF;

    for (uint16_t i = 0; i < length; i++) {
        uint8_t index = (crc ^ data[i]) & 0xFF;
        crc = (crc >> 8) ^ crc_table[index];
    }

    return crc;
}

/**
 * Initialize Modbus slave
 */
void Modbus_Init(Modbus_HandleTypeDef *mb, UART_HandleTypeDef *huart,
                 GPIO_TypeDef *de_port, uint16_t de_pin,
                 uint8_t slave_address,
                 uint16_t *holding_regs, uint16_t reg_count) {

    mb->huart = huart;
    mb->de_port = de_port;
    mb->de_pin = de_pin;
    mb->slave_address = slave_address;
    mb->holding_registers = holding_regs;
    mb->holding_reg_count = reg_count;

    mb->rx_index = 0;
    mb->last_rx_time = 0;
    mb->frame_ready = false;
    mb->write_callback = NULL;

    // Start in receive mode
    Modbus_SetDE(mb, false);

    // Enable UART receive interrupt
    __HAL_UART_ENABLE_IT(mb->huart, UART_IT_RXNE);
}

/**
 * Set DE/RE pin state (true = transmit, false = receive)
 */
static void Modbus_SetDE(Modbus_HandleTypeDef *mb, bool transmit) {
    if (transmit) {
        HAL_GPIO_WritePin(mb->de_port, mb->de_pin, GPIO_PIN_SET);
    } else {
        HAL_GPIO_WritePin(mb->de_port, mb->de_pin, GPIO_PIN_RESET);
    }
}

/**
 * UART RX callback - call from UART IRQ handler
 */
void Modbus_RxCallback(Modbus_HandleTypeDef *mb, uint8_t data) {
    if (mb->rx_index < MODBUS_RX_BUFFER_SIZE) {
        mb->rx_buffer[mb->rx_index++] = data;
        mb->last_rx_time = HAL_GetTick();
    }
}

/**
 * Timer callback - call from SysTick or timer IRQ (every 1ms)
 */
void Modbus_TimerCallback(Modbus_HandleTypeDef *mb) {
    // Check for frame timeout (3.5 character times)
    if (mb->rx_index > 0 && !mb->frame_ready) {
        uint32_t elapsed = HAL_GetTick() - mb->last_rx_time;
        if (elapsed >= MODBUS_FRAME_TIMEOUT_MS) {
            mb->frame_ready = true;
        }
    }
}

/**
 * Main polling function - call from main loop
 */
void Modbus_Poll(Modbus_HandleTypeDef *mb) {
    if (mb->frame_ready) {
        Modbus_ProcessFrame(mb);
        mb->rx_index = 0;
        mb->frame_ready = false;
    }
}

/**
 * Process received Modbus frame
 */
static void Modbus_ProcessFrame(Modbus_HandleTypeDef *mb) {
    // Minimum frame size: Address(1) + Function(1) + CRC(2) = 4 bytes
    if (mb->rx_index < 4) {
        return;
    }

    // Check slave address (0 = broadcast, respond to our address only)
    uint8_t address = mb->rx_buffer[0];
    if (address != mb->slave_address && address != 0) {
        return;
    }

    // Verify CRC
    uint16_t received_crc = mb->rx_buffer[mb->rx_index - 2] |
                           (mb->rx_buffer[mb->rx_index - 1] << 8);
    uint16_t calculated_crc = Modbus_CRC16(mb->rx_buffer, mb->rx_index - 2);

    if (received_crc != calculated_crc) {
        return; // CRC error, ignore frame
    }

    // Process function code
    uint8_t function = mb->rx_buffer[1];

    switch (function) {
        case MODBUS_FC_READ_HOLDING_REGS:
            Modbus_HandleReadHoldingRegisters(mb);
            break;

        case MODBUS_FC_WRITE_SINGLE_REG:
            Modbus_HandleWriteSingleRegister(mb);
            break;

        default:
            // Unsupported function
            if (address != 0) { // Don't respond to broadcast
                Modbus_SendException(mb, function, MODBUS_EX_ILLEGAL_FUNCTION);
            }
            break;
    }
}

/**
 * Handle Read Holding Registers (Function 0x03)
 */
static void Modbus_HandleReadHoldingRegisters(Modbus_HandleTypeDef *mb) {
    // Request: Address(1) + Function(1) + StartAddr(2) + Quantity(2) + CRC(2) = 8 bytes
    if (mb->rx_index < 8) {
        Modbus_SendException(mb, MODBUS_FC_READ_HOLDING_REGS, MODBUS_EX_ILLEGAL_VALUE);
        return;
    }

    uint16_t start_addr = (mb->rx_buffer[2] << 8) | mb->rx_buffer[3];
    uint16_t quantity = (mb->rx_buffer[4] << 8) | mb->rx_buffer[5];

    // Validate request
    if (quantity == 0 || quantity > 125) {
        Modbus_SendException(mb, MODBUS_FC_READ_HOLDING_REGS, MODBUS_EX_ILLEGAL_VALUE);
        return;
    }

    if (start_addr + quantity > mb->holding_reg_count) {
        Modbus_SendException(mb, MODBUS_FC_READ_HOLDING_REGS, MODBUS_EX_ILLEGAL_ADDRESS);
        return;
    }

    // Build response
    uint16_t tx_index = 0;
    mb->tx_buffer[tx_index++] = mb->slave_address;
    mb->tx_buffer[tx_index++] = MODBUS_FC_READ_HOLDING_REGS;
    mb->tx_buffer[tx_index++] = quantity * 2; // Byte count

    // Add register values
    for (uint16_t i = 0; i < quantity; i++) {
        uint16_t value = mb->holding_registers[start_addr + i];
        mb->tx_buffer[tx_index++] = (value >> 8) & 0xFF; // High byte
        mb->tx_buffer[tx_index++] = value & 0xFF;        // Low byte
    }

    // Add CRC
    uint16_t crc = Modbus_CRC16(mb->tx_buffer, tx_index);
    mb->tx_buffer[tx_index++] = crc & 0xFF;
    mb->tx_buffer[tx_index++] = (crc >> 8) & 0xFF;

    Modbus_SendResponse(mb, tx_index);
}

/**
 * Send exception response
 */
static void Modbus_SendException(Modbus_HandleTypeDef *mb, uint8_t function, uint8_t exception) {
    mb->tx_buffer[0] = mb->slave_address;
    mb->tx_buffer[1] = function | 0x80; // Set error bit
    mb->tx_buffer[2] = exception;

    uint16_t crc = Modbus_CRC16(mb->tx_buffer, 3);
    mb->tx_buffer[3] = crc & 0xFF;
    mb->tx_buffer[4] = (crc >> 8) & 0xFF;

    Modbus_SendResponse(mb, 5);
}

/**
 * Send response over RS485
 */
static void Modbus_SendResponse(Modbus_HandleTypeDef *mb, uint16_t length) {
    // Switch to transmit mode
    Modbus_SetDE(mb, true);

    // Small delay for transceiver to settle
    for (volatile int i = 0; i < 100; i++);

    // Transmit
    HAL_UART_Transmit(mb->huart, mb->tx_buffer, length, 100);

    // Wait for transmission complete
    while (__HAL_UART_GET_FLAG(mb->huart, UART_FLAG_TC) == RESET);

    // Small delay before switching back to receive
    for (volatile int i = 0; i < 100; i++);

    // Switch back to receive mode
    Modbus_SetDE(mb, false);
}

/**
 * Handle Write Single Register (Function 0x06)
 */
static void Modbus_HandleWriteSingleRegister(Modbus_HandleTypeDef *mb) {
    // Request: Address(1) + Function(1) + RegAddr(2) + Value(2) + CRC(2) = 8 bytes
    if (mb->rx_index < 8) {
        Modbus_SendException(mb, MODBUS_FC_WRITE_SINGLE_REG, MODBUS_EX_ILLEGAL_VALUE);
        return;
    }

    uint16_t reg_addr = (mb->rx_buffer[2] << 8) | mb->rx_buffer[3];
    uint16_t value = (mb->rx_buffer[4] << 8) | mb->rx_buffer[5];

    // Validate address
    if (reg_addr >= mb->holding_reg_count) {
        Modbus_SendException(mb, MODBUS_FC_WRITE_SINGLE_REG, MODBUS_EX_ILLEGAL_ADDRESS);
        return;
    }

    // Write the value
    mb->holding_registers[reg_addr] = value;

    // Call write callback if registered (for DAC updates, etc.)
    if (mb->write_callback != NULL) {
        mb->write_callback(reg_addr, value);
    }

    // Response is echo of request (Address + Function + RegAddr + Value + CRC)
    uint16_t tx_index = 0;
    mb->tx_buffer[tx_index++] = mb->slave_address;
    mb->tx_buffer[tx_index++] = MODBUS_FC_WRITE_SINGLE_REG;
    mb->tx_buffer[tx_index++] = (reg_addr >> 8) & 0xFF;
    mb->tx_buffer[tx_index++] = reg_addr & 0xFF;
    mb->tx_buffer[tx_index++] = (value >> 8) & 0xFF;
    mb->tx_buffer[tx_index++] = value & 0xFF;

    // Add CRC
    uint16_t crc = Modbus_CRC16(mb->tx_buffer, tx_index);
    mb->tx_buffer[tx_index++] = crc & 0xFF;
    mb->tx_buffer[tx_index++] = (crc >> 8) & 0xFF;

    Modbus_SendResponse(mb, tx_index);
}

/**
 * Set write callback function
 */
void Modbus_SetWriteCallback(Modbus_HandleTypeDef *mb, Modbus_WriteCallback callback) {
    mb->write_callback = callback;
}
