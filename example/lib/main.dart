// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'dart:io' show Platform;

import 'package:flutter/material.dart' hide CloseButton;
import 'package:flutter/src/widgets/_window.dart';
import 'package:window_decoration/window_decoration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = WindowController(
    size: const Size(900, 700),
    title: 'Window Decoration Demo',
  );
  controller.enableDecoratedWindow();

  runWidget(
    Window(
      controller: controller,
      child: _DemoApp(controller: controller),
    ),
  );
}

class _DemoApp extends StatelessWidget {
  const _DemoApp({required this.controller});

  final WindowController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Window Decoration Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: _DemoHome(controller: controller),
    );
  }
}

class _DemoHome extends StatefulWidget {
  const _DemoHome({required this.controller});

  final WindowController controller;

  @override
  State<_DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<_DemoHome> {
  double _opacity = 1.0;
  bool _alwaysOnTop = false;
  bool _skipTaskbar = false;

  DecoratedWindow? get _window => DecoratedWindow.forController(widget.controller);

  @override
  Widget build(BuildContext context) {
    return WindowBorder(
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade900,
        body: Column(
          children: [
            _TitleBar(controller: widget.controller),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const _SectionHeader('Shared controls'),
                  _opacitySlider(),
                  _toggle(
                    label: 'Always on top',
                    value: _alwaysOnTop,
                    onChanged: (v) async {
                      await _window?.setAlwaysOnTop(alwaysOnTop: v);
                      setState(() => _alwaysOnTop = v);
                    },
                  ),
                  _toggle(
                    label: 'Skip taskbar / dock',
                    value: _skipTaskbar,
                    onChanged: (v) async {
                      await _window?.setSkipTaskbar(skip: v);
                      setState(() => _skipTaskbar = v);
                    },
                  ),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () => _window?.center(),
                        child: const Text('Center window'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => _window?.hide().then((_) async {
                          await Future.delayed(const Duration(seconds: 1));
                          await _window?.show();
                        }),
                        child: const Text('Hide for 1 second'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (Platform.isMacOS) _macOSSection(),
                  if (Platform.isWindows) _windowsSection(),
                  if (Platform.isLinux) _linuxSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opacitySlider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        const SizedBox(width: 140, child: Text('Opacity')),
        Expanded(
          child: Slider(
            value: _opacity,
            min: 0.3,
            max: 1.0,
            onChanged: (v) async {
              setState(() => _opacity = v);
              await _window?.setOpacity(v);
            },
          ),
        ),
        SizedBox(width: 48, child: Text(_opacity.toStringAsFixed(2))),
      ],
    ),
  );

  Widget _toggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile(
    title: Text(label),
    value: value,
    onChanged: onChanged,
    contentPadding: EdgeInsets.zero,
  );

  Widget _macOSSection() {
    final macWindow = _window as DecoratedWindowMacOS?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('macOS'),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => macWindow?.setVibrancy(
                NSVisualEffectMaterial.sidebar,
              ),
              child: const Text('Vibrancy: sidebar'),
            ),
            FilledButton(
              onPressed: () => macWindow?.setVibrancy(
                NSVisualEffectMaterial.hudWindow,
              ),
              child: const Text('Vibrancy: HUD'),
            ),
            FilledButton(
              onPressed: () => macWindow?.setHasShadow(hasShadow: false),
              child: const Text('Remove shadow'),
            ),
            FilledButton(
              onPressed: () => macWindow?.setHasShadow(hasShadow: true),
              child: const Text('Add shadow'),
            ),
            FilledButton(
              onPressed: () =>
                  macWindow?.setMovableByWindowBackground(movable: true),
              child: const Text('Movable by background'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _windowsSection() {
    final winWindow = _window as DecoratedWindowWin32?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Windows'),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => winWindow?.setSystemBackdrop(
                DWMSystemBackdropType.mainWindow,
              ),
              child: const Text('Backdrop: Mica'),
            ),
            FilledButton(
              onPressed: () => winWindow?.setSystemBackdrop(
                DWMSystemBackdropType.transientWindow,
              ),
              child: const Text('Backdrop: Acrylic'),
            ),
            FilledButton(
              onPressed: () => winWindow?.setCornerPreference(
                WindowCornerPreference.round,
              ),
              child: const Text('Corners: round'),
            ),
            FilledButton(
              onPressed: () => winWindow?.setDarkMode(enabled: true),
              child: const Text('Dark caption'),
            ),
            FilledButton(
              onPressed: () =>
                  winWindow?.setBorderColor(Colors.deepPurpleAccent),
              child: const Text('Border: purple'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _linuxSection() {
    final linuxWindow = _window as DecoratedWindowLinux?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Linux'),
        FutureBuilder<String>(
          future: () async {
            if (linuxWindow == null) return 'unavailable';
            if (await linuxWindow.isWayland()) return 'Wayland';
            if (await linuxWindow.isX11()) return 'X11';
            return 'unknown';
          }(),
          builder: (context, snap) =>
              Text('Display server: ${snap.data ?? '...'}'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleLarge,
    ),
  );
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.controller});

  final WindowController controller;

  @override
  Widget build(BuildContext context) {
    return WindowDragArea(
      child: Container(
        height: 40,
        color: Colors.blueGrey.shade800,
        child: Row(
          children: [
            const SizedBox(width: 12),
            const WindowTrafficLight(),
            const SizedBox(width: 12),
            Expanded(
              child: Center(
                child: Text(
                  'Window Decoration Demo',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            if (!Platform.isMacOS) ...[
              _TitlebarIconButton.minimize(),
              _TitlebarIconButton.maximize(),
              _TitlebarIconButton.close(),
            ],
          ],
        ),
      ),
    );
  }
}

class _TitlebarIconButton extends StatelessWidget {
  const _TitlebarIconButton._({
    required this.icon,
    required this.kind,
  });

  factory _TitlebarIconButton.close() =>
      const _TitlebarIconButton._(icon: Icons.close, kind: _Kind.close);

  factory _TitlebarIconButton.minimize() =>
      const _TitlebarIconButton._(icon: Icons.remove, kind: _Kind.minimize);

  factory _TitlebarIconButton.maximize() => const _TitlebarIconButton._(
    icon: Icons.crop_square,
    kind: _Kind.maximize,
  );

  final IconData icon;
  final _Kind kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _Kind.close:
        return CloseButton(builder: _build);
      case _Kind.minimize:
        return MinimizeButton(builder: _build);
      case _Kind.maximize:
        return MaximizeButton(
          builder: (context, state, isMaximized) => _build(context, state),
        );
    }
  }

  Widget _build(BuildContext context, TitlebarButtonState state) {
    final color = kind == _Kind.close && state.hovered
        ? Colors.red
        : state.hovered
        ? Colors.white24
        : Colors.transparent;
    return Container(
      width: 46,
      height: 40,
      color: color,
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

enum _Kind { close, minimize, maximize }
