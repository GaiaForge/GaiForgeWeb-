/**
 * STM32G4xx Interrupt Handlers
 * SprigRig Sensor Hub
 */

#include "main.h"
#include "modbus.h"

/* External variables */
extern UART_HandleTypeDef huart2;
extern Modbus_HandleTypeDef modbus;

/**
 * System tick handler - called every 1ms
 */
void SysTick_Handler(void) {
    HAL_IncTick();

    /* Check Modbus frame timeout */
    Modbus_TimerCallback(&modbus);
}

/**
 * USART2 interrupt handler (RS485 Modbus)
 */
void USART2_IRQHandler(void) {
    /* Check for RX data */
    if (__HAL_UART_GET_FLAG(&huart2, UART_FLAG_RXNE)) {
        uint8_t data = (uint8_t)(huart2.Instance->RDR & 0xFF);
        Modbus_RxCallback(&modbus, data);
    }

    /* Handle other UART interrupts */
    HAL_UART_IRQHandler(&huart2);
}

/**
 * Hard Fault Handler
 */
void HardFault_Handler(void) {
    while (1) {
        // Stay here for debugging
    }
}

/**
 * Memory Management Fault Handler
 */
void MemManage_Handler(void) {
    while (1) {
    }
}

/**
 * Bus Fault Handler
 */
void BusFault_Handler(void) {
    while (1) {
    }
}

/**
 * Usage Fault Handler
 */
void UsageFault_Handler(void) {
    while (1) {
    }
}

/**
 * Non-Maskable Interrupt Handler
 */
void NMI_Handler(void) {
}

/**
 * Debug Monitor Handler
 */
void DebugMon_Handler(void) {
}

/**
 * SVC Handler
 */
void SVC_Handler(void) {
}

/**
 * PendSV Handler
 */
void PendSV_Handler(void) {
}
