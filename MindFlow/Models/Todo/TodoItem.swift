import Foundation

struct TodoItem: Identifiable, Codable, Hashable {
    let id: Int
    var title: String
    var description: String?
    var isCompleted: Bool
    var status: TodoWorkStatus
    var priority: TodoPriority
    /// 创建时间
    var createdAt: Date
    /// 计划日期（仅日期语义；nil 时回退到 createdAt）
    var plannedDate: Date?
    /// 结束日期（未完成时；nil 时回退到 completedDate 或 createdAt）
    var endDate: Date?
    /// 首次开始计时的时刻
    var workStartedAt: Date?
    var completedDate: Date?
    /// 完成该任务所用耗时（秒），仅在已完成时有值；由完成时刻与 `createdAt` 差值写入
    var completionDurationSeconds: Int?
    /// 时间段开始（0–23 点），未设置时解码默认为 0
    var timeSlotStartHour: Int
    /// 开始分钟 0–59
    var timeSlotStartMinute: Int
    /// 时间段结束（0–24 点；24 仅表示当日 24:00，须与分钟 0 搭配）
    var timeSlotEndHour: Int
    /// 结束分钟 0–59（`timeSlotEndHour == 24` 时忽略，视为 0）
    var timeSlotEndMinute: Int
    /// 计划时间段（时、分），与开始/结束时间段独立
    var plannedTimeSlotHour: Int
    var plannedTimeSlotMinute: Int
    /// 待办分类 ID，对应 `TodoLifeCategoryCatalog`
    var taskCategoryId: Int?
    /// 重复模式
    var repeatMode: TodoRepeatMode
    /// 周重复：1=周一 … 7=周日
    var weeklyRepeatWeekdays: Set<Int>
    /// 月重复：每月第几天 1…31
    var monthlyRepeatDays: Set<Int>
    /// 月重复：所选 29/30/31 在无该日月份时是否改为当月最后一天
    var monthlyRepeatUsesLastDayFallback: Bool
    /// 年重复：月-日
    var yearlyRepeatDays: Set<TodoYearlyRepeatDay>
    /// 周/年重复：截止时间与循环次数二选一；均未设置时为无限循环
    var repeatLimitKind: TodoRepeatLimitKind
    /// 重复截止日期（`repeatLimitKind == .deadline` 时有效）
    var repeatUntilDate: Date?
    /// 最大循环次数（`repeatLimitKind == .count` 时有效）
    var repeatMaxOccurrences: Int?
    /// 自定义循环：间隔数值
    var customRepeatInterval: Int
    /// 自定义循环：间隔单位
    var customRepeatPeriod: TodoCustomRepeatPeriod
    /// 循环周期状态：进行中 / 暂停中
    var recurringCycleStatus: TodoRecurringCycleStatus
    /// 累计完成循环次数（展示用）
    var recurringCompletedOccurrences: Int
    /// 完成率分母；未设置时回退到 `repeatMaxOccurrences`
    var recurringCompletionRateBasis: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, description, isCompleted, status, priority, createdAt, plannedDate, endDate, workStartedAt, completedDate
        case completionDurationSeconds
        case timeSlotStartHour, timeSlotStartMinute, timeSlotEndHour, timeSlotEndMinute
        case plannedTimeSlotHour, plannedTimeSlotMinute
        case taskCategoryId
        case repeatMode
        case weeklyRepeatWeekdays
        case monthlyRepeatDays
        case monthlyRepeatUsesLastDayFallback
        case yearlyRepeatDays
        case repeatLimitKind
        case repeatUntilDate
        case repeatMaxOccurrences
        case customRepeatInterval
        case customRepeatPeriod
        case recurringCycleStatus
        case recurringCompletedOccurrences
        case recurringCompletionRateBasis
    }

    init(
        id: Int,
        title: String,
        description: String?,
        isCompleted: Bool,
        status: TodoWorkStatus = .notStarted,
        priority: TodoPriority = .p3,
        createdAt: Date,
        plannedDate: Date? = nil,
        endDate: Date? = nil,
        workStartedAt: Date? = nil,
        completedDate: Date?,
        completionDurationSeconds: Int? = nil,
        timeSlotStartHour: Int = 0,
        timeSlotStartMinute: Int = 0,
        timeSlotEndHour: Int = 1,
        timeSlotEndMinute: Int = 0,
        plannedTimeSlotHour: Int? = nil,
        plannedTimeSlotMinute: Int? = nil,
        taskCategoryId: Int? = nil,
        repeatMode: TodoRepeatMode = .none,
        weeklyRepeatWeekdays: Set<Int> = [],
        monthlyRepeatDays: Set<Int> = [],
        monthlyRepeatUsesLastDayFallback: Bool = false,
        yearlyRepeatDays: Set<TodoYearlyRepeatDay> = [],
        repeatLimitKind: TodoRepeatLimitKind = .unset,
        repeatUntilDate: Date? = nil,
        repeatMaxOccurrences: Int? = nil,
        customRepeatInterval: Int = 1,
        customRepeatPeriod: TodoCustomRepeatPeriod = .week,
        recurringCycleStatus: TodoRecurringCycleStatus = .active,
        recurringCompletedOccurrences: Int = 0,
        recurringCompletionRateBasis: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.status = isCompleted ? .completed : status
        self.priority = priority
        self.createdAt = createdAt
        let dayStart = Calendar.current.startOfDay(for: createdAt)
        self.plannedDate = plannedDate ?? dayStart
        self.endDate = endDate ?? dayStart
        self.workStartedAt = workStartedAt
        self.completedDate = completedDate
        self.completionDurationSeconds = completionDurationSeconds
        self.timeSlotStartHour = timeSlotStartHour
        self.timeSlotStartMinute = timeSlotStartMinute
        self.timeSlotEndHour = timeSlotEndHour
        self.timeSlotEndMinute = timeSlotEndMinute
        self.plannedTimeSlotHour = plannedTimeSlotHour ?? timeSlotStartHour
        self.plannedTimeSlotMinute = plannedTimeSlotMinute ?? timeSlotStartMinute
        self.taskCategoryId = taskCategoryId
        self.repeatMode = repeatMode
        self.weeklyRepeatWeekdays = weeklyRepeatWeekdays
        self.monthlyRepeatDays = monthlyRepeatDays
        self.monthlyRepeatUsesLastDayFallback = monthlyRepeatUsesLastDayFallback
        self.yearlyRepeatDays = yearlyRepeatDays
        self.repeatLimitKind = repeatLimitKind
        self.repeatUntilDate = repeatUntilDate
        self.repeatMaxOccurrences = repeatMaxOccurrences
        self.customRepeatInterval = max(1, customRepeatInterval)
        self.customRepeatPeriod = customRepeatPeriod
        self.recurringCycleStatus = repeatMode == .none ? .active : recurringCycleStatus
        self.recurringCompletedOccurrences = max(0, recurringCompletedOccurrences)
        self.recurringCompletionRateBasis = recurringCompletionRateBasis
        normalizeLegacyRepeatMode()
    }

    /// 将旧版周/月/年循环统一迁移为「循环」模式
    mutating func normalizeLegacyRepeatMode() {
        switch repeatMode {
        case .weekly:
            repeatMode = .custom
            customRepeatInterval = max(1, customRepeatInterval)
            customRepeatPeriod = .week
        case .monthly:
            repeatMode = .custom
            customRepeatInterval = max(1, customRepeatInterval)
            customRepeatPeriod = .month
        case .yearly:
            repeatMode = .custom
            customRepeatInterval = max(1, customRepeatInterval)
            customRepeatPeriod = .year
        case .none, .custom:
            break
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        status = try container.decodeIfPresent(TodoWorkStatus.self, forKey: .status)
            ?? (isCompleted ? .completed : .notStarted)
        priority = try container.decodeIfPresent(TodoPriority.self, forKey: .priority) ?? .p3
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        plannedDate = try container.decodeIfPresent(Date.self, forKey: .plannedDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        workStartedAt = try container.decodeIfPresent(Date.self, forKey: .workStartedAt)
        completedDate = try container.decodeIfPresent(Date.self, forKey: .completedDate)
        completionDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .completionDurationSeconds)
        timeSlotStartHour = try container.decodeIfPresent(Int.self, forKey: .timeSlotStartHour) ?? 0
        timeSlotStartMinute = try container.decodeIfPresent(Int.self, forKey: .timeSlotStartMinute) ?? 0
        timeSlotEndHour = try container.decodeIfPresent(Int.self, forKey: .timeSlotEndHour) ?? 1
        timeSlotEndMinute = try container.decodeIfPresent(Int.self, forKey: .timeSlotEndMinute) ?? 0
        plannedTimeSlotHour = try container.decodeIfPresent(Int.self, forKey: .plannedTimeSlotHour) ?? timeSlotStartHour
        plannedTimeSlotMinute = try container.decodeIfPresent(Int.self, forKey: .plannedTimeSlotMinute) ?? timeSlotStartMinute
        taskCategoryId = try container.decodeIfPresent(Int.self, forKey: .taskCategoryId)
        repeatMode = try container.decodeIfPresent(TodoRepeatMode.self, forKey: .repeatMode) ?? .none
        if let days = try container.decodeIfPresent([Int].self, forKey: .weeklyRepeatWeekdays) {
            weeklyRepeatWeekdays = Set(days.filter { (1...7).contains($0) })
        } else {
            weeklyRepeatWeekdays = []
        }
        if let days = try container.decodeIfPresent([Int].self, forKey: .monthlyRepeatDays) {
            monthlyRepeatDays = Set(days.filter { (1...31).contains($0) })
        } else {
            monthlyRepeatDays = []
        }
        monthlyRepeatUsesLastDayFallback = try container.decodeIfPresent(
            Bool.self,
            forKey: .monthlyRepeatUsesLastDayFallback
        ) ?? false
        if let anchors = try container.decodeIfPresent([TodoYearlyRepeatDay].self, forKey: .yearlyRepeatDays) {
            yearlyRepeatDays = Set(anchors.filter { (1...12).contains($0.month) && (1...31).contains($0.day) })
        } else {
            yearlyRepeatDays = []
        }
        if repeatMode == .none, !weeklyRepeatWeekdays.isEmpty {
            repeatMode = .custom
            customRepeatInterval = 1
            customRepeatPeriod = .week
        }
        repeatLimitKind = try container.decodeIfPresent(TodoRepeatLimitKind.self, forKey: .repeatLimitKind) ?? .unset
        repeatUntilDate = try container.decodeIfPresent(Date.self, forKey: .repeatUntilDate)
        repeatMaxOccurrences = try container.decodeIfPresent(Int.self, forKey: .repeatMaxOccurrences)
        if repeatUntilDate == nil, repeatMaxOccurrences == nil {
            repeatLimitKind = .unset
        }
        customRepeatInterval = max(1, try container.decodeIfPresent(Int.self, forKey: .customRepeatInterval) ?? 1)
        customRepeatPeriod = try container.decodeIfPresent(TodoCustomRepeatPeriod.self, forKey: .customRepeatPeriod) ?? .week
        recurringCycleStatus = try container.decodeIfPresent(
            TodoRecurringCycleStatus.self,
            forKey: .recurringCycleStatus
        ) ?? .active
        recurringCompletedOccurrences = max(
            0,
            try container.decodeIfPresent(Int.self, forKey: .recurringCompletedOccurrences) ?? 0
        )
        recurringCompletionRateBasis = try container.decodeIfPresent(Int.self, forKey: .recurringCompletionRateBasis)
        let dayStart = Calendar.current.startOfDay(for: createdAt)
        if plannedDate == nil {
            plannedDate = dayStart
        }
        if endDate == nil {
            endDate = dayStart
        }
        normalizeLegacyRepeatMode()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(status, forKey: .status)
        try container.encode(priority, forKey: .priority)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(plannedDate, forKey: .plannedDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(workStartedAt, forKey: .workStartedAt)
        try container.encodeIfPresent(completedDate, forKey: .completedDate)
        try container.encodeIfPresent(completionDurationSeconds, forKey: .completionDurationSeconds)
        try container.encode(timeSlotStartHour, forKey: .timeSlotStartHour)
        try container.encode(timeSlotStartMinute, forKey: .timeSlotStartMinute)
        try container.encode(timeSlotEndHour, forKey: .timeSlotEndHour)
        try container.encode(timeSlotEndMinute, forKey: .timeSlotEndMinute)
        try container.encode(plannedTimeSlotHour, forKey: .plannedTimeSlotHour)
        try container.encode(plannedTimeSlotMinute, forKey: .plannedTimeSlotMinute)
        try container.encodeIfPresent(taskCategoryId, forKey: .taskCategoryId)
        try container.encode(repeatMode, forKey: .repeatMode)
        try container.encode(Array(weeklyRepeatWeekdays.sorted()), forKey: .weeklyRepeatWeekdays)
        try container.encode(Array(monthlyRepeatDays.sorted()), forKey: .monthlyRepeatDays)
        try container.encode(monthlyRepeatUsesLastDayFallback, forKey: .monthlyRepeatUsesLastDayFallback)
        try container.encode(Array(yearlyRepeatDays).sorted {
            $0.month != $1.month ? $0.month < $1.month : $0.day < $1.day
        }, forKey: .yearlyRepeatDays)
        try container.encode(repeatLimitKind, forKey: .repeatLimitKind)
        try container.encodeIfPresent(repeatUntilDate, forKey: .repeatUntilDate)
        try container.encodeIfPresent(repeatMaxOccurrences, forKey: .repeatMaxOccurrences)
        try container.encode(customRepeatInterval, forKey: .customRepeatInterval)
        try container.encode(customRepeatPeriod, forKey: .customRepeatPeriod)
        try container.encode(recurringCycleStatus, forKey: .recurringCycleStatus)
        try container.encode(recurringCompletedOccurrences, forKey: .recurringCompletedOccurrences)
        try container.encodeIfPresent(recurringCompletionRateBasis, forKey: .recurringCompletionRateBasis)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension TodoItem {
    var isRecurring: Bool { repeatMode != .none }

    /// 月重复：将所选「日」解析为指定年月的实际触发日；无该日且未开启月末回退时返回 nil（跳过该月）
    static func resolvedMonthlyRepeatDay(
        _ selectedDay: Int,
        month: Int,
        year: Int,
        usesLastDayFallback: Bool,
        calendar: Calendar = .current
    ) -> Int? {
        guard (1...31).contains(selectedDay),
              let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return nil
        }
        let lastDay = dayRange.count
        if selectedDay <= lastDay { return selectedDay }
        return usesLastDayFallback ? lastDay : nil
    }

    /// 判断指定日期是否命中月重复规则（以计划日期为锚点）
    func matchesMonthlyRepeat(on date: Date, calendar: Calendar = .current) -> Bool {
        guard repeatMode == .monthly, let plannedDate else { return false }
        let anchorDay = calendar.component(.day, from: plannedDate)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        return Self.resolvedMonthlyRepeatDay(
            anchorDay,
            month: month,
            year: year,
            usesLastDayFallback: monthlyRepeatUsesLastDayFallback,
            calendar: calendar
        ) == day
    }

    /// 判断指定日期是否命中周重复规则（以计划日期的星期为锚点，周一=1 … 周日=7）
    func matchesWeeklyRepeat(on date: Date, calendar: Calendar = .current) -> Bool {
        guard repeatMode == .weekly, let plannedDate else { return false }
        return Self.weekdayIndex(for: date, calendar: calendar)
            == Self.weekdayIndex(for: plannedDate, calendar: calendar)
    }

    /// 判断指定日期是否命中年重复规则（以计划日期的月-日为锚点）
    func matchesYearlyRepeat(on date: Date, calendar: Calendar = .current) -> Bool {
        guard repeatMode == .yearly, let plannedDate else { return false }
        let plannedMonth = calendar.component(.month, from: plannedDate)
        let plannedDay = calendar.component(.day, from: plannedDate)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return month == plannedMonth && day == plannedDay
    }

    /// 判断指定日期是否命中自定义循环规则（以计划日期为锚点）
    func matchesCustomRepeat(on date: Date, calendar: Calendar = .current) -> Bool {
        guard repeatMode == .custom, let plannedDate else { return false }
        let anchor = calendar.startOfDay(for: plannedDate)
        let target = calendar.startOfDay(for: date)
        guard target >= anchor else { return false }

        let interval = max(1, customRepeatInterval)
        switch customRepeatPeriod {
        case .minute, .hour:
            guard let anchorDateTime = plannedDateTimeAnchor(calendar: calendar) else { return false }
            let targetDateTime = calendar.date(
                bySettingHour: min(max(plannedTimeSlotHour, 0), 23),
                minute: min(max(plannedTimeSlotMinute, 0), 59),
                second: 0,
                of: target
            ) ?? target
            guard targetDateTime >= anchorDateTime else { return false }
            let delta: Int
            if customRepeatPeriod == .minute {
                delta = calendar.dateComponents([.minute], from: anchorDateTime, to: targetDateTime).minute ?? 0
            } else {
                delta = calendar.dateComponents([.hour], from: anchorDateTime, to: targetDateTime).hour ?? 0
            }
            guard delta >= 0 else { return false }
            return delta % interval == 0
        case .day:
            let days = calendar.dateComponents([.day], from: anchor, to: target).day ?? 0
            return days % interval == 0
        case .week:
            let days = calendar.dateComponents([.day], from: anchor, to: target).day ?? 0
            guard days >= 0, days % 7 == 0 else { return false }
            return (days / 7) % interval == 0
        case .month:
            let months = calendar.dateComponents([.month], from: anchor, to: target).month ?? 0
            guard months >= 0, months % interval == 0 else { return false }
            guard let expected = calendar.date(byAdding: .month, value: months, to: anchor) else { return false }
            return calendar.isDate(expected, inSameDayAs: target)
        case .year:
            let years = calendar.dateComponents([.year], from: anchor, to: target).year ?? 0
            guard years >= 0, years % interval == 0 else { return false }
            guard let expected = calendar.date(byAdding: .year, value: years, to: anchor) else { return false }
            return calendar.isDate(expected, inSameDayAs: target)
        }
    }

    func matchesRepeat(on date: Date, calendar: Calendar = .current) -> Bool {
        switch repeatMode {
        case .none: return false
        case .weekly: return matchesWeeklyRepeat(on: date, calendar: calendar)
        case .monthly: return matchesMonthlyRepeat(on: date, calendar: calendar)
        case .yearly: return matchesYearlyRepeat(on: date, calendar: calendar)
        case .custom: return matchesCustomRepeat(on: date, calendar: calendar)
        }
    }

    static func weekdayIndex(for date: Date, calendar: Calendar = .current) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 ? 7 : weekday - 1
    }

    /// 规范化后的起止（时、分）；结束可表示为 24:00；非法时回退为 0:00–1:00
    var normalizedTimeSlotHM: (sh: Int, sm: Int, eh: Int, em: Int) {
        var sh = min(max(timeSlotStartHour, 0), 23)
        var sm = min(max(timeSlotStartMinute, 0), 59)
        var eh = min(max(timeSlotEndHour, 0), 24)
        var em = min(max(timeSlotEndMinute, 0), 59)
        if eh == 24 { em = 0 }
        let sMin = sh * 60 + sm
        var eMin: Int
        if eh == 24 {
            eMin = 24 * 60
        } else {
            eMin = eh * 60 + em
        }
        if eMin <= sMin {
            return (0, 0, 1, 0)
        }
        if eh == 24 {
            return (sh, sm, 24, 0)
        }
        return (sh, sm, eh, em)
    }

    /// 兼容旧逻辑：仅整点起止小时（用于分组等仅需小时的场景）
    var normalizedTimeSlot: (start: Int, end: Int) {
        let h = normalizedTimeSlotHM
        return (h.sh, h.eh == 24 ? 24 : h.eh)
    }

    /// 根据任务开始小时归入四个时段之一
    var periodBucket: TodoDayPeriod {
        let start = normalizedTimeSlotHM.sh
        switch start {
        case 0..<6: return .dawn
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        default: return .evening
        }
    }

    var timeSlotDisplayText: String {
        "\(plannedDateOnlyDisplayText) \(plannedTimeSlotDisplayText)"
    }

    /// 今日待办卡片副标题：仅显示开始时刻
    var todayCardTimeDisplayText: String {
        timeSlotStartDisplayText
    }

    var timeSlotStartDisplayText: String {
        let c = normalizedTimeSlotHM
        return String(format: "%02d:%02d", c.sh, c.sm)
    }

    var timeSlotEndDisplayText: String {
        let c = normalizedTimeSlotHM
        if c.eh == 24 { return "24:00" }
        return String(format: "%02d:%02d", c.eh, c.em)
    }

    /// 详情页：开始时间段（直接读存储值，避免非法区间被展示成 0:00）
    var detailStartSlotDisplayText: String {
        String(
            format: "%02d:%02d",
            min(max(timeSlotStartHour, 0), 23),
            min(max(timeSlotStartMinute, 0), 59)
        )
    }

    /// 详情页：结束时间段（直接读存储值）
    var detailEndSlotDisplayText: String {
        let endHour = min(max(timeSlotEndHour, 0), 24)
        if endHour == 24 { return "24:00" }
        return String(
            format: "%02d:%02d",
            endHour,
            min(max(timeSlotEndMinute, 0), 59)
        )
    }

    var plannedTimeSlotDisplayText: String {
        let hour = min(max(plannedTimeSlotHour, 0), 23)
        let minute = min(max(plannedTimeSlotMinute, 0), 59)
        return String(format: "%02d:%02d", hour, minute)
    }

    /// 计划时段时长文案，如「3 小时」
    var timeSlotDurationDisplayText: String {
        Self.durationDisplayText(seconds: timeSlotDurationSeconds)
    }

    var timeSlotDurationUsesMultilineDisplay: Bool {
        timeSlotDurationDisplayText.contains("\n")
    }

    /// 投入时长文案；未开始计时时返回 nil（展示占位横线）
    func investedDurationDisplayText(liveTimerSeconds: Int) -> String? {
        if isCompleted, let sec = completionDurationSeconds, sec >= 0 {
            return Self.durationDisplayText(seconds: sec)
        }
        if liveTimerSeconds > 0 {
            return Self.durationDisplayText(seconds: liveTimerSeconds)
        }
        if workStartedAt == nil {
            return nil
        }
        return "0 分钟"
    }

    static func durationDisplayText(seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) 秒" }
        if seconds < 3600 {
            let m = seconds / 60
            return m == 1 ? "1 分钟" : "\(m) 分钟"
        }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if m == 0 { return h == 1 ? "1 小时" : "\(h) 小时" }
        let hourText = h == 1 ? "1 小时" : "\(h) 小时"
        let minuteText = m == 1 ? "1 分钟" : "\(m) 分钟"
        return "\(hourText)\n\(minuteText)"
    }

    /// 详情页：创建日期 yyyy-MM-dd
    var createdDateOnlyDisplayText: String {
        TodoDetailDateFormatting.dateOnly.string(from: createdAt)
    }

    /// 详情页：计划日期 yyyy-MM-dd
    var plannedDateOnlyDisplayText: String {
        TodoDetailDateFormatting.dateOnly.string(from: plannedDate ?? createdAt)
    }

    /// 详情页：循环截止日期 yyyy-MM-dd
    var repeatUntilDateOnlyDisplayText: String? {
        repeatUntilDate.map { TodoDetailDateFormatting.dateOnly.string(from: $0) }
    }

    var isInfiniteRepeat: Bool {
        repeatUntilDate == nil && repeatMaxOccurrences == nil
    }

    var repeatDeadlineSummaryText: String {
        repeatUntilDateOnlyDisplayText ?? "—"
    }

    var repeatCountSummaryText: String {
        repeatMaxOccurrences.map { "\($0) 次" } ?? "—"
    }

    var recurringNextOccurrenceStart: Date {
        plannedDateTimeAnchor() ?? plannedDate ?? createdAt
    }

    func plannedDateTimeAnchor(calendar: Calendar = .current) -> Date? {
        let base = plannedDate ?? createdAt
        var components = calendar.dateComponents([.year, .month, .day], from: base)
        components.hour = min(max(plannedTimeSlotHour, 0), 23)
        components.minute = min(max(plannedTimeSlotMinute, 0), 59)
        components.second = 0
        return calendar.date(from: components)
    }

    func recurringNextStartTimePhrase(at now: Date = Date()) -> String? {
        let target = recurringNextOccurrenceStart
        guard target > now else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now, to: target)
        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        if years >= 1 {
            return "\(years)年后"
        }
        if months >= 1 {
            return "\(months)月后"
        }
        if days >= 7 {
            let weeks = days / 7
            return "\(weeks)周后"
        }
        if days >= 1 {
            return "\(days)天后"
        }
        if hours >= 1 {
            return "\(hours)小时后"
        }
        if minutes >= 1 {
            return "\(minutes)分钟后"
        }
        return "马上"
    }

    /// 循环方法标签（不含次数、截止等规则）
    var recurringMethodTag: String? {
        guard repeatMode != .none else { return nil }
        if !weeklyRepeatWeekdays.isEmpty,
           let weekLabel = TodoWeekdayCatalog.compactWeeklyTag(from: weeklyRepeatWeekdays) {
            return weekLabel
        }
        return customRepeatPeriod.recurringTag(interval: customRepeatInterval)
    }

    var recurringCompletionRatePercent: Int? {
        let basis = recurringCompletionRateBasis ?? repeatMaxOccurrences
        guard let basis, basis > 0 else { return nil }
        return min(100, (recurringCompletedOccurrences * 100 + basis / 2) / basis)
    }

    var recurringStatusDisplayName: String {
        if isCompleted { return "已完成" }
        return recurringCycleStatus.displayName
    }

    /// 详情页：实际开始日期（首次计时）
    var workStartedDateOnlyDisplayText: String? {
        workStartedAt.map { TodoDetailDateFormatting.dateOnly.string(from: $0) }
    }

    /// 详情页：实际开始时间段
    var workStartedSlotDisplayText: String? {
        workStartedAt.map { TodoDetailDateFormatting.timeOnly.string(from: $0) }
    }

    /// 详情页：实际完成日期
    var actualCompletedDateOnlyDisplayText: String? {
        completedDate.map { TodoDetailDateFormatting.dateOnly.string(from: $0) }
    }

    /// 详情页：实际完成时间段
    var actualCompletedSlotDisplayText: String? {
        completedDate.map { TodoDetailDateFormatting.timeOnly.string(from: $0) }
    }

    /// 详情页：结束日期 yyyy-MM-dd
    var endDateOnlyDisplayText: String {
        if let completedDate {
            return TodoDetailDateFormatting.dateOnly.string(from: completedDate)
        }
        return TodoDetailDateFormatting.dateOnly.string(from: endDate ?? createdAt)
    }

    func date(for target: TodoDetailDateTarget) -> Date {
        switch target {
        case .start:
            return createdAt
        case .end:
            return completedDate ?? endDate ?? createdAt
        case .planned:
            return plannedDate ?? createdAt
        }
    }

    /// 计划时间段的总时长（秒）：按开始/结束的完整日期时间差计算
    var timeSlotDurationSeconds: Int {
        let start = TodoScheduling.scheduleStartDateTime(for: self)
        let end = TodoScheduling.scheduleEndDateTime(for: self)
        return max(0, Int(end.timeIntervalSince(start)))
    }

    /// 完成用时：优先计时器累计；未计时时取计划时间段全长
    func resolvedCompletionDurationSeconds(timerSeconds: Int) -> Int {
        if timerSeconds > 0 {
            return timerSeconds
        }
        return timeSlotDurationSeconds
    }

    /// 待办关联的生活分类名称，如「穿搭」
    var taskCategoryLabel: String? {
        guard let id = taskCategoryId else { return nil }
        return TodoLifeCategoryCatalog.option(for: id)?.title
    }

    /// 列表已完成卡片副标题：已用时：2 分钟
    var completionDurationCardSubtitle: String? {
        guard let text = completionDurationDisplayText else { return nil }
        let body = text.replacingOccurrences(of: "用时 ", with: "")
        return "已用时：\(body)"
    }

    /// 卡片/详情用紧凑用时：3h、45m、30s、2d 等
    var completionDurationCompactText: String? {
        guard isCompleted, let sec = completionDurationSeconds, sec >= 0 else { return nil }
        if sec < 60 {
            return "\(sec)s"
        }
        if sec < 3600 {
            let m = sec / 60
            let s = sec % 60
            return s == 0 ? "\(m)m" : "\(m)m\(s)s"
        }
        if sec < 86_400 {
            let h = sec / 3600
            let m = (sec % 3600) / 60
            return m == 0 ? "\(h)h" : "\(h)h\(m)m"
        }
        let d = sec / 86_400
        let rem = sec % 86_400
        let h = rem / 3600
        return h == 0 ? "\(d)d" : "\(d)d\(h)h"
    }

    /// 完成耗时展示文案（详情等完整句式），未完成或无数据时为 `nil`
    var completionDurationDisplayText: String? {
        guard isCompleted, let sec = completionDurationSeconds, sec >= 0 else { return nil }
        if sec < 60 {
            return "用时 \(sec) 秒"
        }
        if sec < 3600 {
            let m = sec / 60
            let s = sec % 60
            return s == 0 ? "用时 \(m) 分钟" : "用时 \(m) 分 \(s) 秒"
        }
        if sec < 86_400 {
            let h = sec / 3600
            let m = (sec % 3600) / 60
            return m == 0 ? "用时 \(h) 小时" : "用时 \(h) 小时 \(m) 分钟"
        }
        let d = sec / 86_400
        let rem = sec % 86_400
        let h = rem / 3600
        if h == 0 {
            return "用时 \(d) 天"
        }
        return "用时 \(d) 天 \(h) 小时"
    }
}
