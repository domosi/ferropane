import Cocoa
import FlutterMacOS
import Quartz
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
  private var previewURL: URL?
  private var isConfigured = false

  override func awakeFromNib() {
    configureFlutterWindow()
    super.awakeFromNib()
  }

  func configureFlutterWindow() {
    guard !isConfigured else { return }
    isConfigured = true

    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.minSize = NSSize(width: 960, height: 580)
    self.setFrame(NSRect(x: 120, y: 120, width: 1380, height: 840), display: true)
    self.center()
    self.title = "FerroPane"

    let channel = FlutterMethodChannel(
      name: "com.domosi.ferropane/native",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(false)
        return
      }
      let args = call.arguments as? [String: Any]
      let path = args?["path"] as? String ?? ""

      switch call.method {
      case "openFile":
        let url = URL(fileURLWithPath: path)
        let ok = NSWorkspace.shared.open(url)
        result(ok)

      case "getOpenWithApps":
        let fileUrl = URL(fileURLWithPath: path)
        let defaultAppUrl = NSWorkspace.shared.urlForApplication(toOpen: fileUrl)?.standardizedFileURL
        var appUrls = NSWorkspace.shared.urlsForApplications(toOpen: fileUrl)

        // Ensure common editors are available for text/dotfiles even if LaunchServices doesn't list them
        let fallbackPaths = [
          "/Applications/Cursor.app",
          "/Applications/Visual Studio Code.app",
          "/Applications/Zed.app",
          "/Applications/Sublime Text.app",
          "/System/Applications/TextEdit.app"
        ]
        for fp in fallbackPaths where FileManager.default.fileExists(atPath: fp) {
          let u = URL(fileURLWithPath: fp)
          if !appUrls.contains(where: { $0.standardizedFileURL == u.standardizedFileURL }) {
            appUrls.append(u)
          }
        }

        var items: [[String: Any]] = []
        var seen = Set<String>()
        for u in appUrls {
          let stdPath = u.standardizedFileURL.path
          if seen.contains(stdPath) { continue }
          seen.insert(stdPath)
          let name = FileManager.default.displayName(atPath: stdPath)
            .replacingOccurrences(of: ".app", with: "")
          let isDef = (defaultAppUrl != nil && u.standardizedFileURL == defaultAppUrl!)
          items.append([
            "name": name,
            "path": stdPath,
            "isDefault": isDef
          ])
        }

        items.sort { a, b in
          let aDef = a["isDefault"] as? Bool ?? false
          let bDef = b["isDefault"] as? Bool ?? false
          if aDef != bDef { return aDef }
          let aName = a["name"] as? String ?? ""
          let bName = b["name"] as? String ?? ""
          return aName.localizedCaseInsensitiveCompare(bName) == .orderedAscending
        }
        result(items)

      case "openFileWithApp":
        let appPath = args?["appPath"] as? String ?? ""
        let fileUrl = URL(fileURLWithPath: path)
        let appUrl = URL(fileURLWithPath: appPath)
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open(
          [fileUrl],
          withApplicationAt: appUrl,
          configuration: config
        ) { _, err in
          DispatchQueue.main.async {
            result(err == nil)
          }
        }

      case "pickOtherAppAndOpen":
        let fileUrl = URL(fileURLWithPath: path)
        let panel = NSOpenPanel()
        panel.title = "Choose Application to Open \(fileUrl.lastPathComponent)"
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.applicationBundle]
        if panel.runModal() == .OK, let chosenAppUrl = panel.url {
          let config = NSWorkspace.OpenConfiguration()
          NSWorkspace.shared.open(
            [fileUrl],
            withApplicationAt: chosenAppUrl,
            configuration: config,
            completionHandler: nil
          )
          result(chosenAppUrl.path)
        } else {
          result(nil)
        }

      case "revealInFinder":
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
        result(true)

      case "openTerminal":
        let dirUrl = URL(fileURLWithPath: path)
        if let terminalUrl = NSWorkspace.shared.urlForApplication(
          withBundleIdentifier: "com.apple.Terminal"
        ) {
          let config = NSWorkspace.OpenConfiguration()
          NSWorkspace.shared.open(
            [dirUrl],
            withApplicationAt: terminalUrl,
            configuration: config,
            completionHandler: nil
          )
          result(true)
        } else {
          result(false)
        }

      case "quickLook":
        self.previewURL = URL(fileURLWithPath: path)
        if let panel = QLPreviewPanel.shared() {
          if QLPreviewPanel.sharedPreviewPanelExists() && panel.isVisible {
            panel.reloadData()
            panel.orderOut(nil)
          } else {
            panel.dataSource = self
            panel.delegate = self
            panel.makeKeyAndOrderFront(nil)
            panel.reloadData()
          }
        }
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
  }

  override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
    return true
  }

  override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
    panel.dataSource = self
    panel.delegate = self
  }

  override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
    panel.dataSource = nil
    panel.delegate = nil
  }

  func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
    return previewURL != nil ? 1 : 0
  }

  func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
    return previewURL as NSURL?
  }
}
