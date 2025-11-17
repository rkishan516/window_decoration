// ignore_for_file: constant_identifier_names, non_constant_identifier_names, prefer_expression_function_bodies

import 'dart:ffi';

/// GTK3 and X11 bindings for window manipulation
class GtkBindings {
  // Load GTK3 and X11 libraries
  static final DynamicLibrary _gtk = DynamicLibrary.open('libgtk-3.so.0');
  static final DynamicLibrary _gdk = DynamicLibrary.open('libgdk-3.so.0');
  static final DynamicLibrary _x11 = DynamicLibrary.open('libX11.so.6');

  // ==========================================================================
  // GTK Window Functions
  // ==========================================================================

  /// gtk_window_move - Move window to position
  /// void gtk_window_move(GtkWindow *window, gint x, gint y)
  static final _gtk_window_move = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>, Int32, Int32),
        void Function(Pointer<Void>, int, int)
      >('gtk_window_move');

  static void windowMove(Pointer<Void> window, int x, int y) {
    _gtk_window_move(window, x, y);
  }

  /// gtk_window_resize - Resize window
  /// void gtk_window_resize(GtkWindow *window, gint width, gint height)
  static final _gtk_window_resize = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>, Int32, Int32),
        void Function(Pointer<Void>, int, int)
      >('gtk_window_resize');

  static void windowResize(Pointer<Void> window, int width, int height) {
    _gtk_window_resize(window, width, height);
  }

  /// gtk_window_get_position - Get window position
  /// void gtk_window_get_position(GtkWindow *window, gint *root_x, gint *root_y)
  static final _gtk_window_get_position = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>, Pointer<Int32>, Pointer<Int32>),
        void Function(Pointer<Void>, Pointer<Int32>, Pointer<Int32>)
      >('gtk_window_get_position');

  static void windowGetPosition(
    Pointer<Void> window,
    Pointer<Int32> x,
    Pointer<Int32> y,
  ) {
    _gtk_window_get_position(window, x, y);
  }

  /// gtk_window_get_size - Get window size
  /// void gtk_window_get_size(GtkWindow *window, gint *width, gint *height)
  static final _gtk_window_get_size = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>, Pointer<Int32>, Pointer<Int32>),
        void Function(Pointer<Void>, Pointer<Int32>, Pointer<Int32>)
      >('gtk_window_get_size');

  static void windowGetSize(
    Pointer<Void> window,
    Pointer<Int32> width,
    Pointer<Int32> height,
  ) {
    _gtk_window_get_size(window, width, height);
  }

  /// gtk_window_set_opacity - Set window opacity
  /// void gtk_window_set_opacity(GtkWindow *window, gdouble opacity)
  static final _gtk_window_set_opacity = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>, Double),
        void Function(Pointer<Void>, double)
      >('gtk_window_set_opacity');

  static void windowSetOpacity(Pointer<Void> window, double opacity) {
    _gtk_window_set_opacity(window, opacity);
  }

  /// gtk_window_set_keep_above - Set always on top
  /// void gtk_window_set_keep_above(GtkWindow *window, gboolean setting)
  static final _gtk_window_set_keep_above = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>, Int32),
        void Function(Pointer<Void>, int)
      >('gtk_window_set_keep_above');

  static void windowSetKeepAbove(
    Pointer<Void> window, {
    required bool keepAbove,
  }) {
    _gtk_window_set_keep_above(window, keepAbove ? 1 : 0);
  }

  /// gtk_window_set_skip_taskbar_hint - Skip taskbar
  /// void gtk_window_set_skip_taskbar_hint(GtkWindow *window, gboolean setting)
  static final _gtk_window_set_skip_taskbar_hint = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>, Int32),
        void Function(Pointer<Void>, int)
      >('gtk_window_set_skip_taskbar_hint');

  static void windowSetSkipTaskbarHint(
    Pointer<Void> window, {
    required bool skip,
  }) {
    _gtk_window_set_skip_taskbar_hint(window, skip ? 1 : 0);
  }

  /// gtk_window_fullscreen - Enter fullscreen
  /// void gtk_window_fullscreen(GtkWindow *window)
  static final _gtk_window_fullscreen = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('gtk_window_fullscreen');

  static void windowFullscreen(Pointer<Void> window) {
    _gtk_window_fullscreen(window);
  }

  /// gtk_window_unfullscreen - Exit fullscreen
  /// void gtk_window_unfullscreen(GtkWindow *window)
  static final _gtk_window_unfullscreen = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('gtk_window_unfullscreen');

  static void windowUnfullscreen(Pointer<Void> window) {
    _gtk_window_unfullscreen(window);
  }

  /// gtk_window_set_decorated - Show/hide window decorations
  /// void gtk_window_set_decorated(GtkWindow *window, gboolean setting)
  static final _gtk_window_set_decorated = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>, Int32),
        void Function(Pointer<Void>, int)
      >('gtk_window_set_decorated');

  static void windowSetDecorated(
    Pointer<Void> window, {
    required bool decorated,
  }) {
    _gtk_window_set_decorated(window, decorated ? 1 : 0);
  }

  /// gtk_widget_show - Show widget (window)
  /// void gtk_widget_show(GtkWidget *widget)
  static final _gtk_widget_show = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('gtk_widget_show');

  static void widgetShow(Pointer<Void> widget) {
    _gtk_widget_show(widget);
  }

  /// gtk_widget_hide - Hide widget (window)
  /// void gtk_widget_hide(GtkWidget *widget)
  static final _gtk_widget_hide = _gtk
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('gtk_widget_hide');

  static void widgetHide(Pointer<Void> widget) {
    _gtk_widget_hide(widget);
  }

  // ==========================================================================
  // GDK Functions
  // ==========================================================================

  /// gdk_window_set_opacity - Set window opacity (alternative)
  /// void gdk_window_set_opacity(GdkWindow *window, gdouble opacity)
  static final _gdk_window_set_opacity = _gdk
      .lookupFunction<
        Void Function(Pointer<Void>, Double),
        void Function(Pointer<Void>, double)
      >('gdk_window_set_opacity');

  static void gdkWindowSetOpacity(Pointer<Void> window, double opacity) {
    _gdk_window_set_opacity(window, opacity);
  }

  /// gdk_screen_get_default - Get default screen
  /// GdkScreen* gdk_screen_get_default(void)
  static final _gdk_screen_get_default = _gdk
      .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
        'gdk_screen_get_default',
      );

  static Pointer<Void> screenGetDefault() {
    return _gdk_screen_get_default();
  }

  /// gdk_screen_get_width - Get screen width
  /// gint gdk_screen_get_width(GdkScreen *screen)
  static final _gdk_screen_get_width = _gdk
      .lookupFunction<
        Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('gdk_screen_get_width');

  static int screenGetWidth(Pointer<Void> screen) {
    return _gdk_screen_get_width(screen);
  }

  /// gdk_screen_get_height - Get screen height
  /// gint gdk_screen_get_height(GdkScreen *screen)
  static final _gdk_screen_get_height = _gdk
      .lookupFunction<
        Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('gdk_screen_get_height');

  static int screenGetHeight(Pointer<Void> screen) {
    return _gdk_screen_get_height(screen);
  }

  // ==========================================================================
  // X11 Functions (for features not available in GTK)
  // ==========================================================================

  /// XOpenDisplay - Open X11 display
  /// Display* XOpenDisplay(char *display_name)
  static final _XOpenDisplay = _x11
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>),
        Pointer<Void> Function(Pointer<Void>)
      >('XOpenDisplay');

  static Pointer<Void> openDisplay() {
    return _XOpenDisplay(nullptr);
  }

  /// XCloseDisplay - Close X11 display
  /// int XCloseDisplay(Display *display)
  static final _XCloseDisplay = _x11
      .lookupFunction<
        Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('XCloseDisplay');

  static int closeDisplay(Pointer<Void> display) {
    return _XCloseDisplay(display);
  }

  // Additional X11 functions can be added as needed for advanced features
  // such as custom window properties, transparency, etc.
}

/// Helper for checking Wayland vs X11
class DisplayServerHelper {
  static bool isWayland() {
    // Check if running under Wayland
    // This is a simplified check - in production you'd check $XDG_SESSION_TYPE
    return false; // TODO(enhancement): Implement proper detection
  }

  static bool isX11() => !isWayland();
}
