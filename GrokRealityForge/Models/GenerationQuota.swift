import Foundation

final class GenerationQuota: ObservableObject {
    private let dailyLimit = 5
    private let storageKey = "generation_quota"
    private let dateKey = "generation_quota_date"

    @Published private(set) var remaining: Int

    init() {
        let defaults = UserDefaults.standard
        let today = Self.dayStamp(for: Date())
        let storedDate = defaults.string(forKey: dateKey)
        if storedDate == today {
            remaining = defaults.integer(forKey: storageKey)
        } else {
            remaining = dailyLimit
            defaults.set(today, forKey: dateKey)
            defaults.set(remaining, forKey: storageKey)
        }
    }

    func resetIfNeeded() {
        let defaults = UserDefaults.standard
        let today = Self.dayStamp(for: Date())
        let storedDate = defaults.string(forKey: dateKey)
        if storedDate != today {
            remaining = dailyLimit
            defaults.set(today, forKey: dateKey)
            defaults.set(remaining, forKey: storageKey)
        }
    }

    func canConsume(_ count: Int) -> Bool {
        resetIfNeeded()
        return remaining >= count
    }

    func consume(_ count: Int) {
        resetIfNeeded()
        remaining = max(0, remaining - count)
        UserDefaults.standard.set(remaining, forKey: storageKey)
    }

    private static func dayStamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
