/******************************************************************************
 * Front-sensor S3 UART receiver.
 *****************************************************************************/
#include <string.h>

#include "driver/uart.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "game_ui.h"
#include "sensor_protocol.h"
#include "uart_joystick.h"

#define UART_NUM       UART_NUM_2
#define PIN_RX         44
#define PIN_TX         43
#define BUF_SIZE       1024
#define BAUD_RATE      115200

static const char *TAG = "uart_sensor_rx";

static void uart_task(void *pvParameters)
{
    (void)pvParameters;

    uint8_t byte = 0;
    sensor_packet_t packet;
    bool saw_sync0 = false;

    ESP_LOGI(TAG, "S3 UART listener started. TX=%d RX=%d baud=%d",
             PIN_TX, PIN_RX, BAUD_RATE);

    while (1) {
        int read_len = uart_read_bytes(UART_NUM, &byte, 1, pdMS_TO_TICKS(100));
        if (read_len <= 0) {
            continue;
        }

        if (!saw_sync0) {
            saw_sync0 = (byte == SENSOR_PACKET_SYNC0);
            continue;
        }

        if (byte != SENSOR_PACKET_SYNC1) {
            saw_sync0 = (byte == SENSOR_PACKET_SYNC0);
            continue;
        }

        packet.sync0 = SENSOR_PACKET_SYNC0;
        packet.sync1 = SENSOR_PACKET_SYNC1;

        read_len = uart_read_bytes(UART_NUM,
                                   ((uint8_t *)&packet) + 2,
                                   sizeof(packet) - 2,
                                   pdMS_TO_TICKS(40));
        saw_sync0 = false;

        if (read_len != (int)sizeof(packet) - 2) {
            continue;
        }

        if (!sensor_packet_is_valid(&packet)) {
            continue;
        }

        game_ui_update_from_wire(&packet);
    }
}

void uart_joystick_init(void)
{
    const uart_config_t uart_config = {
        .baud_rate = BAUD_RATE,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };

    ESP_ERROR_CHECK(uart_driver_install(UART_NUM, BUF_SIZE, 0, 0, NULL, 0));
    ESP_ERROR_CHECK(uart_param_config(UART_NUM, &uart_config));
    ESP_ERROR_CHECK(uart_set_pin(UART_NUM, PIN_TX, PIN_RX,
                                 UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE));

    xTaskCreatePinnedToCore(uart_task, "uart_sensor_rx", 4096, NULL, 6, NULL, 0);
}
