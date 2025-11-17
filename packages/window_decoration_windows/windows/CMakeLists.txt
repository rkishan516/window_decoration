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

# This is a minimal stub for an FFI plugin.
# FFI plugins don't have native code to compile, but the Flutter build
# system requires a CMakeLists.txt file to be present.

# Define an empty bundled libraries list
set(window_decoration_windows_bundled_libraries
  ""
  PARENT_SCOPE
)
