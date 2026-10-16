import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var panel: RevoPanel?
    private var statusItem: NSStatusItem?
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let index = CommandLine.arguments.firstIndex(of: "--export-icon"), CommandLine.arguments.count > index + 1 {
            Preview.exportIcon(path: CommandLine.arguments[index + 1]); NSApp.terminate(nil); return
        }
        if CommandLine.arguments.contains("--self-test") { SelfTest.run(); return }
        let panel = RevoPanel(); panel.placeAtDefaultCorner(); self.panel = panel
        panel.orderFrontRegardless()
        if let index = CommandLine.arguments.firstIndex(of: "--preview"), CommandLine.arguments.count > index + 1 {
            Preview.export(panel: panel, directory: CommandLine.arguments[index + 1]); return
        }
        let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName: "shredder", accessibilityDescription: "Revo") ?? NSImage(systemSymbolName: "trash", accessibilityDescription: "Revo")
        status.button?.toolTip = "Revo"
        let menu = NSMenu(); menu.delegate = self; status.menu = menu; statusItem = status
    }
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let show = NSMenuItem(title: L10n.text(.showRevo), action: #selector(showPanel), keyEquivalent: ""); show.target = self; menu.addItem(show)
        if let view = panel?.contentView as? RevoView {
            let items = view.makeMenu().items
            for item in items { item.menu?.removeItem(item); menu.addItem(item) }
        }
    }
    @objc private func showPanel() { panel?.placeAtDefaultCorner(); panel?.orderFrontRegardless() }
    func applicationWillTerminate(_ notification: Notification) { panel?.savePosition() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
