import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private static var retainedDelegate: AppDelegate?
  private var strongWindow: MainFlutterWindow?

  static func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    retainedDelegate = delegate
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    setupFallbackMainMenuIfNeeded()

    if self.strongWindow == nil {
      let window = MainFlutterWindow(
        contentRect: NSRect(x: 120, y: 120, width: 1380, height: 840),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
      )
      // Mandatory under Swift ARC for programmatically created NSWindows:
      // NSWindow defaults isReleasedWhenClosed = true for legacy MRR, which causes a double-release crash in objc_release.
      window.isReleasedWhenClosed = false
      window.configureFlutterWindow()
      self.strongWindow = window
      self.mainFlutterWindow = window
      window.makeKeyAndOrderFront(nil)
      window.orderFrontRegardless()
      NSApp.activate(ignoringOtherApps: true)
    }
    super.applicationDidFinishLaunching(notification)
  }

  private func setupFallbackMainMenuIfNeeded() {
    guard NSApp.mainMenu == nil else { return }
    let mainMenu = NSMenu()
    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)

    let appMenu = NSMenu()
    appMenu.addItem(
      withTitle: "Quit FerroPane",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    appMenuItem.submenu = appMenu
    NSApp.mainMenu = mainMenu
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
