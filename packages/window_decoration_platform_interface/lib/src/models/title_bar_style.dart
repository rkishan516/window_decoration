/// Defines the appearance style of the window title bar
enum TitleBarStyle {
  /// Default native title bar with standard appearance
  normal,

  /// Title bar is completely hidden (legacy borderless popup style)
  hidden,

  /// Title bar appears transparent, overlaying content
  transparent,

  /// Unified title and toolbar appearance (macOS)
  unified,

  /// Windows 11 File Explorer style: removes the title bar but keeps
  /// window decorations (shadow, rounded corners, 1px border).
  ///
  /// This style allows you to create a fully custom title bar while
  /// maintaining native window behaviors:
  /// - Proper window shadow and rounded corners (Windows 11)
  /// - Snap layouts support (hover over maximize button area)
  /// - Native resize borders on all edges
  /// - Double-click to maximize in caption area
  /// - Drag to move in caption area
  ///
  /// After setting this style, you should:
  /// 1. Draw your own title bar UI at the top of the window
  /// 2. Optionally call [setCaptionButtonZones] to define button areas
  ///    for proper hit testing and snap layout support
  /// 3. Optionally call [setCaptionHeight] to adjust the draggable area
  customFrame,
}
