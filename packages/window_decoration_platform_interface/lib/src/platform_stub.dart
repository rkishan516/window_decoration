/// Stub implementation for platform checks
/// This is used on web where dart:io is not available

bool get isMacOS => false;
bool get isWindows => false;
bool get isLinux => false;
String get operatingSystem => 'web';
