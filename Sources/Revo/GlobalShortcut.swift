import AppKit
import Carbon

struct KeyboardShortcut: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    static let standard = KeyboardShortcut(keyCode: UInt32(kVK_ANSI_R), modifiers: UInt32(controlKey | optionKey))

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var modifiers: UInt32 = 0
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        self.init(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        guard isValid else { return nil }
    }

    var isValid: Bool {
        let allowed = UInt32(controlKey | optionKey | shiftKey | cmdKey)
        return keyCode <= 127 && !(54...63).contains(keyCode) && modifiers & ~allowed == 0 &&
            modifiers & UInt32(controlKey | optionKey | cmdKey) != 0
    }

    var displayName: String {
        var value = ""
        if modifiers & UInt32(controlKey) != 0 { value += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { value += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { value += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { value += "⌘" }
        let special: [UInt32: String] = [36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "Esc", 76: "⌤",
            115: "↖", 117: "⌦", 119: "↘", 116: "⇞", 121: "⇟", 123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
            101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
            106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20"]
        if let label = special[keyCode] { return value + label }
        let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        if let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) {
            let data = unsafeBitCast(pointer, to: CFData.self)
            let layout = UnsafeRawPointer(CFDataGetBytePtr(data)).assumingMemoryBound(to: UCKeyboardLayout.self)
            var deadKey: UInt32 = 0
            var length = 0
            var characters = [UniChar](repeating: 0, count: 8)
            let status = UCKeyTranslate(layout, UInt16(keyCode), UInt16(kUCKeyActionDisplay), 0,
                UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysMask), &deadKey,
                characters.count, &length, &characters)
            if status == noErr, length > 0 {
                return value + String(utf16CodeUnits: characters, count: length).uppercased()
            }
        }
        return value + "[\(keyCode)]"
    }
}

/// Registers only the chosen combination, without keyboard monitoring or accessibility permission.
final class GlobalShortcut {
    private struct Configuration: Codable {
        var shortcut: KeyboardShortcut?
        var enabled: Bool
    }
    private let defaults: UserDefaults
    private let preferenceKey = "globalShortcutV1"
    private var configuration: Configuration
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var identifier: UInt32 = 0
    private var held = false
    private var suspended = false
    private static let signature: OSType = 0x5245564F
    var onTrigger: (() -> Void)?
    var shortcut: KeyboardShortcut? { configuration.shortcut }
    var isEnabled: Bool { configuration.enabled }
    var isRegistered: Bool { hotKey != nil }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: preferenceKey),
           let saved = try? JSONDecoder().decode(Configuration.self, from: data),
           saved.shortcut == nil || saved.shortcut?.isValid == true {
            configuration = saved
        } else {
            configuration = Configuration(shortcut: .standard, enabled: true)
        }
        var events = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
                      EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))]
        InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<GlobalShortcut>.fromOpaque(context).takeUnretainedValue()
            var key = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &key)
            guard status == noErr, key.signature == GlobalShortcut.signature,
                  key.id == owner.identifier, owner.hotKey != nil else { return OSStatus(eventNotHandledErr) }
            if GetEventKind(event) == UInt32(kEventHotKeyReleased) { owner.held = false }
            else if !owner.held {
                owner.held = true
                owner.onTrigger?()
            }
            return noErr
        }, events.count, &events, Unmanaged.passUnretained(self).toOpaque(), &handler)
        _ = resume()
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }

    /// Register a candidate before removing the active binding, so conflicts preserve it.
    @discardableResult
    func configure(_ candidate: KeyboardShortcut?, enabled: Bool) -> Bool {
        guard candidate == nil || candidate?.isValid == true else { return false }
        if enabled, let candidate, !suspended {
            if candidate == shortcut, isEnabled, isRegistered { return true }
            guard handler != nil else { return false }
            var registration: EventHotKeyRef?
            let next = identifier &+ 1
            let status = RegisterEventHotKey(candidate.keyCode, candidate.modifiers,
                EventHotKeyID(signature: Self.signature, id: next), GetApplicationEventTarget(), 0, &registration)
            guard status == noErr, let registration else { return false }
            if let hotKey { UnregisterEventHotKey(hotKey) }
            hotKey = registration; identifier = next
        } else {
            unregister()
        }
        held = false
        configuration = Configuration(shortcut: candidate, enabled: enabled && candidate != nil)
        if let data = try? JSONEncoder().encode(configuration) { defaults.set(data, forKey: preferenceKey) }
        return true
    }

    func suspend() { suspended = true; unregister() }

    @discardableResult
    func resume() -> Bool {
        suspended = false
        guard configuration.enabled, let shortcut else { return true }
        return configure(shortcut, enabled: true)
    }

    private func unregister() {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        hotKey = nil; held = false
    }
}
