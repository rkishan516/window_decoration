# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "window_decoration_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "window_decoration_windows_plugin")

# Build the native plugin library
add_library(${PLUGIN_NAME} SHARED
  "window_decoration_windows_plugin.cpp"
)

# Set C++ standard
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED YES
)

# Windows-specific compiler definitions
target_compile_definitions(${PLUGIN_NAME} PRIVATE
  UNICODE
  _UNICODE
  WIN32_LEAN_AND_MEAN
)

# Link required Windows libraries
target_link_libraries(${PLUGIN_NAME} PRIVATE
  dwmapi
  comctl32
)

# Bundle the plugin DLL with the Flutter app
set(window_decoration_windows_bundled_libraries
  "$<TARGET_FILE:${PLUGIN_NAME}>"
  PARENT_SCOPE
)
