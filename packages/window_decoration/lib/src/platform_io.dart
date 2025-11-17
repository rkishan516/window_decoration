// ignore_for_file: invalid_use_of_internal_member

import 'dart:ffi';
import 'dart:io';

import 'package:flutter/src/widgets/_window.dart';
import 'package:window_decoration_linux/src/window_decoration_linux.dart';
import 'package:window_decoration_macos/src/window_decoration_macos.dart';
import 'package:window_decoration_platform_interface/window_decoration_platform_interface.dart';
import 'package:window_decoration_windows/src/window_decoration_windows.dart';

/// Desktop platform implementation helper

export 'package:window_decoration_linux/src/window_decoration_linux.dart';
export 'package:window_decoration_macos/src/window_decoration_macos.dart';
export 'package:window_decoration_windows/src/window_decoration_windows.dart';

WindowDecorationPlatform createPlatform(RegularWindowController controller) {
  if (Platform.isMacOS) {
    final handle = (controller as dynamic).getWindowHandle() as Pointer<Void>;
    return WindowDecorationMacOS()..initialize(handle);
  } else if (Platform.isWindows) {
    final handle = (controller as dynamic).getWindowHandle() as Pointer<Void>;
    return WindowDecorationWindows()..initialize(handle);
  } else if (Platform.isLinux) {
    final handle = (controller as dynamic).getWindowHandle() as Pointer<Void>;
    return WindowDecorationLinux()..initialize(handle);
  } else {
    throw UnsupportedError(
      'Platform ${Platform.operatingSystem} is not supported. '
      'Only macOS, Windows, Linux, and Web are supported.',
    );
  }
}

String getPlatformName() => Platform.operatingSystem;
