import Foundation

/// File types determine the paper preview and cutting animation.
enum ShredStyle {
    case document   // Documents become narrow paper strips.
    case photo      // Photos become small fragments.
    case audio      // Audio uses a waveform preview.
    case video      // Video uses perforated film strips.
    case folder     // Folders feed a stack of sheets.
    case heavy      // Large files feed more slowly.

    static func classify(_ url: URL) -> ShredStyle {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
           isDirectory.boolValue {
            return .folder
        }
        if let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int64,
           size > 200 * 1024 * 1024 {
            return .heavy
        }
        switch url.pathExtension.lowercased() {
        case "png", "jpg", "jpeg", "heic", "heif", "webp", "gif",
             "tiff", "tif", "bmp", "psd", "ai", "raw", "dng":
            return .photo
        case "mp3", "wav", "m4a", "aac", "flac", "aiff", "aif", "ogg", "opus":
            return .audio
        case "mp4", "mov", "m4v", "webm", "mkv", "avi", "flv", "wmv":
            return .video
        default:
            return .document
        }
    }
}
