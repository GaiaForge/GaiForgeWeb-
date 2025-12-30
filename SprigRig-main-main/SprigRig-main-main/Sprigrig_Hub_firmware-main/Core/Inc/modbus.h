/**
 * Modbus RTU Slave Implementation
 * SprigRig Sensor Hub
 */

#ifndef __MODBUS_H
#define __MODBUS_H

#include "stm32g4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* Modbus Function Codes */
#define MODBUS_FC_READ_COILS            0x01
#define MODBUS_FC_READ_DISCRETE         0x02
#define MODBUS_FC_READ_HOLDING_REGS     0x03
#define MODBUS_FC_READ_INPUT_REGS       0x04
#define MODBUS_FC_WRITE_SINGLE_COIL     0x05
#define MODBUS_FC_WRITE_SINGLE_REG      0x06
#define MODBUS_FC_WRITE_MULTIPLE_COILS  0x0F
#define MODBUS_FC_WRITE_MULTIPLE_REGS   0x10

/* Modbus Exception Codes */
#define MODBUS_EX_ILLEGAL_FUNCTION      0x01
#define MODBUS_EX_ILLEGAL_ADDRESS       0x02
#define MODBUS_EX_ILLEGAL_VALUE         0x03
#define MODBUS_EX_SLAVE_FAILURE         0x04

/* Buffer sizes */
#define MODBUS_RX_BUFFER_SIZE           256
#define MODBUS_TX_BUFFER_SIZE           256

/* Timing (3.5 character times at 9600 baud = ~4ms) */
#define MODBUS_FRAME_TIMEOUT_MS         5

/* Write callback function type */
typedef void (*Modbus_WriteCallback)(uint16_t reg_addr, uint16_t value);

/* Modbus context structure */
typedef struct {
    UART_HandleTypeDef *huart;
    GPIO_TypeDef *de_port;
    uint16_t de_pin;

    uint8_t slave_address;

    uint16_t *holding_registers;
    uint16_t holding_reg_count;

    uint8_t rx_buffer[MODBUS_RX_BUFFER_SIZE];
    uint8_t tx_buffer[MODBUS_TX_BUFFER_SIZE];

    volatile uint16_t rx_index;
    volatile uint32_t last_rx_time;
    volatile bool frame_ready;

    Modbus_WriteCallback write_callback;
} Modbus_HandleTypeDef;

/* Function prototypes */
void Modbus_Init(Modbus_HandleTypeDef *mb, UART_HandleTypeDef *huart,
                 GPIO_TypeDef *de_port, uint16_t de_pin,
                 uint8_t slave_address,
                 uint16_t *holding_regs, uint16_t reg_count);

void Modbus_Poll(Modbus_HandleTypeDef *mb);
void Modbus_RxCallback(Modbus_HandleTypeDef *mb, uint8_t data);
void Modbus_TimerCallback(Modbus_HandleTypeDef *mb);
void Modbus_SetWriteCallback(Modbus_HandleTypeDef *mb, Modbus_WriteCallback callback);

/* CRC functions */
uint16_t Modbus_CRC16(uint8_t *data, uint16_t length);

#endif /* __MODBUS_H */
