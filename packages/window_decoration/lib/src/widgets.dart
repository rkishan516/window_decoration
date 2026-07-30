// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'button.dart';
import 'decorated_window.dart';
import 'linux_extra.dart';

import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/_window_linux.dart';

/// Represents an area in Window that can be used to drag the window. This is
/// typically used to implement custom title bars.
///
/// The widgets inside the area are still interactive, but pan gestures
/// will not work as pan gesture will result in dragging the window.
///
/// To mark sub-areas that should not trigger dragging, use [WindowDragExcludeArea].
class WindowDragArea extends StatefulWidget {
  const WindowDragArea({super.key, required this.child});

  final Widget child;

  @override
  State<WindowDragArea> createState() => _WindowDragAreaState();
}

/// Represents area within [WindowDragArea] that should not trigger window dragging.
/// This is typically used for toolbar or tabs that are placed inside title bar.
class WindowDragExcludeArea extends StatefulWidget {
  const WindowDragExcludeArea({super.key, required this.child});

  final Widget child;

  @override
  State<WindowDragExcludeArea> createState() => _WindowDragExcludeState();
}

enum WindowTrafficLightMode {
  /// Traffic light buttons are visible and take space in layout.
  visible,

  /// Traffic light buttons are invisible but still take space in layout.
  invisible,

  /// Traffic light buttons are absent and do not take space in layout.
  removed,
}

/// Represents macOS traffic light buttons. Wherever this widget is placed, the
/// window traffic light buttons will be positioned.
///
/// On other platform this renders as [SizedBox.shrink] and has no effect.
class WindowTrafficLight extends StatefulWidget {
  const WindowTrafficLight({
    super.key,
    this.mode = WindowTrafficLightMode.visible,
  });

  /// Traffic light visibility mode.
  final WindowTrafficLightMode mode;

  @override
  State<WindowTrafficLight> createState() => _WindowTrafficLightState();
}

/// Represents state of a titlebar button (close, minimize, maximize).
/// This is used in content builder of [CloseButton], [MinimizeButton]
/// and [MaximizeButton].
class TitlebarButtonState {
  TitlebarButtonState({
    required this.enabled,
    required this.hovered,
    required this.pressed,
  });

  /// Whether the button is enabled (clickable).
  final bool enabled;

  /// Whether the button is currently hovered by mouse cursor.
  final bool hovered;

  /// Whether the button is currently pressed and mouse cursor is inside button area.
  final bool pressed;
}

/// Button for maximizing and restoring the window.
///
/// Supports displaying [snap layout](https://support.microsoft.com/en-us/windows/snap-your-windows-885a9b1e-a983-a3b1-16cd-c531795e6241)
/// on Windows when hovered.
class MaximizeButton extends StatefulWidget {
  const MaximizeButton({super.key, required this.builder, this.enabled = true});

  final Widget Function(
    BuildContext context,
    TitlebarButtonState state,
    bool isMaximized,
  )
  builder;

  final bool enabled;

  @override
  State<MaximizeButton> createState() => _MaximizeButtonState();
}

/// Button for minimizing the window.
class MinimizeButton extends StatefulWidget {
  const MinimizeButton({super.key, required this.builder, this.enabled = true});

  final Widget Function(BuildContext context, TitlebarButtonState state)
  builder;

  final bool enabled;

  @override
  State<MinimizeButton> createState() => _MinimizeButtonState();
}

/// Button for closing the window.
///
/// This button triggers same action as native close button would,
/// meaning that the action can be prevented by overriding
/// [WindowControllerDelegate.onWindowCloseRequested].
class CloseButton extends StatefulWidget {
  const CloseButton({super.key, required this.builder, this.enabled = true});

  final Widget Function(BuildContext context, TitlebarButtonState state)
  builder;

  final bool enabled;

  @override
  State<CloseButton> createState() => _CloseButtonState();
}

/// Widget that draws custom border and shadow around the window.
/// This will only have effect on Linux, on other platforms system
/// compositor will draw the border and shadow.
class WindowBorder extends StatefulWidget {
  const WindowBorder({
    super.key,
    required this.child,
    this.cornerRadius = 12.0,
  });

  final Widget child;
  final double cornerRadius;

  @override
  State<WindowBorder> createState() => _WindowBorderState();
}

//
// Implementation details.
//

class _CloseButtonState extends State<CloseButton> {
  @override
  Widget build(BuildContext context) {
    return WindowDragExcludeArea(
      child: Button(
        builder: (context, buttonState, child) {
          return widget.builder(
            context,
            TitlebarButtonState(
              enabled: buttonState.enabled,
              hovered: buttonState.hovered,
              pressed: buttonState.pressed,
            ),
          );
        },
        focusNode: _buttonNode,
        onPressed: widget.enabled ? _onPressed : null,
      ),
    );
  }

