import SwiftUI
import Combine
import UIKit
import Foundation

struct TodoWeeklyTrendDay: Identifiable {
    let weekdayLabel: String
    let investedSeconds: Int
    let isToday: Bool
    var isPeak: Bool = false

    var id: String { weekdayLabel }
}
enum TodoRecommendationType: CaseIterable {
    case topPriority
    case mostUrgent
    case outfit
    case fitness
    case game

    var displayName: String {
        switch self {
        case .topPriority: return "最优先"
        case .mostUrgent: return "最紧急"
        case .outfit: return "穿搭推荐"
        case .fitness: return "运动推荐"
        case .game: return "游戏推荐"
        }
    }

    var badgeIcon: String {
        switch self {
        case .topPriority: return "star.fill"
        case .mostUrgent: return "bolt.fill"
        case .outfit: return "tshirt.fill"
        case .fitness: return "figure.run"
        case .game: return "gamecontroller.fill"
        }
    }

    var next: TodoRecommendationType {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self) else { return .topPriority }
        return all[(index + 1) % all.count]
    }

    var theme: TodoRecommendationTheme {
        switch self {
        case .topPriority:
            return TodoRecommendationTheme(
                accent: Color(hex: "#6B5DD3"),
                badgeBackground: Color(hex: "#EDE9FE"),
                iconBackground: Color(hex: "#7C6AE8"),
                arrowButtonBackground: Color(hex: "#F4F1FF")
            )
        case .mostUrgent:
            return TodoRecommendationTheme(
                accent: Color(hex: "#E57373"),
                badgeBackground: Color(hex: "#FFEBEE"),
                iconBackground: Color(hex: "#EF9A9A"),
                arrowButtonBackground: Color(hex: "#FFF5F5")
            )
        case .outfit:
            return TodoRecommendationTheme(
                accent: Color(hex: "#2563EB"),
                badgeBackground: Color(hex: "#DBEAFE"),
                iconBackground: Color(hex: "#3B82F6"),
                arrowButtonBackground: Color(hex: "#EFF6FF")
            )
        case .fitness:
            return TodoRecommendationTheme(
                accent: Color(hex: "#6B7280"),
                badgeBackground: Color(hex: "#F3F4F6"),
                iconBackground: Color(hex: "#9CA3AF"),
                arrowButtonBackground: Color(hex: "#F9FAFB")
            )
        case .game:
            return TodoRecommendationTheme(
                accent: Color(hex: "#38BDF8"),
                badgeBackground: Color(hex: "#E0F2FE"),
                iconBackground: Color(hex: "#7DD3FC"),
                arrowButtonBackground: Color(hex: "#F0F9FF")
            )
        }
    }
}

struct TodoRecommendationTheme {
    let accent: Color
    let badgeBackground: Color
    let iconBackground: Color
    let arrowButtonBackground: Color
}

struct TodoNextRecommendation {
    let todoId: Int
    let title: String
    let subtitle: String
    let icon: String
    let estimatedMinutes: Int
    let suggestedStartTime: String
}

enum TodoNextRecommendationMetrics {
    static let titleColor = Color(hex: "#1A1A1A")
    static let taskBoxBorder = Color(hex: "#E5E7EB")

    static func prioritySortOrder(_ priority: TodoPriority) -> Int {
        switch priority {
        case .p1: return 0
        case .p2: return 1
        case .p3: return 2
        case .p4: return 3
        }
    }
}

struct TodoRecurringCategorySection: Identifiable {
    let categoryId: Int?
    let title: String

    var id: String {
        if let categoryId { return "category-\(categoryId)" }
        return "category-uncategorized"
    }

    var headerTitle: String { title }
}

// MARK: - 待办「正在做」计时（不计入 Codable，仅存内存）
struct TodoActiveWorkState: Equatable {
    var accumulated: TimeInterval = 0
    var runningSince: Date?
    /// 暂停瞬间冻结的光带相位（弧度），非 nil 时用角向渐变静态渲染
    var pausedLightBandPhaseRadians: Double?
    /// 当前连续运行段的相位基准（每次开始 / 恢复计时写入）
    var runningSegmentBasePhaseRadians: Double = 0
}

// MARK: - Todo ViewModel
@MainActor
class TodoViewModel: ObservableObject {
    enum RowSlideOutAction: Sendable {
        /// 删除：卡片向左滑出视野
        case delete
        /// 未完成 → 完成：向右滑出视野
        case markComplete
        /// 已完成 → 恢复未完成：向左滑出视野
        case markIncomplete
    }

    @Published var todos: [TodoItem] = []
    @Published var recommendationType: TodoRecommendationType = .topPriority
    @Published private(set) var activeWorkByTodoId: [Int: TodoActiveWorkState] = [:]
    /// 正在做滑出动画的行（删除 / 完成 / 恢复）
    @Published private(set) var slidingOutIds: Set<Int> = []
    /// +1 向右、-1 向左（与 `slidingOutIds` 同步写入）
    @Published private(set) var slideOutSignById: [Int: CGFloat] = [:]

    /// 滑出位移（约一屏宽，保证整卡移出视野）；时长与曲线见下方常量
    /// iOS 26+：避免 `UIScreen.main`，从当前前台 `UIWindowScene` 取屏宽
    static var rowSlideOutOffset: CGFloat { Self.preferredScreenWidthForSlideOut() }

