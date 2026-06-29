import Foundation

enum TodoWeekdayCatalog {
    /// 单行顺序：周一 → 周日
    static let displayOrder = [1, 2, 3, 4, 5, 6, 7]

    static func isActive(_ weekday: Int, in days: Set<Int>) -> Bool {
        days.contains(weekday)
    }

    static func toggled(_ weekday: Int, in days: Set<Int>) -> Set<Int> {
        var updated = days
        if updated.contains(weekday) {
            updated.remove(weekday)
        } else {
            updated.insert(weekday)
        }
        return updated
    }

    static func label(for weekday: Int) -> String {
        switch weekday {
        case 1: return "周一"
        case 2: return "周二"
        case 3: return "周三"
        case 4: return "周四"
        case 5: return "周五"
        case 6: return "周六"
        case 7: return "周日"
        default: return ""
        }
    }

    static func compactWeeklyTag(from days: Set<Int>) -> String? {
        let workdays: Set<Int> = [1, 2, 3, 4, 5]
        if days == workdays { return "工作日" }

        let chars = displayOrder
            .filter { days.contains($0) }
            .compactMap { weekday -> String? in
                switch weekday {
                case 1: return "一"
                case 2: return "二"
                case 3: return "三"
                case 4: return "四"
                case 5: return "五"
                case 6: return "六"
                case 7: return "日"
                default: return nil
                }
            }
        guard !chars.isEmpty else { return nil }
        return "每周" + chars.joined(separator: "、")
    }

    static func displayString(from days: Set<Int>) -> String {
        if let compact = compactWeeklyTag(from: days) {
            return compact
        }
        return displayOrder
            .filter { days.contains($0) }
            .map { label(for: $0) }
            .joined(separator: " ")
    }
}