  void _onPressed() {
    final decoratedWindow = DecoratedWindow.forController(
      WindowScope.of(context),
    );
    decoratedWindow?.requestClose();
  }

  final _buttonNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _buttonNode.canRequestFocus = false;
    _buttonNode.skipTraversal = true;
  }

  @override
  void dispose() {
    super.dispose();
    _buttonNode.dispose();
  }
}

class _MinimizeButtonState extends State<MinimizeButton> {
  @override
  Widget build(BuildContext context) {
    return WindowDragExcludeArea(
      child: Button(
        builder: (context, buttonState, child) {
          return widget.builder(
            context,
            TitlebarButtonState(
              enabled: buttonState.enabled,
              hovered: buttonState.hovered,
              pressed: buttonState.pressed,
            ),
          );
        },
        focusNode: _buttonNode,
        onPressed: widget.enabled ? _onPressed : null,
      ),
    );
  }

  void _onPressed() {
    final controller = WindowScope.of(context);
    if (controller is WindowController) {
      controller.setMinimized(true);
    } else if (controller is DialogWindowController) {
      controller.setMinimized(true);
    }
  }

  final _buttonNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _buttonNode.canRequestFocus = false;
    _buttonNode.skipTraversal = true;
  }

  @override
  void dispose() {
    super.dispose();
    _buttonNode.dispose();
  }
}

class _MaximizeButtonState extends _FrameReportingState<MaximizeButton> {
  @override
  Widget build(BuildContext context) {
    final controller = WindowScope.of(context);
    final isDestroyed = WindowScope.isDestroyedOf(context);
    final isEnabled =
        widget.enabled && !isDestroyed && controller is WindowController;
    final isMaximized = isEnabled && WindowScope.isMaximizedOf(context);

    return WindowDragExcludeArea(
      child: Button(
        builder: (context, buttonState, child) {
          return widget.builder(
            context,
            TitlebarButtonState(
              enabled: buttonState.enabled,
              hovered: buttonState.hovered,
              pressed: buttonState.pressed,
            ),
            isMaximized,
          );
        },
        focusNode: _buttonNode,
        onPressed: isEnabled ? _onPressed : null,
      ),
    );
  }

  void _onPressed() {
    final controller = WindowScope.of(context);
    if (controller is! WindowController || controller.isDestroyed) {
      return;
    }
    controller.setMaximized(!controller.isMaximized);
  }

  final _buttonNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _buttonNode.canRequestFocus = false;
    _buttonNode.skipTraversal = true;
  }

  @override
  void dispose() {
    super.dispose();
    _buttonNode.dispose();
  }

  @override
  void reportFrame(DecoratedWindow window, Rect? rect) {
    window.setMaximizeButtonFrame(context, rect);
  }
}

abstract class _FrameReportingState<T extends StatefulWidget> extends State<T> {
  void reportFrame(DecoratedWindow window, Rect? rect);

  DecoratedWindow? _decoratedWindow;

  void _frameTick() {
    if (!mounted) {
      return;
    }

    final decoratedWindow = DecoratedWindow.forController(
      WindowScope.of(context),
    );
    if (decoratedWindow != null) {
      final view = context.findRenderObject() as RenderBox;
      final transform = view.getTransformTo(null);
      final rect = MatrixUtils.transformRect(
        transform,
        Offset.zero & view.size,
      );
      if (_decoratedWindow != decoratedWindow) {
        if (_decoratedWindow != null) {
          reportFrame(decoratedWindow, null);
        }
        _decoratedWindow = decoratedWindow;
      }
      reportFrame(decoratedWindow, rect);
    }
  }

  @override
  void initState() {
    super.initState();
    _PersistentFrameCallbackManager.instance.addCallback(_frameTick);
  }

  @override
  void dispose() {
    _PersistentFrameCallbackManager.instance.removeCallback(_frameTick);
    if (_decoratedWindow != null) {
      reportFrame(_decoratedWindow!, null);
    }
    super.dispose();
  }
}

