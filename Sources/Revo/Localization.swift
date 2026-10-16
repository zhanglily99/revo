import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case japanese = "ja"
    case korean = "ko"
    case russian = "ru"
    case french = "fr"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .russian: return "Русский"
        case .french: return "Français"
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
        case shortcutTitle = "Global Shortcut"
        case shortcutDescription = "Show or hide Revo from any app. Power stays as you left it."
        case shortcutRecord = "Record a global shortcut"
        case shortcutRecording = "Press shortcut…"
        case shortcutNotSet = "Not Set"
        case shortcutHint = "Click the shortcut above to change it."
        case shortcutRecordingHelp = "Use ⌘, ⌥, or ⌃ with a key. Esc cancels; Delete clears."
        case shortcutInvalid = "Include Command, Option, or Control with your key."
        case shortcutConflict = "This shortcut is unavailable. Your previous setting is kept."
        case shortcutEnable = "Enable global shortcut"
        case shortcutRestore = "Restore Default"
        case done = "Done"
        case menuBarHelp = "Click to show Revo. Right-click for settings."
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
        .shortcutTitle: "全局快捷键",
        .shortcutDescription: "在任何应用中显示或隐藏 Revo，电源状态保持不变。",
        .shortcutRecord: "录入全局快捷键",
        .shortcutRecording: "请按下快捷键…",
        .shortcutNotSet: "未设置",
        .shortcutHint: "点击上方的快捷键，即可更改。",
        .shortcutRecordingHelp: "使用 ⌘、⌥ 或 ⌃ 加一个按键。Esc 取消，Delete 清除。",
        .shortcutInvalid: "请同时按下 Command、Option 或 Control。",
        .shortcutConflict: "此快捷键不可用，已保留原来的设置。",
        .shortcutEnable: "启用全局快捷键",
        .shortcutRestore: "恢复默认",
        .done: "完成",
        .menuBarHelp: "点击显示 Revo，右键打开设置。",
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

    private static let japanese: [Key: String] = [
        .shortcutTitle: "グローバルショートカット",
        .shortcutDescription: "どのアプリからでも Revo を表示・非表示にできます。電源の状態は変わりません。",
        .shortcutRecord: "グローバルショートカットを設定",
        .shortcutRecording: "キーを押してください…",
        .shortcutNotSet: "未設定",
        .shortcutHint: "上のショートカットをクリックして変更します。",
        .shortcutRecordingHelp: "⌘・⌥・⌃ とキーを組み合わせます。Esc で取消、Delete で消去。",
        .shortcutInvalid: "Command・Option・Control のいずれかを組み合わせてください。",
        .shortcutConflict: "この組み合わせは使えません。以前の設定を保持しました。",
        .shortcutEnable: "グローバルショートカットを有効にする",
        .shortcutRestore: "初期設定に戻す",
        .done: "完了",
        .menuBarHelp: "クリックで Revo を表示、右クリックで設定を開きます。",
        .showRevo: "Revo を表示",
        .bodyHelp: "電源を入れてからファイルをドロップしてください。起動時は電源が切れています。右クリックで取り消しや設定ができます。",
        .offHelp: "Revo の電源は切れています。電源を入れるとファイルを受け付けます。",
        .onHelp: "ファイルをドロップするとゴミ箱に移動します。右クリックで取り消せます。",
        .power: "Revo の電源",
        .powerCount: "Revo の電源 · 今日の処理数：%ld",
        .powerHelp: "電源が切れている間はファイルを受け付けません。電源を入れるとゴミ箱に移動できます。今日の処理数：%ld。",
        .turnOnBeforeDrop: "電源を入れてからドロップしてください。",
        .releaseToTrash: "離すとゴミ箱へ · %ld 項目",
        .demoFeed: "紙を一枚、そっと入れてみましょう。",
        .movingToTrash: "ゴミ箱に移動中…",
        .recycleFailed: "ゴミ箱に移動できませんでした",
        .demoFinished: "デモのみ。ファイルは移動していません。",
        .recycleFinished: "ゴミ箱に移動しました · 右クリックで取消",
        .turnOn: "電源を入れる",
        .turnOff: "電源を切る",
        .recycledToday: "今日の処理数：%ld",
        .undo: "最後のファイルを元に戻す",
        .openTrash: "ゴミ箱を開く",
        .tryIt: "試してみる",
        .demoDocument: "書類 · 紙の細片",
        .demoPhoto: "写真 · 紙吹雪",
        .demoAudio: "音声 · 波形",
        .demoVideo: "動画 · フィルム",
        .demoFolder: "フォルダ · 重ねた紙",
        .clearScraps: "紙片を片付ける",
        .sound: "サウンド",
        .language: "言語",
        .hide: "Revo を隠す",
        .quit: "Revo を終了",
        .scrapsCleared: "紙片を片付けました。",
        .restoring: "最後のファイルを復元中…",
        .restored: "元の場所に戻しました。",
        .restoreFailed: "復元できませんでした · ゴミ箱を開いてください",
        .missingTrashLocation: "macOS からゴミ箱内のファイルの場所を取得できませんでした。"
    ]

    private static let korean: [Key: String] = [
        .shortcutTitle: "전역 단축키",
        .shortcutDescription: "어떤 앱에서든 Revo를 표시하거나 숨깁니다. 전원 상태는 유지됩니다.",
        .shortcutRecord: "전역 단축키 지정",
        .shortcutRecording: "단축키를 누르세요…",
        .shortcutNotSet: "설정 안 됨",
        .shortcutHint: "위의 단축키를 클릭하여 변경하세요.",
        .shortcutRecordingHelp: "⌘, ⌥ 또는 ⌃와 키를 함께 누르세요. Esc: 취소, Delete: 지우기.",
        .shortcutInvalid: "Command, Option 또는 Control과 함께 누르세요.",
        .shortcutConflict: "사용할 수 없는 조합입니다. 기존 설정을 유지했습니다.",
        .shortcutEnable: "전역 단축키 사용",
        .shortcutRestore: "기본값 복원",
        .done: "완료",
        .menuBarHelp: "클릭하면 Revo가 표시되고, 오른쪽 클릭하면 설정이 열립니다.",
        .showRevo: "Revo 표시",
        .bodyHelp: "전원을 켠 후 파일을 놓으세요. Revo는 시작할 때 전원이 꺼져 있습니다. 오른쪽 클릭으로 실행을 취소하거나 설정을 변경할 수 있습니다.",
        .offHelp: "Revo가 꺼져 있습니다. 전원을 켜면 파일을 받습니다.",
        .onHelp: "파일을 놓으면 휴지통으로 이동합니다. 오른쪽 클릭으로 취소할 수 있습니다.",
        .power: "Revo 전원",
        .powerCount: "Revo 전원 · 오늘 처리: %ld개",
        .powerHelp: "꺼져 있을 때는 파일을 받지 않습니다. 켜면 휴지통으로 이동할 수 있습니다. 오늘 처리: %ld개.",
        .turnOnBeforeDrop: "전원을 켠 후 파일을 놓으세요.",
        .releaseToTrash: "놓으면 휴지통으로 이동 · %ld개",
        .demoFeed: "종이 한 장을 살며시 넣어 보세요.",
        .movingToTrash: "휴지통으로 이동 중…",
        .recycleFailed: "휴지통으로 이동할 수 없습니다",
        .demoFinished: "데모입니다. 파일은 이동하지 않았습니다.",
        .recycleFinished: "휴지통으로 이동됨 · 오른쪽 클릭으로 취소",
        .turnOn: "전원 켜기",
        .turnOff: "전원 끄기",
        .recycledToday: "오늘 처리: %ld개",
        .undo: "마지막 파일 복원",
        .openTrash: "휴지통 열기",
        .tryIt: "체험하기",
        .demoDocument: "문서 · 종이 조각",
        .demoPhoto: "사진 · 색종이",
        .demoAudio: "오디오 · 파형",
        .demoVideo: "동영상 · 필름",
        .demoFolder: "폴더 · 겹친 종이",
        .clearScraps: "종이 조각 비우기",
        .sound: "소리",
        .language: "언어",
        .hide: "Revo 숨기기",
        .quit: "Revo 종료",
        .scrapsCleared: "종이 조각을 비웠습니다.",
        .restoring: "마지막 파일 복원 중…",
        .restored: "원래 위치로 복원했습니다.",
        .restoreFailed: "복원할 수 없음 · 휴지통을 여세요",
        .missingTrashLocation: "macOS가 휴지통에 있는 파일의 위치를 반환하지 않았습니다."
    ]

    private static let russian: [Key: String] = [
        .shortcutTitle: "Глобальное сочетание клавиш",
        .shortcutDescription: "Показывайте и скрывайте Revo из любого приложения. Состояние питания сохраняется.",
        .shortcutRecord: "Задать глобальное сочетание",
        .shortcutRecording: "Нажмите сочетание…",
        .shortcutNotSet: "Не задано",
        .shortcutHint: "Нажмите на сочетание выше, чтобы изменить его.",
        .shortcutRecordingHelp: "⌘, ⌥ или ⌃ + клавиша. Esc — отмена; Delete — очистить.",
        .shortcutInvalid: "Добавьте Command, Option или Control.",
        .shortcutConflict: "Сочетание недоступно. Прежняя настройка сохранена.",
        .shortcutEnable: "Включить глобальное сочетание",
        .shortcutRestore: "По умолчанию",
        .done: "Готово",
        .menuBarHelp: "Щелчок показывает Revo. Правый щелчок открывает настройки.",
        .showRevo: "Показать Revo",
        .bodyHelp: "Включите питание, прежде чем перетаскивать файлы. При запуске Revo питание выключено. Правый щелчок открывает отмену и настройки.",
        .offHelp: "Revo выключен. Включите питание, чтобы добавлять файлы.",
        .onHelp: "Перетащите файл в Корзину. Для отмены нажмите правой кнопкой.",
        .power: "Питание Revo",
        .powerCount: "Питание Revo · Сегодня обработано: %ld",
        .powerHelp: "При выключенном питании файлы не принимаются. Включите питание для перемещения в Корзину. Сегодня обработано: %ld.",
        .turnOnBeforeDrop: "Сначала включите питание.",
        .releaseToTrash: "Отпустите — в Корзину · %ld",
        .demoFeed: "Аккуратно вставьте лист бумаги.",
        .movingToTrash: "Перемещение в Корзину…",
        .recycleFailed: "Не удалось переместить в Корзину",
        .demoFinished: "Демо. Файлы не перемещались.",
        .recycleFinished: "В Корзине · правый щелчок для отмены",
        .turnOn: "Включить",
        .turnOff: "Выключить",
        .recycledToday: "Сегодня обработано: %ld",
        .undo: "Вернуть последний файл",
        .openTrash: "Открыть Корзину",
        .tryIt: "Попробовать",
        .demoDocument: "Документ · Полоски бумаги",
        .demoPhoto: "Фото · Конфетти",
        .demoAudio: "Аудио · Звуковая волна",
        .demoVideo: "Видео · Киноплёнка",
        .demoFolder: "Папка · Стопка листов",
        .clearScraps: "Убрать обрезки бумаги",
        .sound: "Звук",
        .language: "Язык",
        .hide: "Скрыть Revo",
        .quit: "Завершить Revo",
        .scrapsCleared: "Обрезки бумаги убраны.",
        .restoring: "Восстановление последнего файла…",
        .restored: "Файл возвращён на место.",
        .restoreFailed: "Не удалось вернуть · откройте Корзину",
        .missingTrashLocation: "macOS не вернула расположение файла в Корзине."
    ]

    private static let french: [Key: String] = [
        .shortcutTitle: "Raccourci global",
        .shortcutDescription: "Affichez ou masquez Revo depuis toute app. Son état de marche est conservé.",
        .shortcutRecord: "Définir un raccourci global",
        .shortcutRecording: "Appuyez sur les touches…",
        .shortcutNotSet: "Non défini",
        .shortcutHint: "Cliquez sur le raccourci ci-dessus pour le modifier.",
        .shortcutRecordingHelp: "⌘, ⌥ ou ⌃ + une touche. Échap annule ; Suppr efface.",
        .shortcutInvalid: "Ajoutez Commande, Option ou Contrôle.",
        .shortcutConflict: "Raccourci indisponible. Le réglage précédent est conservé.",
        .shortcutEnable: "Activer le raccourci global",
        .shortcutRestore: "Par défaut",
        .done: "Terminé",
        .menuBarHelp: "Cliquez pour afficher Revo. Clic droit pour les réglages.",
        .showRevo: "Afficher Revo",
        .bodyHelp: "Allumez Revo avant de déposer des fichiers. Revo démarre toujours éteint. Le clic droit donne accès aux réglages et à l’annulation.",
        .offHelp: "Revo est éteint. Allumez-le pour recevoir des fichiers.",
        .onHelp: "Déposez un fichier pour le mettre à la Corbeille. Clic droit pour annuler.",
        .power: "Alimentation de Revo",
        .powerCount: "Revo · Fichiers traités aujourd’hui : %ld",
        .powerHelp: "Revo éteint refuse les fichiers. Allumez-le pour les mettre à la Corbeille. Fichiers traités aujourd’hui : %ld.",
        .turnOnBeforeDrop: "Allumez Revo avant de déposer un fichier.",
        .releaseToTrash: "Relâchez vers la Corbeille · %ld éléments",
        .demoFeed: "Glissez une feuille, tout doucement.",
        .movingToTrash: "Mise à la Corbeille…",
        .recycleFailed: "Impossible de mettre à la Corbeille",
        .demoFinished: "Démo uniquement. Aucun fichier déplacé.",
        .recycleFinished: "Dans la Corbeille · clic droit pour annuler",
        .turnOn: "Allumer",
        .turnOff: "Éteindre",
        .recycledToday: "Traités aujourd’hui : %ld",
        .undo: "Restaurer le dernier fichier",
        .openTrash: "Ouvrir la Corbeille",
        .tryIt: "Essayer",
        .demoDocument: "Document · Bandelettes",
        .demoPhoto: "Photo · Confettis",
        .demoAudio: "Audio · Forme d’onde",
        .demoVideo: "Vidéo · Pellicule",
        .demoFolder: "Dossier · Pile de feuilles",
        .clearScraps: "Retirer les morceaux de papier",
        .sound: "Son",
        .language: "Langue",
        .hide: "Masquer Revo",
        .quit: "Quitter Revo",
        .scrapsCleared: "Morceaux de papier retirés.",
        .restoring: "Restauration du dernier fichier…",
        .restored: "Fichier restauré à son emplacement.",
        .restoreFailed: "Restauration impossible · voir la Corbeille",
        .missingTrashLocation: "macOS n’a pas renvoyé l’emplacement du fichier dans la Corbeille."
    ]

    static func translation(for key: Key, language: AppLanguage) -> String {
        switch language {
        case .english: return key.rawValue
        case .simplifiedChinese: return simplifiedChinese[key] ?? key.rawValue
        case .japanese: return japanese[key] ?? key.rawValue
        case .korean: return korean[key] ?? key.rawValue
        case .russian: return russian[key] ?? key.rawValue
        case .french: return french[key] ?? key.rawValue
        }
    }

    static func text(_ key: Key, _ arguments: CVarArg...) -> String {
        text(key, arguments: arguments)
    }

    static func text(_ key: Key, arguments: [CVarArg]) -> String {
        let format = translation(for: key, language: language)
        return arguments.isEmpty ? format : String(format: format, arguments: arguments)
    }
}
