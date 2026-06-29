import Foundation

// MARK: - 待办按一天中的时段分组

enum TodoDayPeriod: Int, CaseIterable, Identifiable {
    case dawn
    case morning
    case afternoon
    case evening

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .dawn: return "凌晨"
        case .morning: return "早上"
        case .afternoon: return "下午"
        case .evening: return "晚上"
        }
    }
}

// MARK: - 工作状态 / 优先级 / 循环类型

enum TodoWorkStatus: String, Codable, CaseIterable, Hashable {
    case notStarted
    case inProgress
    case paused
    case completed

    var displayName: String {
        switch self {
        case .notStarted: return "未开始"
        case .inProgress: return "进行中"
        case .paused: return "暂停"
        case .completed: return "已完成"
        }
    }
}

enum TodoPriority: String, Codable, CaseIterable, Hashable {
    case p1
    case p2
    case p3
    case p4

    var displayName: String {
        rawValue.uppercased()
    }

    var next: TodoPriority {
        switch self {
        case .p1: return .p2
        case .p2: return .p3
        case .p3: return .p4
        case .p4: return .p1
        }
    }
}

// MARK: - 待办重复规则

enum TodoRepeatLimitKind: String, Codable, CaseIterable {
    case unset
    case deadline
    case count

    var displayName: String {
        switch self {
        case .unset: return ""
        case .deadline: return "截止时间"
        case .count: return "循环次数"
        }
    }
}

enum TodoCustomRepeatPeriod: String, Codable, CaseIterable {
    case year
    case month
    case week
    case day
    case hour
    case minute

    /// 滚轮展示顺序（不含分钟）
    static let wheelOrder: [TodoCustomRepeatPeriod] = [.hour, .day, .week, .month, .year]

    var displayName: String {
        switch self {
        case .year: return "年"
        case .month: return "月"
        case .week: return "周"
        case .day: return "天"
        case .hour: return "小时"
        case .minute: return "分钟"
        }
    }

    /// 循环规则滚轮展示用（如「时」而非「小时」）
    var wheelDisplayName: String {
        switch self {
        case .hour: return "时"
        default: return displayName
        }
    }

    /// 间隔为 1 时的规则文案（如「每天」「每周」）
    var singularIntervalLabel: String {
        switch self {
        case .day: return "每天"
        case .week: return "每周"
        case .month: return "每月"
        case .year: return "每年"
        case .hour: return "每小时"
        case .minute: return "每分钟"
        }
    }

    func recurringTag(interval: Int) -> String {
        let value = max(1, interval)
        if value == 1 { return singularIntervalLabel }
        return "每\(value)\(displayName)"
    }
}

/// 循环任务周期状态（与任务计时「进行中/暂停」无关）
enum TodoRecurringCycleStatus: String, Codable, CaseIterable {
    case active
    case paused

    var displayName: String {
        switch self {
        case .active: return "进行中"
        case .paused: return "暂停中"
        }
    }

    var toggled: TodoRecurringCycleStatus {
        switch self {
        case .active: return .paused
        case .paused: return .active
        }
    }
}

enum TodoRepeatMode: String, Codable, CaseIterable {
    case none
    case weekly
    case monthly
    case yearly
    case custom

    var displayName: String {
        switch self {
        case .none: return "不循环"
        case .weekly: return "周循环"
        case .monthly: return "月循环"
        case .yearly: return "年循环"
        case .custom: return "循环"
        }
    }

    /// 待办详情循环芯片：仅「不循环 / 循环」
    var cycleChipDisplayName: String {
        switch self {
        case .none: return "不循环"
        case .weekly, .monthly, .yearly, .custom: return "循环"
        }
    }

    var usesRepeatLimit: Bool {
        self != .none
    }

    var next: TodoRepeatMode {
        switch self {
        case .none: return .custom
        case .weekly, .monthly, .yearly, .custom: return .none
        }
    }
}

struct TodoYearlyRepeatDay: Hashable, Codable {
    var month: Int
    var day: Int
}

enum TodoDetailDateTarget {
    case start
    case end
    case planned
}
