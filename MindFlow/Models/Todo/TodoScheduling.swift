import Foundation

enum TodoScheduling {
    static func endTimeComponents(
        startHour: Int,
        startMinute: Int,
        durationMinutes: Int
    ) -> (hour: Int, minute: Int) {
        let start = min(max(startHour, 0), 23) * 60 + min(max(startMinute, 0), 59)
        let end = start + max(1, durationMinutes)
        if end >= 24 * 60 {
            return (24, 0)
        }
        return (end / 60, end % 60)
    }

    static func scheduleStartDateTime(for todo: TodoItem) -> Date {
        mergeTime(
            hour: min(max(todo.plannedTimeSlotHour, 0), 23),
            minute: min(max(todo.plannedTimeSlotMinute, 0), 59),
            into: todo.plannedDate ?? todo.createdAt
        )
    }

    static func scheduleEndDateTime(for todo: TodoItem) -> Date {
        let base = todo.plannedDate ?? todo.completedDate ?? todo.endDate ?? todo.createdAt
        let endHour = min(max(todo.timeSlotEndHour, 0), 24)
        let endMinute: Int
        let mergeHour: Int
        if endHour == 24 {
            mergeHour = 23
            endMinute = 59
        } else {
            mergeHour = endHour
            endMinute = min(max(todo.timeSlotEndMinute, 0), 59)
        }
        return mergeTime(hour: mergeHour, minute: endMinute, into: base)
    }

    static func isScheduleEndAfterStart(for todo: TodoItem) -> Bool {
        scheduleEndDateTime(for: todo) > scheduleStartDateTime(for: todo)
    }

    private static let maxScheduleSpanSeconds: TimeInterval = 7 * 24 * 3600

    enum ScheduleValidationFailure {
        case endBeforeStart
        case spanExceedsOneWeek

        var alertMessage: String {
            switch self {
            case .endBeforeStart:
                return "结束时间不能早于开始时间"
            case .spanExceedsOneWeek:
                return "开始时间与结束时间的跨度不能超过一周"
            }
        }
    }

    static func validateSchedule(for todo: TodoItem) -> ScheduleValidationFailure? {
        guard isScheduleEndAfterStart(for: todo) else { return .endBeforeStart }
        let span = scheduleEndDateTime(for: todo).timeIntervalSince(scheduleStartDateTime(for: todo))
        if span > maxScheduleSpanSeconds { return .spanExceedsOneWeek }
        return nil
    }

    static func mergeTime(hour: Int, minute: Int, into date: Date) -> Date {
        let cal = Calendar.current
        var components = cal.dateComponents([.year, .month, .day], from: date)
        components.hour = min(max(hour, 0), 23)
        components.minute = min(max(minute, 0), 59)
        components.second = 0
        return cal.date(from: components) ?? date
    }

    static func mergeCalendarDay(_ day: Date, into existing: Date) -> Date {
        let cal = Calendar.current
        var dayComponents = cal.dateComponents([.year, .month, .day], from: day)
        let timeComponents = cal.dateComponents([.hour, .minute, .second], from: existing)
        dayComponents.hour = timeComponents.hour
        dayComponents.minute = timeComponents.minute
        dayComponents.second = timeComponents.second
        return cal.date(from: dayComponents) ?? day
    }
}
