/******************************************************************************
 * Front radar dashboard for the ESP32-S3 RGB LCD.
 *****************************************************************************/
#pragma once

void game_ui_init(void);
void game_ui_update_from_wire(const void *packet_void);
