// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:win32/win32.dart';

import 'decorated_window.dart';
import 'effects/dwm_effects.dart';
import 'win32_extra.dart';
import 'package:flutter/src/widgets/_window_win32.dart' hide HWND;

import 'dart:ffi' hide Size;

import 'win32_util.dart';

// `MA_NOACTIVATE` is not exported by the win32 package (as of 6.0.1).
// See https://learn.microsoft.com/windows/win32/inputdev/wm-mouseactivate
const int _kMaNoActivate = 3;

// DWM attributes such as `DWMWA_CAPTION_COLOR`, `DWMWA_BORDER_COLOR`,
// `DWMWA_WINDOW_CORNER_PREFERENCE`, and `DWMWA_SYSTEMBACKDROP_TYPE`
// require Windows 11 (Build 22000+). Calling them on Windows 10 returns
// `E_INVALIDARG (0x80070057)` and the win32 binding throws.
int? _cachedWindowsBuild;

int _windowsBuildNumber() {
  final cached = _cachedWindowsBuild;
  if (cached != null) return cached;
  final info = malloc<OSVERSIONINFOEX>();
  try {
    info.ref.dwOSVersionInfoSize = sizeOf<OSVERSIONINFOEX>();
    final ok = RtlGetVersion(info.cast()) == 0;
    return _cachedWindowsBuild = ok ? info.ref.dwBuildNumber : 0;
  } finally {
    malloc.free(info);
  }
}

bool get _isWindows11OrLater => _windowsBuildNumber() >= 22000;

class _SubclassState {
  bool needRearmMouseTracker = false;
}

final _subclassState = <int, _SubclassState>{};

int _subclassProc(
  Pointer hwnd,
  int msg,
  int wparam,
  int lparam,
  int idSubclass,
  int refData,
) {
  final state = _subclassState.putIfAbsent(
    hwnd.address,
    () => _SubclassState(),
  );
  if (msg == WM_DESTROY) {
    _subclassState.remove(hwnd.address);
  }
  if (msg == WM_MOUSELEAVE) {
    HWND parentWindow = GetAncestor(HWND(hwnd), GA_ROOT);
    if (parentWindow.isNotNull) {
      final cursorPos = malloc<POINT>();
      GetCursorPos(cursorPos);
      final cursorPosLparam = makeLParam(cursorPos.ref.x, cursorPos.ref.y);
      free(cursorPos);
      final parentHitTest = SendMessage(
        parentWindow,
        WM_NCHITTEST,
        WPARAM(0),
        LPARAM(cursorPosLparam),
      ).value;
      if (parentHitTest == HTMAXBUTTON || parentHitTest == HTCAPTION) {
        state.needRearmMouseTracker = true;
        return 0;
      }
    }
  } else if (msg == WM_NCHITTEST) {
    HWND parentWindow = GetAncestor(HWND(hwnd), GA_ROOT);
    if (parentWindow.isNotNull) {
      final parentResult = SendMessage(
        parentWindow,
        msg,
        WPARAM(wparam),
        LPARAM(lparam),
      ).value;
      if (parentResult == HTCLIENT) {
        return HTCLIENT;
      } else {
        return HTTRANSPARENT;
      }
    } else {
      return HTCLIENT;
    }
  } else if (msg == WM_MOUSEMOVE) {
    if (state.needRearmMouseTracker) {
      final trackMouseEvent = malloc<TRACKMOUSEEVENT>();
      trackMouseEvent.ref.cbSize = sizeOf<TRACKMOUSEEVENT>();
      trackMouseEvent.ref.hwndTrack = HWND(hwnd);
      trackMouseEvent.ref.dwFlags = TME_LEAVE;
      TrackMouseEvent(trackMouseEvent);
      malloc.free(trackMouseEvent);
      state.needRearmMouseTracker = false;
    }
  }
  return DefSubclassProc(HWND(hwnd), msg, WPARAM(wparam), LPARAM(lparam));
}

class DecoratedWindowWin32 extends DecoratedWindow {
  DecoratedWindowWin32(this.controller, {required this.onClose}) {
    controller.addWindowsMessageHandler(handleWindowsMessage);
    _makeWindowUndecorated(_hwnd);
    _flutterView = _findFlutterView();
    SetWindowSubclass(
      _flutterView,
      Pointer.fromFunction<SUBCLASSPROC>(_subclassProc, 0),
      0,
      0,
    );
  }

