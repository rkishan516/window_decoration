import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:window_decoration_platform_interface/window_decoration_platform_interface.dart';

import 'package:window_decoration_windows/src/effects/dwm_effects.dart';
import 'package:window_decoration_windows/src/ffi/win32_bindings.dart';

/// Windows implementation of the window_decoration plugin
class WindowDecorationWindows extends WindowDecorationPlatform {
  /// The HWND (window handle) pointer
  late final int _hwnd;

  /// Whether the platform has been initialized
  bool _isInitialized = false;

  /// Registers this class as the default instance of [WindowDecorationPlatform]
  static void registerWith() {
    WindowDecorationPlatform.instance = WindowDecorationWindows();
  }

  @override
  void initialize(covariant Pointer<Void> windowHandle) {
    _hwnd = windowHandle.address;
    _isInitialized = true;
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'WindowDecorationWindows not initialized. '
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

    // Get current window rect
    final rect = calloc<RECT>();
    try {
      Win32Bindings.getWindowRect(_hwnd, rect);

      final windowWidth = rect.ref.right - rect.ref.left;
      final windowHeight = rect.ref.bottom - rect.ref.top;

      // Get screen dimensions
      final screenWidth = Win32Bindings.getSystemMetrics(
        Win32Bindings.SM_CXSCREEN,
      );
      final screenHeight = Win32Bindings.getSystemMetrics(
        Win32Bindings.SM_CYSCREEN,
      );

      // Calculate centered position
      final x = (screenWidth - windowWidth) ~/ 2;
      final y = (screenHeight - windowHeight) ~/ 2;

      // Set window position
      Win32Bindings.setWindowPos(
        _hwnd,
        0,
        x,
        y,
        0,
        0,
        Win32Bindings.SWP_NOSIZE | Win32Bindings.SWP_NOZORDER,
      );
    } finally {
      calloc.free(rect);
    }
  }

  @override
  Future<WindowBounds> getBounds() async {
    _checkInitialized();

    final rect = calloc<RECT>();
    try {
      Win32Bindings.getWindowRect(_hwnd, rect);

      return WindowBounds(
        x: rect.ref.left.toDouble(),
        y: rect.ref.top.toDouble(),
        width: (rect.ref.right - rect.ref.left).toDouble(),
        height: (rect.ref.bottom - rect.ref.top).toDouble(),
      );
    } finally {
      calloc.free(rect);
    }
  }

  @override
  Future<void> setBounds(WindowBounds bounds) async {
    _checkInitialized();

    Win32Bindings.setWindowPos(
      _hwnd,
      0,
      bounds.x.toInt(),
      bounds.y.toInt(),
      bounds.width.toInt(),
      bounds.height.toInt(),
      Win32Bindings.SWP_NOZORDER,
    );
  }

  // ==========================================================================
  // Appearance
  // ==========================================================================

  @override
  Future<void> setBackgroundColor(Color color) async {
    _checkInitialized();

    // Windows doesn't have a direct API to set window background color
    // This would typically be handled by the Flutter rendering layer
    // For now, we'll use DWM to set caption/border color
    final colorValue = calloc<Uint32>();
    try {
      // Convert Flutter color to COLORREF (0x00BBGGRR)
      final b = (color.b * 255.0).round().clamp(0, 255);
      final g = (color.g * 255.0).round().clamp(0, 255);
      final r = (color.r * 255.0).round().clamp(0, 255);
      colorValue.value = (b << 16) | (g << 8) | r;

      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_CAPTION_COLOR,
        colorValue.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(colorValue);
    }
  }

  @override
  Future<void> setOpacity(double opacity) async {
    _checkInitialized();

    final clampedOpacity = opacity.clamp(0.0, 1.0);

    // Get current window style
    final currentStyle = Win32Bindings.getWindowLongPtr(
      _hwnd,
      Win32Bindings.GWL_EXSTYLE,
    );

    // Add WS_EX_LAYERED style if not present
    if ((currentStyle & Win32Bindings.WS_EX_LAYERED) == 0) {
      Win32Bindings.setWindowLongPtr(
        _hwnd,
        Win32Bindings.GWL_EXSTYLE,
        currentStyle | Win32Bindings.WS_EX_LAYERED,
      );
    }

    // Set alpha value (0-255)
    final alpha = (clampedOpacity * 255).round();
    Win32Bindings.setLayeredWindowAttributes(
      _hwnd,
      0,
      alpha,
      Win32Bindings.LWA_ALPHA,
    );
  }

