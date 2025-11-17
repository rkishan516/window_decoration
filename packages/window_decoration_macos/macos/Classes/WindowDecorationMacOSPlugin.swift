import Cocoa
import FlutterMacOS

/// Minimal plugin registration for window_decoration_macos
/// The actual implementation uses Dart FFI, so this is just for Flutter plugin registration
public class WindowDecorationMacOSPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op: All functionality is implemented via Dart FFI
    // This class exists only to satisfy Flutter's plugin registration requirements
  }
}