class _WindowDragAreaState extends _FrameReportingState<WindowDragArea> {
  @override
  Widget build(BuildContext context) {
    final gestures = <Type, GestureRecognizerFactory>{};
    final decoratedWindow = DecoratedWindow.forController(
      WindowScope.of(context),
    );
    if (decoratedWindow?.windowNeedsMoveDragDetector() == true) {
      gestures[_DragPanGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<_DragPanGestureRecognizer>(
            () => _DragPanGestureRecognizer(debugOwner: this),
            (_DragPanGestureRecognizer instance) {
              instance.onStart = (details) {
                final decoratedWindow = DecoratedWindow.forController(
                  WindowScope.of(context),
                )!;
                decoratedWindow.startWindowMoveDrag(details.globalPosition);
              };
            },
          );
    }
    final controller = WindowScope.of(context);
    if (decoratedWindow?.titlebarNeedsDoubleClickDetector() == true &&
        controller is WindowController) {
      gestures[_DoubleTapToMaximizeGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<
            _DoubleTapToMaximizeGestureRecognizer
          >(() => _DoubleTapToMaximizeGestureRecognizer(debugOwner: this), (
            _DoubleTapToMaximizeGestureRecognizer instance,
          ) {
            instance.onDoubleTap = () {
              controller.setMaximized(!controller.isMaximized);
            };
          });
    }
    if (gestures.isNotEmpty) {
      return RawGestureDetector(
        gestures: gestures,
        behavior: HitTestBehavior.translucent,
        child: widget.child,
      );
    } else {
      return widget.child;
    }
  }

  @override
  void reportFrame(DecoratedWindow window, Rect? rect) {
    window.setDraggableRectForElement(context, rect);
  }
}

class _WindowDragExcludeState
    extends _FrameReportingState<WindowDragExcludeArea> {
  @override
  Widget build(BuildContext context) {
    return _DragExcludeWidget(child: widget.child);
  }

  @override
  void reportFrame(DecoratedWindow window, Rect? rect) {
    window.setDragExcludeRectForElement(context, rect);
  }
}

class _WindowTrafficLightState
    extends _FrameReportingState<WindowTrafficLight> {
  @override
  Widget build(BuildContext context) {
    final decoratedWindow = DecoratedWindow.forController(
      WindowScope.of(context),
    );
    if (decoratedWindow == null ||
        widget.mode == WindowTrafficLightMode.removed) {
      return const SizedBox.shrink();
    } else {
      return SizedBox.fromSize(size: decoratedWindow.getTrafficLightSize());
    }
  }

  @override
  void reportFrame(DecoratedWindow window, Rect? rect) {
    if (widget.mode == WindowTrafficLightMode.invisible ||
        widget.mode == WindowTrafficLightMode.removed) {
      window.setTrafficLightPosition(Offset(0, -100));
    } else if (rect != null) {
      window.setTrafficLightPosition(rect.topLeft);
    }
  }
}

class _WindowBorderState extends State<WindowBorder> with WindowDelegateLinux {
  // Complete padding around the content, must be enough for shadow to blend smoothly
  static const _borderPadding = 16.0;
  // Part of border padding that can is user interactive (resizing handles)
  static const _resizingHandleThickness = 12.0;
  // Part of resizing handles that is inside window frame
  static const _resizingHandleThicknessInside = 2.0;

  @override
  void didChangeDependencies() {
    final controller = WindowScope.of(context);
    final decoratedWindow = DecoratedWindow.forController(controller);
    if (decoratedWindow != null && decoratedWindow.windowNeedsCustomBorder()) {
      decoratedWindow.setCustomBorderShadowWidth(
        _borderPadding,
        _borderPadding,
        _borderPadding,
        _borderPadding,
      );
    }
    _controller?.removeDelegate(this);
    if (controller is WindowControllerLinux) {
      _controller = controller;
      _controller!.addDelegate(this);
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controller?.removeDelegate(this);
    _controller = null;
    super.dispose();
  }

  @override
  void windowStateDidChange() {
    setState(() {});
  }

  WindowControllerLinux? _controller;

  @override
  Widget build(BuildContext context) {
    final decoratedWindow = DecoratedWindow.forController(
      WindowScope.of(context),
    );
    if (decoratedWindow == null || !decoratedWindow.windowNeedsCustomBorder()) {
      return widget.child;
    }
    double effectiveCornerRadius = widget.cornerRadius;
    if (_controller != null) {
      final state = _controller!.getWindowState();
      if (state.maximized ||
          state.fullscreen ||
          state.topTiled ||
          state.rightTiled ||
          state.bottomTiled ||
          state.leftTiled) {
        effectiveCornerRadius = 0;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(
        _borderPadding -
            _resizingHandleThickness +
            _resizingHandleThicknessInside,
      ),
      child: _ResizingHandles(
        thickness: _resizingHandleThickness,
        cornerSize: _resizingHandleThickness + effectiveCornerRadius / 2.0,
        child: Padding(
          padding: const EdgeInsets.all(
            _resizingHandleThickness - _resizingHandleThicknessInside,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(effectiveCornerRadius),
              border: Border.all(
                width: 1,
                color: Color(0xFF000000).withValues(alpha: 0.1),
              ),
              boxShadow: [
                if (effectiveCornerRadius > 0)
                  BoxShadow(
                    color: Color(0xFF000000).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(effectiveCornerRadius),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizingHandles extends StatelessWidget {
  const _ResizingHandles({
    // ignore: unused_element_parameter
    super.key,
    required this.thickness,
    required this.cornerSize,
    required this.child,
  });

  final Widget child;
  final double cornerSize;
  final double thickness;

  Widget _buildHandle(WindowEdge edge, BuildContext context) {
    final cursor = switch (edge) {
      WindowEdge.northWest => SystemMouseCursors.resizeUpLeftDownRight,
      WindowEdge.north => SystemMouseCursors.resizeUpDown,
      WindowEdge.northEast => SystemMouseCursors.resizeUpRightDownLeft,
      WindowEdge.west => SystemMouseCursors.resizeLeftRight,
      WindowEdge.east => SystemMouseCursors.resizeLeftRight,
      WindowEdge.southWest => SystemMouseCursors.resizeUpRightDownLeft,
      WindowEdge.south => SystemMouseCursors.resizeUpDown,
      WindowEdge.southEast => SystemMouseCursors.resizeUpLeftDownRight,
    };
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          final decoratedWindow = DecoratedWindow.forController(
            WindowScope.of(context),
          )!;
          decoratedWindow.startWindowResizeDrag(details.globalPosition, edge);
        },
        child: SizedBox.expand(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.topLeft,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          width: cornerSize,
          height: cornerSize,
          child: _buildHandle(WindowEdge.northWest, context),
        ),
        Positioned(
          top: 0,
          left: cornerSize,
          right: cornerSize,
          height: thickness,
          child: _buildHandle(WindowEdge.north, context),
        ),
        Positioned(
          top: 0,
          right: 0,
          width: cornerSize,
          height: cornerSize,
          child: _buildHandle(WindowEdge.northEast, context),
        ),
        Positioned(
          top: cornerSize,
          left: 0,
          bottom: cornerSize,
          width: thickness,
          child: _buildHandle(WindowEdge.west, context),
        ),
        Positioned(
          top: cornerSize,
          right: 0,
          bottom: cornerSize,
          width: thickness,
          child: _buildHandle(WindowEdge.east, context),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          width: cornerSize,
          height: cornerSize,
          child: _buildHandle(WindowEdge.southWest, context),
        ),
        Positioned(
          bottom: 0,
          left: cornerSize,
          right: cornerSize,
          height: thickness,
          child: _buildHandle(WindowEdge.south, context),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          width: cornerSize,
          height: cornerSize,
          child: _buildHandle(WindowEdge.southEast, context),
        ),
      ],
    );
  }
}

class _PersistentFrameCallbackManager {
  _PersistentFrameCallbackManager._() {
    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      final callbacksCopy = List<VoidCallback>.from(
        _callbacks,
        growable: false,
      );
      for (final callback in callbacksCopy) {
        callback();
      }
    });
  }

  void addCallback(VoidCallback callback) {
    _callbacks.add(callback);
  }

  void removeCallback(VoidCallback callback) {
    _callbacks.remove(callback);
  }

  final _callbacks = <VoidCallback>[];
  static final instance = _PersistentFrameCallbackManager._();
}

class _DragExcludeWidget extends SingleChildRenderObjectWidget {
  // ignore: unused_element_parameter
  const _DragExcludeWidget({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _DragExcludeRenderObject();
  }
}

class _DragExcludeRenderObject extends RenderProxyBox {}

class _DragPanGestureRecognizer extends PanGestureRecognizer {
  _DragPanGestureRecognizer({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final HitTestResult result = HitTestResult();
    RendererBinding.instance.hitTestInView(
      result,
      event.position,
      event.viewId,
    );
    for (final hit in result.path) {
      if (hit.target is _DragExcludeRenderObject) {
        return;
      }
    }
    super.addAllowedPointer(event);
  }
}

class _DoubleTapToMaximizeGestureRecognizer extends DoubleTapGestureRecognizer {
  _DoubleTapToMaximizeGestureRecognizer({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final HitTestResult result = HitTestResult();
    RendererBinding.instance.hitTestInView(
      result,
      event.position,
      event.viewId,
    );
    for (final hit in result.path) {
      if (hit.target is _DragExcludeRenderObject) {
        return;
      }
    }
    super.addAllowedPointer(event);
  }
}
