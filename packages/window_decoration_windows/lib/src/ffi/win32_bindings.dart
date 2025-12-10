// ignore_for_file: constant_identifier_names, non_constant_identifier_names, prefer_expression_function_bodies

import 'dart:ffi';
import 'dart:io';

/// Win32 API bindings for window manipulation
class Win32Bindings {
  // Load user32.dll and dwmapi.dll
  static final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');
  static final DynamicLibrary _dwmapi = DynamicLibrary.open('dwmapi.dll');

  // Load our native plugin DLL for custom frame handling
  static DynamicLibrary? _pluginLib;

  /// Initialize the native plugin library
  /// This must be called before using enableCustomFrame
  static void initializePlugin(String pluginPath) {
    if (_pluginLib == null) {
      _pluginLib = DynamicLibrary.open(pluginPath);
    }
  }

  /// Try to auto-detect and load the plugin from common locations
  static bool tryAutoInitializePlugin() {
    if (_pluginLib != null) return true;

    // Try common locations where Flutter places plugin DLLs
    final possiblePaths = [
      'window_decoration_windows_plugin.dll',
      'plugins/window_decoration_windows/window_decoration_windows_plugin.dll',
    ];

    for (final path in possiblePaths) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          _pluginLib = DynamicLibrary.open(path);
          return true;
        }
      } catch (_) {
        // Continue trying other paths
      }
    }

    // Try loading from the executable directory
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final pluginPath = '$exeDir/window_decoration_windows_plugin.dll';
      if (File(pluginPath).existsSync()) {
        _pluginLib = DynamicLibrary.open(pluginPath);
        return true;
      }
    } catch (_) {
      // Failed to load
    }

    return false;
  }

  // ==========================================================================
  // Window Positioning & Size (user32.dll)
  // ==========================================================================

  /// SetWindowPos flags
  static const int SWP_NOSIZE = 0x0001;
  static const int SWP_NOMOVE = 0x0002;
  static const int SWP_NOZORDER = 0x0004;
  static const int SWP_NOACTIVATE = 0x0010;
  static const int SWP_FRAMECHANGED = 0x0020;
  static const int SWP_SHOWWINDOW = 0x0040;

  /// HWND_TOPMOST and related constants
  static const int HWND_TOPMOST = -1;
  static const int HWND_NOTOPMOST = -2;

  /// SetWindowPos - Move/resize window
  /// BOOL SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags)
  static final _SetWindowPos = _user32
      .lookupFunction<
        Int32 Function(IntPtr, IntPtr, Int32, Int32, Int32, Int32, Uint32),
        int Function(int, int, int, int, int, int, int)
      >('SetWindowPos');

  static int setWindowPos(
    int hwnd,
    int hwndInsertAfter,
    int x,
    int y,
    int cx,
    int cy,
    int flags,
  ) {
    return _SetWindowPos(hwnd, hwndInsertAfter, x, y, cx, cy, flags);
  }

  /// GetWindowRect - Get window bounds
  /// BOOL GetWindowRect(HWND hWnd, LPRECT lpRect)
  static final _GetWindowRect = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<RECT>),
        int Function(int, Pointer<RECT>)
      >('GetWindowRect');

  static int getWindowRect(int hwnd, Pointer<RECT> rect) {
    return _GetWindowRect(hwnd, rect);
  }

  /// GetSystemMetrics - Get screen dimensions
  /// int GetSystemMetrics(int nIndex)
  static final _GetSystemMetrics = _user32
      .lookupFunction<Int32 Function(Int32), int Function(int)>(
        'GetSystemMetrics',
      );

  static const int SM_CXSCREEN = 0;
  static const int SM_CYSCREEN = 1;

  static int getSystemMetrics(int index) {
    return _GetSystemMetrics(index);
  }

  // ==========================================================================
  // Window Styles & Attributes (user32.dll)
  // ==========================================================================

  /// Window style constants
  static const int GWL_STYLE = -16;
  static const int GWL_EXSTYLE = -20;

  // Window styles
  static const int WS_OVERLAPPED = 0x00000000;
  static const int WS_CAPTION = 0x00C00000;
  static const int WS_SYSMENU = 0x00080000;
  static const int WS_THICKFRAME = 0x00040000;
  static const int WS_MINIMIZEBOX = 0x00020000;
  static const int WS_MAXIMIZEBOX = 0x00010000;
  static const int WS_POPUP = 0x80000000;
  static const int WS_BORDER = 0x00800000;

  // Extended window styles
  static const int WS_EX_TOPMOST = 0x00000008;
  static const int WS_EX_TOOLWINDOW = 0x00000080;
  static const int WS_EX_LAYERED = 0x00080000;

  /// GetWindowLongPtr - Get window attribute
  /// LONG_PTR GetWindowLongPtrW(HWND hWnd, int nIndex)
  static final _GetWindowLongPtr = _user32
      .lookupFunction<IntPtr Function(IntPtr, Int32), int Function(int, int)>(
        'GetWindowLongPtrW',
      );

  static int getWindowLongPtr(int hwnd, int index) {
    return _GetWindowLongPtr(hwnd, index);
  }

  /// SetWindowLongPtr - Set window attribute
  /// LONG_PTR SetWindowLongPtrW(HWND hWnd, int nIndex, LONG_PTR dwNewLong)
  static final _SetWindowLongPtr = _user32
      .lookupFunction<
        IntPtr Function(IntPtr, Int32, IntPtr),
        int Function(int, int, int)
      >('SetWindowLongPtrW');

  static int setWindowLongPtr(int hwnd, int index, int newLong) {
    return _SetWindowLongPtr(hwnd, index, newLong);
  }

  /// SetLayeredWindowAttributes - Set window opacity
  /// BOOL SetLayeredWindowAttributes(HWND hwnd, COLORREF crKey, BYTE bAlpha, DWORD dwFlags)
  static final _SetLayeredWindowAttributes = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Uint32, Uint8, Uint32),
        int Function(int, int, int, int)
      >('SetLayeredWindowAttributes');

  static const int LWA_ALPHA = 0x00000002;
  static const int LWA_COLORKEY = 0x00000001;

  static int setLayeredWindowAttributes(
    int hwnd,
    int crKey,
    int alpha,
    int flags,
  ) {
    return _SetLayeredWindowAttributes(hwnd, crKey, alpha, flags);
  }

  // ==========================================================================
  // DWM (Desktop Window Manager) APIs (dwmapi.dll)
  // ==========================================================================

  /// DwmSetWindowAttribute - Set DWM window attributes
  /// HRESULT DwmSetWindowAttribute(HWND hwnd, DWORD dwAttribute, LPCVOID pvAttribute, DWORD cbAttribute)
  static final _DwmSetWindowAttribute = _dwmapi
      .lookupFunction<
        Int32 Function(IntPtr, Uint32, Pointer<Void>, Uint32),
        int Function(int, int, Pointer<Void>, int)
      >('DwmSetWindowAttribute');

  static int dwmSetWindowAttribute(
    int hwnd,
    int attribute,
    Pointer<Void> attributeValue,
    int attributeSize,
  ) {
    return _DwmSetWindowAttribute(
      hwnd,
      attribute,
      attributeValue,
      attributeSize,
    );
  }

  /// DwmExtendFrameIntoClientArea - Extend window frame into client area
  /// HRESULT DwmExtendFrameIntoClientArea(HWND hWnd, const MARGINS *pMarInset)
  static final _DwmExtendFrameIntoClientArea = _dwmapi
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<MARGINS>),
        int Function(int, Pointer<MARGINS>)
      >('DwmExtendFrameIntoClientArea');

  static int dwmExtendFrameIntoClientArea(int hwnd, Pointer<MARGINS> margins) {
    return _DwmExtendFrameIntoClientArea(hwnd, margins);
  }

  /// DWMWA (DWM Window Attribute) constants
  static const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  static const int DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  static const int DWMWA_BORDER_COLOR = 34;
  static const int DWMWA_CAPTION_COLOR = 35;
  static const int DWMWA_TEXT_COLOR = 36;
  static const int DWMWA_VISIBLE_FRAME_BORDER_THICKNESS = 37;
  static const int DWMWA_SYSTEMBACKDROP_TYPE = 38;
  static const int DWMWA_MICA_EFFECT = 1029;

  /// DWM_WINDOW_CORNER_PREFERENCE values
  static const int DWMWCP_DEFAULT = 0;
  static const int DWMWCP_DONOTROUND = 1;
  static const int DWMWCP_ROUND = 2;
  static const int DWMWCP_ROUNDSMALL = 3;

  /// DWM_SYSTEMBACKDROP_TYPE values
  static const int DWMSBT_AUTO = 0;
  static const int DWMSBT_NONE = 1;
  static const int DWMSBT_MAINWINDOW = 2;
  static const int DWMSBT_TRANSIENTWINDOW = 3;
  static const int DWMSBT_TABBEDWINDOW = 4;

  // ==========================================================================
  // Monitor APIs (user32.dll)
  // ==========================================================================

  /// MonitorFromWindow - Get monitor handle from window
  /// HMONITOR MonitorFromWindow(HWND hwnd, DWORD dwFlags)
  static final _MonitorFromWindow = _user32
      .lookupFunction<IntPtr Function(IntPtr, Uint32), int Function(int, int)>(
        'MonitorFromWindow',
      );

  static const int MONITOR_DEFAULTTONEAREST = 0x00000002;

  static int monitorFromWindow(int hwnd, int flags) {
    return _MonitorFromWindow(hwnd, flags);
  }

  /// GetMonitorInfo - Get monitor information
  /// BOOL GetMonitorInfoW(HMONITOR hMonitor, LPMONITORINFO lpmi)
  static final _GetMonitorInfo = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<MONITORINFO>),
        int Function(int, Pointer<MONITORINFO>)
      >('GetMonitorInfoW');

  static int getMonitorInfo(int monitor, Pointer<MONITORINFO> info) {
    return _GetMonitorInfo(monitor, info);
  }

  // ==========================================================================
  // Fullscreen APIs
  // ==========================================================================

  /// GetWindowPlacement - Get window state
  /// BOOL GetWindowPlacement(HWND hWnd, WINDOWPLACEMENT *lpwndpl)
  static final _GetWindowPlacement = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<WINDOWPLACEMENT>),
        int Function(int, Pointer<WINDOWPLACEMENT>)
      >('GetWindowPlacement');

  static int getWindowPlacement(int hwnd, Pointer<WINDOWPLACEMENT> placement) {
    return _GetWindowPlacement(hwnd, placement);
  }

  /// SetWindowPlacement - Set window state
  /// BOOL SetWindowPlacement(HWND hWnd, const WINDOWPLACEMENT *lpwndpl)
  static final _SetWindowPlacement = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<WINDOWPLACEMENT>),
        int Function(int, Pointer<WINDOWPLACEMENT>)
      >('SetWindowPlacement');

  static int setWindowPlacement(int hwnd, Pointer<WINDOWPLACEMENT> placement) {
    return _SetWindowPlacement(hwnd, placement);
  }

  /// Window show state constants
  static const int SW_HIDE = 0;
  static const int SW_NORMAL = 1;
  static const int SW_MAXIMIZE = 3;
  static const int SW_SHOW = 5;

  /// ShowWindow - Show or hide window
  /// BOOL ShowWindow(HWND hWnd, int nCmdShow)
  static final _ShowWindow = _user32
      .lookupFunction<Int32 Function(IntPtr, Int32), int Function(int, int)>(
        'ShowWindow',
      );

  static int showWindow(int hwnd, int cmdShow) {
    return _ShowWindow(hwnd, cmdShow);
  }

  // ==========================================================================
  // Custom Frame Functions (from our native plugin)
  // ==========================================================================

  /// Enable or disable custom frameless window handling (legacy hidden mode)
  /// This handles WM_NCCALCSIZE to remove the black bar when title bar is hidden
  static void enableCustomFrame(int hwnd, bool enable) {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        throw StateError(
          'Native plugin not loaded. Call Win32Bindings.initializePlugin() first '
          'or ensure window_decoration_windows_plugin.dll is in the app directory.',
        );
      }
    }

    final enableCustomFrameFunc = _pluginLib!.lookupFunction<
        Void Function(IntPtr hwnd, Bool enable),
        void Function(int hwnd, bool enable)>('EnableCustomFrame');

    enableCustomFrameFunc(hwnd, enable);
  }

  /// Enable Windows 11 File Explorer style custom frame mode
  /// This removes the title bar while keeping window decorations (shadow, border, rounded corners)
  /// [captionHeight] is the height of your custom title bar in logical pixels (will be scaled for DPI)
  static void enableCustomFrameMode(int hwnd, int captionHeight) {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        throw StateError(
          'Native plugin not loaded. Call Win32Bindings.initializePlugin() first '
          'or ensure window_decoration_windows_plugin.dll is in the app directory.',
        );
      }
    }

    final enableFunc = _pluginLib!.lookupFunction<
        Void Function(IntPtr hwnd, Int32 captionHeight),
        void Function(int hwnd, int captionHeight)>('EnableCustomFrameMode');

    enableFunc(hwnd, captionHeight);
  }

  /// Disable custom frame mode and restore normal window
  static void disableCustomFrame(int hwnd) {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        throw StateError('Native plugin not loaded.');
      }
    }

    final disableFunc = _pluginLib!.lookupFunction<
        Void Function(IntPtr hwnd),
        void Function(int hwnd)>('DisableCustomFrame');

    disableFunc(hwnd);
  }

  /// Set the caption button zones for hit testing
  /// All coordinates are in client area pixels (not scaled - pass actual pixel values)
  /// This enables Windows 11 snap layouts when hovering over the maximize button
  static void setCaptionButtonZones(
    int hwnd, {
    required int minLeft,
    required int minTop,
    required int minRight,
    required int minBottom,
    required int maxLeft,
    required int maxTop,
    required int maxRight,
    required int maxBottom,
    required int closeLeft,
    required int closeTop,
    required int closeRight,
    required int closeBottom,
  }) {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        throw StateError('Native plugin not loaded.');
      }
    }

    final setZonesFunc = _pluginLib!.lookupFunction<
        Void Function(
          IntPtr hwnd,
          Int32 minLeft, Int32 minTop, Int32 minRight, Int32 minBottom,
          Int32 maxLeft, Int32 maxTop, Int32 maxRight, Int32 maxBottom,
          Int32 closeLeft, Int32 closeTop, Int32 closeRight, Int32 closeBottom,
        ),
        void Function(
          int hwnd,
          int minLeft, int minTop, int minRight, int minBottom,
          int maxLeft, int maxTop, int maxRight, int maxBottom,
          int closeLeft, int closeTop, int closeRight, int closeBottom,
        )>('SetCaptionButtonZones');

    setZonesFunc(
      hwnd,
      minLeft, minTop, minRight, minBottom,
      maxLeft, maxTop, maxRight, maxBottom,
      closeLeft, closeTop, closeRight, closeBottom,
    );
  }

  /// Clear caption button zones (the entire caption area will be draggable)
  static void clearCaptionButtonZones(int hwnd) {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        throw StateError('Native plugin not loaded.');
      }
    }

    final clearFunc = _pluginLib!.lookupFunction<
        Void Function(IntPtr hwnd),
        void Function(int hwnd)>('ClearCaptionButtonZones');

    clearFunc(hwnd);
  }

  /// Set the caption height (the draggable area at the top of the window)
  /// [height] is in logical pixels (will be scaled for DPI)
  static void setCaptionHeight(int hwnd, int height) {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        throw StateError('Native plugin not loaded.');
      }
    }

    final setHeightFunc = _pluginLib!.lookupFunction<
        Void Function(IntPtr hwnd, Int32 height),
        void Function(int hwnd, int height)>('SetCaptionHeight');

    setHeightFunc(hwnd, height);
  }

  /// Get current frame mode
  /// Returns: 0 = Normal, 1 = Hidden (legacy), 2 = CustomFrame (Windows 11 style)
  static int getFrameMode(int hwnd) {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        return 0;
      }
    }

    final getModeFunc = _pluginLib!.lookupFunction<
        Int32 Function(IntPtr hwnd),
        int Function(int hwnd)>('GetFrameMode');

    return getModeFunc(hwnd);
  }

  /// Check if custom frame handling is currently enabled for a window
  static bool isCustomFrameEnabled(int hwnd) {
    if (_pluginLib == null) {
      return false;
    }

    final isEnabledFunc = _pluginLib!.lookupFunction<
        Bool Function(IntPtr hwnd),
        bool Function(int hwnd)>('IsCustomFrameEnabled');

    return isEnabledFunc(hwnd);
  }

  /// Check if running on Windows 11
  static bool isWindows11() {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        return false;
      }
    }

    final isWin11Func = _pluginLib!.lookupFunction<
        Bool Function(),
        bool Function()>('IsWindows11');

    return isWin11Func();
  }

  /// Start window resize from a specific edge
  /// edge: 0=left, 1=right, 2=top, 3=bottom, 4=topLeft, 5=topRight, 6=bottomLeft, 7=bottomRight
  static void startResize(int hwnd, int edge) {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        throw StateError('Native plugin not loaded.');
      }
    }

    final startResizeFunc = _pluginLib!.lookupFunction<
        Void Function(IntPtr hwnd, Int32 edge),
        void Function(int hwnd, int edge)>('StartResize');

    startResizeFunc(hwnd, edge);
  }

  /// Start window drag/move operation
  static void startDrag(int hwnd) {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        throw StateError('Native plugin not loaded.');
      }
    }

    final startDragFunc = _pluginLib!.lookupFunction<
        Void Function(IntPtr hwnd),
        void Function(int hwnd)>('StartDrag');

    startDragFunc(hwnd);
  }

  /// Get the resize border width in pixels
  static int getResizeBorderWidth() {
    if (_pluginLib == null) {
      if (!tryAutoInitializePlugin()) {
        return 8; // Default fallback
      }
    }

    final getBorderWidthFunc = _pluginLib!.lookupFunction<
        Int32 Function(),
        int Function()>('GetResizeBorderWidth');

    return getBorderWidthFunc();
  }
}

// ==========================================================================
// Windows Structures
// ==========================================================================

/// RECT structure
final class RECT extends Struct {
  @Int32()
  external int left;

  @Int32()
  external int top;

  @Int32()
  external int right;

  @Int32()
  external int bottom;
}

/// MONITORINFO structure
final class MONITORINFO extends Struct {
  @Uint32()
  external int cbSize;

  external RECT rcMonitor;

  external RECT rcWork;

  @Uint32()
  external int dwFlags;
}

/// WINDOWPLACEMENT structure
final class WINDOWPLACEMENT extends Struct {
  @Uint32()
  external int length;

  @Uint32()
  external int flags;

  @Uint32()
  external int showCmd;

  @Int32()
  external int ptMinPositionX;

  @Int32()
  external int ptMinPositionY;

  @Int32()
  external int ptMaxPositionX;

  @Int32()
  external int ptMaxPositionY;

  external RECT rcNormalPosition;
}

/// MARGINS structure
final class MARGINS extends Struct {
  @Int32()
  external int cxLeftWidth;

  @Int32()
  external int cxRightWidth;

  @Int32()
  external int cyTopHeight;

  @Int32()
  external int cyBottomHeight;
}