  // ==========================================================================
  // Behavior
  // ==========================================================================

  @override
  Future<void> setAlwaysOnTop({required bool alwaysOnTop}) async {
    _checkInitialized();

    final insertAfter = alwaysOnTop
        ? Win32Bindings.HWND_TOPMOST
        : Win32Bindings.HWND_NOTOPMOST;

    Win32Bindings.setWindowPos(
      _hwnd,
      insertAfter,
      0,
      0,
      0,
      0,
      Win32Bindings.SWP_NOMOVE |
          Win32Bindings.SWP_NOSIZE |
          Win32Bindings.SWP_NOACTIVATE,
    );
  }

  @override
  Future<void> setSkipTaskbar({required bool skip}) async {
    _checkInitialized();

    final currentStyle = Win32Bindings.getWindowLongPtr(
      _hwnd,
      Win32Bindings.GWL_EXSTYLE,
    );

    final newStyle = skip
        ? currentStyle | Win32Bindings.WS_EX_TOOLWINDOW
        : currentStyle & ~Win32Bindings.WS_EX_TOOLWINDOW;

    Win32Bindings.setWindowLongPtr(_hwnd, Win32Bindings.GWL_EXSTYLE, newStyle);

    // Force window to update
    Win32Bindings.setWindowPos(
      _hwnd,
      0,
      0,
      0,
      0,
      0,
      Win32Bindings.SWP_NOMOVE |
          Win32Bindings.SWP_NOSIZE |
          Win32Bindings.SWP_NOZORDER |
          Win32Bindings.SWP_FRAMECHANGED,
    );
  }

  @override
  Future<void> setFullScreen({required bool fullScreen}) async {
    _checkInitialized();

    final placement = calloc<WINDOWPLACEMENT>();
    try {
      placement.ref.length = sizeOf<WINDOWPLACEMENT>();
      Win32Bindings.getWindowPlacement(_hwnd, placement);

      if (fullScreen) {
        // Get monitor info
        final monitor = Win32Bindings.monitorFromWindow(
          _hwnd,
          Win32Bindings.MONITOR_DEFAULTTONEAREST,
        );

        final monitorInfo = calloc<MONITORINFO>();
        try {
          monitorInfo.ref.cbSize = sizeOf<MONITORINFO>();
          Win32Bindings.getMonitorInfo(monitor, monitorInfo);

          // Set fullscreen bounds
          Win32Bindings.setWindowPos(
            _hwnd,
            0,
            monitorInfo.ref.rcMonitor.left,
            monitorInfo.ref.rcMonitor.top,
            monitorInfo.ref.rcMonitor.right - monitorInfo.ref.rcMonitor.left,
            monitorInfo.ref.rcMonitor.bottom - monitorInfo.ref.rcMonitor.top,
            Win32Bindings.SWP_NOZORDER | Win32Bindings.SWP_FRAMECHANGED,
          );
        } finally {
          calloc.free(monitorInfo);
        }

        placement.ref.showCmd = Win32Bindings.SW_MAXIMIZE;
      } else {
        placement.ref.showCmd = Win32Bindings.SW_NORMAL;
      }

      Win32Bindings.setWindowPlacement(_hwnd, placement);
    } finally {
      calloc.free(placement);
    }
  }

  @override
  Future<void> setTitleBarStyle(TitleBarStyle style) async {
    _checkInitialized();

    switch (style) {
      case TitleBarStyle.normal:
        // Reset to default window with standard title bar
        _restoreStandardTitleBar();

      case TitleBarStyle.hidden:
        // Hide title bar by removing caption and borders
        _hideWindowFrame();

      case TitleBarStyle.transparent:
        // Create transparent title bar by extending frame into client area
        _createTransparentTitleBar();

      case TitleBarStyle.unified:
        // Create unified look with custom drawn title bar
        _createUnifiedTitleBar();
    }

    // Force window to redraw with new style
    Win32Bindings.setWindowPos(
      _hwnd,
      0,
      0,
      0,
      0,
      0,
      Win32Bindings.SWP_NOMOVE |
          Win32Bindings.SWP_NOSIZE |
          Win32Bindings.SWP_NOZORDER |
          Win32Bindings.SWP_FRAMECHANGED,
    );
  }

