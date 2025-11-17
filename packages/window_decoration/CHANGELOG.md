# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Migrated to Dart workspace architecture
- Updated minimum Dart SDK to 3.10.0
- Updated minimum Flutter SDK to 3.38.1
- Centralized analysis configuration

## [0.1.0] - 2025-01-16

### Added
- Initial release with multi-platform support (macOS, Windows, Linux)
- Core features (all platforms):
  - Window positioning: `center()`, `getBounds()`, `setBounds()`
  - Window appearance: `setBackgroundColor()`, `setOpacity()`
  - Window behavior: `setAlwaysOnTop()`, `setSkipTaskbar()`, `setFullScreen()`
  - Title bar styles: Normal, Hidden, Transparent, Unified
- Declarative API via `DecoratedWindow` widget
- Programmatic API via `WindowDecorationService`
- Example application demonstrating all features

### Platform-Specific Features

#### macOS (10.14+)
- NSVisualEffectMaterial support for vibrancy effects
- Window shadow control
- Movable by window background
- Collection behavior configuration
- Full NSWindow API access

#### Windows (10/11)
- DWM (Desktop Window Manager) effects
- Mica effect (Windows 11)
- Acrylic backdrop (Windows 10 1803+)
- Custom window corner preference
- Border and caption color customization
- Dark mode titlebar support
- Win32 window manipulation via FFI

#### Linux (GTK3/X11)
- GTK3-based window management
- X11 support for positioning and always-on-top
- Wayland support with limitations (compositor restrictions)
- Opacity and fullscreen support
- X11 window manager hints

### Platform Support
- ✅ macOS 10.14+ (fully supported and tested)
- ✅ Windows 10/11 (fully implemented)
- ✅ Linux (GTK3/X11/Wayland)

## [Unreleased]

[0.1.0]: https://github.com/rkishan516/window_decoration/releases/tag/v0.1.0
