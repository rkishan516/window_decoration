# window_decoration_linux

Linux implementation of the `window_decoration` plugin.

This package provides native Linux window decoration support using GTK3 and X11.

## Features

- Window positioning and sizing (`center()`, `getBounds()`, `setBounds()`)
- Window appearance (`setOpacity()`, `setBackgroundColor()`)
- Window behavior (`setAlwaysOnTop()`, `setSkipTaskbar()`, `setFullScreen()`)
- GTK3-based window management
- X11 support for positioning and always-on-top
- Wayland detection and graceful degradation for unsupported features
- Display server detection (`isX11()`, `isWayland()`)

## Platform Requirements

- Linux with X11 or Wayland
- GTK3 libraries
- Dart SDK: >=3.10.0 <4.0.0
- Flutter SDK: >=3.38.1

## Usage

This package is automatically used by the main `window_decoration` package on Linux. You typically don't need to depend on it directly.

## Implementation

Uses FFI bindings to GTK3 and X11 libraries for native window manipulation.
