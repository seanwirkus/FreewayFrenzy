#include <math.h>
#include <stdio.h>
#include <string.h>

#include "driver/gpio.h"
#include "driver/uart.h"
#include "esp_log.h"
#include "esp_rom_sys.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "sensor_protocol.h"

#define UART_PORT               UART_NUM_1
#define UART_TX_PIN             GPIO_NUM_6
#define UART_RX_PIN             GPIO_NUM_7
#define UART_BAUD_RATE          115200

#define ULTRASONIC_TRIG_PIN     GPIO_NUM_4
#define ULTRASONIC_ECHO_PIN     GPIO_NUM_5

#define SAMPLE_BATCH_SIZE       5
#define SAMPLE_GAP_MS           12
#define STREAM_PERIOD_MS        60

#define DETECT_MIN_MM           60u
#define DETECT_MAX_MM           2500u
#define WAIT_ECHO_RISE_US       18000
#define WAIT_ECHO_FALL_US       18000

typedef enum {
    SENSOR_MEASUREMENT_VALID = 0,
    SENSOR_MEASUREMENT_CLEAR,
    SENSOR_MEASUREMENT_FAULT,
} sensor_measurement_t;

static const char *TAG = "c3_ultrasonic";
static float filtered_mm;
static bool filter_seeded;
static uint16_t sequence_id;

static void sort_u16(uint16_t *values, size_t count)
{
    for (size_t i = 1; i < count; ++i) {
        uint16_t key = values[i];
        size_t j = i;

        while (j > 0 && values[j - 1] > key) {
            values[j] = values[j - 1];
            --j;
        }

        values[j] = key;
    }
}

static void ultrasonic_trigger_pulse(void)
{
    gpio_set_level(ULTRASONIC_TRIG_PIN, 0);
    esp_rom_delay_us(4);
    gpio_set_level(ULTRASONIC_TRIG_PIN, 1);
    esp_rom_delay_us(10);
    gpio_set_level(ULTRASONIC_TRIG_PIN, 0);
}

static sensor_measurement_t ultrasonic_measure_once(uint16_t *distance_mm)
{
    int64_t start_us = 0;
    int64_t now_us = 0;

    if (gpio_get_level(ULTRASONIC_ECHO_PIN) != 0) {
        return SENSOR_MEASUREMENT_FAULT;
    }

    ultrasonic_trigger_pulse();

    start_us = esp_timer_get_time();
    while (gpio_get_level(ULTRASONIC_ECHO_PIN) == 0) {
        now_us = esp_timer_get_time();
        if ((now_us - start_us) > WAIT_ECHO_RISE_US) {
            return SENSOR_MEASUREMENT_CLEAR;
        }
    }

    const int64_t echo_start_us = esp_timer_get_time();
    while (gpio_get_level(ULTRASONIC_ECHO_PIN) == 1) {
        now_us = esp_timer_get_time();
        if ((now_us - echo_start_us) > WAIT_ECHO_FALL_US) {
            return SENSOR_MEASUREMENT_CLEAR;
        }
    }

    const int64_t echo_width_us = esp_timer_get_time() - echo_start_us;
    if (echo_width_us <= 0) {
        return SENSOR_MEASUREMENT_FAULT;
    }

    uint32_t measured_mm = (uint32_t)((echo_width_us * 343LL + 1000LL) / 2000LL);
    if (measured_mm > DETECT_MAX_MM) {
        return SENSOR_MEASUREMENT_CLEAR;
    }

    if (measured_mm < DETECT_MIN_MM) {
        measured_mm = DETECT_MIN_MM;
    }

    *distance_mm = (uint16_t)measured_mm;
    return SENSOR_MEASUREMENT_VALID;
}

static uint16_t reduce_samples(const uint16_t *samples, size_t count)
{
    uint16_t ordered[SAMPLE_BATCH_SIZE];
    memcpy(ordered, samples, count * sizeof(uint16_t));
    sort_u16(ordered, count);

    if (count >= 4) {
        uint32_t total = 0;
        for (size_t i = 1; i + 1 < count; ++i) {
            total += ordered[i];
        }
        return (uint16_t)(total / (count - 2));
    }

    return ordered[count / 2];
}

static uint8_t compute_confidence(const uint16_t *samples, size_t count)
{
    if (count == 0) {
        return 0;
    }

    uint16_t ordered[SAMPLE_BATCH_SIZE];
    memcpy(ordered, samples, count * sizeof(uint16_t));
    sort_u16(ordered, count);

    const uint16_t spread = ordered[count - 1] - ordered[0];
    int confidence = (int)((count * 45u) / SAMPLE_BATCH_SIZE);
    confidence += 55 - (int)((spread * 55u) / 220u);

    if (confidence > 100) {
        confidence = 100;
    }
    if (confidence < 10) {
        confidence = 10;
    }

    return (uint8_t)confidence;
}

