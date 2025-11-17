# window_decoration_macos

macOS implementation of the `window_decoration` plugin.

This package provides native macOS window decoration support using AppKit and Cocoa frameworks.

## Features

- Window positioning and sizing
- Window appearance customization (background color, opacity)
- Title bar styles (normal, hidden, transparent, unified)
- NSVisualEffectMaterial support for vibrancy effects
- Window behavior (always on top, skip taskbar, fullscreen)
- Window shadow control
- Collection behavior configuration

## Platform Requirements

- macOS 10.14 (Mojave) or later
- Dart SDK: >=3.10.0 <4.0.0
- Flutter SDK: >=3.38.1

## Usage

This package is automatically used by the main `window_decoration` package on macOS. You typically don't need to depend on it directly.

## Implementation

Uses FFI bindings to AppKit and Cocoa frameworks for native window manipulation.
