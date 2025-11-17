import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:window_decoration_platform_interface/src/models/title_bar_style.dart';
import 'package:window_decoration_platform_interface/src/models/window_bounds.dart';
import 'package:window_decoration_platform_interface/src/platform_stub.dart'
    if (dart.library.io) 'package:window_decoration_platform_interface/src/platform_io.dart';
import 'package:window_decoration_platform_interface/src/ffi_stub.dart'
    if (dart.library.io) 'package:window_decoration_platform_interface/src/ffi_io.dart';

/// The interface that platform-specific implementations of window_decoration must implement.
///
/// Platform implementations should extend this class rather than implement it as `window_decoration`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [WindowDecorationPlatform] methods.
abstract class WindowDecorationPlatform extends PlatformInterface {
  WindowDecorationPlatform() : super(token: _token);

  static final Object _token = Object();

  static WindowDecorationPlatform? _instance;

  /// The default instance of [WindowDecorationPlatform] to use.
  ///
  /// Defaults to the appropriate platform-specific implementation.
  static WindowDecorationPlatform get instance {
    _instance ??= _createPlatformInstance();
    return _instance!;
  }

  /// Platform implementations should set this with their own platform-specific class that extends [WindowDecorationPlatform].
  static set instance(WindowDecorationPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  static WindowDecorationPlatform _createPlatformInstance() {
    if (kIsWeb) {
      // Will be set by window_decoration_web package
      throw UnsupportedError(
        'Web platform implementation not found. '
        'Make sure window_decoration_web is added as a dependency.',
      );
    } else if (isMacOS) {
      // Will be set by window_decoration_macos package
      throw UnsupportedError(
        'macOS platform implementation not found. '
        'Make sure window_decoration_macos is added as a dependency.',
      );
    } else if (isWindows) {
      throw UnsupportedError(
        'Windows platform implementation not found. '
        'Make sure window_decoration_windows is added as a dependency.',
      );
    } else if (isLinux) {
      throw UnsupportedError(
        'Linux platform implementation not found. '
        'Make sure window_decoration_linux is added as a dependency.',
      );
    }
    throw UnsupportedError('Platform $operatingSystem is not supported');
  }

  /// Initialize the platform implementation with the native window handle.
  ///
  /// This must be called before any other methods.
  ///
  /// The [windowHandle] is a pointer to the native window:
  /// - macOS: NSWindow* (Pointer<Void>)
  /// - Windows: HWND (Pointer<Void>)
  /// - Linux: GtkWindow* (Pointer<Void>)
  /// - Web: null
  void initialize(FfiPointer windowHandle);

  /// Centers the window on the screen.
  Future<void> center();

  /// Gets the current window bounds (position and size).
  Future<WindowBounds> getBounds();

  /// Sets the window bounds (position and size).
  Future<void> setBounds(WindowBounds bounds);

  /// Sets the background color of the window.
  ///
  /// Note: On some platforms, this may only affect the window frame,
  /// not the Flutter content area.
  Future<void> setBackgroundColor(Color color);

  /// Sets the opacity of the window.
  ///
  /// [opacity] should be between 0.0 (fully transparent) and 1.0 (fully opaque).
  Future<void> setOpacity(double opacity);

  /// Sets whether the window should stay on top of other windows.
  Future<void> setAlwaysOnTop({required bool alwaysOnTop});

  /// Sets whether the window should be hidden from the taskbar/dock.
  ///
  /// On macOS, this affects the entire application's dock icon.
  /// On Windows/Linux, this only affects the specific window.
  Future<void> setSkipTaskbar({required bool skip});

  /// Sets whether the window should be in fullscreen mode.
  Future<void> setFullScreen({required bool fullScreen});

  /// Sets the title bar style.
  Future<void> setTitleBarStyle(TitleBarStyle style);

  /// Sets whether the window is visible.
  ///
  /// When [visible] is true, the window will be shown.
  /// When [visible] is false, the window will be hidden.
  Future<void> setVisible({required bool visible});
}
