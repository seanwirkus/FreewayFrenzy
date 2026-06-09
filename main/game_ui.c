/******************************************************************************
 * Front radar dashboard for the ESP32-S3 RGB LCD.
 *
 * This file renders a dark automotive-style forward scan UI inspired by
 * the provided mockup and updates it from sensor packets streamed by the
 * ESP32-C3 over UART.
 *****************************************************************************/
#include "game_ui.h"

#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "lvgl.h"
#include "sensor_protocol.h"

#define SCR_W 1024
#define SCR_H 600

#define HISTORY_MARKERS 6

#define CENTER_X        (SCR_W / 2)
#define TOP_PANEL_H     122
#define BOTTOM_PANEL_Y  500
#define BOTTOM_PANEL_H  100

#define LANE_SHELL_W    84
#define LANE_CHANNEL_W  48
#define LANE_CORE_W     26
#define LANE_TOP        0
#define LANE_BOTTOM     SCR_H
#define CONTACT_TOP_Y   132
#define CONTACT_BOT_Y   452

#define PORTAL_RING_SZ  250
#define PORTAL_HOLE_SZ  186
#define PORTAL_CY       282

#define NAV_RING_SZ     176
#define NAV_FACE_SZ     136
#define NAV_CY          388

typedef struct {
    bool link_up;
    bool target_valid;
    bool caution;
    bool alert;
    bool clear_path;
    bool sensor_fault;

    uint16_t raw_mm;
    uint16_t filtered_mm;
    uint16_t min_mm;
    uint16_t max_mm;
    uint16_t beam_mm;
    uint16_t sequence;
    uint8_t confidence;
    uint8_t valid_samples;

    uint16_t history_mm[HISTORY_MARKERS];
    uint8_t history_count;

    int64_t last_packet_us;
    float pulse_phase;
} dashboard_state_t;

static const char *TAG = "front_scope_ui";

static dashboard_state_t ds;

static sensor_packet_t pkt_buf;
static bool pkt_ready;
static SemaphoreHandle_t pkt_mutex;

static lv_obj_t *scr_main;
static lv_obj_t *lane_core;
static lv_obj_t *portal_ring;
static lv_obj_t *portal_hole;
static lv_obj_t *nav_face;
static lv_obj_t *distance_label;
static lv_obj_t *status_label;
static lv_obj_t *detail_label;
static lv_obj_t *footprint_label;
static lv_obj_t *link_label;
static lv_obj_t *primary_halo;
static lv_obj_t *primary_core;
static lv_obj_t *history_markers[HISTORY_MARKERS];

static lv_point_t top_left_bevel[] = { {0, 88}, {270, 122} };
static lv_point_t top_right_bevel[] = { {SCR_W - 270, 122}, {SCR_W, 88} };
static lv_point_t bottom_left_bevel[] = { {0, SCR_H - 46}, {250, BOTTOM_PANEL_Y} };
static lv_point_t bottom_right_bevel[] = { {SCR_W - 250, BOTTOM_PANEL_Y}, {SCR_W, SCR_H - 46} };
static lv_point_t cone_left[] = { {CENTER_X, NAV_CY - 78}, {CENTER_X - 98, CONTACT_TOP_Y + 14} };
static lv_point_t cone_right[] = { {CENTER_X, NAV_CY - 78}, {CENTER_X + 98, CONTACT_TOP_Y + 14} };

