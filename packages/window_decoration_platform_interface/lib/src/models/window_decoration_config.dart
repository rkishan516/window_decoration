import 'package:flutter/material.dart';

import 'package:window_decoration_platform_interface/src/models/title_bar_style.dart';
import 'package:window_decoration_platform_interface/src/models/window_effect.dart';

/// Configuration for window decoration behavior and appearance
@immutable
class WindowDecorationConfig {
  const WindowDecorationConfig({
    this.centered = false,
    this.alwaysOnTop = false,
    this.skipTaskbar = false,
    this.frameless = false,
    this.visible = true,
    this.backgroundColor,
    this.opacity,
    this.titleBarStyle = TitleBarStyle.normal,
    this.effects = const [],
  });

  /// Whether to center the window on screen on initialization
  final bool centered;

  /// Whether the window should stay on top of other windows
  final bool alwaysOnTop;

  /// Whether to hide the window from the taskbar/dock
  final bool skipTaskbar;

  /// Whether to remove the window frame (title bar and borders)
  final bool frameless;

  /// Whether the window should be visible on initialization
  final bool visible;

  /// Background color of the window
  final Color? backgroundColor;

  /// Opacity of the window (0.0 to 1.0)
  final double? opacity;

  /// Title bar appearance style
  final TitleBarStyle titleBarStyle;

  /// Visual effects to apply to the window
  final List<WindowEffect> effects;

  /// Default configuration with standard window appearance
  static const WindowDecorationConfig defaultConfig = WindowDecorationConfig();

  WindowDecorationConfig copyWith({
    bool? centered,
    bool? alwaysOnTop,
    bool? skipTaskbar,
    bool? frameless,
    bool? visible,
    Color? backgroundColor,
    double? opacity,
    TitleBarStyle? titleBarStyle,
    List<WindowEffect>? effects,
  }) => WindowDecorationConfig(
    centered: centered ?? this.centered,
    alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
    skipTaskbar: skipTaskbar ?? this.skipTaskbar,
    frameless: frameless ?? this.frameless,
    visible: visible ?? this.visible,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    opacity: opacity ?? this.opacity,
    titleBarStyle: titleBarStyle ?? this.titleBarStyle,
    effects: effects ?? this.effects,
  );
}
