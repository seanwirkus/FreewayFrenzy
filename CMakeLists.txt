cmake_minimum_required(VERSION 3.5)

# Use the local components folder for drivers (RGB LCD, LVGL, etc.)
set(EXTRA_COMPONENT_DIRS "components")
set(PROJECT_VER "0.1.0")

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
add_compile_options("-Wno-attributes")
project(FreewayFrenzy)
