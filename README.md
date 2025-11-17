# window_decoration

Customize window decorations on desktop platforms with Flutter. This package provides both declarative and programmatic APIs for controlling window appearance and behavior.

## Platform Support

| Feature | macOS | Windows | Linux |
|---------|-------|---------|-------|
| Center window | ✅ | ✅ | ✅ |
| Get/Set bounds | ✅ | ✅ | ✅ |
| Show/Hide window | ✅ | ✅ | ✅ |
| Background color | ✅ | ✅ | ⚠️ Limited |
| Opacity | ✅ | ✅ | ✅ |
| Always on top | ✅ | ✅ | ✅ X11 / ⚠️ Wayland |
| Skip taskbar/dock | ✅ | ✅ | ✅ |
| Fullscreen | ✅ | ✅ | ✅ |
| Title bar styles | ✅ | ⚠️ Limited | ⚠️ Limited |
| Vibrancy effects | ✅ NSVisualEffect | - | - |
| DWM effects | - | ✅ Mica/Acrylic | - |

**Legend:** ✅ Full Support | ⚠️ Limited Support | - Not Applicable

## Features

### Core Features (All Platforms)
- **Window Positioning**: Center windows, get/set custom bounds
- **Window Visibility**: Show/hide windows programmatically
- **Appearance**: Background color, opacity control
- **Behavior**: Always on top, skip taskbar, fullscreen mode
- **Title Bar**: Multiple styles (normal, hidden, transparent, unified)

### Platform-Specific Features

#### macOS
- Vibrancy/blur effects with NSVisualEffectMaterial
- Window shadow control
- Movable by window background
- Collection behavior configuration
- Complete NSWindow API access

#### Windows
- DWM (Desktop Window Manager) effects
  - Mica effect (Windows 11)
  - Acrylic backdrop (Windows 10 1803+)
  - Custom window corner preference
  - Border and caption color customization
- Dark mode support (Windows 10 1809+)
- Layered windows for transparency

#### Linux
- GTK3-based window management
- X11 support for positioning and always-on-top
- Wayland support with limitations:
  - Window positioning not available (compositor restriction)
  - Always-on-top may not work (compositor restriction)
- Opacity and fullscreen support

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  window_decoration:
    git:
      url: https://github.com/rkishan516/window_decoration.git
      path: packages/window_decoration
```

Or for local development:

```yaml
dependencies:
  window_decoration:
    path: ../window_decoration/packages/window_decoration
```

## Usage

### Declarative API (DecoratedWindow Widget)

The simplest way to use window_decoration is with the `DecoratedWindow` widget:

```dart
import 'package:flutter/src/widgets/_window.dart';
import 'package:window_decoration/window_decoration.dart';