  @override
  Future<void> setVisible({required bool visible}) async {
    _checkInitialized();

    // Use ShowWindow to show or hide the window
    final showCmd = visible ? Win32Bindings.SW_SHOW : Win32Bindings.SW_HIDE;
    Win32Bindings.showWindow(_hwnd, showCmd);
  }

  void _restoreStandardTitleBar() {
    // Restore standard window style with title bar
    final currentStyle = Win32Bindings.getWindowLongPtr(
      _hwnd,
      Win32Bindings.GWL_STYLE,
    );

    // Add back caption and frame
    final newStyle =
        currentStyle |
        Win32Bindings.WS_CAPTION |
        Win32Bindings.WS_THICKFRAME |
        Win32Bindings.WS_SYSMENU |
        Win32Bindings.WS_MINIMIZEBOX |
        Win32Bindings.WS_MAXIMIZEBOX;

    Win32Bindings.setWindowLongPtr(_hwnd, Win32Bindings.GWL_STYLE, newStyle);

    // Reset frame extension
    final margins = calloc<MARGINS>();
    try {
      margins.ref.cxLeftWidth = 0;
      margins.ref.cxRightWidth = 0;
      margins.ref.cyTopHeight = 0;
      margins.ref.cyBottomHeight = 0;
      Win32Bindings.dwmExtendFrameIntoClientArea(_hwnd, margins);
    } finally {
      calloc.free(margins);
    }
  }

  void _hideWindowFrame() {
    // Remove all window decorations including title bar
    final currentStyle = Win32Bindings.getWindowLongPtr(
      _hwnd,
      Win32Bindings.GWL_STYLE,
    );

    // Use WS_POPUP style for proper borderless window that handles input correctly.
    // Simply removing WS_CAPTION without WS_POPUP causes input issues (text fields don't work)
    // because Windows doesn't properly handle the non-client area calculations.
    final newStyle =
        (currentStyle &
            ~(Win32Bindings.WS_CAPTION |
                Win32Bindings.WS_SYSMENU |
                Win32Bindings.WS_OVERLAPPED)) |
        Win32Bindings.WS_POPUP |
        Win32Bindings.WS_THICKFRAME |
        Win32Bindings.WS_MINIMIZEBOX |
        Win32Bindings.WS_MAXIMIZEBOX;

    Win32Bindings.setWindowLongPtr(_hwnd, Win32Bindings.GWL_STYLE, newStyle);
  }

  void _createTransparentTitleBar() {
    // Transparent title bar: Keep title bar but make it blend with content
    // Uses DWM attributes to style the title bar without frame extension

    // Ensure we have standard window style
    final currentStyle = Win32Bindings.getWindowLongPtr(
      _hwnd,
      Win32Bindings.GWL_STYLE,
    );
    if ((currentStyle & Win32Bindings.WS_CAPTION) == 0) {
      final newStyle =
          currentStyle | Win32Bindings.WS_CAPTION | Win32Bindings.WS_THICKFRAME;
      Win32Bindings.setWindowLongPtr(_hwnd, Win32Bindings.GWL_STYLE, newStyle);
    }

    // Set transparent/dark caption color (Windows 11)
    final captionColor = calloc<Uint32>();
    try {
      // COLORREF format: 0x00BBGGRR (black with some transparency)
      captionColor.value = 0x00000000;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_CAPTION_COLOR,
        captionColor.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(captionColor);
    }

    // Set text color to white for visibility
    final textColor = calloc<Uint32>();
    try {
      textColor.value = 0x00FFFFFF; // White
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_TEXT_COLOR,
        textColor.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(textColor);
    }

    // Enable dark mode
    final darkMode = calloc<Uint32>();
    try {
      darkMode.value = 1;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_USE_IMMERSIVE_DARK_MODE,
        darkMode.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(darkMode);
    }

    // Apply Mica backdrop effect (Windows 11 22H2+)
    final backdrop = calloc<Uint32>();
    try {
      backdrop.value = Win32Bindings.DWMSBT_MAINWINDOW;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_SYSTEMBACKDROP_TYPE,
        backdrop.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(backdrop);
    }
  }

