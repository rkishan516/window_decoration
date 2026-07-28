# window_decoration

Fully custom windows and decorations for Flutter desktop, designed to work with
Flutter's experimental multi-window API (`WindowController`).

`window_decoration` 0.2.x is a single pure-Dart Flutter package. Platform code
for macOS and Linux is shipped as native source and built via Dart's native
build hooks; Windows uses `package:win32` only (no plugin DLL).

## Features

- Widget-driven custom title bars via `WindowDragArea`
- macOS traffic lights repositionable with `WindowTrafficLight`
- Cross-platform `CloseButton` / `MinimizeButton` / `MaximizeButton`
- Linux custom border, shadow, and resize handles via `WindowBorder`
- Platform-specific window chrome:
  - **macOS**: `NSVisualEffectView` vibrancy, shadow, movable-by-background,
    collection behavior, fullscreen/resize delegate hooks
  - **Windows**: DWM Mica/Acrylic backdrop, corner preference, border color,
    immersive dark mode, `WM_*` message handler hook
  - **Linux**: GTK opacity, keep-above, skip-taskbar, window-state delegate

## Platform support

| Platform | Status |
|----------|--------|
| macOS    | Supported (Apple Silicon + Intel) |
| Windows  | Supported (Windows 10 1809+, Mica/Acrylic need Windows 11) |
| Linux    | Supported (GTK 3, X11; Wayland has compositor limitations) |
| Web/iOS/Android | Not supported |

## Installation

Path dependency:
```yaml
dependencies:
  window_decoration:
    path: path/to/window_decoration
```

Or via git:
```yaml
dependencies:
  window_decoration:
    git:
      url: https://github.com/rkishan516/window_decoration
      path: packages/window_decoration
```

The package uses Dart native build hooks (`hooks`, `native_toolchain_ninja`,
`code_assets`), which require Flutter 3.42+. Enable native asset building if
your Flutter version does not do so by default:

```
flutter config --enable-native-assets
```

## Quick start

```dart
import 'package:flutter/material.dart' hide CloseButton;
import 'package:flutter/src/widgets/_window.dart';
import 'package:window_decoration/window_decoration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = WindowController(
    preferredSize: const Size(800, 600),
    title: 'My App',
  );
  controller.enableDecoratedWindow();
  runWidget(Window(controller: controller, child: MyApp()));
}

class MyTitleBar extends StatelessWidget {
  const MyTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowDragArea(
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const WindowTrafficLight(),
            const Spacer(),
            MinimizeButton(builder: _icon(Icons.remove)),
            MaximizeButton(
              builder: (context, state, isMaximized) =>
                  _icon(isMaximized ? Icons.filter_none : Icons.crop_square)(
                context,
                state,
              ),
            ),
            CloseButton(builder: _icon(Icons.close)),
          ],
        ),
      ),
    );
  }

  Widget Function(BuildContext, TitlebarButtonState) _icon(IconData d) =>
      (context, s) => Container(
            width: 46,
            color: s.hovered ? Colors.white10 : Colors.transparent,
            child: Icon(d, size: 16),
          );
}
```

Wrap your root widget in `WindowBorder` to get Linux custom shadow and resize
handles (no-op on other platforms):

```dart
WindowBorder(child: Scaffold(body: ...))
```

## Platform-specific features

Platform-specific methods live on `DecoratedWindowMacOS`, `DecoratedWindowWin32`,
and `DecoratedWindowLinux`. Access them by downcasting:

```dart
final window = DecoratedWindow.forController(controller);

if (Platform.isMacOS) {
  (window as DecoratedWindowMacOS?)
      ?.setVibrancy(NSVisualEffectMaterial.sidebar);
}
if (Platform.isWindows) {
  (window as DecoratedWindowWin32?)
      ?.setSystemBackdrop(DWMSystemBackdropType.mainWindow);
}
```

Shared methods available on all platforms (via the base class):

- `center()`
- `setBackgroundColor(Color)`
- `setOpacity(double)`
- `setAlwaysOnTop({required bool alwaysOnTop})`
- `setSkipTaskbar({required bool skip})`
- `setVisible({required bool visible})` / `show()` / `hide()`

For fullscreen, maximize, minimize, size, and constraints, use
`WindowController` directly.

## Required native setup

To use `window_decoration` with Flutter's multi-window API, configure the
macOS `AppDelegate` to create the `FlutterEngine` manually so that multi-view
can be enabled from Dart later.

`macos/Runner/AppDelegate.swift`:

```swift
import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  var engine: FlutterEngine?

  override func applicationDidFinishLaunching(_ notification: Notification) {
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

This is needed because the default `FlutterAppDelegate` creates a view
controller automatically, and multi-view must be enabled BEFORE any view
controller is created.

## Delegates

For lifecycle / resize / fullscreen / state hooks, register a delegate mixin
on the platform controller:

```dart
class _MyPage extends State<MyPage> with WindowDelegateMacOS {
  @override
  void initState() {
    super.initState();
    (controller as WindowControllerMacOS).addDelegate(this);
  }

  @override
  Size? windowWillResizeToSize(Size newSize) {
    // Enforce an aspect ratio, etc.
    return null;
  }

  @override
  void windowWillEnterFullScreen() {}
}
```

Equivalent mixins exist for Windows (`WindowDelegateWin32` +
`Win32MessageHandler`) and Linux (`WindowDelegateLinux`, with
`WindowControllerLinuxExtension.getWindowState()`).

## Limitations

- The package targets the experimental Flutter multi-window API. Breaking
  changes in Flutter's internal `_window.dart` imports may require updates.
- Integration testing with `integration_test` is currently not compatible with
  this setup; use the example app for manual verification.
- Linux Wayland imposes compositor-level restrictions on keep-above,
  positioning, and window-state queries.
- Mica/Acrylic effects and rounded corners require Windows 11.

## Credits

- Based on architectural patterns from
  [knopp/window_toolbox](https://github.com/knopp/window_toolbox).
- Earlier federated implementation drew on `bitsdojo_window` and
  `window_manager`.
