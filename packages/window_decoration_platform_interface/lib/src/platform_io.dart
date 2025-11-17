import 'dart:io';

/// IO implementation for platform checks
/// This is used on desktop platforms where dart:io is available

bool get isMacOS => Platform.isMacOS;
bool get isWindows => Platform.isWindows;
bool get isLinux => Platform.isLinux;
String get operatingSystem => Platform.operatingSystem;
