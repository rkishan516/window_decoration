// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:window_decoration_platform_interface/window_decoration_platform_interface.dart';
import 'package:window_decoration/src/platform_stub.dart'
    if (dart.library.io) 'package:window_decoration/src/platform_io.dart';

/// Service for programmatic window decoration control
///
/// This class provides methods to customize window appearance and behavior
/// on desktop platforms. It wraps the platform-specific implementations
/// and provides a unified API.
///
/// Example:
/// ```dart
/// final controller = RegularWindowController(...);
/// final service = WindowDecorationService(controller);
///
/// await service.center();
/// await service.setAlwaysOnTop(true);
/// ```
class WindowDecorationService {
  WindowDecorationService(this._controller) {
    _initializePlatform();
  }

  /// The window controller provided by Flutter
  final RegularWindowController _controller;

  /// The platform-specific implementation
  late final WindowDecorationPlatform _platform;

  /// Platform-specific macOS implementation
  /// Only available on macOS, throws on other platforms
  dynamic get macos {
    if (kIsWeb) {
      throw UnsupportedError('macOS-specific API not available on web.');
    }
    final platformImpl = _platform as dynamic;
    if (platformImpl.runtimeType.toString() == 'WindowDecorationMacOS') {
      return platformImpl;
    }
    throw UnsupportedError(
      'macOS-specific API only available on macOS. '
      'Current platform: ${getPlatformName()}',
    );
  }

  /// Platform-specific Windows implementation
  /// Only available on Windows, throws on other platforms
  dynamic get windows {
    if (kIsWeb) {
      throw UnsupportedError('Windows-specific API not available on web.');
    }
    final platformImpl = _platform as dynamic;
    if (platformImpl.runtimeType.toString() == 'WindowDecorationWindows') {
      return platformImpl;
    }
    throw UnsupportedError(
      'Windows-specific API only available on Windows. '
      'Current platform: ${getPlatformName()}',
    );
  }

  /// Platform-specific Linux implementation
  /// Only available on Linux, throws on other platforms
  dynamic get linux {
    if (kIsWeb) {
      throw UnsupportedError('Linux-specific API not available on web.');
    }
    final platformImpl = _platform as dynamic;
    if (platformImpl.runtimeType.toString() == 'WindowDecorationLinux') {
      return platformImpl;
    }
    throw UnsupportedError(
      'Linux-specific API only available on Linux. '
      'Current platform: ${getPlatformName()}',
    );
  }

  void _initializePlatform() {
    _platform = createPlatform(_controller);
  }

  // ==========================================================================
  // Position & Size
  // ==========================================================================

  /// Centers the window on the screen
  Future<void> center() => _platform.center();

  /// Gets the current window bounds (position and size)
  Future<WindowBounds> getBounds() => _platform.getBounds();

  /// Sets the window bounds (position and size)
  Future<void> setBounds(WindowBounds bounds) => _platform.setBounds(bounds);

  // ==========================================================================
  // Appearance
  // ==========================================================================

  /// Sets the background color of the window
  ///
  /// Note: On some platforms, this may only affect the window frame,
  /// not the Flutter content area.
  Future<void> setBackgroundColor(Color color) =>
      _platform.setBackgroundColor(color);

  /// Sets the opacity of the window
  ///
  /// [opacity] should be between 0.0 (fully transparent) and 1.0 (fully opaque).
  Future<void> setOpacity(double opacity) => _platform.setOpacity(opacity);

  // ==========================================================================
  // Behavior
  // ==========================================================================

  /// Sets whether the window should stay on top of other windows
  Future<void> setAlwaysOnTop({required bool alwaysOnTop}) =>
      _platform.setAlwaysOnTop(alwaysOnTop: alwaysOnTop);

  /// Sets whether the window should be hidden from the taskbar/dock
  ///
  /// On macOS, this affects the entire application's dock icon.
  /// On Windows/Linux, this only affects the specific window.
  Future<void> setSkipTaskbar({required bool skip}) =>
      _platform.setSkipTaskbar(skip: skip);

  /// Sets whether the window should be in fullscreen mode
  Future<void> setFullScreen({required bool fullScreen}) =>
      _platform.setFullScreen(fullScreen: fullScreen);

  /// Sets the title bar style
  ///
  /// [captionHeight] is only used on Windows when [style] is [TitleBarStyle.customFrame].
  /// It defines the height of the draggable caption area in logical pixels.
  /// Default is 32 pixels.
  Future<void> setTitleBarStyle(TitleBarStyle style, {int captionHeight = 32}) =>
      _platform.setTitleBarStyle(style, captionHeight: captionHeight);

  /// Sets whether the window is visible
  ///
  /// When [visible] is true, the window will be shown.
  /// When [visible] is false, the window will be hidden.
  Future<void> setVisible({required bool visible}) =>
      _platform.setVisible(visible: visible);

  /// Shows the window (convenience method for setVisible(visible: true))
  Future<void> show() => setVisible(visible: true);

  /// Hides the window (convenience method for setVisible(visible: false))
  Future<void> hide() => setVisible(visible: false);
}
