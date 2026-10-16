import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }
}

/// Explicit in-app language selection; first launch always uses English.
enum L10n {
    static let didChange = Notification.Name("RevoLanguageDidChange")
    private static let preferenceKey = "appLanguage"

    static var language: AppLanguage {
        get { AppLanguage(rawValue: UserDefaults.standard.string(forKey: preferenceKey) ?? "") ?? .english }
        set {
            guard language != newValue else { return }
            UserDefaults.standard.set(newValue.rawValue, forKey: preferenceKey)
            NotificationCenter.default.post(name: didChange, object: nil)
        }
    }

    enum Key: String, CaseIterable {
        case showRevo = "Show Revo"
        case bodyHelp = "Turn on the power switch before dropping files. Revo starts off each time it opens. Right-click for undo and settings."
        case offHelp = "Revo is off. Turn on the switch to accept files."
        case onHelp = "Drop a file to move it to Trash. Right-click to undo."
        case power = "Revo power"
        case powerCount = "Revo power · Files recycled today: %ld"
        case powerHelp = "Off rejects file drops. On allows files to move to Trash. Files recycled today: %ld."
        case turnOnBeforeDrop = "Turn on before dropping files."
        case releaseToTrash = "Release to move to Trash · %ld items"
        case demoFeed = "Try a sheet. Let it go."
        case movingToTrash = "Moving to Trash…"
        case recycleFailed = "Could not move to Trash"
        case demoFinished = "Demo only. No files moved."
        case recycleFinished = "Moved to Trash · Right-click to undo"
        case turnOn = "Turn On"
        case turnOff = "Turn Off"
        case recycledToday = "Recycled today: %ld"
        case undo = "Undo Last File"
        case openTrash = "Open Trash"
        case tryIt = "Try It"
        case demoDocument = "Document · Paper Strips"
        case demoPhoto = "Photo · Confetti"
        case demoAudio = "Audio · Waveform"
        case demoVideo = "Video · Film Strips"
        case demoFolder = "Folder · Stacked Sheets"
        case clearScraps = "Clear Paper Scraps"
        case sound = "Sound"
        case language = "Language"
        case hide = "Hide Revo"
        case quit = "Quit Revo"
        case scrapsCleared = "Paper scraps cleared."
        case restoring = "Restoring the last file…"
        case restored = "Restored to its original location."
        case restoreFailed = "Could not restore · Open Trash"
        case missingTrashLocation = "macOS did not return the location of the recycled file."
    }

    private static let simplifiedChinese: [Key: String] = [
        .showRevo: "显示 Revo",
        .bodyHelp: "请先打开开关，再拖入文件。Revo 每次启动时默认关闭。右键可撤销操作或更改设置。",
        .offHelp: "Revo 已关闭，请打开开关后拖入文件。",
        .onHelp: "拖入文件以移至废纸篓，右键可撤销。",
        .power: "Revo 电源",
        .powerCount: "Revo 电源 · 今日已处理：%ld 个文件",
        .powerHelp: "关闭时不接收文件，开启后可将文件移至废纸篓。今日已处理：%ld 个文件。",
        .turnOnBeforeDrop: "请先打开开关，再拖入文件。",
        .releaseToTrash: "松手移至废纸篓 · %ld 个项目",
        .demoFeed: "放入一张纸，轻轻放下。",
        .movingToTrash: "正在移至废纸篓…",
        .recycleFailed: "无法移至废纸篓",
        .demoFinished: "仅为演示，未移动任何文件。",
        .recycleFinished: "已移至废纸篓 · 右键可撤销",
        .turnOn: "开启",
        .turnOff: "关闭",
        .recycledToday: "今日已处理：%ld 个文件",
        .undo: "撤销上一个文件",
        .openTrash: "打开废纸篓",
        .tryIt: "试一试",
        .demoDocument: "文档 · 纸条",
        .demoPhoto: "照片 · 纸屑",
        .demoAudio: "音频 · 波形",
        .demoVideo: "视频 · 胶片",
        .demoFolder: "文件夹 · 叠纸",
        .clearScraps: "清空纸屑",
        .sound: "声音",
        .language: "语言",
        .hide: "隐藏 Revo",
        .quit: "退出 Revo",
        .scrapsCleared: "纸屑已清空。",
        .restoring: "正在恢复上一个文件…",
        .restored: "已恢复到原来的位置。",
        .restoreFailed: "无法恢复 · 请打开废纸篓",
        .missingTrashLocation: "macOS 未返回文件在废纸篓中的位置。"
    ]

    static func text(_ key: Key, _ arguments: CVarArg...) -> String {
        text(key, arguments: arguments)
    }

    static func text(_ key: Key, arguments: [CVarArg]) -> String {
        let format = language == .simplifiedChinese ? simplifiedChinese[key] ?? key.rawValue : key.rawValue
        return arguments.isEmpty ? format : String(format: format, arguments: arguments)
    }
}
