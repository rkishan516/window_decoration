# Window Decoration Example

This example demonstrates all features of the `window_decoration` package for macOS.

## ⚠️ Note: Best Example in desktop-next

Due to Flutter's experimental multi-window API initialization constraints, **the best working example is in the `desktop-next` app**:

```bash
cd ../../../apps/desktop-next
flutter run -d macos
```

Look for console output: `Window customization applied via window_decoration package`

This standalone example app works but requires specific native configuration (see below).

## Features Demonstrated

### Window Behavior
- **Always on Top**: Keep window above all other windows
- **Skip Taskbar/Dock**: Hide from macOS dock (affects entire app)
- **Fullscreen**: Toggle fullscreen mode

### Window Appearance
- **Opacity**: Adjust window transparency (20%-100%)
- **Background Color**: Choose from preset colors

### Title Bar Styles
- **Normal**: Standard macOS title bar
- **Hidden**: Completely hidden title bar
- **Transparent**: Transparent title bar with full-size content
- **Unified**: Unified toolbar appearance

### macOS-Specific Features
- **Window Shadow**: Toggle drop shadow
- **Movable by Background**: Drag window by clicking anywhere

### Actions
- **Center Window**: Center on screen
- **Set Custom Bounds**: Set specific position and size
- **Reset to Defaults**: Restore all settings

## Running the Example

From the example directory:

```bash
flutter run -d macos
```

Or from the package root:

```bash
cd example
flutter run -d macos
```

## Requirements

- macOS
- Flutter 3.38.0 or later
- Experimental multi-window API enabled
- **Native Configuration (Already Done)**: `macos/Runner/AppDelegate.swift` must manually create FlutterEngine

### Why Native Configuration Is Needed

Flutter's multi-view API requires multi-view to be enabled **BEFORE** any view controllers are created. The default `FlutterAppDelegate` creates a view controller automatically, preventing multi-view. The AppDelegate in this example has been configured to create the engine manually without view controllers:

```swift
override func applicationDidFinishLaunching(_ notification: Notification) {
  engine = FlutterEngine(name: "main", project: nil)
  engine?.run(withEntrypoint: nil)
  RegisterGeneratedPlugins(registry: engine!)
}
```

This allows `RegularWindowController` to enable multi-view when created from Dart.

## Screenshots

The example app provides an interactive interface to test all window decoration features in real-time.