  void _createUnifiedTitleBar() {
    // Unified title bar: Similar to transparent but with Mica/Acrylic effect
    // Creates a modern Windows 11 appearance

    // Ensure we have standard window style
    final currentStyle = Win32Bindings.getWindowLongPtr(
      _hwnd,
      Win32Bindings.GWL_STYLE,
    );
    if ((currentStyle & Win32Bindings.WS_CAPTION) == 0) {
      final newStyle =
          currentStyle | Win32Bindings.WS_CAPTION | Win32Bindings.WS_THICKFRAME;
      Win32Bindings.setWindowLongPtr(_hwnd, Win32Bindings.GWL_STYLE, newStyle);
    }

    // Apply Mica backdrop for unified appearance (Windows 11)
    final backdrop = calloc<Uint32>();
    try {
      backdrop.value = Win32Bindings.DWMSBT_MAINWINDOW;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_SYSTEMBACKDROP_TYPE,
        backdrop.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(backdrop);
    }

    // Enable rounded corners
    final corners = calloc<Uint32>();
    try {
      corners.value = Win32Bindings.DWMWCP_ROUND;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_WINDOW_CORNER_PREFERENCE,
        corners.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(corners);
    }

    // Use dark mode
    final darkMode = calloc<Uint32>();
    try {
      darkMode.value = 1;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_USE_IMMERSIVE_DARK_MODE,
        darkMode.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(darkMode);
    }

    // Make caption color match the unified theme
    final captionColor = calloc<Uint32>();
    try {
      // Dark gray for unified appearance
      captionColor.value = 0x00202020;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_CAPTION_COLOR,
        captionColor.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(captionColor);
    }

    // Set border color to match
    final borderColor = calloc<Uint32>();
    try {
      borderColor.value = 0x00404040;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_BORDER_COLOR,
        borderColor.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(borderColor);
    }
  }

  // ==========================================================================
  // Windows-Specific Features
  // ==========================================================================

  /// Set DWM system backdrop type (Windows 11 only)
  Future<void> setSystemBackdrop(DWMSystemBackdropType backdrop) async {
    _checkInitialized();

    final value = calloc<Uint32>();
    try {
      value.value = backdrop.value;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_SYSTEMBACKDROP_TYPE,
        value.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(value);
    }
  }

  /// Set window corner preference (Windows 11 only)
  Future<void> setCornerPreference(WindowCornerPreference preference) async {
    _checkInitialized();

    final value = calloc<Uint32>();
    try {
      value.value = preference.value;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_WINDOW_CORNER_PREFERENCE,
        value.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(value);
    }
  }

  /// Set border color (Windows 11 only)
  Future<void> setBorderColor(Color color) async {
    _checkInitialized();

    final colorValue = calloc<Uint32>();
    try {
      // Convert Flutter color to COLORREF (0x00BBGGRR)
      final b = (color.b * 255.0).round().clamp(0, 255);
      final g = (color.g * 255.0).round().clamp(0, 255);
      final r = (color.r * 255.0).round().clamp(0, 255);
      colorValue.value = (b << 16) | (g << 8) | r;

      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_BORDER_COLOR,
        colorValue.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(colorValue);
    }
  }

  /// Enable dark mode (Windows 10 1809+)
  Future<void> setDarkMode({required bool enabled}) async {
    _checkInitialized();

    final value = calloc<Uint32>();
    try {
      value.value = enabled ? 1 : 0;
      Win32Bindings.dwmSetWindowAttribute(
        _hwnd,
        Win32Bindings.DWMWA_USE_IMMERSIVE_DARK_MODE,
        value.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      calloc.free(value);
    }
  }

  /// Check if window is always on top
  Future<bool> isAlwaysOnTop() async {
    _checkInitialized();

    final exStyle = Win32Bindings.getWindowLongPtr(
      _hwnd,
      Win32Bindings.GWL_EXSTYLE,
    );
    return (exStyle & Win32Bindings.WS_EX_TOPMOST) != 0;
  }
}
