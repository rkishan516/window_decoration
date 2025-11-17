import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  var engine: FlutterEngine?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    engine = FlutterEngine(name: "main", project: nil)
    engine?.run(withEntrypoint: nil)
    RegisterGeneratedPlugins(registry: engine!)
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
