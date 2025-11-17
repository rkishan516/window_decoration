// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:window_decoration/window_decoration.dart';

void main() {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Create RegularWindowController
  final controller = RegularWindowController(
    preferredSize: const Size(900, 700),
    title: 'Window Decoration Demo',
  );

  // Run the app with RegularWindow
  runWidget(
    RegularWindow(
      controller: controller,
      child: WindowDecorationDemoApp(controller: controller),
    ),
  );
}

class WindowDecorationDemoApp extends StatelessWidget {
  const WindowDecorationDemoApp({required this.controller, super.key});

  final RegularWindowController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Window Decoration Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: DemoHomePage(controller: controller),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({required this.controller, super.key});

  final RegularWindowController controller;

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  late final WindowDecorationService service;
  String statusMessage = 'Ready';
  double opacity = 1.0;
  bool alwaysOnTop = false;
  bool skipTaskbar = false;
  bool fullScreen = false;
  TitleBarStyle titleBarStyle = TitleBarStyle.normal;
  Color backgroundColor = Colors.black;
  WindowBounds? currentBounds;

  @override
  void initState() {
    super.initState();
    service = WindowDecorationService(widget.controller);
    // Load initial window bounds
    _loadCurrentBounds();
  }

  Future<void> _loadCurrentBounds() async {
    try {
      final bounds = await service.getBounds();
      if (!mounted) return;
      setState(() {
        currentBounds = bounds;
        statusMessage = 'Loaded window bounds';
      });
    } catch (e) {
      if (!mounted) return;
      _setStatus('Error loading bounds: $e');
    }
  }

  void _setStatus(String message) {
    setState(() {
      statusMessage = message;
    });
    debugPrint(message);
  }

  Future<void> _centerWindow() async {
    try {
      await service.center();
      if (!mounted) return;
      _setStatus('Window centered successfully');
    } catch (e) {
      if (!mounted) return;
      _setStatus('Error centering window: $e');
    }
  }

  Future<void> _setOpacity(double value) async {
    try {
      await service.setOpacity(value);
      if (!mounted) return;
      setState(() {
        opacity = value;
      });
      _setStatus('Opacity set to ${value.toStringAsFixed(2)}');
    } catch (e) {
      if (!mounted) return;
      _setStatus('Error setting opacity: $e');
    }
  }

  Future<void> _toggleAlwaysOnTop() async {
    try {
      final newValue = !alwaysOnTop;
      await service.setAlwaysOnTop(alwaysOnTop: newValue);
      if (!mounted) return;
      setState(() {
        alwaysOnTop = newValue;
      });
      _setStatus('Always on top: $newValue');
    } catch (e) {
      if (!mounted) return;
      _setStatus('Error toggling always on top: $e');
    }
  }

  Future<void> _toggleSkipTaskbar() async {
    try {
      final newValue = !skipTaskbar;
      await service.setSkipTaskbar(skip: newValue);
      if (!mounted) return;
      setState(() {
        skipTaskbar = newValue;
      });
      _setStatus('Skip taskbar: $newValue');
    } catch (e) {
      if (!mounted) return;
      _setStatus('Error toggling skip taskbar: $e');
    }
  }

  Future<void> _toggleFullScreen() async {
    try {
      final newValue = !fullScreen;
      await service.setFullScreen(fullScreen: newValue);
      if (!mounted) return;
      setState(() {
        fullScreen = newValue;
      });
      _setStatus('Fullscreen: $newValue');
    } catch (e) {
      if (!mounted) return;
      _setStatus('Error toggling fullscreen: $e');
    }
  }

  Future<void> _setTitleBarStyle(TitleBarStyle style) async {
    try {
      await service.setTitleBarStyle(style);
      if (!mounted) return;
      setState(() {
        titleBarStyle = style;
      });
      _setStatus('Title bar style: ${style.name}');
    } catch (e) {
      if (!mounted) return;
      _setStatus('Error setting title bar style: $e');
    }
  }

  Future<void> _setBackgroundColor(Color color) async {
    try {
      await service.setBackgroundColor(color);
      if (!mounted) return;
      setState(() {
        backgroundColor = color;
      });
      _setStatus('Background color changed');
    } catch (e) {
      if (!mounted) return;
      _setStatus('Error setting background color: $e');
    }
  }

  Future<void> _setVibrancy(NSVisualEffectMaterial material) async {
    if (!Platform.isMacOS) {
      _setStatus('Vibrancy is macOS-only');
      return;
    }
    try {
      await service.macos.setVibrancy(material);
      if (!mounted) return;
      _setStatus('Vibrancy: ${material.name}');
    } catch (e) {
      if (!mounted) return;
      _setStatus('Error setting vibrancy: $e');
    }
  }

