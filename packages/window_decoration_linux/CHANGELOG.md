# Changelog

## [Unreleased]

### Changed
- Migrated to Dart workspace architecture
- Updated minimum Dart SDK to 3.10.0
- Updated minimum Flutter SDK to 3.38.1

## [0.1.0] - 2025-01-16

### Added
- Initial release with full Linux support
- GTK3-based window management
- X11 support for window positioning and always-on-top
- Wayland support with graceful degradation for unsupported features
- Window positioning: `center()`, `getBounds()`, `setBounds()`
- Window appearance: `setOpacity()`, `setBackgroundColor()`
- Window behavior: `setAlwaysOnTop()`, `setSkipTaskbar()`, `setFullScreen()`
- Display server detection (`isX11()`, `isWayland()`)
- FFI bindings to GTK3 and X11 libraries
