# window_decoration example

Demonstrates the widget-first API of the `window_decoration` package:
`WindowDragArea`, `WindowTrafficLight`, `CloseButton`, `MinimizeButton`,
`MaximizeButton`, `WindowBorder`, and the platform-specific feature methods
on `DecoratedWindowMacOS` / `DecoratedWindowWin32` / `DecoratedWindowLinux`.

## Run

```bash
cd example
flutter run -d macos    # or -d windows, -d linux
```

## Native configuration

The example's `macos/Runner/AppDelegate.swift` is set up to create the
`FlutterEngine` manually so that Flutter's multi-view can be enabled by
`WindowController`. See the top-level `README.md` for details.