  final VoidCallback onClose;

  late final HWND _flutterView;

  HWND _findFlutterView() {
    final className = 'FlutterView'.toNativeUtf16();
    final child = FindWindowEx(_hwnd, null, PCWSTR(className), null);
    free(className);
    if (child.value.isNull) {
      throw Exception('Could not find FlutterView child window');
    }
    return child.value;
  }

  final WindowControllerWin32 controller;

  HWND get _hwnd => HWND(controller.windowHandle);

  static final int Function(Pointer<Void>) _getDpiForWindow =
      DynamicLibrary.process().lookupFunction<
        Uint32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('FlutterDesktopGetDpiForHWND');

  static void _makeWindowUndecorated(HWND hwnd) {
    SetWindowLongPtr(
      hwnd,
      GWL_STYLE,
      WS_THICKFRAME |
          WS_CAPTION |
          WS_SYSMENU |
          WS_MAXIMIZEBOX |
          WS_MINIMIZEBOX |
          WS_OVERLAPPED,
    );
    SetWindowPos(
      hwnd,
      null,
      0,
      0,
      0,
      0,
      SWP_FRAMECHANGED |
          SWP_NOMOVE |
          SWP_NOSIZE |
          SWP_NOZORDER |
          SWP_NOACTIVATE,
    );
  }

  final _dragExcludeRects = <BuildContext, Rect>{};
  final _maximizeButtonRects = <BuildContext, Rect>{};

  @override
  void setDragExcludeRectForElement(BuildContext element, Rect? rect) {
    if (rect == null) {
      _dragExcludeRects.remove(element);
    } else {
      _dragExcludeRects[element] = rect;
    }
  }

  @override
  void setDraggableRectForElement(BuildContext element, Rect? rect) {}

  @override
  void setMaximizeButtonFrame(BuildContext element, Rect? rect) {
    if (rect == null) {
      _maximizeButtonRects.remove(element);
    } else {
      _maximizeButtonRects[element] = rect;
    }
  }

  @override
  Size getTrafficLightSize() {
    return Size.zero;
  }

  @override
  void setTrafficLightPosition(Offset offset) {}

  @override
  void requestClose() {
    PostMessage(_hwnd, WM_CLOSE, WPARAM(0), LPARAM(0));
  }

  bool _trackingMouseLeave = false;
  bool _noActivate = false;

