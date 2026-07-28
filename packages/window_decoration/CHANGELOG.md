# Changelog

All notable changes to this project will be documented in this file.

## 0.2.0

BREAKING: full architectural rewrite. Package is now a single, unified Flutter package (no longer federated).

### Removed
- `WindowDecorationService` class — dropped in favor of the widget-first API.
- `DecoratedWindow` *widget* — the name now refers to the abstract platform-dispatch base class.
- `TitleBarStyle` enum and `setTitleBarStyle()` — replaced by `WindowDragArea` + custom chrome widgets.
- `WindowBounds`, `getBounds()`, `setBounds()` — use `WindowController.contentSize` and `setSize()` directly.
- `setSizeConstraints()` — use `WindowController.setConstraints()`.
- `setFullScreen()` — use `WindowController.setFullscreen()`.
- `onWindowStateChanged` stream — replaced by `WindowDelegateMacOS`/`Win32`/`Linux` mixins.
- Windows C++ native plugin — all Win32 handling now pure Dart via `SetWindowSubclass` from `package:win32`.
- Federated packages: `window_decoration_linux`, `window_decoration_macos`, `window_decoration_windows`, `window_decoration_platform_interface`, `window_decoration_web`.

### Added
- `controller.enableDecoratedWindow()` extension on `BaseWindowController`.
- Widget API: `WindowDragArea`, `WindowDragExcludeArea`, `WindowTrafficLight`, `CloseButton`, `MinimizeButton`, `MaximizeButton`, `WindowBorder`.
- Delegate mixins with FFI `NativeCallable` bridging: `WindowDelegateMacOS` (windowWillClose/WillResize/WillUseStandardFrame/Enter+ExitFullScreen), `WindowDelegateWin32` (windowWillClose/WillResizeToSize + `Win32MessageHandler`), `WindowDelegateLinux` (windowWillClose/StateDidChange + `WindowStateLinux`).
- ffigen-generated bindings for macOS and Linux native code.
- Native code built via Dart's native hooks (`hooks` + `native_toolchain_ninja` + `code_assets`).

## 0.1.0

Initial federated-plugin release. Removed in 0.2.0.