void main() {
  final controller = RegularWindowController(
    preferredSize: Size(1200, 800),
    title: 'My App',
  );

  runWidget(
    DecoratedWindow(
      controller: controller,
      config: WindowDecorationConfig(
        centered: true,
        alwaysOnTop: false,
        visible: true,
        titleBarStyle: TitleBarStyle.transparent,
        backgroundColor: Colors.black,
        opacity: 0.95,
      ),
      child: MyApp(),
    ),
  );
}
```

### Programmatic API (WindowDecorationService)

For dynamic control, use the `WindowDecorationService`:

```dart
import 'package:flutter/src/widgets/_window.dart';
import 'package:window_decoration/window_decoration.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late WindowDecorationService _service;

  @override
  void initState() {
    super.initState();
    final controller = WindowScope.of(context) as RegularWindowController;
    _service = WindowDecorationService(controller);

    _setupWindow();
  }

  Future<void> _setupWindow() async {
    // Center the window
    await _service.center();

    // Set always on top
    await _service.setAlwaysOnTop(alwaysOnTop: true);

    // Set opacity
    await _service.setOpacity(0.9);

    // Configure title bar
    await _service.setTitleBarStyle(TitleBarStyle.transparent);

    // Show the window
    await _service.show();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _service.center(),
                child: Text('Center Window'),
              ),
              ElevatedButton(
                onPressed: () => _service.setFullScreen(fullScreen: true),
                child: Text('Fullscreen'),
              ),
              ElevatedButton(
                onPressed: () => _service.hide(),
                child: Text('Hide Window'),
              ),
              ElevatedButton(
                onPressed: () => _service.show(),
                child: Text('Show Window'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Platform-Specific Feature Access

#### macOS-Specific Features

Access through the `macos` extension:

```dart
// Set vibrancy effect
await _service.macos.setVibrancy(
  NSVisualEffectMaterial.sidebar,
);

// Configure window shadow
await _service.macos.setHasShadow(hasShadow: false);

// Make window movable by dragging background
await _service.macos.setMovableByWindowBackground(movable: true);

// Check if window is always on top
final isOnTop = await _service.macos.isAlwaysOnTop();
```

#### Windows-Specific Features

Access through the `windows` extension:

```dart
// Enable Mica effect (Windows 11)
await _service.windows.setSystemBackdrop(
  DWMSystemBackdropType.mainWindow, // Mica effect
);

// Set window corner preference
await _service.windows.setCornerPreference(
  WindowCornerPreference.round,
);

// Set custom border color
await _service.windows.setBorderColor(Colors.blue);

// Enable dark mode
await _service.windows.setDarkMode(enabled: true);
```

#### Linux-Specific Features

Access through the `linux` extension:

```dart
// Check display server type
final isWayland = await _service.linux.isWayland();
final isX11 = await _service.linux.isX11();

// Note: Some features may not work on Wayland
if (isX11) {
  // X11-specific operations work reliably
  await _service.setAlwaysOnTop(alwaysOnTop: true);
}
```

## API Reference

### WindowDecorationService

#### Position & Size
```dart
Future<void> center()
Future<WindowBounds> getBounds()
Future<void> setBounds(WindowBounds bounds)
```

#### Appearance
```dart
Future<void> setBackgroundColor(Color color)
Future<void> setOpacity(double opacity)
```

#### Behavior
```dart
Future<void> setAlwaysOnTop({required bool alwaysOnTop})
Future<void> setSkipTaskbar({required bool skip})
Future<void> setFullScreen({required bool fullScreen})
Future<void> setTitleBarStyle(TitleBarStyle style)
Future<void> setVisible({required bool visible})
Future<void> show()  // Convenience method for setVisible(visible: true)
Future<void> hide()  // Convenience method for setVisible(visible: false)
```

### WindowDecorationConfig

```dart
WindowDecorationConfig({
  bool centered = false,
  bool alwaysOnTop = false,
  bool skipTaskbar = false,
  bool frameless = false,
  bool visible = true,
  Color? backgroundColor,
  double? opacity,
  TitleBarStyle titleBarStyle = TitleBarStyle.normal,
  List<WindowEffect> effects = const [],
})
```

### TitleBarStyle

```dart
enum TitleBarStyle {
  normal,      // Default native title bar
  hidden,      // Completely hidden
  transparent, // Transparent with full-size content
  unified,     // Unified toolbar appearance (macOS)
}
```

### NSVisualEffectMaterial (macOS)

```dart
enum NSVisualEffectMaterial {
  titlebar,
  selection,
  menu,
  popover,
  sidebar,
  headerView,
  sheet,
  windowBackground,
  hudWindow,
  fullScreenUI,
  toolTip,
  contentBackground,
  underWindowBackground,
  underPageBackground,
}
```

### DWMSystemBackdropType (Windows)

```dart
enum DWMSystemBackdropType {
  auto,              // Automatically select backdrop
  none,              // No backdrop effect
  mainWindow,        // Mica effect (Windows 11)
  transientWindow,   // Acrylic effect
  tabbedWindow,      // Tabbed window backdrop
}
```

### WindowCornerPreference (Windows)

```dart
enum WindowCornerPreference {
  defaultCorners,    // Default system behavior
  doNotRound,        // Square corners
  round,             // Rounded corners
  roundSmall,        // Small rounded corners
}
```

## Requirements

- **Dart SDK**: >=3.10.0 <4.0.0
- **Flutter SDK**: >=3.38.1 (for multi-window API)
- **macOS**: macOS 10.14+ (for NSVisualEffectView)
- **Windows**: Windows 10 1803+ (for basic features), Windows 11 (for Mica effect)
- **Linux**:
  - GTK 3.0+
  - X11 for full feature support
  - Wayland with limited positioning support

## Architecture

This package uses a **Dart workspace** with a federated plugin architecture:

### Workspace Structure

```
window_decoration/
├── pubspec.yaml                    # Workspace root
├── analysis.yaml                   # Shared analysis configuration
├── packages/
│   ├── window_decoration/          # Main package with public API
│   ├── window_decoration_platform_interface/  # Platform contract
│   ├── window_decoration_macos/    # macOS implementation (AppKit FFI)
│   ├── window_decoration_windows/  # Windows implementation (Win32 FFI)
│   └── window_decoration_linux/    # Linux implementation (GTK3/X11 FFI)
└── example/                        # Example application
```

### Package Responsibilities

- **window_decoration**: Main package with public API
- **window_decoration_platform_interface**: Platform contract and base classes
- **window_decoration_macos**: macOS implementation via Objective-C FFI
- **window_decoration_windows**: Windows implementation via Win32 FFI
- **window_decoration_linux**: Linux implementation via GTK3/X11 FFI

### Key Design Decisions

1. **Pure FFI**: Uses `dart:ffi` instead of platform channels for maximum performance
2. **No Custom Window Types**: Integrates with Flutter's `RegularWindowController` via `getWindowHandle()`
3. **Platform-Specific Extensions**: Each platform can expose unique features
4. **Declarative & Programmatic**: Supports both widget-based and service-based APIs

## Examples

### Interactive Example App

The repository includes a comprehensive example app demonstrating all features:

**To run the example:**
```bash
cd example
flutter run -d macos  # or windows, linux
```

The example app provides an interactive UI to test all window decoration features including:
- Window positioning and centering
- Opacity control
- Always-on-top behavior
- Title bar styles
- Platform-specific effects (vibrancy on macOS, DWM effects on Windows)

### Required Native Setup

To use `window_decoration` with Flutter's `RegularWindowController`, you need to configure your macOS AppDelegate:

**macos/Runner/AppDelegate.swift:**
```swift
import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  var engine: FlutterEngine?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // CRITICAL: Create engine manually without creating view controllers
    // This allows multi-view to be enabled later from Dart
    engine = FlutterEngine(name: "main", project: nil)
    engine?.run(withEntrypoint: nil)
    RegisterGeneratedPlugins(registry: engine!)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
```

**Why this is needed:** Flutter's multi-view API requires that multi-view be enabled BEFORE any view controllers are created. The default FlutterAppDelegate creates a view controller automatically, which prevents multi-view from being enabled. By manually creating the FlutterEngine without view controllers, we allow `RegularWindowController` to enable multi-view when it's created from Dart.

## Testing

Due to Flutter's experimental multi-window API initialization requirements, automated integration tests are not compatible with this package.

### Manual Testing

The package has been thoroughly tested on macOS (Apple Silicon). Testing on Windows and Linux is pending.

**To test the package:**

1. **Run the example app** (Recommended):
   ```bash
   cd example
   flutter run -d macos  # or windows, linux
   ```

2. **In your own app**:
   ```dart
   final service = WindowDecorationService(controller);
   await service.center();
   await service.setTitleBarStyle(TitleBarStyle.transparent);
   ```

### Platform Testing Status

- ✅ **macOS**: Fully tested on Apple Silicon (arm64)
- ✅ **Windows**: Implementation complete (Windows 10/11)
- ✅ **Linux**: Implementation complete (GTK3/X11/Wayland)

## Limitations

### macOS
- `setSkipTaskbar()` affects the entire application's dock icon, not individual windows
- Some features require macOS 10.14+ (Mojave)
- NSRect struct handling uses platform-specific approach (arm64 vs x86_64)

### Windows
- DWM effects require Windows 10 1803+ or later
- Mica effect requires Windows 11
- Title bar customization is limited compared to macOS
- `setBackgroundColor()` sets caption color, not full window background

### Linux
- **Wayland limitations** (compositor security restrictions):
  - Window positioning (`setBounds()`, `center()`) may not work
  - Always-on-top (`setAlwaysOnTop()`) may not work
  - Feature availability depends on compositor
- **X11**: Full feature support
- Background color customization requires CSS providers (not yet implemented)
- Title bar transparency requires custom compositing

## Development

This repository uses a Dart workspace for managing multiple packages. To get started:

```bash
# Clone the repository
git clone https://github.com/rkishan516/window_decoration.git
cd window_decoration

# Install dependencies for all packages in the workspace
flutter pub get

# Run the example app
cd example
flutter run -d macos  # or windows, linux
```

### Working with the Workspace

The workspace configuration allows all packages to be developed together:

- Dependencies are resolved at the workspace level
- All packages share the same `analysis.yaml` configuration
- Changes to platform packages are immediately reflected in the main package
- Run `flutter pub get` from the root to update all packages

### Running Tests

```bash
# From the root directory
flutter test packages/window_decoration
flutter test packages/window_decoration_platform_interface

# Platform-specific tests
flutter test packages/window_decoration_macos
flutter test packages/window_decoration_windows
flutter test packages/window_decoration_linux
```

## Contributing

This package was built as part of a Flutter desktop window customization initiative. Contributions and improvements are welcome!

### Known Issues & Future Enhancements

- **macOS**: All core features implemented and tested on Apple Silicon
- **Windows**: Additional testing on various Windows 10/11 configurations
- **Linux**:
  - Implement CSS provider for custom background colors
  - Enhanced Wayland compositor compatibility testing
  - Additional X11 window type hints
- **All platforms**: Comprehensive automated test suites

## License

MIT License - see [LICENSE](LICENSE) file for details

## Credits

Built using Flutter's experimental multi-window API and inspired by:
- [bitsdojo_window](https://pub.dev/packages/bitsdojo_window)
- [window_manager](https://pub.dev/packages/window_manager)
- [nativeapi-flutter](https://github.com/libnativeapi/nativeapi-flutter)
