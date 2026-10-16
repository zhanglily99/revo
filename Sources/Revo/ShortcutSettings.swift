import AppKit

/// Captures keystrokes only while this focused settings button is recording.
private final class ShortcutRecorder: NSButton {
    var recording = false
    var onKey: ((NSEvent) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
        if recording { onKey?(event) } else { super.keyDown(with: event) }
    }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard recording else { return super.performKeyEquivalent(with: event) }
        onKey?(event); return true
    }
}

final class ShortcutSettings: NSWindowController, NSWindowDelegate {
    private let shortcut: GlobalShortcut
    private let heading = NSTextField(labelWithString: "")
    private let descriptionLabel = NSTextField(wrappingLabelWithString: "")
    private let recorder = ShortcutRecorder(title: "", target: nil, action: nil)
    private let hint = NSTextField(wrappingLabelWithString: "")
    private let enabled = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let restore = NSButton(title: "", target: nil, action: nil)
    private let done = NSButton(title: "", target: nil, action: nil)
    private var status: L10n.Key?

    init(shortcut: GlobalShortcut) {
        self.shortcut = shortcut
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 390, height: 285),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        super.init(window: window)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.appearance = NSAppearance(named: .aqua)
        guard let content = window.contentView else { return }
        heading.font = .systemFont(ofSize: 20, weight: .semibold)
        heading.frame = CGRect(x: 26, y: 222, width: 338, height: 28)
        descriptionLabel.font = .systemFont(ofSize: 12)
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.frame = CGRect(x: 26, y: 185, width: 338, height: 32)
        recorder.frame = CGRect(x: 26, y: 128, width: 338, height: 44)
        recorder.bezelStyle = .regularSquare
        recorder.isBordered = false
        recorder.wantsLayer = true
        recorder.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        recorder.layer?.cornerRadius = 9
        recorder.layer?.borderWidth = 1
        recorder.focusRingType = .none
        recorder.font = .monospacedSystemFont(ofSize: 19, weight: .medium)
        recorder.target = self; recorder.action = #selector(record)
        recorder.onKey = { [weak self] in self?.capture($0) }
        hint.font = .systemFont(ofSize: 11)
        hint.frame = CGRect(x: 28, y: 87, width: 334, height: 34)
        enabled.frame = CGRect(x: 26, y: 59, width: 338, height: 22)
        enabled.target = self; enabled.action = #selector(toggleEnabled)
        restore.frame = CGRect(x: 22, y: 16, width: 142, height: 30)
        restore.bezelStyle = .rounded; restore.target = self; restore.action = #selector(reset)
        done.frame = CGRect(x: 275, y: 16, width: 93, height: 30)
        done.bezelStyle = .rounded; done.target = self; done.action = #selector(closeSettings)
        done.keyEquivalent = "\r"
        [heading, descriptionLabel, recorder, hint, enabled, restore, done].forEach { content.addSubview($0) }
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: L10n.didChange, object: nil)
        refresh()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
    deinit { NotificationCenter.default.removeObserver(self) }

    func present() {
        status = nil; refresh()
        if window?.isVisible != true { window?.center() }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    @objc private func refresh() {
        window?.title = L10n.text(.shortcutTitle)
        heading.stringValue = L10n.text(.shortcutTitle)
        descriptionLabel.stringValue = L10n.text(.shortcutDescription)
        recorder.title = recorder.recording ? L10n.text(.shortcutRecording) : shortcut.shortcut?.displayName ?? L10n.text(.shortcutNotSet)
        recorder.layer?.borderColor = (recorder.recording ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
        recorder.setAccessibilityLabel(L10n.text(.shortcutRecord))
        recorder.setAccessibilityHelp(L10n.text(recorder.recording ? .shortcutRecordingHelp : .shortcutHint))
        enabled.title = L10n.text(.shortcutEnable)
        enabled.state = shortcut.isEnabled ? .on : .off
        enabled.isEnabled = !recorder.recording && shortcut.shortcut != nil
        restore.title = L10n.text(.shortcutRestore)
        restore.isEnabled = !recorder.recording
        done.title = L10n.text(.done)
        let unavailable = shortcut.isEnabled && !shortcut.isRegistered && !recorder.recording
        let message = status ?? (recorder.recording ? .shortcutRecordingHelp : unavailable ? .shortcutConflict : .shortcutHint)
        hint.stringValue = L10n.text(message)
        hint.textColor = message == .shortcutConflict || message == .shortcutInvalid ? .systemOrange : .secondaryLabelColor
    }

    @objc private func record() {
        if recorder.recording { cancelRecording(); return }
        shortcut.suspend()
        status = nil; recorder.recording = true
        window?.makeFirstResponder(recorder)
        refresh()
    }

    private func capture(_ event: NSEvent) {
        guard recorder.recording, !event.isARepeat else { return }
        if event.keyCode == 53 { cancelRecording(); return }
        let flags = event.modifierFlags.intersection([.control, .option, .command, .shift])
        if (event.keyCode == 51 || event.keyCode == 117), flags.isEmpty {
            recorder.recording = false
            _ = shortcut.configure(nil, enabled: false)
            _ = shortcut.resume()
            status = nil; refresh(); return
        }
        guard let candidate = KeyboardShortcut(event: event) else { status = .shortcutInvalid; refresh(); return }
        // Resume first to restore the old registration, then replace it atomically.
        recorder.recording = false
        _ = shortcut.resume()
        status = shortcut.configure(candidate, enabled: true) ? nil : .shortcutConflict
        refresh()
    }

    private func cancelRecording() {
        guard recorder.recording else { return }
        recorder.recording = false
        status = shortcut.resume() ? nil : .shortcutConflict
        refresh()
    }
    @objc private func toggleEnabled() {
        status = shortcut.configure(shortcut.shortcut, enabled: enabled.state == .on) ? nil : .shortcutConflict
        refresh()
    }
    @objc private func reset() {
        status = shortcut.configure(.standard, enabled: true) ? nil : .shortcutConflict
        refresh()
    }
    @objc private func closeSettings() { window?.close() }
    func windowWillClose(_ notification: Notification) { cancelRecording() }
    func windowDidResignKey(_ notification: Notification) { cancelRecording() }
}
