import Foundation

enum OutfitTodoCategory {
    static let outfitTaskCategoryId = 8
}

/// 待办可选分类：与分类页已接入的叶子分类对齐（新增分类待办能力时在此追加）
struct TodoLifeCategoryOption: Identifiable, Hashable {
    let taskCategoryId: Int
    let title: String
    let icon: String

    var id: Int { taskCategoryId }
}

enum TodoLifeCategoryCatalog {
    static let fitnessCategoryId = 1
    static let workCategoryId = 2
    static let lifeCategoryId = 3

    static let available: [TodoLifeCategoryOption] = [
        TodoLifeCategoryOption(taskCategoryId: fitnessCategoryId, title: "健身", icon: "figure.run"),
        TodoLifeCategoryOption(taskCategoryId: workCategoryId, title: "工作", icon: "briefcase"),
        TodoLifeCategoryOption(taskCategoryId: lifeCategoryId, title: "生活", icon: "leaf"),
        TodoLifeCategoryOption(taskCategoryId: OutfitTodoCategory.outfitTaskCategoryId, title: "穿搭", icon: "tshirt")
    ]

    static func option(for taskCategoryId: Int) -> TodoLifeCategoryOption? {
        available.first { $0.taskCategoryId == taskCategoryId }
    }

    static var outfitCategoryId: Int { OutfitTodoCategory.outfitTaskCategoryId }
}