  Future<void> _resetDefaults() async {
    try {
      await service.setOpacity(1.0);
      await service.setAlwaysOnTop(alwaysOnTop: false);
      await service.setSkipTaskbar(skip: false);
      await service.setFullScreen(fullScreen: false);
      await service.setTitleBarStyle(TitleBarStyle.normal);
      await service.setBackgroundColor(Colors.black);

      if (!mounted) return;
      setState(() {
        opacity = 1.0;
        alwaysOnTop = false;
        skipTaskbar = false;
        fullScreen = false;
        titleBarStyle = TitleBarStyle.normal;
        backgroundColor = Colors.black;
      });

      _setStatus('Reset to defaults');
    } catch (e) {
      if (!mounted) return;
      _setStatus('Error resetting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Window Decoration Interactive Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetDefaults,
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Window Bounds Info
            if (currentBounds != null) ...[
              _buildSection('Current Window Bounds', [
                Text(
                  'Position: (${currentBounds!.x.toInt()}, ${currentBounds!.y.toInt()})\n'
                  'Size: ${currentBounds!.width.toInt()} × ${currentBounds!.height.toInt()}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ]),
              const SizedBox(height: 24),
            ],

            // Window Positioning
            _buildSection('Window Positioning', [
              ElevatedButton.icon(
                onPressed: _centerWindow,
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Center Window'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadCurrentBounds,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Bounds'),
              ),
            ]),

            const SizedBox(height: 24),

            // Window Appearance
            _buildSection('Window Appearance', [
              const Text(
                'Opacity:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: opacity,
                      min: 0.3,
                      max: 1.0,
                      divisions: 14,
                      label: opacity.toStringAsFixed(2),
                      onChanged: _setOpacity,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      opacity.toStringAsFixed(2),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Background Color:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _colorButton(Colors.black, 'Black'),
                  _colorButton(Colors.white, 'White'),
                  _colorButton(Colors.red.shade900, 'Red'),
                  _colorButton(Colors.blue.shade900, 'Blue'),
                  _colorButton(Colors.green.shade900, 'Green'),
                  _colorButton(Colors.purple.shade900, 'Purple'),
                ],
              ),
            ]),

            const SizedBox(height: 24),

            // Window Behavior
            _buildSection('Window Behavior', [
              SwitchListTile(
                title: const Text('Always on Top'),
                subtitle: const Text('Keep window above all others'),
                value: alwaysOnTop,
                onChanged: (_) => _toggleAlwaysOnTop(),
              ),
              SwitchListTile(
                title: const Text('Skip Taskbar'),
                subtitle: const Text('Hide from dock/taskbar'),
                value: skipTaskbar,
                onChanged: (_) => _toggleSkipTaskbar(),
              ),
              SwitchListTile(
                title: const Text('Fullscreen'),
                subtitle: const Text('Toggle fullscreen mode'),
                value: fullScreen,
                onChanged: (_) => _toggleFullScreen(),
              ),
            ]),

            const SizedBox(height: 24),

            // Title Bar Styles
            _buildSection('Title Bar Style', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _titleBarButton(TitleBarStyle.normal, 'Normal'),
                  _titleBarButton(TitleBarStyle.hidden, 'Hidden'),
                  _titleBarButton(TitleBarStyle.transparent, 'Transparent'),
                  _titleBarButton(TitleBarStyle.unified, 'Unified'),
                ],
              ),
            ]),

            const SizedBox(height: 24),

            // macOS-Specific Features
            if (Platform.isMacOS) ...[
              _buildSection('macOS Vibrancy Effects', [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _vibrancyButton(NSVisualEffectMaterial.sidebar, 'Sidebar'),
                    _vibrancyButton(
                      NSVisualEffectMaterial.titlebar,
                      'Titlebar',
                    ),
                    _vibrancyButton(NSVisualEffectMaterial.menu, 'Menu'),
                    _vibrancyButton(NSVisualEffectMaterial.popover, 'Popover'),
                    _vibrancyButton(
                      NSVisualEffectMaterial.windowBackground,
                      'Window BG',
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _colorButton(Color color, String label) {
    final isSelected = backgroundColor == color;
    return ElevatedButton(
      onPressed: () => _setBackgroundColor(color),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white,
        side: isSelected
            ? const BorderSide(color: Colors.white, width: 3)
            : null,
      ),
      child: Text(label),
    );
  }

  Widget _titleBarButton(TitleBarStyle style, String label) {
    final isSelected = titleBarStyle == style;
    return ElevatedButton(
      onPressed: () => _setTitleBarStyle(style),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
      ),
      child: Text(label),
    );
  }

  Widget _vibrancyButton(NSVisualEffectMaterial material, String label) {
    return ElevatedButton(
      onPressed: () => _setVibrancy(material),
      child: Text(label),
    );
  }
}
