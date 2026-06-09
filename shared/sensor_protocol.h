#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define SENSOR_PACKET_SYNC0 0xA5u
#define SENSOR_PACKET_SYNC1 0x5Au
#define SENSOR_PROTOCOL_VERSION 1u

#define SENSOR_DEFAULT_MIN_DISTANCE_MM 60u
#define SENSOR_DEFAULT_MAX_DISTANCE_MM 2500u

enum {
    SENSOR_FLAG_TARGET_VALID = 1u << 0,
    SENSOR_FLAG_CAUTION      = 1u << 1,
    SENSOR_FLAG_ALERT        = 1u << 2,
    SENSOR_FLAG_CLEAR        = 1u << 3,
    SENSOR_FLAG_SENSOR_FAULT = 1u << 4,
};

typedef struct __attribute__((packed)) {
    uint8_t  sync0;
    uint8_t  sync1;
    uint8_t  version;
    uint8_t  flags;
    uint16_t sequence;
    uint32_t uptime_ms;
    uint16_t raw_distance_mm;
    uint16_t filtered_distance_mm;
    uint16_t min_distance_mm;
    uint16_t max_distance_mm;
    uint16_t beam_width_mm;
    uint8_t  confidence_pc;
    uint8_t  valid_samples;
    uint16_t checksum;
} sensor_packet_t;

static inline uint16_t sensor_protocol_checksum_bytes(const uint8_t *data, size_t len)
{
    uint32_t hash = 0xA55Au;

    for (size_t i = 0; i < len; ++i) {
        hash ^= (uint32_t)data[i] << ((i & 1u) ? 8u : 0u);
        hash = ((hash << 5u) | (hash >> 11u)) & 0xFFFFu;
        hash = (hash + 0x31u + (uint32_t)(i * 17u)) & 0xFFFFu;
    }

    return (uint16_t)hash;
}

static inline uint16_t sensor_packet_checksum(const sensor_packet_t *packet)
{
    return sensor_protocol_checksum_bytes((const uint8_t *)packet,
                                          offsetof(sensor_packet_t, checksum));
}

static inline bool sensor_packet_is_valid(const sensor_packet_t *packet)
{
    return packet != NULL &&
           packet->sync0 == SENSOR_PACKET_SYNC0 &&
           packet->sync1 == SENSOR_PACKET_SYNC1 &&
           packet->version == SENSOR_PROTOCOL_VERSION &&
           packet->checksum == sensor_packet_checksum(packet);
}

static inline void sensor_packet_finalize(sensor_packet_t *packet)
{
    packet->sync0 = SENSOR_PACKET_SYNC0;
    packet->sync1 = SENSOR_PACKET_SYNC1;
    packet->version = SENSOR_PROTOCOL_VERSION;
    packet->checksum = sensor_packet_checksum(packet);
}

static inline uint16_t sensor_cone_width_mm(uint16_t distance_mm)
{
    return (uint16_t)((distance_mm * 26u + 50u) / 100u);
}