static uint16_t update_filter(uint16_t raw_mm)
{
    if (!filter_seeded) {
        filtered_mm = (float)raw_mm;
        filter_seeded = true;
        return raw_mm;
    }

    const float delta = fabsf((float)raw_mm - filtered_mm);
    float alpha = 0.24f;

    if (delta < 45.0f) {
        alpha = 0.48f;
    } else if (delta < 120.0f) {
        alpha = 0.34f;
    }

    filtered_mm += alpha * ((float)raw_mm - filtered_mm);
    return (uint16_t)lroundf(filtered_mm);
}

static void sensor_task(void *arg)
{
    (void)arg;

    while (1) {
        uint16_t samples[SAMPLE_BATCH_SIZE] = {0};
        size_t valid_count = 0;
        int fault_count = 0;

        for (int i = 0; i < SAMPLE_BATCH_SIZE; ++i) {
            uint16_t mm = 0;
            const sensor_measurement_t result = ultrasonic_measure_once(&mm);

            if (result == SENSOR_MEASUREMENT_VALID) {
                samples[valid_count++] = mm;
            } else if (result == SENSOR_MEASUREMENT_FAULT) {
                fault_count++;
            }

            vTaskDelay(pdMS_TO_TICKS(SAMPLE_GAP_MS));
        }

        sensor_packet_t packet = {
            .flags = 0,
            .sequence = sequence_id++,
            .uptime_ms = (uint32_t)(esp_timer_get_time() / 1000ULL),
            .min_distance_mm = DETECT_MIN_MM,
            .max_distance_mm = DETECT_MAX_MM,
            .beam_width_mm = sensor_cone_width_mm(DETECT_MAX_MM),
            .confidence_pc = 0,
            .valid_samples = (uint8_t)valid_count,
        };

        if (valid_count >= 2) {
            const uint16_t raw_mm = reduce_samples(samples, valid_count);
            const uint16_t filtered = update_filter(raw_mm);

            packet.flags |= SENSOR_FLAG_TARGET_VALID;
            if (filtered <= 450u) {
                packet.flags |= SENSOR_FLAG_ALERT;
            } else if (filtered <= 900u) {
                packet.flags |= SENSOR_FLAG_CAUTION;
            }

            packet.raw_distance_mm = raw_mm;
            packet.filtered_distance_mm = filtered;
            packet.beam_width_mm = sensor_cone_width_mm(filtered);
            packet.confidence_pc = compute_confidence(samples, valid_count);
        } else if (fault_count >= 3) {
            packet.flags |= SENSOR_FLAG_SENSOR_FAULT;
        } else {
            packet.flags |= SENSOR_FLAG_CLEAR;
            packet.filtered_distance_mm = DETECT_MAX_MM;
            packet.beam_width_mm = sensor_cone_width_mm(DETECT_MAX_MM);
        }

        sensor_packet_finalize(&packet);
        uart_write_bytes(UART_PORT, &packet, sizeof(packet));
        vTaskDelay(pdMS_TO_TICKS(STREAM_PERIOD_MS));
    }
}

void app_main(void)
{
    const uart_config_t uart_config = {
        .baud_rate = UART_BAUD_RATE,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };

    ESP_LOGI(TAG, "Starting C3 ultrasonic streamer");
    ESP_LOGI(TAG, "UART1 TX=%d RX=%d  TRIG=%d ECHO=%d",
             UART_TX_PIN, UART_RX_PIN, ULTRASONIC_TRIG_PIN, ULTRASONIC_ECHO_PIN);

    ESP_ERROR_CHECK(gpio_reset_pin(ULTRASONIC_TRIG_PIN));
    ESP_ERROR_CHECK(gpio_set_direction(ULTRASONIC_TRIG_PIN, GPIO_MODE_OUTPUT));
    ESP_ERROR_CHECK(gpio_set_level(ULTRASONIC_TRIG_PIN, 0));

    ESP_ERROR_CHECK(gpio_reset_pin(ULTRASONIC_ECHO_PIN));
    ESP_ERROR_CHECK(gpio_set_direction(ULTRASONIC_ECHO_PIN, GPIO_MODE_INPUT));
    ESP_ERROR_CHECK(gpio_set_pull_mode(ULTRASONIC_ECHO_PIN, GPIO_FLOATING));

    ESP_ERROR_CHECK(uart_driver_install(UART_PORT, 1024, 0, 0, NULL, 0));
    ESP_ERROR_CHECK(uart_param_config(UART_PORT, &uart_config));
    ESP_ERROR_CHECK(uart_set_pin(UART_PORT, UART_TX_PIN, UART_RX_PIN,
                                 UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE));

    xTaskCreate(sensor_task, "sensor_task", 4096, NULL, 8, NULL);
}
