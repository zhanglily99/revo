import Foundation

/// Daily recycled-file count, reset at the start of each local day.
enum Stats {
    private static let dayKey = "shredDay"
    private static let countKey = "shredCount"

    static var todayCount: Int {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        guard let saved = defaults.object(forKey: dayKey) as? Date, saved == today else { return 0 }
        return defaults.integer(forKey: countKey)
    }

    static func decrement() {
        UserDefaults.standard.set(max(0, todayCount - 1), forKey: countKey)
    }

    static func increment() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        let saved = defaults.object(forKey: dayKey) as? Date
        let count = (saved == today ? defaults.integer(forKey: countKey) : 0) + 1
        defaults.set(today, forKey: dayKey)
        defaults.set(count, forKey: countKey)
    }
}
