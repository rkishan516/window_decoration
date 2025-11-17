// ignore_for_file: implementation_imports

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:window_decoration_macos/src/effects/ns_visual_effect_material.dart';
import 'package:window_decoration_macos/src/ffi/objc_bindings.dart';
import 'package:window_decoration_platform_interface/window_decoration_platform_interface.dart';

/// macOS implementation of the window_decoration plugin
class WindowDecorationMacOS extends WindowDecorationPlatform {
  /// The NSWindow pointer
  late final ObjCObjectPointer _nsWindow;

  /// Whether the platform has been initialized
  bool _isInitialized = false;

  /// Registers this class as the default instance of [WindowDecorationPlatform]
  static void registerWith() {
    WindowDecorationPlatform.instance = WindowDecorationMacOS();
  }

  @override
  void initialize(covariant Pointer<Void> windowHandle) {
    _nsWindow = windowHandle.cast<ObjCObject>();
    _isInitialized = true;
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'WindowDecorationMacOS not initialized. '
        'Call initialize() with the window handle first.',
      );
    }
  }

  // ==========================================================================
  // Position & Size
  // ==========================================================================

  @override
  Future<void> center() async {
    _checkInitialized();
    final centerSel = ObjCBindings.sel('center');
    ObjCBindings.objc_msgSend(_nsWindow, centerSel);
  }

  @override
  Future<WindowBounds> getBounds() async {
    _checkInitialized();

    // Get frame: NSRect frame = [window frame];
    final frameSel = ObjCBindings.sel('frame');

    // On arm64, objc_msgSend returns structs in registers
    final rect = ObjCBindings.objc_msgSend_stret_nsrect(_nsWindow, frameSel);

    return WindowBounds(
      x: rect.x,
      y: rect.y,
      width: rect.width,
      height: rect.height,
    );
  }

  @override
  Future<void> setBounds(WindowBounds bounds) async {
    _checkInitialized();

    // setFrame:display:
    final setFrameSel = ObjCBindings.sel('setFrame:display:');
    final rect = calloc<NSRect>();

    try {
      // Create NSRect with the desired bounds
      rect.ref.x = bounds.x;
      rect.ref.y = bounds.y;
      rect.ref.width = bounds.width;
      rect.ref.height = bounds.height;

      // Call setFrame:display:YES
      ObjCBindings.objc_msgSend_void_rect_bool(
        _nsWindow,
        setFrameSel,
        rect,
        true,
      );
    } finally {
      calloc.free(rect);
    }
  }

  // ==========================================================================
  // Appearance
  // ==========================================================================

  @override
  Future<void> setBackgroundColor(Color color) async {
    _checkInitialized();

    // Create NSColor
    final nsColorClass = ObjCBindings.getClass('NSColor');
    final colorWithRGBASel = ObjCBindings.sel('colorWithRed:green:blue:alpha:');

    final nsColor = ObjCBindings.objc_msgSend_obj_4doubles(
      nsColorClass,
      colorWithRGBASel,
      (color.r * 255.0).round().clamp(0, 255) / 255.0,
      (color.g * 255.0).round().clamp(0, 255) / 255.0,
      (color.b * 255.0).round().clamp(0, 255) / 255.0,
      (color.a * 255.0).round().clamp(0, 255) / 255.0,
    );

    // Set background color
    final setBackgroundColorSel = ObjCBindings.sel('setBackgroundColor:');
    ObjCBindings.objc_msgSend_void_obj(
      _nsWindow,
      setBackgroundColorSel,
      nsColor,
    );
  }

  @override
  Future<void> setOpacity(double opacity) async {
    _checkInitialized();

    // Set opaque to false if opacity < 1.0
    final setOpaqueSel = ObjCBindings.sel('setOpaque:');
    ObjCBindings.objc_msgSend_void_bool(
      _nsWindow,
      setOpaqueSel,
      opacity >= 1.0,
    );

    // Set alpha value
    final setAlphaValueSel = ObjCBindings.sel('setAlphaValue:');
    ObjCBindings.objc_msgSend_void_double(_nsWindow, setAlphaValueSel, opacity);
  }

  // ==========================================================================
  // Behavior
  // ==========================================================================

  @override
  Future<void> setAlwaysOnTop({required bool alwaysOnTop}) async {
    _checkInitialized();

    final setLevelSel = ObjCBindings.sel('setLevel:');
    final level = alwaysOnTop ? NSWindowLevel.floating : NSWindowLevel.normal;

    ObjCBindings.objc_msgSend_void_int(_nsWindow, setLevelSel, level);
  }

  @override
  Future<void> setSkipTaskbar({required bool skip}) async {
    _checkInitialized();

    // This affects the entire application's dock icon, not just the window
    final nsAppClass = ObjCBindings.getClass('NSApplication');
    final sharedApplicationSel = ObjCBindings.sel('sharedApplication');
    final nsApp = ObjCBindings.objc_msgSend(nsAppClass, sharedApplicationSel);

    final setActivationPolicySel = ObjCBindings.sel('setActivationPolicy:');
    final policy = skip
        ? NSApplicationActivationPolicy.accessory
        : NSApplicationActivationPolicy.regular;

    ObjCBindings.objc_msgSend_void_int(nsApp, setActivationPolicySel, policy);
  }

  @override
  Future<void> setFullScreen({required bool fullScreen}) async {
    _checkInitialized();

    final isFullscreen = await _isFullScreen();

    if (fullScreen && !isFullscreen) {
      // Enter fullscreen
      final toggleFullScreenSel = ObjCBindings.sel('toggleFullScreen:');
      ObjCBindings.objc_msgSend(_nsWindow, toggleFullScreenSel);
    } else if (!fullScreen && isFullscreen) {
      // Exit fullscreen
      final toggleFullScreenSel = ObjCBindings.sel('toggleFullScreen:');
      ObjCBindings.objc_msgSend(_nsWindow, toggleFullScreenSel);
    }
  }

  Future<bool> _isFullScreen() async {
    final styleMaskSel = ObjCBindings.sel('styleMask');
    final styleMask = ObjCBindings.objc_msgSend_int(_nsWindow, styleMaskSel);
    return (styleMask & NSWindowStyleMask.fullScreen) != 0;
  }

  @override
  Future<void> setTitleBarStyle(TitleBarStyle style) async {
    _checkInitialized();

    switch (style) {
      case TitleBarStyle.normal:
        await _setTitleBarNormal();
      case TitleBarStyle.hidden:
        await _setTitleBarHidden();
      case TitleBarStyle.transparent:
        await _setTitleBarTransparent();
      case TitleBarStyle.unified:
        await _setUnifiedTitleBar();
    }
  }

  @override
  Future<void> setVisible({required bool visible}) async {
    _checkInitialized();

    if (visible) {
      // Show the window using orderFront:
      final orderFrontSel = ObjCBindings.sel('orderFront:');
      ObjCBindings.objc_msgSend(_nsWindow, orderFrontSel);
    } else {
      // Hide the window using orderOut:
      final orderOutSel = ObjCBindings.sel('orderOut:');
      ObjCBindings.objc_msgSend(_nsWindow, orderOutSel);
    }
  }

  Future<void> _setTitleBarNormal() async {
    // Reset to default title bar
    final setTitlebarAppearsTransparentSel = ObjCBindings.sel(
      'setTitlebarAppearsTransparent:',
    );
    ObjCBindings.objc_msgSend_void_bool(
      _nsWindow,
      setTitlebarAppearsTransparentSel,
      false,
    );

    final setTitleVisibilitySel = ObjCBindings.sel('setTitleVisibility:');
    ObjCBindings.objc_msgSend_void_int(
      _nsWindow,
      setTitleVisibilitySel,
      NSWindowTitleVisibility.visible,
    );

    // Show window buttons
    _setWindowButtonsHidden(false);
  }

  Future<void> _setTitleBarHidden() async {
    final setTitlebarAppearsTransparentSel = ObjCBindings.sel(
      'setTitlebarAppearsTransparent:',
    );
    ObjCBindings.objc_msgSend_void_bool(
      _nsWindow,
      setTitlebarAppearsTransparentSel,
      true,
    );

    final setTitleVisibilitySel = ObjCBindings.sel('setTitleVisibility:');
    ObjCBindings.objc_msgSend_void_int(
      _nsWindow,
      setTitleVisibilitySel,
      NSWindowTitleVisibility.hidden,
    );

    // Hide window buttons
    _setWindowButtonsHidden(true);
  }

  Future<void> _setTitleBarTransparent() async {
    final setTitlebarAppearsTransparentSel = ObjCBindings.sel(
      'setTitlebarAppearsTransparent:',
    );
    ObjCBindings.objc_msgSend_void_bool(
      _nsWindow,
      setTitlebarAppearsTransparentSel,
      true,
    );

    // Enable full size content view
    final getStyleMaskSel = ObjCBindings.sel('styleMask');
    final currentStyle = ObjCBindings.objc_msgSend_int(
      _nsWindow,
      getStyleMaskSel,
    );

    final newStyle = currentStyle | NSWindowStyleMask.fullSizeContentView;

    final setStyleMaskSel = ObjCBindings.sel('setStyleMask:');
    ObjCBindings.objc_msgSend_void_int(_nsWindow, setStyleMaskSel, newStyle);
  }

  Future<void> _setUnifiedTitleBar() async {
    // Unified title bar with toolbar
    await _setTitleBarTransparent();

    // Create and set toolbar for unified appearance
    final toolbarClass = ObjCBindings.getClass('NSToolbar');
    final allocSel = ObjCBindings.sel('alloc');
    final initSel = ObjCBindings.sel('init');

    final toolbar = ObjCBindings.objc_msgSend(
      ObjCBindings.objc_msgSend(toolbarClass, allocSel),
      initSel,
    );

    final setToolbarSel = ObjCBindings.sel('setToolbar:');
    ObjCBindings.objc_msgSend_void_obj(_nsWindow, setToolbarSel, toolbar);
  }

  void _setWindowButtonsHidden(bool hidden) {
    final standardWindowButtonSel = ObjCBindings.sel('standardWindowButton:');
    final setHiddenSel = ObjCBindings.sel('setHidden:');

    // Hide/show close, minimize, zoom buttons
    for (var buttonType = 0; buttonType < 3; buttonType++) {
      final button = ObjCBindings.objc_msgSend_obj_int(
        _nsWindow,
        standardWindowButtonSel,
        buttonType,
      );

      if (button.address != 0) {
        ObjCBindings.objc_msgSend_void_bool(button, setHiddenSel, hidden);
      }
    }
  }

  // ==========================================================================
  // macOS-Specific Features
  // ==========================================================================

  /// Set the window's collection behavior
  Future<void> setCollectionBehavior(int behavior) async {
    _checkInitialized();

    final setCollectionBehaviorSel = ObjCBindings.sel('setCollectionBehavior:');
    ObjCBindings.objc_msgSend_void_int(
      _nsWindow,
      setCollectionBehaviorSel,
      behavior,
    );
  }

  /// Check if window is currently always on top
  Future<bool> isAlwaysOnTop() async {
    _checkInitialized();

    final levelSel = ObjCBindings.sel('level');
    final level = ObjCBindings.objc_msgSend_int(_nsWindow, levelSel);
    return level >= NSWindowLevel.floating;
  }

  /// Set whether the window can be moved by dragging its background
  Future<void> setMovableByWindowBackground({required bool movable}) async {
    _checkInitialized();

    final setMovableByWindowBackgroundSel = ObjCBindings.sel(
      'setMovableByWindowBackground:',
    );
    ObjCBindings.objc_msgSend_void_bool(
      _nsWindow,
      setMovableByWindowBackgroundSel,
      movable,
    );
  }

  /// Set whether the window has a shadow
  Future<void> setHasShadow({required bool hasShadow}) async {
    _checkInitialized();

    final setHasShadowSel = ObjCBindings.sel('setHasShadow:');
    ObjCBindings.objc_msgSend_void_bool(_nsWindow, setHasShadowSel, hasShadow);
  }

  /// Set vibrancy effect for the window
  Future<void> setVibrancy(
    NSVisualEffectMaterial material, {
    NSVisualEffectBlendingMode blendingMode =
        NSVisualEffectBlendingMode.behindWindow,
    NSVisualEffectState state = NSVisualEffectState.followsWindowActiveState,
  }) async {
    _checkInitialized();

    // Get the content view
    final contentViewSel = ObjCBindings.sel('contentView');
    final contentView = ObjCBindings.objc_msgSend(_nsWindow, contentViewSel);

    // Create NSVisualEffectView
    final nsVisualEffectViewClass = ObjCBindings.getClass('NSVisualEffectView');
    final allocSel = ObjCBindings.sel('alloc');
    final initSel = ObjCBindings.sel('init');

    final visualEffectView = ObjCBindings.objc_msgSend(
      ObjCBindings.objc_msgSend(nsVisualEffectViewClass, allocSel),
      initSel,
    );

    // Set material
    final setMaterialSel = ObjCBindings.sel('setMaterial:');
    ObjCBindings.objc_msgSend_void_int(
      visualEffectView,
      setMaterialSel,
      material.value,
    );

    // Set blending mode
    final setBlendingModeSel = ObjCBindings.sel('setBlendingMode:');
    ObjCBindings.objc_msgSend_void_int(
      visualEffectView,
      setBlendingModeSel,
      blendingMode.value,
    );

    // Set state
    final setStateSel = ObjCBindings.sel('setState:');
    ObjCBindings.objc_msgSend_void_int(
      visualEffectView,
      setStateSel,
      state.value,
    );

    // Get bounds of content view
    final boundsSel = ObjCBindings.sel('bounds');
    final contentViewBounds = ObjCBindings.objc_msgSend(contentView, boundsSel);

    // Set frame to match content view bounds
    final setFrameSel = ObjCBindings.sel('setFrame:');
    ObjCBindings.objc_msgSend_void_obj(
      visualEffectView,
      setFrameSel,
      contentViewBounds,
    );

    // Set autoresizing mask (NSViewWidthSizable | NSViewHeightSizable = 2 | 16 = 18)
    final setAutoresizingMaskSel = ObjCBindings.sel('setAutoresizingMask:');
    const autoresizingMask = 18;
    ObjCBindings.objc_msgSend_void_int(
      visualEffectView,
      setAutoresizingMaskSel,
      autoresizingMask,
    );

    // Add as subview at the bottom
    final addSubviewSel = ObjCBindings.sel('addSubview:positioned:relativeTo:');
    final objcLib = DynamicLibrary.process();
    final addSubviewPositionedRelativeTo = objcLib
        .lookupFunction<
          Void Function(
            ObjCObjectPointer,
            ObjCSelectorPointer,
            ObjCObjectPointer,
            Int64,
            ObjCObjectPointer,
          ),
          void Function(
            ObjCObjectPointer,
            ObjCSelectorPointer,
            ObjCObjectPointer,
            int,
            ObjCObjectPointer,
          )
        >('objc_msgSend');

    const positioned = -1; // NSWindowBelow
    addSubviewPositionedRelativeTo(
      contentView,
      addSubviewSel,
      visualEffectView,
      positioned,
      Pointer.fromAddress(0),
    );
  }
}
