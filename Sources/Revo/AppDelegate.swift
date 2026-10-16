import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var panel: RevoPanel?
    private var statusItem: NSStatusItem?
    private let statusMenu = NSMenu()
    private var globalShortcut: GlobalShortcut?
    private var shortcutSettings: ShortcutSettings?
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
        let shortcut = GlobalShortcut()
        shortcut.onTrigger = { [weak self] in self?.togglePanel() }
        globalShortcut = shortcut
        // AppKit otherwise appends new items beyond the visible area on crowded, notched displays.
        // Seed only the initial position so subsequent user rearrangements remain intact.
        let positionKey = "NSStatusItem Preferred Position RevoMenuBar"
        if UserDefaults.standard.object(forKey: positionKey) == nil {
            UserDefaults.standard.set(280.0, forKey: positionKey)
        }
        let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.autosaveName = "RevoMenuBar"
        status.behavior = []
        status.isVisible = true
        status.button?.image = MenuBarIcon.image()
        status.button?.target = self
        status.button?.action = #selector(menuBarClicked(_:))
        status.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        status.button?.setAccessibilityLabel("Revo")
        statusMenu.delegate = self
        statusItem = status
        NotificationCenter.default.addObserver(self, selector: #selector(updateMenuBarText), name: L10n.didChange, object: nil)
        updateMenuBarText()
    }
    @objc private func updateMenuBarText() {
        statusItem?.button?.toolTip = L10n.text(.menuBarHelp)
        statusItem?.button?.setAccessibilityHelp(L10n.text(.menuBarHelp))
    }
    @objc private func menuBarClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            statusMenu.update()
            statusMenu.popUp(positioning: nil, at: CGPoint(x: 0, y: sender.bounds.minY - 4), in: sender)
        } else {
            showPanel()
        }
    }
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let show = NSMenuItem(title: L10n.text(.showRevo), action: #selector(showPanel), keyEquivalent: ""); show.target = self; menu.addItem(show)
        if let view = panel?.contentView as? RevoView {
            let items = view.makeMenu().items
            for item in items { item.menu?.removeItem(item); menu.addItem(item) }
        }
        RevoView.fitMenu(menu)
    }
    private func togglePanel() {
        guard let panel else { return }
        if panel.isVisible { panel.orderOut(nil) } else { showPanel() }
    }
    @objc func showShortcutSettings() {
        guard let globalShortcut else { return }
        if shortcutSettings == nil { shortcutSettings = ShortcutSettings(shortcut: globalShortcut) }
        shortcutSettings?.present()
    }
    @objc private func showPanel() { panel?.placeAtDefaultCorner(); panel?.orderFrontRegardless() }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel()
        return true
    }
    func applicationWillTerminate(_ notification: Notification) {
        panel?.savePosition()
        NotificationCenter.default.removeObserver(self)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
