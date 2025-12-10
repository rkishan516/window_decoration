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

  // Custom title bar height
  static const double kTitleBarHeight = 48.0;
  static const double kButtonWidth = 46.0;

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
      // For customFrame style, use custom caption height
      final captionHeight =
          style == TitleBarStyle.customFrame ? kTitleBarHeight.toInt() : 32;
      await service.setTitleBarStyle(style, captionHeight: captionHeight);

      // On Windows, set up caption button zones for snap layout support
      if (Platform.isWindows && style == TitleBarStyle.customFrame) {
        await _updateCaptionButtonZones();
      }

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

  Future<void> _updateCaptionButtonZones() async {
    if (!Platform.isWindows) return;

    try {
      final bounds = await service.getBounds();
      final windowWidth = bounds.width;

      // Define button zones (right-aligned: minimize, maximize, close)
      await service.windows.setCaptionButtonZones(
        minimize: Rect.fromLTWH(
          windowWidth - 3 * kButtonWidth,
          0,
          kButtonWidth,
          kTitleBarHeight,
        ),
        maximize: Rect.fromLTWH(
          windowWidth - 2 * kButtonWidth,
          0,
          kButtonWidth,
          kTitleBarHeight,
        ),
        close: Rect.fromLTWH(
          windowWidth - kButtonWidth,
          0,
          kButtonWidth,
          kTitleBarHeight,
        ),
      );
    } catch (e) {
      debugPrint('Error updating caption button zones: $e');
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

  void _minimizeWindow() {
    // In a real app, you'd implement minimize via platform channel
    _setStatus('Minimize clicked');
  }

  void _maximizeWindow() {
    // In a real app, you'd implement maximize via platform channel
    _setStatus('Maximize clicked (try hovering for snap layouts on Win11)');
  }

  void _closeWindow() {
    // In a real app, you'd close the window
    _setStatus('Close clicked');
  }

  @override
  Widget build(BuildContext context) {
    // When using customFrame style, we need to show our own title bar
    final showCustomTitleBar =
        titleBarStyle == TitleBarStyle.customFrame ||
        titleBarStyle == TitleBarStyle.hidden;

    return Scaffold(
      appBar: showCustomTitleBar ? null : _buildDefaultAppBar(),
      body: Column(
        children: [
          // Custom title bar when using customFrame or hidden style
          if (showCustomTitleBar) _buildCustomTitleBar(),

          // Main content
          Expanded(
            child: SingleChildScrollView(
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
                        'Size: ${currentBounds!.width.toInt()} x ${currentBounds!.height.toInt()}',
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
                        _titleBarButton(
                          TitleBarStyle.transparent,
                          'Transparent',
                        ),
                        _titleBarButton(TitleBarStyle.unified, 'Unified'),
                        _titleBarButton(
                          TitleBarStyle.customFrame,
                          'Custom Frame (Win11)',
                        ),
                      ],
                    ),
                    if (titleBarStyle == TitleBarStyle.customFrame) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.shade700,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Windows 11 File Explorer Style Active',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Window has shadow, rounded corners & border\n'
                              '• Custom title bar with drag area\n'
                              '• Hover over maximize button for snap layouts\n'
                              '• Resize from all edges and corners\n'
                              '• Double-click title bar to maximize',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (titleBarStyle == TitleBarStyle.hidden) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade900.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Hidden mode (legacy borderless):\n'
                          '• No window decorations\n'
                          '• Drag the custom title bar to move\n'
                          '• Use custom buttons to control window',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 24),

                  // macOS-Specific Features
                  if (Platform.isMacOS) ...[
                    _buildSection('macOS Vibrancy Effects', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _vibrancyButton(
                            NSVisualEffectMaterial.sidebar,
                            'Sidebar',
                          ),
                          _vibrancyButton(
                            NSVisualEffectMaterial.titlebar,
                            'Titlebar',
                          ),
                          _vibrancyButton(NSVisualEffectMaterial.menu, 'Menu'),
                          _vibrancyButton(
                            NSVisualEffectMaterial.popover,
                            'Popover',
                          ),
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
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    return AppBar(
      title: const Text('Window Decoration Interactive Demo'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _resetDefaults,
          tooltip: 'Reset to defaults',
        ),
      ],
    );
  }

  Widget _buildCustomTitleBar() {
    return GestureDetector(
      onPanStart: (_) {
        // Start dragging the window
        service.windows.startDrag();
      },
      onDoubleTap: _maximizeWindow,
      child: Container(
        height: kTitleBarHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade800,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // App icon and title
            const SizedBox(width: 16),
            Icon(
              Icons.window,
              color: Colors.blue.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Window Decoration Demo - Custom Title Bar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Reset button
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _resetDefaults,
              tooltip: 'Reset to defaults',
              splashRadius: 18,
            ),

            const SizedBox(width: 8),

            // Window control buttons
            _WindowButton(
              icon: Icons.remove,
              onPressed: _minimizeWindow,
              tooltip: 'Minimize',
            ),
            _WindowButton(
              icon: Icons.crop_square,
              onPressed: _maximizeWindow,
              tooltip: 'Maximize (hover for snap layouts)',
            ),
            _WindowButton(
              icon: Icons.close,
              onPressed: _closeWindow,
              tooltip: 'Close',
              isClose: true,
            ),
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
        foregroundColor:
            color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
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

/// A window control button (minimize, maximize, close)
class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: _DemoHomePageState.kButtonWidth,
            height: _DemoHomePageState.kTitleBarHeight,
            color: _isHovered
                ? (widget.isClose ? Colors.red : Colors.white.withValues(alpha: 0.1))
                : Colors.transparent,
            child: Icon(
              widget.icon,
              size: 16,
              color: _isHovered && widget.isClose ? Colors.white : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
