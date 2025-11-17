import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:window_decoration_web/src/window_decoration_web.dart';

export 'src/window_decoration_web.dart';

/// Web plugin class for window_decoration
class WindowDecorationWebPlugin {
  /// Registers the web plugin
  static void registerWith(Registrar registrar) {
    WindowDecorationWeb.registerWith();
  }
}
