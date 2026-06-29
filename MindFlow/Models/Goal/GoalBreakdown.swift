import Foundation

enum GoalBreakdownTaskStatus: String, CaseIterable, Hashable, Codable {
    case notStarted
    case inProgress
    case completed

    var title: String {
        switch self {
        case .notStarted: return "未开始"
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        }
    }

    var next: GoalBreakdownTaskStatus {
        switch self {
        case .notStarted: return .inProgress
        case .inProgress: return .completed
        case .completed: return .notStarted
        }
    }
}

struct GoalBreakdownSection: Identifiable, Hashable {
    let id: UUID
    var goalId: UUID
    var title: String
    var icon: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        goalId: UUID,
        title: String,
        icon: String,
        sortOrder: Int
    ) {
        self.id = id
        self.goalId = goalId
        self.title = title
        self.icon = icon
        self.sortOrder = sortOrder
    }
}

struct GoalBreakdownTask: Identifiable, Hashable {
    let id: UUID
    var sectionId: UUID
    var title: String
    var status: GoalBreakdownTaskStatus
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        sectionId: UUID,
        title: String,
        status: GoalBreakdownTaskStatus = .notStarted,
        sortOrder: Int
    ) {
        self.id = id
        self.sectionId = sectionId
        self.title = title
        self.status = status
        self.sortOrder = sortOrder
    }
}

enum GoalBreakdownSampleData {
    static func makeSampleBreakdown(for goalId: UUID) -> (sections: [GoalBreakdownSection], tasks: [GoalBreakdownTask]) {
        let docSection = GoalBreakdownSection(goalId: goalId, title: "产品文档", icon: "doc.text", sortOrder: 0)
        let devSection = GoalBreakdownSection(goalId: goalId, title: "核心开发", icon: "chevron.left.forwardslash.chevron.right", sortOrder: 1)
        let releaseSection = GoalBreakdownSection(goalId: goalId, title: "发布准备", icon: "paperplane.fill", sortOrder: 2)

        let sections = [docSection, devSection, releaseSection]

        let tasks: [GoalBreakdownTask] = [
            GoalBreakdownTask(sectionId: docSection.id, title: "PRD 文档", status: .completed, sortOrder: 0),
            GoalBreakdownTask(sectionId: docSection.id, title: "测试用例", status: .completed, sortOrder: 1),
            GoalBreakdownTask(sectionId: docSection.id, title: "Bug 记录表", status: .completed, sortOrder: 2),
            GoalBreakdownTask(sectionId: docSection.id, title: "上架资料", status: .inProgress, sortOrder: 3),

            GoalBreakdownTask(sectionId: devSection.id, title: "待办模块", status: .completed, sortOrder: 0),
            GoalBreakdownTask(sectionId: devSection.id, title: "分类模块", status: .completed, sortOrder: 1),
            GoalBreakdownTask(sectionId: devSection.id, title: "衣物模块", status: .inProgress, sortOrder: 2),
            GoalBreakdownTask(sectionId: devSection.id, title: "菜品模块", status: .notStarted, sortOrder: 3),
            GoalBreakdownTask(sectionId: devSection.id, title: "穿搭模块", status: .notStarted, sortOrder: 4),

            GoalBreakdownTask(sectionId: releaseSection.id, title: "TestFlight", status: .notStarted, sortOrder: 0),
            GoalBreakdownTask(sectionId: releaseSection.id, title: "App Store 审核", status: .notStarted, sortOrder: 1)
        ]

        return (sections, tasks)
    }
}
