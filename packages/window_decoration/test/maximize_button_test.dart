// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_decoration/window_decoration.dart';

void main() {
  testWidgets('MaximizeButton does not read window state after destruction', (
    tester,
  ) async {
    final controller = _TestWindowController();

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return WindowScope(
            controller: controller,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: MaximizeButton(
                builder: (context, state, isMaximized) {
                  return Text('$isMaximized');
                },
              ),
            ),
          );
        },
      ),
    );
    expect(find.text('false'), findsOneWidget);

    controller.setMaximized(true);
    await tester.pump();
    expect(find.text('true'), findsOneWidget);

    controller.markDestroyed();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('false'), findsOneWidget);
  });
}

class _TestWindowController extends ChangeNotifier implements WindowController {
  bool _destroyed = false;
  bool _maximized = false;

  @override
  bool get isDestroyed => _destroyed;

  @override
  Size get contentSize {
    _ensureNotDestroyed();
    return Size.zero;
  }

  @override
  String get title {
    _ensureNotDestroyed();
    return '';
  }

  @override
  bool get isActivated {
    _ensureNotDestroyed();
    return true;
  }

  @override
  bool get isMaximized {
    _ensureNotDestroyed();
    return _maximized;
  }

  @override
  bool get isMinimized {
    _ensureNotDestroyed();
    return false;
  }

  @override
  bool get isFullscreen {
    _ensureNotDestroyed();
    return false;
  }

  @override
  Future<void> setMaximized(bool maximized) async {
    _ensureNotDestroyed();
    _maximized = maximized;
    notifyListeners();
  }

  void markDestroyed() {
    _destroyed = true;
    notifyListeners();
  }

  void _ensureNotDestroyed() {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
