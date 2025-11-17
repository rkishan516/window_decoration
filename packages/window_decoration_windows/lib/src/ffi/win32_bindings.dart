// ignore_for_file: constant_identifier_names, non_constant_identifier_names, prefer_expression_function_bodies

import 'dart:ffi';

/// Win32 API bindings for window manipulation
class Win32Bindings {
  // Load user32.dll and dwmapi.dll
  static final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');
  static final DynamicLibrary _dwmapi = DynamicLibrary.open('dwmapi.dll');

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