static lv_obj_t *make_panel(lv_obj_t *parent, lv_coord_t w, lv_coord_t h,
                            lv_color_t bg0, lv_color_t bg1)
{
    lv_obj_t *obj = lv_obj_create(parent);
    lv_obj_remove_style_all(obj);
    lv_obj_set_size(obj, w, h);
    lv_obj_clear_flag(obj, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_bg_opa(obj, LV_OPA_COVER, 0);
    lv_obj_set_style_bg_color(obj, bg0, 0);
    lv_obj_set_style_bg_grad_color(obj, bg1, 0);
    lv_obj_set_style_bg_grad_dir(obj, LV_GRAD_DIR_VER, 0);
    lv_obj_set_style_border_width(obj, 0, 0);
    return obj;
}

static lv_obj_t *make_circle(lv_obj_t *parent, lv_coord_t size,
                             lv_color_t bg, lv_opa_t opa)
{
    lv_obj_t *obj = lv_obj_create(parent);
    lv_obj_remove_style_all(obj);
    lv_obj_set_size(obj, size, size);
    lv_obj_clear_flag(obj, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_radius(obj, LV_RADIUS_CIRCLE, 0);
    lv_obj_set_style_bg_color(obj, bg, 0);
    lv_obj_set_style_bg_opa(obj, opa, 0);
    lv_obj_set_style_border_width(obj, 0, 0);
    return obj;
}

static lv_obj_t *make_chip(lv_obj_t *parent, const char *text,
                           lv_coord_t w, lv_coord_t h,
                           lv_color_t bg, lv_color_t text_color)
{
    lv_obj_t *chip = make_panel(parent, w, h, bg, bg);
    lv_obj_set_style_radius(chip, LV_RADIUS_CIRCLE, 0);
    lv_obj_set_style_bg_opa(chip, LV_OPA_70, 0);
    lv_obj_set_style_border_width(chip, 1, 0);
    lv_obj_set_style_border_color(chip, lv_color_hex(0x505050), 0);
    lv_obj_set_style_border_opa(chip, LV_OPA_70, 0);

    lv_obj_t *label = lv_label_create(chip);
    lv_label_set_text(label, text);
    lv_obj_set_style_text_font(label, &lv_font_montserrat_14, 0);
    lv_obj_set_style_text_color(label, text_color, 0);
    lv_obj_center(label);
    return chip;
}

static lv_obj_t *make_line(lv_obj_t *parent, lv_point_t *points, uint16_t count,
                           lv_color_t color, lv_opa_t opa, lv_coord_t width)
{
    lv_obj_t *line = lv_line_create(parent);
    lv_line_set_points(line, points, count);
    lv_obj_set_style_line_color(line, color, 0);
    lv_obj_set_style_line_opa(line, opa, 0);
    lv_obj_set_style_line_width(line, width, 0);
    lv_obj_set_style_line_rounded(line, true, 0);
    return line;
}

static void hide_marker_objects(void)
{
    lv_obj_add_flag(primary_halo, LV_OBJ_FLAG_HIDDEN);
    lv_obj_add_flag(primary_core, LV_OBJ_FLAG_HIDDEN);

    for (int i = 0; i < HISTORY_MARKERS; ++i) {
        lv_obj_add_flag(history_markers[i], LV_OBJ_FLAG_HIDDEN);
    }
}

static lv_coord_t distance_to_y(uint16_t distance_mm)
{
    const uint16_t min_mm = ds.min_mm ? ds.min_mm : SENSOR_DEFAULT_MIN_DISTANCE_MM;
    const uint16_t max_mm = ds.max_mm > min_mm ? ds.max_mm : SENSOR_DEFAULT_MAX_DISTANCE_MM;

    uint16_t clipped = distance_mm;
    if (clipped < min_mm) {
        clipped = min_mm;
    }
    if (clipped > max_mm) {
        clipped = max_mm;
    }

    const float span = (float)(max_mm - min_mm);
    const float norm = span > 1.0f ? ((float)(clipped - min_mm) / span) : 0.5f;
    return CONTACT_BOT_Y - (lv_coord_t)(norm * (float)(CONTACT_BOT_Y - CONTACT_TOP_Y));
}

static void push_history(uint16_t distance_mm)
{
    for (int i = HISTORY_MARKERS - 1; i > 0; --i) {
        ds.history_mm[i] = ds.history_mm[i - 1];
    }

    ds.history_mm[0] = distance_mm;
    if (ds.history_count < HISTORY_MARKERS) {
        ds.history_count++;
    }
}

static void apply_marker_visuals(void)
{
    lv_color_t accent = lv_color_hex(0x2BD975);
    lv_color_t accent_soft = lv_color_hex(0x1F8F50);
    const char *status_text = "WAITING FOR C3";
    char distance_text[32];
    char detail_text[96];
    char footprint_text[96];
    char link_text[48];

    snprintf(distance_text, sizeof(distance_text), "--.-- m");
    snprintf(detail_text, sizeof(detail_text), "UART idle");
    snprintf(footprint_text, sizeof(footprint_text), "Front cone only");
    snprintf(link_text, sizeof(link_text), "C3 link offline");

    if (!ds.link_up) {
        ds.history_count = 0;
        hide_marker_objects();
    } else if (ds.sensor_fault) {
        accent = lv_color_hex(0xFF4D4D);
        accent_soft = lv_color_hex(0x7A1010);
        status_text = "SENSOR FAULT";
        snprintf(distance_text, sizeof(distance_text), "CHECK SENSOR");
        snprintf(detail_text, sizeof(detail_text), "Echo line unstable or timing out");
        snprintf(footprint_text, sizeof(footprint_text), "Trig/Echo or power needs attention");
        snprintf(link_text, sizeof(link_text), "C3 link live");
        hide_marker_objects();
        ds.history_count = 0;
    } else if (ds.target_valid) {
        const float filtered_m = (float)ds.filtered_mm / 1000.0f;
        const float raw_m = (float)ds.raw_mm / 1000.0f;
        const float cone_cm = (float)ds.beam_mm / 10.0f;

        if (ds.alert) {
            accent = lv_color_hex(0xFF4C2E);
            accent_soft = lv_color_hex(0x8C140C);
            status_text = "BRAKE";
        } else if (ds.caution) {
            accent = lv_color_hex(0xFFC247);
            accent_soft = lv_color_hex(0x875B10);
            status_text = "OBJECT AHEAD";
        } else {
            status_text = "TRACKING";
        }

        snprintf(distance_text, sizeof(distance_text), "%.2f m", filtered_m);
        snprintf(detail_text, sizeof(detail_text),
                 "Raw %.2f m  |  Confidence %u%%  |  Samples %u",
                 raw_m, ds.confidence, ds.valid_samples);
        snprintf(footprint_text, sizeof(footprint_text),
                 "Cone width %.1f cm  |  Window %.2f m to %.2f m",
                 cone_cm,
                 (float)ds.min_mm / 1000.0f,
                 (float)ds.max_mm / 1000.0f);
        snprintf(link_text, sizeof(link_text), "C3 link live  |  seq %u", ds.sequence);

        const lv_coord_t contact_y = distance_to_y(ds.filtered_mm);
        lv_coord_t halo_w = 52 + (lv_coord_t)(ds.beam_mm / 16u);
        if (halo_w > 180) {
            halo_w = 180;
        }
        if (halo_w < 56) {
            halo_w = 56;
        }

        lv_obj_clear_flag(primary_halo, LV_OBJ_FLAG_HIDDEN);
        lv_obj_set_size(primary_halo, halo_w, 18);
        lv_obj_set_pos(primary_halo, CENTER_X - halo_w / 2, contact_y - 9);
        lv_obj_set_style_bg_color(primary_halo, accent, 0);
        lv_obj_set_style_bg_opa(primary_halo, (lv_opa_t)(60 + ds.confidence), 0);
        lv_obj_set_style_shadow_color(primary_halo, accent, 0);
        lv_obj_set_style_shadow_width(primary_halo, 16, 0);
        lv_obj_set_style_shadow_opa(primary_halo, LV_OPA_80, 0);

        lv_obj_clear_flag(primary_core, LV_OBJ_FLAG_HIDDEN);
        lv_obj_set_size(primary_core, 24, 24);
        lv_obj_set_pos(primary_core, CENTER_X - 12, contact_y - 12);
        lv_obj_set_style_bg_color(primary_core, lv_color_white(), 0);
        lv_obj_set_style_bg_opa(primary_core, LV_OPA_COVER, 0);
        lv_obj_set_style_border_width(primary_core, 3, 0);
        lv_obj_set_style_border_color(primary_core, accent, 0);
        lv_obj_set_style_border_opa(primary_core, LV_OPA_COVER, 0);

        for (int i = 0; i < HISTORY_MARKERS; ++i) {
            if (i >= ds.history_count) {
                lv_obj_add_flag(history_markers[i], LV_OBJ_FLAG_HIDDEN);
                continue;
            }

            const lv_coord_t y = distance_to_y(ds.history_mm[i]);
            const lv_coord_t size = 12 - (lv_coord_t)i;
            const lv_opa_t opa = (lv_opa_t)(140 - i * 18);

            lv_obj_clear_flag(history_markers[i], LV_OBJ_FLAG_HIDDEN);
            lv_obj_set_size(history_markers[i], size, size);
            lv_obj_set_pos(history_markers[i], CENTER_X - size / 2, y - size / 2);
            lv_obj_set_style_bg_color(history_markers[i], accent_soft, 0);
            lv_obj_set_style_bg_opa(history_markers[i], opa, 0);
            lv_obj_set_style_shadow_width(history_markers[i], 0, 0);
        }
    } else {
        status_text = "CLEAR";
        snprintf(distance_text, sizeof(distance_text), "NO CONTACT");
        snprintf(detail_text, sizeof(detail_text),
                 "No echo inside %.2f m detection window",
                 (float)ds.max_mm / 1000.0f);
        snprintf(footprint_text, sizeof(footprint_text),
                 "Cone reaches about %.1f cm at max range",
                 (float)sensor_cone_width_mm(ds.max_mm) / 10.0f);
        snprintf(link_text, sizeof(link_text), "C3 link live  |  path clear");
        hide_marker_objects();
        ds.history_count = 0;
    }

    lv_label_set_text(status_label, status_text);
    lv_label_set_text(distance_label, distance_text);
    lv_label_set_text(detail_label, detail_text);
    lv_label_set_text(footprint_label, footprint_text);
    lv_label_set_text(link_label, link_text);

    lv_obj_set_style_text_color(status_label, accent, 0);
    lv_obj_set_style_text_color(distance_label, accent, 0);
    lv_obj_set_style_bg_color(lane_core, lv_color_hex(0xFF4D1C), 0);
    lv_obj_set_style_bg_grad_color(lane_core, lv_color_hex(0x64100D), 0);
    lv_obj_set_style_shadow_color(portal_hole, accent_soft, 0);
    lv_obj_set_style_shadow_opa(portal_hole, ds.link_up ? LV_OPA_70 : LV_OPA_20, 0);
    lv_obj_set_style_shadow_color(portal_ring, accent, 0);
    lv_obj_set_style_border_color(nav_face, accent, 0);
    lv_obj_set_style_border_opa(nav_face, ds.link_up ? LV_OPA_40 : LV_OPA_10, 0);
}

static void apply_packet(const sensor_packet_t *packet, int64_t now_us)
{
    ds.link_up = true;
    ds.last_packet_us = now_us;
    ds.target_valid = (packet->flags & SENSOR_FLAG_TARGET_VALID) != 0;
    ds.caution = (packet->flags & SENSOR_FLAG_CAUTION) != 0;
    ds.alert = (packet->flags & SENSOR_FLAG_ALERT) != 0;
    ds.clear_path = (packet->flags & SENSOR_FLAG_CLEAR) != 0;
    ds.sensor_fault = (packet->flags & SENSOR_FLAG_SENSOR_FAULT) != 0;

    ds.raw_mm = packet->raw_distance_mm;
    ds.filtered_mm = packet->filtered_distance_mm;
    ds.min_mm = packet->min_distance_mm ? packet->min_distance_mm
                                        : SENSOR_DEFAULT_MIN_DISTANCE_MM;
    ds.max_mm = packet->max_distance_mm > ds.min_mm ? packet->max_distance_mm
                                                    : SENSOR_DEFAULT_MAX_DISTANCE_MM;
    ds.beam_mm = packet->beam_width_mm ? packet->beam_width_mm
                                       : sensor_cone_width_mm(ds.filtered_mm);
    ds.sequence = packet->sequence;
    ds.confidence = packet->confidence_pc;
    ds.valid_samples = packet->valid_samples;

    if (ds.target_valid) {
        push_history(ds.filtered_mm);
    }
}

static void dashboard_tick_cb(lv_timer_t *timer)
{
    (void)timer;

    const int64_t now_us = esp_timer_get_time();

    if (pkt_ready && xSemaphoreTake(pkt_mutex, 0) == pdTRUE) {
        sensor_packet_t packet = pkt_buf;
        pkt_ready = false;
        xSemaphoreGive(pkt_mutex);
        apply_packet(&packet, now_us);
    }

    if (ds.link_up && (now_us - ds.last_packet_us) > 1500000) {
        ds.link_up = false;
        ds.target_valid = false;
        ds.caution = false;
        ds.alert = false;
        ds.clear_path = false;
        ds.sensor_fault = false;
    }

    ds.pulse_phase += 0.11f;
    if (ds.pulse_phase > 6.2831853f) {
        ds.pulse_phase -= 6.2831853f;
    }

    apply_marker_visuals();

    const float pulse = 0.5f + 0.5f * sinf(ds.pulse_phase);
    lv_coord_t portal_shadow = 34 + (lv_coord_t)(pulse * 12.0f);
    lv_coord_t nav_shadow = 18 + (lv_coord_t)(pulse * 8.0f);

    if (ds.target_valid) {
        portal_shadow += 12;
        nav_shadow += 6;
    }

    lv_obj_set_style_shadow_width(portal_hole, portal_shadow, 0);
    lv_obj_set_style_shadow_width(nav_face, nav_shadow, 0);
    lv_obj_set_style_shadow_color(nav_face, lv_color_hex(0x0B6BCB), 0);
    lv_obj_set_style_shadow_opa(nav_face, LV_OPA_50, 0);
}

void game_ui_update_from_wire(const void *packet_void)
{
    if (packet_void == NULL || pkt_mutex == NULL) {
        return;
    }

    if (xSemaphoreTake(pkt_mutex, pdMS_TO_TICKS(5)) == pdTRUE) {
        memcpy(&pkt_buf, packet_void, sizeof(pkt_buf));
        pkt_ready = true;
        xSemaphoreGive(pkt_mutex);
    }
}

void game_ui_init(void)
{
    ESP_LOGI(TAG, "dashboard init");

    memset(&ds, 0, sizeof(ds));
    ds.min_mm = SENSOR_DEFAULT_MIN_DISTANCE_MM;
    ds.max_mm = SENSOR_DEFAULT_MAX_DISTANCE_MM;

    pkt_mutex = xSemaphoreCreateMutex();
    assert(pkt_mutex != NULL);

    scr_main = lv_obj_create(NULL);
    lv_obj_remove_style_all(scr_main);
    lv_obj_set_size(scr_main, SCR_W, SCR_H);
    lv_obj_set_style_bg_color(scr_main, lv_color_hex(0x101010), 0);
    lv_obj_set_style_bg_grad_color(scr_main, lv_color_hex(0x050505), 0);
    lv_obj_set_style_bg_grad_dir(scr_main, LV_GRAD_DIR_VER, 0);
    lv_obj_set_style_bg_opa(scr_main, LV_OPA_COVER, 0);
    lv_obj_clear_flag(scr_main, LV_OBJ_FLAG_SCROLLABLE);

    lv_obj_t *top_panel = make_panel(scr_main, SCR_W, TOP_PANEL_H,
                                     lv_color_hex(0x383838), lv_color_hex(0x252525));
    lv_obj_align(top_panel, LV_ALIGN_TOP_MID, 0, 0);
    lv_obj_set_style_shadow_color(top_panel, lv_color_black(), 0);
    lv_obj_set_style_shadow_width(top_panel, 18, 0);
    lv_obj_set_style_shadow_opa(top_panel, LV_OPA_40, 0);

    make_line(scr_main, top_left_bevel, 2, lv_color_hex(0x777777), LV_OPA_40, 2);
    make_line(scr_main, top_right_bevel, 2, lv_color_hex(0x777777), LV_OPA_40, 2);

    lv_obj_t *bottom_panel = make_panel(scr_main, SCR_W, BOTTOM_PANEL_H,
                                        lv_color_hex(0x2C2C2C), lv_color_hex(0x1B1B1B));
    lv_obj_align(bottom_panel, LV_ALIGN_BOTTOM_MID, 0, 0);

    make_line(scr_main, bottom_left_bevel, 2, lv_color_hex(0x6E6E6E), LV_OPA_35, 2);
    make_line(scr_main, bottom_right_bevel, 2, lv_color_hex(0x6E6E6E), LV_OPA_35, 2);
    make_line(scr_main, cone_left, 2, lv_color_hex(0xB73B26), LV_OPA_20, 3);
    make_line(scr_main, cone_right, 2, lv_color_hex(0xB73B26), LV_OPA_20, 3);

    lv_obj_t *left_arrow = lv_label_create(top_panel);
    lv_label_set_text(left_arrow, LV_SYMBOL_LEFT);
    lv_obj_set_style_text_font(left_arrow, &lv_font_montserrat_44, 0);
    lv_obj_set_style_text_color(left_arrow, lv_color_white(), 0);
    lv_obj_align(left_arrow, LV_ALIGN_TOP_LEFT, 28, 12);

    lv_obj_t *right_arrow = lv_label_create(top_panel);
    lv_label_set_text(right_arrow, LV_SYMBOL_RIGHT);
    lv_obj_set_style_text_font(right_arrow, &lv_font_montserrat_44, 0);
    lv_obj_set_style_text_color(right_arrow, lv_color_white(), 0);
    lv_obj_align(right_arrow, LV_ALIGN_TOP_RIGHT, -28, 12);

    lv_obj_t *chip_left = make_chip(top_panel, "FRONT", 86, 28,
                                    lv_color_hex(0x2A2A2A), lv_color_white());
    lv_obj_align(chip_left, LV_ALIGN_TOP_MID, -118, 18);

    lv_obj_t *chip_mid = make_chip(top_panel, "ULTRASONIC", 126, 28,
                                   lv_color_hex(0x242424), lv_color_white());
    lv_obj_align(chip_mid, LV_ALIGN_TOP_MID, 0, 18);

    lv_obj_t *chip_right = make_chip(top_panel, "UART", 78, 28,
                                     lv_color_hex(0x242424), lv_color_white());
    lv_obj_align(chip_right, LV_ALIGN_TOP_MID, 118, 18);

    lv_obj_t *heading = lv_label_create(top_panel);
    lv_label_set_text(heading, "FORWARD SCAN");
    lv_obj_set_style_text_font(heading, &lv_font_montserrat_20, 0);
    lv_obj_set_style_text_color(heading, lv_color_hex(0x00E070), 0);
    lv_obj_align(heading, LV_ALIGN_TOP_MID, 0, 54);

    distance_label = lv_label_create(top_panel);
    lv_label_set_text(distance_label, "--.-- m");
    lv_obj_set_style_text_font(distance_label, &lv_font_montserrat_44, 0);
    lv_obj_set_style_text_color(distance_label, lv_color_hex(0x00E070), 0);
    lv_obj_align(distance_label, LV_ALIGN_TOP_MID, 0, 68);

    status_label = lv_label_create(top_panel);
    lv_label_set_text(status_label, "WAITING FOR C3");
    lv_obj_set_style_text_font(status_label, &lv_font_montserrat_20, 0);
    lv_obj_set_style_text_color(status_label, lv_color_hex(0xAAAAAA), 0);
    lv_obj_align(status_label, LV_ALIGN_TOP_MID, 0, 102);

    lv_obj_t *lane_shadow = make_panel(scr_main, 116, SCR_H, lv_color_hex(0x2A0E0B), lv_color_hex(0x160606));
    lv_obj_align(lane_shadow, LV_ALIGN_CENTER, 0, 0);
    lv_obj_set_style_bg_opa(lane_shadow, LV_OPA_30, 0);

    lv_obj_t *lane_shell = make_panel(scr_main, LANE_SHELL_W, LANE_BOTTOM - LANE_TOP,
                                      lv_color_hex(0xF2F2F2), lv_color_hex(0xD6D6D6));
    lv_obj_align(lane_shell, LV_ALIGN_CENTER, 0, 0);

    lv_obj_t *lane_channel = make_panel(scr_main, LANE_CHANNEL_W, LANE_BOTTOM - LANE_TOP,
                                        lv_color_hex(0x430E11), lv_color_hex(0x240608));
    lv_obj_align(lane_channel, LV_ALIGN_CENTER, 0, 0);

    lane_core = make_panel(scr_main, LANE_CORE_W, LANE_BOTTOM - LANE_TOP,
                           lv_color_hex(0xFF4D1C), lv_color_hex(0x5E0F0C));
    lv_obj_align(lane_core, LV_ALIGN_CENTER, 0, 0);

    portal_ring = make_circle(scr_main, PORTAL_RING_SZ, lv_color_white(), LV_OPA_95);
    lv_obj_set_pos(portal_ring, CENTER_X - PORTAL_RING_SZ / 2, PORTAL_CY - PORTAL_RING_SZ / 2);

    portal_hole = make_circle(scr_main, PORTAL_HOLE_SZ, lv_color_black(), LV_OPA_COVER);
    lv_obj_set_pos(portal_hole, CENTER_X - PORTAL_HOLE_SZ / 2, PORTAL_CY - PORTAL_HOLE_SZ / 2);
    lv_obj_set_style_shadow_color(portal_hole, lv_color_black(), 0);
    lv_obj_set_style_shadow_width(portal_hole, 36, 0);
    lv_obj_set_style_shadow_opa(portal_hole, LV_OPA_70, 0);

    primary_halo = make_panel(scr_main, 60, 18, lv_color_hex(0x2BD975), lv_color_hex(0x2BD975));
    lv_obj_set_style_radius(primary_halo, LV_RADIUS_CIRCLE, 0);
    lv_obj_set_style_bg_opa(primary_halo, LV_OPA_60, 0);
    lv_obj_set_style_shadow_color(primary_halo, lv_color_hex(0x2BD975), 0);
    lv_obj_set_style_shadow_width(primary_halo, 16, 0);
    lv_obj_set_style_shadow_opa(primary_halo, LV_OPA_80, 0);

    primary_core = make_circle(scr_main, 24, lv_color_white(), LV_OPA_COVER);
    lv_obj_set_style_border_width(primary_core, 3, 0);
    lv_obj_set_style_border_color(primary_core, lv_color_hex(0x2BD975), 0);
    lv_obj_set_style_border_opa(primary_core, LV_OPA_COVER, 0);

    for (int i = 0; i < HISTORY_MARKERS; ++i) {
        history_markers[i] = make_circle(scr_main, 10, lv_color_hex(0x1F8F50), LV_OPA_40);
    }

    lv_obj_t *nav_ring = make_circle(scr_main, NAV_RING_SZ, lv_color_white(), LV_OPA_96);
    lv_obj_set_pos(nav_ring, CENTER_X - NAV_RING_SZ / 2, NAV_CY - NAV_RING_SZ / 2);

    nav_face = make_circle(scr_main, NAV_FACE_SZ, lv_color_hex(0x1E88F5), LV_OPA_COVER);
    lv_obj_set_pos(nav_face, CENTER_X - NAV_FACE_SZ / 2, NAV_CY - NAV_FACE_SZ / 2);
    lv_obj_set_style_shadow_color(nav_face, lv_color_hex(0x0B6BCB), 0);
    lv_obj_set_style_shadow_width(nav_face, 22, 0);
    lv_obj_set_style_shadow_opa(nav_face, LV_OPA_50, 0);
    lv_obj_set_style_border_width(nav_face, 3, 0);
    lv_obj_set_style_border_color(nav_face, lv_color_hex(0x6EC0FF), 0);
    lv_obj_set_style_border_opa(nav_face, LV_OPA_50, 0);

    lv_obj_t *nav_arrow = lv_label_create(nav_face);
    lv_label_set_text(nav_arrow, LV_SYMBOL_UP);
    lv_obj_set_style_text_font(nav_arrow, &lv_font_montserrat_44, 0);
    lv_obj_set_style_text_color(nav_arrow, lv_color_white(), 0);
    lv_obj_center(nav_arrow);

    detail_label = lv_label_create(bottom_panel);
    lv_label_set_text(detail_label, "UART idle");
    lv_obj_set_style_text_font(detail_label, &lv_font_montserrat_20, 0);
    lv_obj_set_style_text_color(detail_label, lv_color_white(), 0);
    lv_obj_align(detail_label, LV_ALIGN_TOP_MID, 0, 12);

    link_label = lv_label_create(bottom_panel);
    lv_label_set_text(link_label, "C3 link offline");
    lv_obj_set_style_text_font(link_label, &lv_font_montserrat_14, 0);
    lv_obj_set_style_text_color(link_label, lv_color_hex(0xC8C8C8), 0);
    lv_obj_align(link_label, LV_ALIGN_BOTTOM_LEFT, 18, -16);

    footprint_label = lv_label_create(bottom_panel);
    lv_label_set_text(footprint_label, "Front cone only");
    lv_obj_set_style_text_font(footprint_label, &lv_font_montserrat_14, 0);
    lv_obj_set_style_text_color(footprint_label, lv_color_hex(0xC8C8C8), 0);
    lv_obj_align(footprint_label, LV_ALIGN_BOTTOM_RIGHT, -18, -16);

    hide_marker_objects();
    lv_scr_load(scr_main);
    apply_marker_visuals();
    lv_timer_create(dashboard_tick_cb, 33, NULL);

    ESP_LOGI(TAG, "dashboard ready");
}
