import 'package:flutter/foundation.dart';

/// Represents the position and size of a window
@immutable
class WindowBounds {
  const WindowBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// X coordinate of the window's top-left corner
  final double x;

  /// Y coordinate of the window's top-left corner
  final double y;

  /// Width of the window
  final double width;

  /// Height of the window
  final double height;

  @override
  String toString() =>
      'WindowBounds(x: $x, y: $y, width: $width, height: $height)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowBounds &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}
