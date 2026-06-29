import Foundation

enum GoalStatus: String, CaseIterable, Hashable, Codable {
    case inProgress
    case completed
    case paused

    var title: String {
        switch self {
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        case .paused: return "暂停中"
        }
    }

    var iconName: String {
        switch self {
        case .inProgress: return "play.fill"
        case .completed: return "checkmark"
        case .paused: return "pause.fill"
        }
    }
}

struct GoalItem: Identifiable, Hashable {
    let id: UUID
    var categoryId: UUID
    var title: String
    var note: String?
    var status: GoalStatus
    var progress: Int
    var targetDate: Date?
    var createdAt: Date
    var stageTitle: String?

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        title: String,
        note: String? = nil,
        status: GoalStatus = .inProgress,
        progress: Int = 0,
        targetDate: Date? = nil,
        createdAt: Date = Date(),
        stageTitle: String? = nil
    ) {
        self.id = id
        self.categoryId = categoryId
        self.title = title
        self.note = note
        self.status = status
        self.progress = min(100, max(0, progress))
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.stageTitle = stageTitle
    }
}

struct GoalOverviewStats: Equatable {
    let total: Int
    let inProgress: Int
    let completed: Int
    let paused: Int

    var completionRate: Int {
        guard total > 0 else { return 0 }
        return Int((Double(completed) / Double(total) * 100).rounded())
    }
}

enum LifeCategoryCatalog {
    static let goalsTitle = "目标"

    static func isGoalsCategory(_ category: LifeCategory) -> Bool {
        category.title == goalsTitle
    }
}

enum GoalListFilter: Equatable {
    case all
    case completed
    case paused
    case inProgress

    var matchingStatus: GoalStatus? {
        switch self {
        case .all: return nil
        case .completed: return .completed
        case .paused: return .paused
        case .inProgress: return .inProgress
        }
    }
}
