import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:window_decoration_linux/src/ffi/gtk_bindings.dart';
import 'package:window_decoration_platform_interface/window_decoration_platform_interface.dart';

/// Linux implementation of the window_decoration plugin
class WindowDecorationLinux extends WindowDecorationPlatform {
  /// The GtkWindow pointer
  late final Pointer<Void> _gtkWindow;

  /// Whether the platform has been initialized
  bool _isInitialized = false;

  /// Registers this class as the default instance of [WindowDecorationPlatform]
  static void registerWith() {
    WindowDecorationPlatform.instance = WindowDecorationLinux();
  }

  @override
  void initialize(covariant Pointer<Void> windowHandle) {
    _gtkWindow = windowHandle;
    _isInitialized = true;
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'WindowDecorationLinux not initialized. '
        'Call initialize() with the window handle first.',
      );
    }
  }

  // ==========================================================================
  // Position & Size
  // ==========================================================================

  @override
  Future<void> center() async {
    _checkInitialized();

    // Get current window size
    final width = calloc<Int32>();
    final height = calloc<Int32>();

    try {
      GtkBindings.windowGetSize(_gtkWindow, width, height);

      // Get screen dimensions
      final screen = GtkBindings.screenGetDefault();
      final screenWidth = GtkBindings.screenGetWidth(screen);
      final screenHeight = GtkBindings.screenGetHeight(screen);

      // Calculate centered position
      final x = (screenWidth - width.value) ~/ 2;
      final y = (screenHeight - height.value) ~/ 2;

      // Move window to center
      GtkBindings.windowMove(_gtkWindow, x, y);
    } finally {
      calloc
        ..free(width)
        ..free(height);
    }
  }

  @override
  Future<WindowBounds> getBounds() async {
    _checkInitialized();

    final x = calloc<Int32>();
    final y = calloc<Int32>();
    final width = calloc<Int32>();
    final height = calloc<Int32>();

    try {
      GtkBindings.windowGetPosition(_gtkWindow, x, y);
      GtkBindings.windowGetSize(_gtkWindow, width, height);

      return WindowBounds(
        x: x.value.toDouble(),
        y: y.value.toDouble(),
        width: width.value.toDouble(),
        height: height.value.toDouble(),
      );
    } finally {
      calloc
        ..free(x)
        ..free(y)
        ..free(width)
        ..free(height);
    }
  }

  @override
  Future<void> setBounds(WindowBounds bounds) async {
    _checkInitialized();

    // Move and resize window
    GtkBindings.windowMove(_gtkWindow, bounds.x.toInt(), bounds.y.toInt());
    GtkBindings.windowResize(
      _gtkWindow,
      bounds.width.toInt(),
      bounds.height.toInt(),
    );
  }

  // ==========================================================================
  // Appearance
  // ==========================================================================

  @override
  Future<void> setBackgroundColor(Color color) async {
    _checkInitialized();

    // GTK window background color is typically handled by the theme
    // For custom colors, you would need to use CSS providers
    // This is a limitation of GTK3 - not easily customizable via FFI
    // TODO(enhancement): Implement CSS provider for custom background colors
  }

  @override
  Future<void> setOpacity(double opacity) async {
    _checkInitialized();

    final clampedOpacity = opacity.clamp(0.0, 1.0);
    GtkBindings.windowSetOpacity(_gtkWindow, clampedOpacity);
  }

  // ==========================================================================
  // Behavior
  // ==========================================================================

  @override
  Future<void> setAlwaysOnTop({required bool alwaysOnTop}) async {
    _checkInitialized();

    // Note: On Wayland, this may not work due to security restrictions
    if (DisplayServerHelper.isWayland()) {
      debugPrint(
        'Warning: setAlwaysOnTop may not work on Wayland due to compositor restrictions',
      );
    }

    GtkBindings.windowSetKeepAbove(_gtkWindow, keepAbove: alwaysOnTop);
  }

  @override
  Future<void> setSkipTaskbar({required bool skip}) async {
    _checkInitialized();

    GtkBindings.windowSetSkipTaskbarHint(_gtkWindow, skip: skip);
  }

  @override
  Future<void> setFullScreen({required bool fullScreen}) async {
    _checkInitialized();

    if (fullScreen) {
      GtkBindings.windowFullscreen(_gtkWindow);
    } else {
      GtkBindings.windowUnfullscreen(_gtkWindow);
    }
  }

  @override
  Future<void> setTitleBarStyle(TitleBarStyle style) async {
    _checkInitialized();

    switch (style) {
      case TitleBarStyle.normal:
        GtkBindings.windowSetDecorated(_gtkWindow, decorated: true);
      case TitleBarStyle.hidden:
        GtkBindings.windowSetDecorated(_gtkWindow, decorated: false);
      case TitleBarStyle.transparent:
        // GTK doesn't have direct transparent title bar support
        // This would require custom CSS and compositing
        GtkBindings.windowSetDecorated(_gtkWindow, decorated: true);
      case TitleBarStyle.unified:
        // Not applicable to Linux GTK windows
        GtkBindings.windowSetDecorated(_gtkWindow, decorated: true);
    }
  }

  @override
  Future<void> setVisible({required bool visible}) async {
    _checkInitialized();

    if (visible) {
      // Show the window
      GtkBindings.widgetShow(_gtkWindow);
    } else {
      // Hide the window
      GtkBindings.widgetHide(_gtkWindow);
    }
  }

  // ==========================================================================
  // Linux-Specific Features
  // ==========================================================================

  /// Check if running on Wayland
  Future<bool> isWayland() async => DisplayServerHelper.isWayland();

  /// Check if running on X11
  Future<bool> isX11() async => DisplayServerHelper.isX11();

  /// Set window type hint (for X11)
  /// Note: This is primarily useful on X11, may not work on Wayland
  Future<void> setWindowTypeHint(String typeHint) async {
    _checkInitialized();

    // This would require accessing GdkWindow and setting X11 properties
    // TODO(enhancement): Implement X11 window type hints via GDK
  }
}