    private static func preferredScreenWidthForSlideOut() -> CGFloat {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            if scene.activationState == .foregroundActive || scene.activationState == .foregroundInactive {
                return scene.screen.bounds.width
            }
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return scene.screen.bounds.width
        }
        return 390
    }
    /// 行滑出动画时长（秒）：完成 / 删除 / 恢复共用；改小更快、改大更慢
    static let rowSlideOutDuration: TimeInterval = 0.22
    /// 完成 / 删除 / 恢复共用同一套曲线与时长，仅位移方向（`slideOutSignById` ±1）不同
    static var rowSlideOutAnimation: Animation { .easeOut(duration: rowSlideOutDuration) }

    var activeTodos: [TodoItem] {
        todos.filter { !$0.isCompleted }
    }
    
    var completedTodos: [TodoItem] {
        todos
            .filter(\.isCompleted)
            .sorted { lhs, rhs in
                let left = lhs.completedDate ?? lhs.createdAt
                let right = rhs.completedDate ?? rhs.createdAt
                return left > right
            }
    }

    var recurringTodos: [TodoItem] {
        todos
            .filter { $0.repeatMode != .none }
            .sorted { lhs, rhs in
                let left = lhs.plannedDate ?? lhs.createdAt
                let right = rhs.plannedDate ?? rhs.createdAt
                if left != right { return left < right }
                return lhs.id < rhs.id
            }
    }

    var recurringIncompleteTodos: [TodoItem] {
        recurringTodos.filter { !$0.isCompleted }
    }

    var recurringInProgressCount: Int {
        recurringTodos.filter { !$0.isCompleted && $0.recurringCycleStatus == .active }.count
    }

    var recurringPausedCount: Int {
        recurringTodos.filter { !$0.isCompleted && $0.recurringCycleStatus == .paused }.count
    }

    var recurringTotalCompletedCount: Int {
        recurringTodos.filter(\.isCompleted).count
    }

    func recurringCategorySections() -> [TodoRecurringCategorySection] {
        var sections: [TodoRecurringCategorySection] = []
        let listTodos = recurringIncompleteTodos
        for category in TodoLifeCategoryCatalog.available {
            let count = listTodos.filter { $0.taskCategoryId == category.taskCategoryId }.count
            if count > 0 {
                sections.append(
                    TodoRecurringCategorySection(categoryId: category.taskCategoryId, title: category.title)
                )
            }
        }
        let uncategorizedCount = listTodos.filter { todo in
            guard let id = todo.taskCategoryId else { return true }
            return TodoLifeCategoryCatalog.option(for: id) == nil
        }.count
        if uncategorizedCount > 0 {
            sections.append(TodoRecurringCategorySection(categoryId: nil, title: "未分类"))
        }
        return sections
    }

    func recurringTodos(in categoryId: Int?) -> [TodoItem] {
        let listTodos = recurringIncompleteTodos
        if let categoryId {
            return listTodos.filter { $0.taskCategoryId == categoryId }
        }
        return listTodos.filter { todo in
            guard let id = todo.taskCategoryId else { return true }
            return TodoLifeCategoryCatalog.option(for: id) == nil
        }
    }

    private let repository = MindFlowRepository.shared

    init() {
        NotificationCenter.default.addObserver(
            forName: .mindFlowDataDidReset,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.loadTodos()
            }
        }
    }

    private func persistTodos() {
        repository.saveTodos(todos)
    }

    func loadTodos() async {
        todos = repository.loadTodos()
    }

    static func makeSampleTodos() -> [TodoItem] {
        makeSampleTodosInternal()
    }

    private static func makeSampleTodosInternal() -> [TodoItem] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        func atTime(on day: Date, hour: Int, minute: Int) -> Date {
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = hour
            components.minute = minute
            components.second = 0
            return calendar.date(from: components) ?? day
        }

        func plan(from date: Date) -> (day: Date, hour: Int, minute: Int) {
            (
                calendar.startOfDay(for: date),
                calendar.component(.hour, from: date),
                calendar.component(.minute, from: date)
            )
        }

        let fitnessPlan = plan(from: calendar.date(byAdding: .day, value: 2, to: atTime(on: today, hour: 14, minute: 20)) ?? now)
        let meditationPlan = plan(from: calendar.date(byAdding: .day, value: 1, to: atTime(on: today, hour: 7, minute: 0)) ?? now)
        let englishPlan = plan(from: calendar.date(byAdding: .minute, value: 45, to: now) ?? now)
        let standPlan = plan(from: calendar.date(byAdding: .hour, value: 3, to: now) ?? now)
        let eyeCarePlan = plan(from: calendar.date(byAdding: .minute, value: 50, to: now) ?? now)
        let accountingPlan = plan(from: calendar.date(byAdding: .day, value: 12, to: atTime(on: today, hour: 21, minute: 0)) ?? now)
        let checkupPlan = plan(from: calendar.date(byAdding: .year, value: 2, to: atTime(on: today, hour: 9, minute: 0)) ?? now)
        let challengePlan = plan(from: calendar.date(byAdding: .day, value: 5, to: atTime(on: today, hour: 8, minute: 0)) ?? now)
        let reviewPlan = plan(from: calendar.date(byAdding: .day, value: 10, to: atTime(on: today, hour: 16, minute: 0)) ?? now)
        let outfitPlan = plan(from: calendar.date(byAdding: .day, value: 3, to: atTime(on: today, hour: 19, minute: 0)) ?? now)
        let challengeDeadline = calendar.date(byAdding: .day, value: 30, to: today) ?? today

        return [
            TodoItem(
                id: 1,
                title: "完成项目文档",
                description: "编写项目说明文档",
                isCompleted: false,
                status: .notStarted,
                priority: .p2,
                createdAt: today,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 9,
                timeSlotEndHour: 12,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId
            ),
            TodoItem(
                id: 26,
                title: "学习 Python 函数",
                description: "掌握函数定义与参数使用",
                isCompleted: false,
                status: .notStarted,
                priority: .p1,
                createdAt: today,
                plannedDate: today,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 20,
                timeSlotStartMinute: 30,
                timeSlotEndHour: 21,
                timeSlotEndMinute: 0,
                plannedTimeSlotHour: 20,
                plannedTimeSlotMinute: 30,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId
            ),
            TodoItem(
                id: 27,
                title: "完成每日游戏任务",
                description: "推进主线关卡",
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: today,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 21,
                timeSlotStartMinute: 0,
                timeSlotEndHour: 21,
                timeSlotEndMinute: 45,
                plannedTimeSlotHour: 21,
                plannedTimeSlotMinute: 0,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId
            ),
            // 周几标签 + 完成率进度条 +「x天后」倒计时
            TodoItem(
                id: 10,
                title: "每周健身 3 次",
                description: "力量 + 有氧",
                isCompleted: false,
                status: .notStarted,
                priority: .p2,
                createdAt: today,
                plannedDate: fitnessPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 14,
                timeSlotStartMinute: 20,
                timeSlotEndHour: 16,
                plannedTimeSlotHour: fitnessPlan.hour,
                plannedTimeSlotMinute: fitnessPlan.minute,
                taskCategoryId: TodoLifeCategoryCatalog.fitnessCategoryId,
                repeatMode: .custom,
                weeklyRepeatWeekdays: [1, 3, 5],
                customRepeatInterval: 1,
                customRepeatPeriod: .week,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 28,
                recurringCompletionRateBasis: 37
            ),
            // 暂停态 + 短横线指示
            TodoItem(
                id: 11,
                title: "晨间冥想",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: meditationPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 7,
                timeSlotEndHour: 7,
                timeSlotEndMinute: 30,
                plannedTimeSlotHour: meditationPlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                customRepeatInterval: 1,
                customRepeatPeriod: .day,
                recurringCycleStatus: .paused,
                recurringCompletedOccurrences: 12,
                recurringCompletionRateBasis: 20
            ),
            // 循环次数上限 + 完成率
            TodoItem(
                id: 12,
                title: "代码审查",
                description: "团队 PR 审查",
                isCompleted: false,
                status: .notStarted,
                priority: .p2,
                createdAt: today,
                plannedDate: meditationPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 10,
                timeSlotEndHour: 11,
                plannedTimeSlotHour: 10,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId,
                repeatMode: .custom,
                repeatLimitKind: .count,
                repeatMaxOccurrences: 24,
                customRepeatInterval: 1,
                customRepeatPeriod: .week,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 18
            ),
            // 无限循环 ∞ 指示
            TodoItem(
                id: 13,
                title: "每日饮水 8 杯",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p4,
                createdAt: today,
                plannedDate: today,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 8,
                timeSlotEndHour: 22,
                plannedTimeSlotHour: 8,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                customRepeatInterval: 1,
                customRepeatPeriod: .day,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 45
            ),
            // 已完成循环（汇总卡「已完成」计数）
            TodoItem(
                id: 14,
                title: "月度穿搭复盘",
                description: nil,
                isCompleted: true,
                status: .completed,
                priority: .p3,
                createdAt: today,
                plannedDate: today,
                completedDate: today,
                completionDurationSeconds: 900,
                timeSlotStartHour: 20,
                timeSlotEndHour: 21,
                taskCategoryId: TodoLifeCategoryCatalog.outfitCategoryId,
                repeatMode: .custom,
                monthlyRepeatDays: [1],
                customRepeatInterval: 1,
                customRepeatPeriod: .month,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 6,
                recurringCompletionRateBasis: 6
            ),
            TodoItem(
                id: 24,
                title: "撰写周报",
                description: nil,
                isCompleted: true,
                status: .completed,
                priority: .p2,
                createdAt: today,
                plannedDate: today,
                completedDate: today,
                completionDurationSeconds: 11_400,
                timeSlotStartHour: 10,
                timeSlotEndHour: 13,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId
            ),
            TodoItem(
                id: 25,
                title: "阅读专业书籍",
                description: nil,
                isCompleted: true,
                status: .completed,
                priority: .p3,
                createdAt: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
                plannedDate: calendar.date(byAdding: .day, value: -1, to: today),
                completedDate: calendar.date(byAdding: .day, value: -1, to: today),
                completionDurationSeconds: 10_620,
                timeSlotStartHour: 20,
                timeSlotEndHour: 21,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId
            ),
            // 工作日标签 +「x分钟后」
            TodoItem(
                id: 15,
                title: "工作日英语听力",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: englishPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: englishPlan.hour,
                timeSlotStartMinute: englishPlan.minute,
                timeSlotEndHour: min(englishPlan.hour + 1, 23),
                plannedTimeSlotHour: englishPlan.hour,
                plannedTimeSlotMinute: englishPlan.minute,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId,
                repeatMode: .custom,
                weeklyRepeatWeekdays: [1, 2, 3, 4, 5],
                customRepeatInterval: 1,
                customRepeatPeriod: .day,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 86,
                recurringCompletionRateBasis: 120
            ),
            // 自定义小时间隔 +「x小时后」
            TodoItem(
                id: 16,
                title: "每 2 小时站立活动",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p4,
                createdAt: today,
                plannedDate: standPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: standPlan.hour,
                timeSlotStartMinute: standPlan.minute,
                timeSlotEndHour: min(standPlan.hour + 1, 23),
                plannedTimeSlotHour: standPlan.hour,
                plannedTimeSlotMinute: standPlan.minute,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                customRepeatInterval: 2,
                customRepeatPeriod: .hour,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 4,
                recurringCompletionRateBasis: 8
            ),
            // 自定义分钟间隔
            TodoItem(
                id: 17,
                title: "每 30 分钟护眼",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p4,
                createdAt: today,
                plannedDate: eyeCarePlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: eyeCarePlan.hour,
                timeSlotStartMinute: eyeCarePlan.minute,
                timeSlotEndHour: eyeCarePlan.hour,
                timeSlotEndMinute: min(eyeCarePlan.minute + 5, 59),
                plannedTimeSlotHour: eyeCarePlan.hour,
                plannedTimeSlotMinute: eyeCarePlan.minute,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                customRepeatInterval: 30,
                customRepeatPeriod: .hour,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 11,
                recurringCompletionRateBasis: 16
            ),
            // 月循环 +「x天后」
            TodoItem(
                id: 18,
                title: "每月 5 号记账",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: accountingPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 21,
                timeSlotEndHour: 22,
                plannedTimeSlotHour: accountingPlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                monthlyRepeatDays: [5],
                customRepeatInterval: 1,
                customRepeatPeriod: .month,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 9,
                recurringCompletionRateBasis: 12
            ),
            // 年循环 +「x年后」
            TodoItem(
                id: 19,
                title: "年度健康体检",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p2,
                createdAt: today,
                plannedDate: checkupPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 9,
                timeSlotEndHour: 11,
                plannedTimeSlotHour: checkupPlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.fitnessCategoryId,
                repeatMode: .custom,
                yearlyRepeatDays: [TodoYearlyRepeatDay(month: 6, day: 15)],
                customRepeatInterval: 1,
                customRepeatPeriod: .year,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 2,
                recurringCompletionRateBasis: 3
            ),
            // 循环截止日
            TodoItem(
                id: 20,
                title: "21 天早起挑战",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p2,
                createdAt: today,
                plannedDate: challengePlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 6,
                timeSlotEndHour: 7,
                plannedTimeSlotHour: challengePlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                repeatLimitKind: .deadline,
                repeatUntilDate: challengeDeadline,
                customRepeatInterval: 1,
                customRepeatPeriod: .day,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 14,
                recurringCompletionRateBasis: 21
            ),
            // 隔周循环 +「x周后」
            TodoItem(
                id: 21,
                title: "隔周团队复盘",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: reviewPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 16,
                timeSlotEndHour: 17,
                plannedTimeSlotHour: reviewPlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId,
                repeatMode: .custom,
                customRepeatInterval: 2,
                customRepeatPeriod: .week,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 7,
                recurringCompletionRateBasis: 10
            ),
            // 穿搭分类
            TodoItem(
                id: 22,
                title: "每周日衣橱整理",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: outfitPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 19,
                timeSlotEndHour: 20,
                plannedTimeSlotHour: outfitPlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.outfitCategoryId,
                repeatMode: .custom,
                weeklyRepeatWeekdays: [7],
                customRepeatInterval: 1,
                customRepeatPeriod: .week,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 15,
                recurringCompletionRateBasis: 20
            )
        ]
    }

    func addTodo(
        title: String,
        description: String?,
        plannedDate: Date,
        plannedTimeSlotHour: Int,
        plannedTimeSlotMinute: Int,
        plannedDurationMinutes: Int,
        taskCategoryId: Int? = nil,
        priority: TodoPriority = .p3
    ) {
        let newId = (todos.map(\.id).max() ?? 0) + 1
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: plannedDate)
        let (endHour, endMinute) = TodoScheduling.endTimeComponents(
            startHour: plannedTimeSlotHour,
            startMinute: plannedTimeSlotMinute,
            durationMinutes: plannedDurationMinutes
        )
        let item = TodoItem(
            id: newId,
            title: title,
            description: description,
            isCompleted: false,
            status: .notStarted,
            priority: priority,
            createdAt: Date(),
            plannedDate: dayStart,
            completedDate: nil,
            completionDurationSeconds: nil,
            timeSlotStartHour: plannedTimeSlotHour,
            timeSlotStartMinute: plannedTimeSlotMinute,
            timeSlotEndHour: endHour,
            timeSlotEndMinute: endMinute,
            plannedTimeSlotHour: plannedTimeSlotHour,
            plannedTimeSlotMinute: plannedTimeSlotMinute,
            taskCategoryId: taskCategoryId
        )
        let willGrowActiveCard = todos.filter { !$0.isCompleted }.isEmpty
        if willGrowActiveCard {
            withAnimation(TodoCardMotion.grow) {
                todos.append(item)
            }
        } else {
            todos.append(item)
        }
        persistTodos()
    }

    func updateTodoDescription(id: Int, description: String) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        todos[index].description = trimmed.isEmpty ? nil : description
        persistTodos()
    }

    func toggleTodoWeekday(id: Int, weekday: Int) {
        guard (1...7).contains(weekday),
              let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].weeklyRepeatWeekdays = TodoWeekdayCatalog.toggled(weekday, in: todos[index].weeklyRepeatWeekdays)
        persistTodos()
    }

    func cycleTodoRepeatMode(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        if todos[index].repeatMode == .none {
            todos[index].repeatMode = .custom
            todos[index].recurringCycleStatus = .active
            if todos[index].customRepeatInterval < 1 {
                todos[index].customRepeatInterval = 1
            }
        } else {
            todos[index].repeatMode = .none
        }
        persistTodos()
    }

    func toggleTodoRecurringCycleStatus(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }),
              todos[index].repeatMode != .none else { return }
        todos[index].recurringCycleStatus = todos[index].recurringCycleStatus.toggled
        persistTodos()
    }

    func setTodoRepeatLimitKind(id: Int, kind: TodoRepeatLimitKind) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        switch kind {
        case .unset:
            todos[index].repeatLimitKind = .unset
            todos[index].repeatUntilDate = nil
            todos[index].repeatMaxOccurrences = nil
        case .deadline:
            todos[index].repeatLimitKind = .deadline
            todos[index].repeatMaxOccurrences = nil
        case .count:
            todos[index].repeatLimitKind = .count
            todos[index].repeatUntilDate = nil
            if todos[index].repeatMaxOccurrences == nil {
                todos[index].repeatMaxOccurrences = 1
            }
        }
        persistTodos()
    }

    func updateTodoRepeatUntilDate(id: Int, date: Date) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].repeatLimitKind = .deadline
        todos[index].repeatMaxOccurrences = nil
        todos[index].repeatUntilDate = Calendar.current.startOfDay(for: date)
        persistTodos()
    }

    func updateTodoRepeatMaxOccurrences(id: Int, count: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].repeatLimitKind = .count
        todos[index].repeatUntilDate = nil
        todos[index].repeatMaxOccurrences = max(1, count)
        persistTodos()
    }

    func incrementTodoRepeatMaxOccurrences(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].repeatLimitKind = .count
        todos[index].repeatUntilDate = nil
        let next = (todos[index].repeatMaxOccurrences ?? 0) + 1
        todos[index].repeatMaxOccurrences = next
        persistTodos()
    }

    func decrementTodoRepeatMaxOccurrences(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        guard let count = todos[index].repeatMaxOccurrences else { return }
        if count <= 1 {
            todos[index].repeatMaxOccurrences = nil
            if todos[index].repeatUntilDate == nil {
                todos[index].repeatLimitKind = .unset
            }
        } else {
            todos[index].repeatMaxOccurrences = count - 1
        }
        persistTodos()
    }

    func updateTodoCustomRepeatInterval(id: Int, interval: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].customRepeatInterval = max(1, interval)
        if todos[index].repeatMode != .none {
            todos[index].repeatMode = .custom
        }
        persistTodos()
    }

    func updateTodoCustomRepeatPeriod(id: Int, period: TodoCustomRepeatPeriod) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].customRepeatPeriod = period
        if todos[index].repeatMode != .none {
            todos[index].repeatMode = .custom
        }
        persistTodos()
    }

    func cycleTodoPriority(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].priority = todos[index].priority.next
        persistTodos()
    }

    func updateTodoCategory(id: Int, taskCategoryId: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }),
              TodoLifeCategoryCatalog.option(for: taskCategoryId) != nil else { return }
        todos[index].taskCategoryId = taskCategoryId
        persistTodos()
    }

    func toggleTodoMonthlyRepeatDay(id: Int, day: Int) {
        guard (1...31).contains(day),
              let index = todos.firstIndex(where: { $0.id == id }) else { return }
        if todos[index].monthlyRepeatDays.contains(day) {
            todos[index].monthlyRepeatDays.remove(day)
        } else {
            todos[index].monthlyRepeatDays.insert(day)
        }
        persistTodos()
    }

    func toggleTodoMonthlyRepeatLastDayFallback(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].monthlyRepeatUsesLastDayFallback.toggle()
        persistTodos()
    }

    func toggleTodoYearlyRepeatDay(id: Int, month: Int, day: Int) {
        guard (1...12).contains(month), (1...31).contains(day),
              let index = todos.firstIndex(where: { $0.id == id }) else { return }
        let anchor = TodoYearlyRepeatDay(month: month, day: day)
        if todos[index].yearlyRepeatDays.contains(anchor) {
            todos[index].yearlyRepeatDays.remove(anchor)
        } else {
            todos[index].yearlyRepeatDays.insert(anchor)
        }
        persistTodos()
    }

    func updateTodoTimeSlot(
        id: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].timeSlotStartHour = startHour
        todos[index].timeSlotStartMinute = startMinute
        todos[index].timeSlotEndHour = endHour
        todos[index].timeSlotEndMinute = endMinute
        persistTodos()
    }

    func updateTodoTimeSlotStart(id: Int, hour: Int, minute: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].timeSlotStartHour = hour
        todos[index].timeSlotStartMinute = minute
        todos[index].createdAt = TodoScheduling.mergeTime(hour: hour, minute: minute, into: todos[index].createdAt)
        persistTodos()
    }

    @discardableResult
    func tryUpdateTodoTimeSlotStart(id: Int, hour: Int, minute: Int) -> String? {
        guard let index = todos.firstIndex(where: { $0.id == id }) else {
            return "待办不存在"
        }
        var candidate = todos[index]
        candidate.timeSlotStartHour = hour
        candidate.timeSlotStartMinute = minute
        candidate.createdAt = TodoScheduling.mergeTime(hour: hour, minute: minute, into: candidate.createdAt)
        if let failure = TodoScheduling.validateSchedule(for: candidate) {
            return failure.alertMessage
        }
        todos[index] = candidate
        persistTodos()
        return nil
    }

    func updateTodoTimeSlotEnd(id: Int, hour: Int, minute: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].timeSlotEndHour = hour
        todos[index].timeSlotEndMinute = minute
        if todos[index].isCompleted, let completedDate = todos[index].completedDate {
            todos[index].completedDate = TodoScheduling.mergeTime(hour: hour, minute: minute, into: completedDate)
        } else if let endDate = todos[index].endDate {
            todos[index].endDate = TodoScheduling.mergeTime(hour: hour, minute: minute, into: endDate)
        }
        persistTodos()
    }

    @discardableResult
    func tryUpdateTodoTimeSlotEnd(id: Int, hour: Int, minute: Int) -> String? {
        guard let index = todos.firstIndex(where: { $0.id == id }) else {
            return "待办不存在"
        }
        var candidate = todos[index]
        candidate.timeSlotEndHour = hour
        candidate.timeSlotEndMinute = minute
        if candidate.isCompleted, let completedDate = candidate.completedDate {
            candidate.completedDate = TodoScheduling.mergeTime(hour: hour, minute: minute, into: completedDate)
        } else if let endDate = candidate.endDate {
            candidate.endDate = TodoScheduling.mergeTime(hour: hour, minute: minute, into: endDate)
        }
        if let failure = TodoScheduling.validateSchedule(for: candidate) {
            return failure.alertMessage
        }
        todos[index] = candidate
        persistTodos()
        return nil
    }

    func updateTodoPlannedTimeSlot(id: Int, hour: Int, minute: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].plannedTimeSlotHour = hour
        todos[index].plannedTimeSlotMinute = minute
        if let plannedDate = todos[index].plannedDate {
            todos[index].plannedDate = TodoScheduling.mergeTime(hour: hour, minute: minute, into: plannedDate)
        }
        persistTodos()
    }

    func updateTodoRepeatMoment(id: Int, hour: Int, minute: Int) {
        updateTodoTimeSlotStart(id: id, hour: hour, minute: minute)
    }

    func updateTodoDate(id: Int, target: TodoDetailDateTarget, date: Date) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        applyTodoDate(date, target: target, to: &todos[index])
        persistTodos()
    }

    @discardableResult
    func tryUpdateTodoDate(id: Int, target: TodoDetailDateTarget, date: Date) -> String? {
        guard let index = todos.firstIndex(where: { $0.id == id }) else {
            return "待办不存在"
        }
        var candidate = todos[index]
        applyTodoDate(date, target: target, to: &candidate)
        if target == .start || target == .end {
            if let failure = TodoScheduling.validateSchedule(for: candidate) {
                return failure.alertMessage
            }
        }
        todos[index] = candidate
        persistTodos()
        return nil
    }

    private func applyTodoDate(_ date: Date, target: TodoDetailDateTarget, to todo: inout TodoItem) {
        switch target {
        case .start:
            todo.createdAt = TodoScheduling.mergeCalendarDay(date, into: todo.createdAt)
        case .end:
            let base = todo.completedDate ?? todo.endDate ?? todo.createdAt
            let merged = TodoScheduling.mergeCalendarDay(date, into: base)
            if todo.isCompleted {
                todo.completedDate = merged
            } else {
                todo.endDate = merged
            }
        case .planned:
            let base = todo.plannedDate ?? todo.createdAt
            todo.plannedDate = TodoScheduling.mergeCalendarDay(date, into: base)
        }
    }

    func toggleTodo(_ id: Int) async {
        applyToggleTodo(id)
    }

    /// 右滑完成（无列表行动画时仍可用）；带行动画时请用 `beginRowSlideOut(..., .markComplete)`。
    func markCompleteFromSwipe(id: Int) async {
        beginRowSlideOut(id: id, action: .markComplete)
    }

    private func applyToggleTodo(_ id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].isCompleted.toggle()
        if todos[index].isCompleted {
            let now = Date()
            let todoId = todos[index].id
            let workSeconds = consumeWorkTimerForCompletion(todoId: todoId)
            let duration = todos[index].resolvedCompletionDurationSeconds(timerSeconds: workSeconds)
            todos[index].completedDate = now
            todos[index].completionDurationSeconds = duration
            todos[index].status = .completed
            if todos[index].taskCategoryId == TodoLifeCategoryCatalog.outfitCategoryId {
                OutfitResearchTimeStore.add(seconds: TimeInterval(duration))
            }
        } else {
            todos[index].completedDate = nil
            todos[index].completionDurationSeconds = nil
            todos[index].status = resolvedWorkStatus(for: todos[index])
        }
        persistTodos()
    }

    func beginRowSlideOut(id: Int, action: RowSlideOutAction) {
        guard !slidingOutIds.contains(id), todos.contains(where: { $0.id == id }) else { return }
        switch action {
        case .markComplete:
            guard let t = todos.first(where: { $0.id == id }), !t.isCompleted else { return }
        case .markIncomplete:
            guard let t = todos.first(where: { $0.id == id }), t.isCompleted else { return }
        case .delete:
            break
        }

        let sign: CGFloat = switch action {
        case .delete: -1
        case .markComplete: 1
        case .markIncomplete: -1
        }
        let d = Self.rowSlideOutDuration
        withAnimation(Self.rowSlideOutAnimation) {
            slideOutSignById = slideOutSignById.merging([id: sign], uniquingKeysWith: { _, new in new })
            slidingOutIds = slidingOutIds.union([id])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
            self?.finishRowSlideOut(id: id, action: action)
        }
    }

    private func finishRowSlideOut(id: Int, action: RowSlideOutAction) {
        let cardMotion = cardHeightMotion(after: action, id: id)

        var cleanup = Transaction()
        cleanup.disablesAnimations = true
        withTransaction(cleanup) {
            slidingOutIds = slidingOutIds.subtracting([id])
            slideOutSignById = slideOutSignById.filter { $0.key != id }
        }

        let applyMutation = { [self] in
            switch action {
            case .delete:
                activeWorkByTodoId[id] = nil
                todos.removeAll { $0.id == id }
            case .markComplete, .markIncomplete:
                applyToggleTodo(id)
            }
        }

        switch cardMotion {
        case .shrink:
            withAnimation(TodoCardMotion.shrink, applyMutation)
        case .none:
            var mutation = Transaction()
            mutation.disablesAnimations = true
            withTransaction(mutation, applyMutation)
        }
        persistTodos()
    }

    private enum CardHeightMotion {
        case shrink
        case none
    }

    /// 数据源变更后，当前列表是否会在「有待办 ↔ 无待办」两档高度间切换
    private func cardHeightMotion(after action: RowSlideOutAction, id: Int) -> CardHeightMotion {
        switch action {
        case .delete:
            guard let todo = todos.first(where: { $0.id == id }) else { return .none }
            if todo.isCompleted {
                return todos.filter(\.isCompleted).count == 1 ? .shrink : .none
            }
            return todos.filter { !$0.isCompleted }.count == 1 ? .shrink : .none
        case .markComplete:
            guard todos.contains(where: { $0.id == id && !$0.isCompleted }) else { return .none }
            return todos.filter { !$0.isCompleted }.count == 1 ? .shrink : .none
        case .markIncomplete:
            guard todos.contains(where: { $0.id == id && $0.isCompleted }) else { return .none }
            return todos.filter(\.isCompleted).count == 1 ? .shrink : .none
        }
    }

    /// 删除入口：先左滑出屏，再从数据源移除
    func deleteTodo(_ id: Int) {
        beginRowSlideOut(id: id, action: .delete)
    }

    func resolvedWorkStatus(for todo: TodoItem) -> TodoWorkStatus {
        if todo.isCompleted { return .completed }
        let state = activeWorkByTodoId[todo.id] ?? TodoActiveWorkState()
        if state.runningSince != nil { return .inProgress }
        if state.accumulated > 0.5 || state.pausedLightBandPhaseRadians != nil {
            return .paused
        }
        return .notStarted
    }

    func toggleWorkTimer(todoId: Int) {
        guard todos.contains(where: { $0.id == todoId && !$0.isCompleted }) else { return }
        var state = activeWorkByTodoId[todoId] ?? TodoActiveWorkState()
        let now = Date()
        if let since = state.runningSince {
            let elapsed = now.timeIntervalSince(since)
            state.accumulated += elapsed
            state.runningSince = nil
            state.pausedLightBandPhaseRadians = state.runningSegmentBasePhaseRadians + elapsed * TodoLightBandConstants.angularSpeed
        } else {
            state.runningSince = now
            state.runningSegmentBasePhaseRadians = state.pausedLightBandPhaseRadians ?? TodoLightBandConstants.defaultIdleFramePhaseRadians
            state.pausedLightBandPhaseRadians = nil
            if let index = todos.firstIndex(where: { $0.id == todoId }),
               todos[index].workStartedAt == nil {
                todos[index].workStartedAt = now
            }
        }
        activeWorkByTodoId[todoId] = state
        if let index = todos.firstIndex(where: { $0.id == todoId }) {
            todos[index].status = resolvedWorkStatus(for: todos[index])
        }
        persistTodos()
    }

    func isWorkTimerRunning(todoId: Int) -> Bool {
        activeWorkByTodoId[todoId]?.runningSince != nil
    }

    func workTimerRunningSince(todoId: Int) -> Date? {
        activeWorkByTodoId[todoId]?.runningSince
    }

    func pausedLightBandPhaseRadians(todoId: Int) -> Double? {
        activeWorkByTodoId[todoId]?.pausedLightBandPhaseRadians
    }

    func lightBandRunningBasePhaseRadians(todoId: Int) -> Double {
        activeWorkByTodoId[todoId]?.runningSegmentBasePhaseRadians ?? TodoLightBandConstants.defaultIdleFramePhaseRadians
    }

    func showsWorkTimer(todoId: Int) -> Bool {
        let s = activeWorkByTodoId[todoId] ?? TodoActiveWorkState()
        return s.runningSince != nil || s.accumulated > 0.5 || s.pausedLightBandPhaseRadians != nil
    }

    func currentWorkSeconds(todoId: Int) -> Int {
        var acc = activeWorkByTodoId[todoId]?.accumulated ?? 0
        if let since = activeWorkByTodoId[todoId]?.runningSince {
            acc += Date().timeIntervalSince(since)
        }
        return max(0, Int(acc))
    }

    func investedSeconds(on day: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }

        var total = todos.reduce(into: 0) { partial, todo in
            guard todo.isCompleted,
                  let completedDate = todo.completedDate,
                  completedDate >= start,
                  completedDate < end,
                  let seconds = todo.completionDurationSeconds,
                  seconds > 0 else { return }
            partial += seconds
        }

        if calendar.isDateInToday(day) {
            for todoId in activeWorkByTodoId.keys {
                total += currentWorkSeconds(todoId: todoId)
            }
        }
        return total
    }

    var todayInvestedSeconds: Int {
        investedSeconds(on: Date())
    }

    var yesterdayInvestedSeconds: Int {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return investedSeconds(on: yesterday)
    }

    var weeklyTrendDays: [TodoWeeklyTrendDay] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }

        let weekdayLabels = ["一", "二", "三", "四", "五", "六", "日"]
        let days = (0..<7).compactMap { offset -> TodoWeeklyTrendDay? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            return TodoWeeklyTrendDay(
                weekdayLabel: weekdayLabels[offset],
                investedSeconds: investedSeconds(on: day),
                isToday: calendar.isDate(day, inSameDayAs: today)
            )
        }
        let peakSeconds = days.map(\.investedSeconds).max() ?? 0
        guard peakSeconds > 0 else { return days }
        return days.map { day in
            var copy = day
            copy.isPeak = day.investedSeconds == peakSeconds
            return copy
        }
    }

    var weeklyTotalInvestedHoursText: String {
        let totalSeconds = weeklyTrendDays.reduce(0) { $0 + $1.investedSeconds }
        let hours = Double(totalSeconds) / 3600.0
        if hours >= 10 {
            return String(format: "%.0fh", hours)
        }
        return String(format: "%.1fh", hours)
    }

    var weeklyCompletedCount: Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: Date())
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: today) else { return 0 }
        return todos.filter { todo in
            guard todo.isCompleted, let completedDate = todo.completedDate else { return false }
            return interval.contains(completedDate)
        }.count
    }

    func cycleRecommendationType() {
        recommendationType = recommendationType.next
    }

    var nextRecommendation: TodoNextRecommendation? {
        guard let todo = recommendedTodo(for: recommendationType) else { return nil }

        let estimatedMinutes = max(1, todo.timeSlotDurationSeconds / 60)
        let categoryIcon: String = {
            if todo.title.contains("Python") {
                return "chevron.left.forwardslash.chevron.right"
            }
            if todo.title.contains("游戏") {
                return "gamecontroller.fill"
            }
            return todo.taskCategoryId.flatMap { TodoLifeCategoryCatalog.option(for: $0)?.icon }
                ?? "chevron.left.forwardslash.chevron.right"
        }()

        return TodoNextRecommendation(
            todoId: todo.id,
            title: todo.title,
            subtitle: todo.description ?? "",
            icon: categoryIcon,
            estimatedMinutes: estimatedMinutes,
            suggestedStartTime: todo.plannedTimeSlotDisplayText
        )
    }

    private func recommendedTodo(for type: TodoRecommendationType) -> TodoItem? {
        let candidates = candidateTodos(for: type)
        switch type {
        case .topPriority:
            return candidates.min(by: compareByPriorityThenStartTime)
        case .mostUrgent:
            return candidates.min(by: compareByScheduledDateThenPriority)
        case .outfit, .fitness, .game:
            return candidates.min(by: compareByPriorityThenStartTime)
        }
    }

    private func candidateTodos(for type: TodoRecommendationType) -> [TodoItem] {
        switch type {
        case .topPriority, .mostUrgent:
            return activeTodos.filter { $0.repeatMode == .none }
        case .outfit:
            return activeTodos.filter { $0.taskCategoryId == TodoLifeCategoryCatalog.outfitCategoryId }
        case .fitness:
            return activeTodos.filter { $0.taskCategoryId == TodoLifeCategoryCatalog.fitnessCategoryId }
        case .game:
            return activeTodos.filter { todo in
                todo.title.contains("游戏") || (todo.description?.contains("游戏") == true)
            }
        }
    }

    private func compareByPriorityThenStartTime(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        let leftOrder = TodoNextRecommendationMetrics.prioritySortOrder(lhs.priority)
        let rightOrder = TodoNextRecommendationMetrics.prioritySortOrder(rhs.priority)
        if leftOrder != rightOrder { return leftOrder < rightOrder }
        if lhs.timeSlotStartHour != rhs.timeSlotStartHour {
            return lhs.timeSlotStartHour < rhs.timeSlotStartHour
        }
        return lhs.timeSlotStartMinute < rhs.timeSlotStartMinute
    }

    private func compareByScheduledDateThenPriority(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        let leftDate = scheduledDate(for: lhs)
        let rightDate = scheduledDate(for: rhs)
        if leftDate != rightDate { return leftDate < rightDate }
        return compareByPriorityThenStartTime(lhs, rhs)
    }

    private func scheduledDate(for todo: TodoItem) -> Date {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: todo.plannedDate ?? todo.createdAt)
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = min(max(todo.plannedTimeSlotHour, 0), 23)
        components.minute = min(max(todo.plannedTimeSlotMinute, 0), 59)
        return calendar.date(from: components) ?? day
    }

    /// 结束计时并返回累计秒数（清空该条待办的计时状态）
    private func consumeWorkTimerForCompletion(todoId: Int) -> Int {
        var state = activeWorkByTodoId.removeValue(forKey: todoId) ?? TodoActiveWorkState()
        if let since = state.runningSince {
            state.accumulated += Date().timeIntervalSince(since)
            state.runningSince = nil
        }
        return max(0, Int(state.accumulated))
    }
}
