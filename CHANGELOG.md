# Changelog

All notable changes to the window_decoration workspace will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Dart workspace configuration for managing multiple packages
- Centralized `analysis.yaml` with shared lint rules
- README files for all platform packages
- CHANGELOG files for all platform packages
- Development documentation in root README

### Changed
- Migrated to Dart workspace architecture
- Updated minimum Dart SDK to 3.10.0 across all packages
- Updated minimum Flutter SDK to 3.38.1 across all packages
- Consolidated analysis configuration to root level
- Removed nested `analysis_options.yaml` files

### Package Versions
- window_decoration: 0.1.0
- window_decoration_platform_interface: 0.1.0
- window_decoration_macos: 0.1.0
- window_decoration_linux: 0.1.0
- window_decoration_windows: 0.1.0

## [0.1.0] - 2025-01-16

### Added
- Initial release of window_decoration package
- Multi-platform support (macOS, Windows, Linux)
- macOS implementation with full feature support (tested on Apple Silicon)
- Windows implementation with DWM effects support
- Linux implementation with GTK3/X11/Wayland support
- Platform interface for extensibility
- Example application demonstrating all features
- Comprehensive API for window decoration across all platforms
