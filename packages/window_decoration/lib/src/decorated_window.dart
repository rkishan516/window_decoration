// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:flutter/src/widgets/_window.dart';
import 'package:window_decoration/src/window_decoration_service.dart';
import 'package:window_decoration_platform_interface/window_decoration_platform_interface.dart';

/// A window widget with custom decorations
///
/// This widget wraps [RegularWindow] and applies custom decorations
/// based on the provided [WindowDecorationConfig].
///
/// Example:
/// ```dart
/// final controller = RegularWindowController(...);
///
/// runWidget(
///   DecoratedWindow(
///     controller: controller,
///     config: WindowDecorationConfig(
///       centered: true,
///       alwaysOnTop: false,
///       titleBarStyle: TitleBarStyle.transparent,
///     ),
///     child: MyApp(),
///   ),
/// );
/// ```
class DecoratedWindow extends StatefulWidget {
  const DecoratedWindow({
    required this.controller,
    required this.child,
    this.config,
    super.key,
  });

  /// The window controller from Flutter's multi-window API
  final RegularWindowController controller;

  /// The widget to display in the window
  final Widget child;

  /// Configuration for window decorations
  ///
  /// If null, [WindowDecorationConfig.defaultConfig] will be used.
  final WindowDecorationConfig? config;

  @override
  State<DecoratedWindow> createState() => _DecoratedWindowState();
}

class _DecoratedWindowState extends State<DecoratedWindow> {
  late final WindowDecorationService _service;
  bool _configurationApplied = false;

  @override
  void initState() {
    super.initState();
    _service = WindowDecorationService(widget.controller);

    // Apply configuration after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_configurationApplied) {
        _applyConfiguration();
      }
    });
  }

  Future<void> _applyConfiguration() async {
    if (_configurationApplied) {
      return;
    }

    final config = widget.config ?? WindowDecorationConfig.defaultConfig;

    try {
      // Apply window positioning
      if (config.centered) {
        await _service.center();
      }

      // Apply window behavior
      if (config.alwaysOnTop) {
        await _service.setAlwaysOnTop(alwaysOnTop: true);
      }

      if (config.skipTaskbar) {
        await _service.setSkipTaskbar(skip: true);
      }

      // Apply appearance
      if (config.backgroundColor != null) {
        await _service.setBackgroundColor(config.backgroundColor!);
      }

      if (config.opacity != null) {
        await _service.setOpacity(config.opacity!);
      }

      // Apply title bar style
      await _service.setTitleBarStyle(
        config.titleBarStyle,
        captionHeight: config.captionHeight,
      );

      // Apply visibility
      await _service.setVisible(visible: config.visible);

      // Apply platform-specific effects
      // TODO(enhancement): Implement effects application

      _configurationApplied = true;
    } on Exception catch (e, stackTrace) {
      debugPrint('Error applying window decoration configuration: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) =>
      // Simply wrap the child with RegularWindow
      // The decoration configuration is applied via the service
      RegularWindow(controller: widget.controller, child: widget.child);
}
