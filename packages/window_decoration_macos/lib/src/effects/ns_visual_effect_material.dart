/// NSVisualEffectMaterial constants for macOS vibrancy effects
///
/// These materials define the appearance of the visual effect view.
enum NSVisualEffectMaterial {
  /// A default material for the view's effectiveAppearance
  appearanceBased(0),

  /// The material for a window's titlebar
  titlebar(3),

  /// The material used to indicate selection
  selection(4),

  /// The material for menus
  menu(5),

  /// The material for the background of popover windows
  popover(6),

  /// The material for the background of window sidebars
  sidebar(7),

  /// The material for in-line header or footer views
  headerView(10),

  /// The material for the background of sheet windows
  sheet(11),

  /// The material for the background of opaque windows
  windowBackground(12),

  /// The material for the background of heads-up display (HUD) windows
  hudWindow(13),

  /// The material for the background of a full-screen modal interface
  fullScreenUI(15),

  /// The material for the background of a tool tip
  toolTip(17),

  /// The material for the background of opaque content
  contentBackground(18),

  /// The material to show under a window's background
  underWindowBackground(21),

  /// The material for the area behind the pages of a document
  underPageBackground(22);

  const NSVisualEffectMaterial(this.value);

  /// The raw integer value for the material
  final int value;
}

/// NSVisualEffectBlendingMode constants
enum NSVisualEffectBlendingMode {
  /// Blend with content behind the window
  behindWindow(0),

  /// Blend with content within the window
  withinWindow(1);

  const NSVisualEffectBlendingMode(this.value);

  /// The raw integer value for the blending mode
  final int value;
}

/// NSVisualEffectState constants
enum NSVisualEffectState {
  /// The backdrop should always appear active
  active(1),

  /// The backdrop should always appear inactive
  inactive(2),

  /// The backdrop should automatically appear active when the window is active
  followsWindowActiveState(0);

  const NSVisualEffectState(this.value);

  /// The raw integer value for the state
  final int value;
}
