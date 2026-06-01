import Foundation

struct CalendarSpec: Hashable {
    var month: Int
    var year: Int

    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "LLLL"
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: 1))!
        return formatter.string(from: date)
    }

    static var current: CalendarSpec {
        let comps = Calendar.current.dateComponents([.year, .month], from: Date())
        return CalendarSpec(month: comps.month ?? 1, year: comps.year ?? 2026)
    }
}
