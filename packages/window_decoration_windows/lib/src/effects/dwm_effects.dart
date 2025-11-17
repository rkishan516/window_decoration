// Windows-specific DWM (Desktop Window Manager) effects

/// DWM system backdrop types for Windows 11
enum DWMSystemBackdropType {
  /// Automatically select backdrop based on window type
  auto(0),

  /// No backdrop effect
  none(1),

  /// Main window backdrop (Mica effect on Windows 11)
  mainWindow(2),

  /// Transient window backdrop (Acrylic effect)
  transientWindow(3),

  /// Tabbed window backdrop
  tabbedWindow(4);

  const DWMSystemBackdropType(this.value);
  final int value;
}

/// Window corner preference for Windows 11
enum WindowCornerPreference {
  /// Default system behavior
  defaultCorners(0),

  /// Do not round corners
  doNotRound(1),

  /// Round corners
  round(2),

  /// Small rounded corners
  roundSmall(3);

  const WindowCornerPreference(this.value);
  final int value;
}

/// Mica effect variants (Windows 11 22H2+)
enum MicaEffect {
  /// Disable Mica
  disabled(0),

  /// Enable standard Mica
  enabled(1),

  /// Enable Mica Alt (more subtle)
  alt(2);

  const MicaEffect(this.value);
  final int value;
}
