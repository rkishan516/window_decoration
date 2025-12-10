import 'package:flutter/material.dart';
import 'package:window_decoration_platform_interface/src/models/title_bar_style.dart';
import 'package:window_decoration_platform_interface/src/models/window_bounds.dart';
import 'package:window_decoration_platform_interface/src/window_decoration_platform.dart';

/// Web implementation of the window_decoration plugin
///
/// Most window decoration features are not available on web as browsers
/// control the window chrome. This implementation provides no-op or
/// limited functionality where possible.
class WindowDecorationWeb extends WindowDecorationPlatform {
  /// Whether the platform has been initialized
  bool _isInitialized = false;

  /// Registers this class as the default instance of [WindowDecorationPlatform]
  static void registerWith() {
    WindowDecorationPlatform.instance = WindowDecorationWeb();
  }

  @override
  void initialize(Object? windowHandle) {
    // On web, there's no native window handle
    // Mark as initialized to allow other methods to be called
    _isInitialized = true;
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'WindowDecorationWeb not initialized. '
        'Call initialize() first.',
      );
    }
  }

  // ==========================================================================
  // Position & Size
  // ==========================================================================

  @override
  Future<void> center() async {
    _checkInitialized();
    // No-op on web - browsers control window positioning
  }

  @override
  Future<WindowBounds> getBounds() async {
    _checkInitialized();

    // Return browser window dimensions
    // Note: This returns the viewport size, not the actual window bounds
    return WindowBounds(x: 0, y: 0, width: 0, height: 0);
  }

  @override
  Future<void> setBounds(WindowBounds bounds) async {
    _checkInitialized();
    // No-op on web - browsers control window size and position
  }

  // ==========================================================================
  // Appearance
  // ==========================================================================

  @override
  Future<void> setBackgroundColor(Color color) async {
    _checkInitialized();
    // Could potentially set document background color here
    // For now, no-op as Flutter controls the canvas
  }

  @override
  Future<void> setOpacity(double opacity) async {
    _checkInitialized();
    // No-op on web - browsers don't support window opacity
  }

  // ==========================================================================
  // Behavior
  // ==========================================================================

  @override
  Future<void> setAlwaysOnTop({required bool alwaysOnTop}) async {
    _checkInitialized();
    // No-op on web - browsers control window layering
  }

  @override
  Future<void> setSkipTaskbar({required bool skip}) async {
    _checkInitialized();
    // No-op on web - not applicable
  }

  @override
  Future<void> setFullScreen({required bool fullScreen}) async {
    _checkInitialized();
    // Could potentially use Fullscreen API here
    // For now, no-op
  }

  @override
  Future<void> setTitleBarStyle(TitleBarStyle style, {int captionHeight = 32}) async {
    _checkInitialized();
    // No-op on web - browsers control the title bar
  }

  @override
  Future<void> setVisible({required bool visible}) async {
    _checkInitialized();
    // No-op on web - browsers control window visibility
  }
}
