/// Represents the edge or corner of a window for resize operations.
enum ResizeEdge {
  /// Left edge
  left(0),

  /// Right edge
  right(1),

  /// Top edge
  top(2),

  /// Bottom edge
  bottom(3),

  /// Top-left corner
  topLeft(4),

  /// Top-right corner
  topRight(5),

  /// Bottom-left corner
  bottomLeft(6),

  /// Bottom-right corner
  bottomRight(7);

  const ResizeEdge(this.value);

  /// The native value for this edge
  final int value;
}