  int? handleWindowsMessage(
    HWND windowHandle,
    int message,
    int wParam,
    int lParam,
  ) {
    switch (message) {
      case WM_DESTROY:
        onClose();
        break;
      case WM_MOUSEACTIVATE:
        if (_noActivate) {
          // Click on the window does not activate it — keeps the foreground
          // (e.g. a fullscreen game) from losing focus.
          return _kMaNoActivate;
        }
        break;
      case WM_SIZE:
        if (wParam == SIZE_MINIMIZED) return 0;
        break;
      case WM_NCCALCSIZE:
        if (wParam == 1) {
          final dpi = _getDpiForWindow(windowHandle.cast());
          int padding = GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi).value;
          int borderLR =
              GetSystemMetricsForDpi(SM_CXFRAME, dpi).value + padding;
          int borderTB =
              GetSystemMetricsForDpi(SM_CYFRAME, dpi).value + padding;
          final params = Pointer<NCCALCSIZE_PARAMS>.fromAddress(lParam);
          final rect = params.ref.rgrc[0];
          double scale = dpi / 96.0;
          if (IsZoomed(_hwnd)) {
            rect.top += borderTB;
          } else {
            rect.top += (1 * scale).round();
          }
          rect.left += borderLR;
          rect.right -= borderLR;
          rect.bottom -= borderTB;
          return 0;
        }
      case WM_NCHITTEST:
        final (xPos, yPos) = splitLParam(lParam);
        final (xClient, yClient) = screenToClient(_hwnd, xPos, yPos);

        double scale = _getDpiForWindow(windowHandle.cast()) / 96.0;
        double x = xClient / scale;
        double y = yClient / scale;

        final rect = malloc<RECT>();
        GetClientRect(_hwnd, rect);
        final width = (rect.ref.right - rect.ref.left) / scale;
        final height = (rect.ref.bottom - rect.ref.top) / scale;
        malloc.free(rect);

        const edgeSize = 1;
        const topEdgeSize = 3;

        if (_maximizeButtonRects.values.any((r) => r.contains(Offset(x, y)))) {
          return HTMAXBUTTON;
        }

        if (y < topEdgeSize) {
          if (x < topEdgeSize) {
            return HTTOPLEFT;
          } else if (x > width - topEdgeSize) {
            return HTTOPRIGHT;
          } else {
            return HTTOP;
          }
        } else if (y > height - edgeSize) {
          if (x < edgeSize) {
            return HTBOTTOMLEFT;
          } else if (x > width - edgeSize) {
            return HTBOTTOMRIGHT;
          } else {
            return HTBOTTOM;
          }
        } else if (x < edgeSize) {
          return HTLEFT;
        } else if (x > width - edgeSize) {
          return HTRIGHT;
        }

        for (final excludeRect in _dragExcludeRects.values) {
          if (excludeRect.contains(Offset(x, y))) {
            return HTCLIENT;
          }
        }
        return HTCLIENT;
      case WM_NCMOUSEMOVE:
        if (wParam == HTMAXBUTTON || wParam == HTCAPTION) {
          final (x, y) = splitLParam(lParam);
          final (flutterX, flutterY) = screenToClient(_flutterView, x, y);

          SendMessage(
            _flutterView,
            WM_MOUSEMOVE,
            WPARAM(0),
            LPARAM(makeLParam(flutterX, flutterY)),
          );

          if (!_trackingMouseLeave) {
            final trackMouseEvent = malloc<TRACKMOUSEEVENT>();
            trackMouseEvent.ref.cbSize = sizeOf<TRACKMOUSEEVENT>();
            trackMouseEvent.ref.hwndTrack = _hwnd;
            trackMouseEvent.ref.dwFlags = TME_LEAVE | TME_NONCLIENT;
            TrackMouseEvent(trackMouseEvent);
            malloc.free(trackMouseEvent);
            _trackingMouseLeave = true;
          }
          return 0;
        }
      case WM_NCLBUTTONDOWN:
        if (wParam == HTMAXBUTTON) {
          final (x, y) = splitLParam(lParam);
          final (flutterX, flutterY) = screenToClient(_flutterView, x, y);
          SendMessage(
            _flutterView,
            WM_LBUTTONDOWN,
            WPARAM(0),
            LPARAM(makeLParam(flutterX, flutterY)),
          );
          return 0;
        }
        return null;
      case WM_NCLBUTTONUP:
        if (wParam == HTMAXBUTTON) {
          final (x, y) = splitLParam(lParam);
          final (flutterX, flutterY) = screenToClient(_flutterView, x, y);
          SendMessage(
            _flutterView,
            WM_LBUTTONUP,
            WPARAM(0),
            LPARAM(makeLParam(flutterX, flutterY)),
          );
          return 0;
        }
        return null;
      case WM_NCMOUSELEAVE:
        _trackingMouseLeave = false;
        final cursorPos = malloc<POINT>();
        GetCursorPos(cursorPos);
        final cursorPosLparam = makeLParam(cursorPos.ref.x, cursorPos.ref.y);
        free(cursorPos);
        final flutterHitTest = SendMessage(
          _flutterView,
          WM_NCHITTEST,
          WPARAM(0),
          LPARAM(cursorPosLparam),
        ).value;
        if (flutterHitTest != HTCLIENT) {
          SendMessage(_flutterView, WM_MOUSELEAVE, WPARAM(0), LPARAM(0));
        }
        return 0;
    }
    return null;
  }

  @override
  bool windowNeedsCustomBorder() {
    return false;
  }

  @override
  bool windowNeedsMoveDragDetector() {
    return true;
  }

  @override
  void setCustomBorderShadowWidth(
    double top,
    double left,
    double bottom,
    double right,
  ) {}

  @override
  void startWindowMoveDrag(Offset globalPosition) {
    ReleaseCapture();
    // PostMessage avoids a nested modal pump re-entering Flutter
    // from the caller's gesture-callback stack.
    PostMessage(_hwnd, WM_NCLBUTTONDOWN, WPARAM(HTCAPTION), LPARAM(0));
  }

  @override
  void startWindowResizeDrag(Offset globalPosition, WindowEdge edge) {}

  @override
  bool titlebarNeedsDoubleClickDetector() {
    return true;
  }

  //
  // Shared feature methods.
  //

  @override
  Future<void> center() async {
    final rect = malloc<RECT>();
    try {
      GetWindowRect(_hwnd, rect);
      final width = rect.ref.right - rect.ref.left;
      final height = rect.ref.bottom - rect.ref.top;
      final screenWidth = GetSystemMetrics(SM_CXSCREEN);
      final screenHeight = GetSystemMetrics(SM_CYSCREEN);
      final x = (screenWidth - width) ~/ 2;
      final y = (screenHeight - height) ~/ 2;
      SetWindowPos(_hwnd, null, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
    } finally {
      malloc.free(rect);
    }
  }

  @override
  Future<Offset> getPosition() async {
    final rect = malloc<RECT>();
    try {
      GetWindowRect(_hwnd, rect);
      return Offset(rect.ref.left.toDouble(), rect.ref.top.toDouble());
    } finally {
      malloc.free(rect);
    }
  }

  @override
  Future<void> setPosition(Offset position) async {
    SetWindowPos(
      _hwnd,
      null,
      position.dx.round(),
      position.dy.round(),
      0,
      0,
      SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE,
    );
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    if (!_isWindows11OrLater) return;
    final value = malloc<Uint32>();
    try {
      final r = (color.r * 255.0).round().clamp(0, 255);
      final g = (color.g * 255.0).round().clamp(0, 255);
      final b = (color.b * 255.0).round().clamp(0, 255);
      value.value = (b << 16) | (g << 8) | r;
      DwmSetWindowAttribute(
        _hwnd,
        DWMWA_CAPTION_COLOR,
        value.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      malloc.free(value);
    }
  }

  @override
  Future<void> setOpacity(double opacity) async {
    final clamped = opacity.clamp(0.0, 1.0);
    final currentStyle = GetWindowLongPtr(_hwnd, GWL_EXSTYLE).value;
    if ((currentStyle & WS_EX_LAYERED) == 0) {
      SetWindowLongPtr(_hwnd, GWL_EXSTYLE, currentStyle | WS_EX_LAYERED);
    }
    final alpha = (clamped * 255).round();
    SetLayeredWindowAttributes(_hwnd, COLORREF(0), alpha, LWA_ALPHA);
  }

  @override
  Future<void> setAlwaysOnTop({required bool alwaysOnTop}) async {
    final insertAfter = alwaysOnTop ? HWND_TOPMOST : HWND_NOTOPMOST;
    SetWindowPos(
      _hwnd,
      insertAfter,
      0,
      0,
      0,
      0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE,
    );
  }

  @override
  Future<void> setSkipTaskbar({required bool skip}) async {
    final currentStyle = GetWindowLongPtr(_hwnd, GWL_EXSTYLE).value;
    final newStyle = skip
        ? currentStyle | WS_EX_TOOLWINDOW
        : currentStyle & ~WS_EX_TOOLWINDOW;
    SetWindowLongPtr(_hwnd, GWL_EXSTYLE, newStyle);
    SetWindowPos(
      _hwnd,
      null,
      0,
      0,
      0,
      0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED |
          SWP_NOACTIVATE,
    );
  }

  @override
  Future<void> setVisible({required bool visible}) async {
    if (!visible) {
      ShowWindow(_hwnd, SW_HIDE);
      return;
    }
    // When non-activating, use SW_SHOWNOACTIVATE so showing the window
    // does not steal foreground focus from another app (e.g. a
    // fullscreen game).
    ShowWindow(_hwnd, _noActivate ? SW_SHOWNOACTIVATE : SW_SHOW);
  }

  @override
  Future<void> bringToForeground() async {
    if (_noActivate) return;
    if (IsIconic(_hwnd)) {
      ShowWindow(_hwnd, SW_RESTORE);
    }
    // Windows will only honor SetForegroundWindow when the calling thread
    // already owns the foreground (the "foreground lock"). When another
    // window is on top, attach our input queue to the foreground thread's
    // so the OS treats us as a peer and lets us steal activation.
    final foreHwnd = GetForegroundWindow();
    final foreThread = foreHwnd.isNotNull
        ? GetWindowThreadProcessId(foreHwnd, nullptr)
        : 0;
    final currentThread = GetCurrentThreadId();
    final attach = foreThread != 0 && foreThread != currentThread;
    if (attach) {
      AttachThreadInput(currentThread, foreThread, true);
    }
    try {
      BringWindowToTop(_hwnd);
      SetForegroundWindow(_hwnd);
      SetFocus(_hwnd);
    } finally {
      if (attach) {
        AttachThreadInput(currentThread, foreThread, false);
      }
    }
  }

  @override
  Future<void> setNoActivate({required bool enabled}) async {
    _noActivate = enabled;

    final currentStyle = GetWindowLongPtr(_hwnd, GWL_EXSTYLE).value;
    final newStyle = enabled
        ? currentStyle | WS_EX_NOACTIVATE
        : currentStyle & ~WS_EX_NOACTIVATE;
    if (newStyle != currentStyle) {
      SetWindowLongPtr(_hwnd, GWL_EXSTYLE, newStyle);
      SetWindowPos(
        _hwnd,
        null,
        0,
        0,
        0,
        0,
        SWP_NOMOVE |
            SWP_NOSIZE |
            SWP_NOZORDER |
            SWP_FRAMECHANGED |
            SWP_NOACTIVATE,
      );
    }
  }

  //
  // Windows-only feature methods.
  //

  /// Set the DWM system backdrop type (Windows 11 only).
  Future<void> setSystemBackdrop(DWMSystemBackdropType backdrop) async {
    if (!_isWindows11OrLater) return;
    final value = malloc<Uint32>();
    try {
      value.value = backdrop.value;
      DwmSetWindowAttribute(
        _hwnd,
        DWMWA_SYSTEMBACKDROP_TYPE,
        value.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      malloc.free(value);
    }
  }

  /// Set the window corner preference (Windows 11 only).
  Future<void> setCornerPreference(WindowCornerPreference preference) async {
    if (!_isWindows11OrLater) return;
    final value = malloc<Uint32>();
    try {
      value.value = preference.value;
      DwmSetWindowAttribute(
        _hwnd,
        DWMWA_WINDOW_CORNER_PREFERENCE,
        value.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      malloc.free(value);
    }
  }

  /// Set the window border color (Windows 11 only).
  Future<void> setBorderColor(Color color) async {
    if (!_isWindows11OrLater) return;
    final value = malloc<Uint32>();
    try {
      final r = (color.r * 255.0).round().clamp(0, 255);
      final g = (color.g * 255.0).round().clamp(0, 255);
      final b = (color.b * 255.0).round().clamp(0, 255);
      value.value = (b << 16) | (g << 8) | r;
      DwmSetWindowAttribute(
        _hwnd,
        DWMWA_BORDER_COLOR,
        value.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      malloc.free(value);
    }
  }

  /// Enable or disable immersive dark mode (Windows 10 1809+).
  Future<void> setDarkMode({required bool enabled}) async {
    final value = malloc<Uint32>();
    try {
      value.value = enabled ? 1 : 0;
      DwmSetWindowAttribute(
        _hwnd,
        DWMWA_USE_IMMERSIVE_DARK_MODE,
        value.cast(),
        sizeOf<Uint32>(),
      );
    } finally {
      malloc.free(value);
    }
  }

  /// Whether the window currently has the `WS_EX_TOPMOST` style.
  Future<bool> isAlwaysOnTop() async {
    final exStyle = GetWindowLongPtr(_hwnd, GWL_EXSTYLE).value;
    return (exStyle & WS_EX_TOPMOST) != 0;
  }

  /// Returns whether the OS is Windows 11 (build 22000+).
  bool isWindows11() {
    final info = malloc<OSVERSIONINFOEX>();
    try {
      info.ref.dwOSVersionInfoSize = sizeOf<OSVERSIONINFOEX>();
      RtlGetVersion(info.cast());
      final major = info.ref.dwMajorVersion;
      final build = info.ref.dwBuildNumber;
      return major >= 10 && build >= 22000;
    } finally {
      malloc.free(info);
    }
  }
}
