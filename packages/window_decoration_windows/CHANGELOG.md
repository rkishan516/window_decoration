# Changelog

## [Unreleased]

### Changed
- Migrated to Dart workspace architecture
- Updated minimum Dart SDK to 3.10.0
- Updated minimum Flutter SDK to 3.38.1

## [0.1.0] - 2025-01-16

### Added
- Initial release with full Windows support
- Win32 window manipulation via FFI
- DWM (Desktop Window Manager) effects:
  - Mica effect (Windows 11)
  - Acrylic backdrop (Windows 10 1803+)
  - Custom system backdrop types
- Window positioning: `center()`, `getBounds()`, `setBounds()`
- Window appearance: `setOpacity()`, `setBackgroundColor()`
- Window behavior: `setAlwaysOnTop()`, `setSkipTaskbar()`, `setFullScreen()`
- Dark mode titlebar support (Windows 10 1809+)
- Window corner preference (rounded, sharp, etc.)
- Border and caption color customization
- FFI bindings to Win32 APIs (User32, DwmApi)
