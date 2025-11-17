# window_decoration_windows

Windows implementation of the `window_decoration` plugin.

This package provides native Windows window decoration support using Win32 APIs.

## Features

- Window positioning and sizing (`center()`, `getBounds()`, `setBounds()`)
- Window appearance (`setOpacity()`, `setBackgroundColor()`)
- Window behavior (`setAlwaysOnTop()`, `setSkipTaskbar()`, `setFullScreen()`)
- DWM effects (Mica, Acrylic, custom system backdrops)
- Win32 window manipulation via FFI
- Dark mode titlebar support (Windows 10 1809+)
- Window corner preference (rounded, sharp, etc.)
- Border and caption color customization
- Window behavior customization

## Platform Requirements

- Windows 10 or later (Windows 11 recommended for modern effects)
- Dart SDK: >=3.10.0 <4.0.0
- Flutter SDK: >=3.38.1

## Usage

This package is automatically used by the main `window_decoration` package on Windows. You typically don't need to depend on it directly.

## Implementation

Uses FFI bindings to Win32 APIs for native window manipulation.
