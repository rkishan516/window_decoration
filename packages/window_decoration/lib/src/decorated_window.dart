// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/_window_macos.dart';
import 'package:flutter/src/widgets/_window_win32.dart';
import 'package:flutter/src/widgets/_window_linux.dart';
import 'package:flutter/widgets.dart';

import 'decorated_window_macos.dart';
import 'decorated_window_win32.dart';
import 'decorated_window_linux.dart';

abstract class DecoratedWindow {
  static DecoratedWindow? forController(BaseWindowController controller) {
    return _expando[controller];
  }

  static void init(BaseWindowController controller) {
    final created = _create(
      controller,
      onClose: () {
        _expando[controller] = null;
      },
    );
    if (created != null) {
      _expando[controller] = created;
    }
  }

  static final _expando = Expando<DecoratedWindow>('DecoratedWindow');

  static DecoratedWindow? _create(
    BaseWindowController controller, {
    required VoidCallback onClose,
  }) {
    if (controller is WindowControllerMacOS) {
      return DecoratedWindowMacOS(
        controller,
        onClose: onClose,
      );
    } else if (controller is WindowControllerWin32) {
      return DecoratedWindowWin32(
        controller,
        onClose: onClose,
      );
    } else if (controller is WindowControllerLinux) {
      return DecoratedWindowLinux(controller);
    } else {
      return null;
    }
  }

  void setDraggableRectForElement(BuildContext element, Rect? rect);
  void setDragExcludeRectForElement(BuildContext element, Rect? rect);
  void setTrafficLightPosition(Offset offset);
  void setMaximizeButtonFrame(BuildContext element, Rect? rect);
  Size getTrafficLightSize();
  void requestClose();

  bool windowNeedsMoveDragDetector();
  bool windowNeedsCustomBorder();
  bool titlebarNeedsDoubleClickDetector();
  void setCustomBorderShadowWidth(
    double top,
    double left,
    double bottom,
    double right,
  );

  void startWindowMoveDrag(Offset globalPosition);
  void startWindowResizeDrag(Offset globalPosition, WindowEdge edge);

  /// Center the window on its current screen.
  Future<void> center();

  /// Returns the current window origin in native screen coordinates.
  ///
  /// Coordinate conventions differ by platform: macOS reports the bottom-left
  /// corner of the window frame with the Y axis growing up; Windows and Linux
  /// report the top-left corner with the Y axis growing down.
  Future<Offset> getPosition();

  /// Moves the window so that its origin is at [position], using the same
  /// native coordinate convention documented on [getPosition].
  Future<void> setPosition(Offset position);

  /// Set the window background color.
  Future<void> setBackgroundColor(Color color);

  /// Set the window opacity (0.0 to 1.0).
  Future<void> setOpacity(double opacity);

  /// Set whether the window is always on top of other windows.
  Future<void> setAlwaysOnTop({required bool alwaysOnTop});

  /// Set whether the window skips the taskbar / dock.
  Future<void> setSkipTaskbar({required bool skip});

  /// Set whether the window is visible.
  Future<void> setVisible({required bool visible});

  /// Mark the window as non-activating.
  ///
  /// When enabled, the window does not steal foreground focus when it is
  /// shown, positioned, clicked, or brought topmost. This is required for
  /// Steam-style toast notifications: without it, exclusive-fullscreen
  /// D3D games (e.g. CS2) lose the foreground and minimize every time a
  /// notification appears.
  ///
  /// Default implementation is a no-op; platforms that need the distinction
  /// override this (Windows uses `WS_EX_NOACTIVATE` + `SW_SHOWNOACTIVATE`
  /// + `MA_NOACTIVATE`).
  Future<void> setNoActivate({required bool enabled}) async {}

  /// Convenience wrapper for [setVisible] with `visible: true`.
  Future<void> show() => setVisible(visible: true);

  /// Convenience wrapper for [setVisible] with `visible: false`.
  Future<void> hide() => setVisible(visible: false);

  /// Bring the window to the foreground and give it focus.
  ///
  /// Restores the window if it is minimized. On platforms that distinguish
  /// app-level activation from window-level ordering (macOS), the owning
  /// application is also activated. No-ops when the window is configured as
  /// non-activating via [setNoActivate].
  Future<void> bringToForeground();
}

enum WindowEdge {
  northWest,
  north,
  northEast,
  west,
  east,
  southWest,
  south,
  southEast,
}
