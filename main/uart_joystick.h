/******************************************************************************
 * uart_joystick.h – UART2 sensor receiver for ESP32-S3
 *****************************************************************************/
#pragma once

/**
 * @brief Initialize UART2 (GPIO43 TX / GPIO44 RX) and start the listener task.
 */
void uart_joystick_init(void);
