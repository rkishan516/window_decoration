# window_decoration_platform_interface

Platform interface for the `window_decoration` plugin.

This package defines the interface that platform-specific implementations must implement.

## Usage

This package is typically not used directly. Instead, use the main `window_decoration` package which will automatically use the correct platform implementation.

## For Plugin Implementers

To implement support for a new platform:

1. Extend `WindowDecorationPlatform`
2. Implement all required methods
3. Register your implementation using `WindowDecorationPlatform.instance = YourImplementation()`

## Requirements

- Dart SDK: >=3.10.0 <4.0.0
- Flutter SDK: >=3.38.1
