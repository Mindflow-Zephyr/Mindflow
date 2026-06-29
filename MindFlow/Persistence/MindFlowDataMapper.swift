import Foundation

enum MindFlowDataMapper {
    private static let jsonEncoder = JSONEncoder()
    private static let jsonDecoder = JSONDecoder()

    // MARK: - Dashboard

    static func lifeCategory(from record: SDLifeCategoryRecord) -> LifeCategory {
        LifeCategory(
            id: record.id,
            title: record.title,
            icon: record.icon,
            accentHex: record.accentHex,
            parentId: record.parentId
        )
    }

    static func lifeCategoryRecord(from category: LifeCategory) -> SDLifeCategoryRecord {
        SDLifeCategoryRecord(
            id: category.id,
            title: category.title,
            icon: category.icon,
            accentHex: category.accentHex,
            parentId: category.parentId
        )
    }

    static func lifeDetailItem(from record: SDLifeDetailItemRecord) -> LifeDetailItem {
        LifeDetailItem(id: record.id, categoryId: record.categoryId, title: record.title, note: record.note)
    }

    static func lifeDetailItemRecord(from item: LifeDetailItem) -> SDLifeDetailItemRecord {
        SDLifeDetailItemRecord(id: item.id, categoryId: item.categoryId, title: item.title, note: item.note)
    }

    static func goal(from record: SDGoalRecord) -> GoalItem {
        GoalItem(
            id: record.id,
            categoryId: record.categoryId,
            title: record.title,
            note: record.note,
            status: GoalStatus(rawValue: record.statusRaw) ?? .inProgress,
            progress: record.progress,
            targetDate: record.targetDate,
            createdAt: record.createdAt,
            stageTitle: record.stageTitle
        )
    }

    static func goalRecord(from item: GoalItem) -> SDGoalRecord {
        SDGoalRecord(
            id: item.id,
            categoryId: item.categoryId,
            title: item.title,
            note: item.note,
            statusRaw: item.status.rawValue,
            progress: item.progress,
            targetDate: item.targetDate,
            createdAt: item.createdAt,
            stageTitle: item.stageTitle
        )
    }

    static func goalBreakdownSection(from record: SDGoalBreakdownSectionRecord) -> GoalBreakdownSection {
        GoalBreakdownSection(
            id: record.id,
            goalId: record.goalId,
            title: record.title,
            icon: record.icon,
            sortOrder: record.sortOrder
        )
    }

    static func goalBreakdownSectionRecord(from section: GoalBreakdownSection) -> SDGoalBreakdownSectionRecord {
        SDGoalBreakdownSectionRecord(
            id: section.id,
            goalId: section.goalId,
            title: section.title,
            icon: section.icon,
            sortOrder: section.sortOrder
        )
    }

    static func goalBreakdownTask(from record: SDGoalBreakdownTaskRecord) -> GoalBreakdownTask {
        GoalBreakdownTask(
            id: record.id,
            sectionId: record.sectionId,
            title: record.title,
            status: GoalBreakdownTaskStatus(rawValue: record.statusRaw) ?? .notStarted,
            sortOrder: record.sortOrder
        )
    }

    static func goalBreakdownTaskRecord(from task: GoalBreakdownTask) -> SDGoalBreakdownTaskRecord {
        SDGoalBreakdownTaskRecord(
            id: task.id,
            sectionId: task.sectionId,
            title: task.title,
            statusRaw: task.status.rawValue,
            sortOrder: task.sortOrder
        )
    }

    static func wardrobeItem(from record: SDWardrobeItemRecord) -> WardrobeItem {
        WardrobeItem(
            id: record.id,
            categoryId: record.categoryId,
            name: record.name,
            wardrobeGroup: record.wardrobeGroup,
            wardrobeType: record.wardrobeType,
            brand: record.brand,
            color: record.color,
            fabric: record.fabric,
            season: record.season,
            purchasePrice: record.purchasePrice,
            purchaseDate: record.purchaseDate,
            wearCount: record.wearCount,
            lastWearDate: record.lastWearDate,
            favoriteScores: WardrobeFavoriteScores(
                appearance: record.scoreAppearance,
                fabricComfort: record.scoreFabricComfort,
                fit: record.scoreFit,
                texture: record.scoreTexture,
                personalPreference: record.scorePersonalPreference
            )
        )
    }

    static func wardrobeItemRecord(from item: WardrobeItem) -> SDWardrobeItemRecord {
        SDWardrobeItemRecord(
            id: item.id,
            categoryId: item.categoryId,
            name: item.name,
            wardrobeGroup: item.wardrobeGroup,
            wardrobeType: item.wardrobeType,
            brand: item.brand,
            color: item.color,
            fabric: item.fabric,
            season: item.season,
            purchasePrice: item.purchasePrice,
            purchaseDate: item.purchaseDate,
            wearCount: item.wearCount,
            lastWearDate: item.lastWearDate,
            scoreAppearance: item.favoriteScores.appearance,
            scoreFabricComfort: item.favoriteScores.fabricComfort,
            scoreFit: item.favoriteScores.fit,
            scoreTexture: item.favoriteScores.texture,
            scorePersonalPreference: item.favoriteScores.personalPreference
        )
    }

    static func menuItem(from record: SDMenuItemRecord) -> MenuItem? {
        guard
            let cuisine = MenuCuisineKind(rawValue: record.cuisineRaw),
            let status = MenuItemStatus(rawValue: record.statusRaw)
        else { return nil }
        return MenuItem(
            id: record.id,
            categoryId: record.categoryId,
            name: record.name,
            cuisine: cuisine,
            status: status,
            cookCount: record.cookCount
        )
    }

    static func menuItemRecord(from item: MenuItem) -> SDMenuItemRecord {
        SDMenuItemRecord(
            id: item.id,
            categoryId: item.categoryId,
            name: item.name,
            cuisineRaw: item.cuisine.rawValue,
            statusRaw: item.status.rawValue,
            cookCount: item.cookCount
        )
    }

    static func outfitPlan(from data: Data) -> OutfitPlan {
        (try? jsonDecoder.decode(OutfitPlan.self, from: data)) ?? OutfitPlan()
    }

    static func outfitPlanData(_ plan: OutfitPlan) -> Data {
        (try? jsonEncoder.encode(plan)) ?? Data()
    }

    static func ootdHistoryRecord(from record: SDOOTDHistoryRecord) -> OOTDHistoryRecord {
        OOTDHistoryRecord(
            id: record.id,
            categoryId: record.categoryId,
            date: record.date,
            plan: outfitPlan(from: record.planJSON),
            wearCountApplied: record.wearCountApplied
        )
    }

    static func ootdHistoryEntity(from record: OOTDHistoryRecord) -> SDOOTDHistoryRecord {
        SDOOTDHistoryRecord(
            id: record.id,
            categoryId: record.categoryId,
            date: record.date,
            planJSON: outfitPlanData(record.plan),
            wearCountApplied: record.wearCountApplied
        )
    }

    static func outfitPageSettings(from record: SDOutfitPageSettingsRecord) -> OutfitPageCardSettings {
        OutfitPageCardSettings(
            showWardrobeLibrary: record.showWardrobeLibrary,
            showOOTDPlan: record.showOOTDPlan,
            showOOTDCalendar: record.showOOTDCalendar,
            showFavoriteRanking: record.showFavoriteRanking,
            showActionCards: record.showActionCards
        )
    }

    static func outfitPageSettingsRecord(from settings: OutfitPageCardSettings) -> SDOutfitPageSettingsRecord {
        SDOutfitPageSettingsRecord(
            showWardrobeLibrary: settings.showWardrobeLibrary,
            showOOTDPlan: settings.showOOTDPlan,
            showOOTDCalendar: settings.showOOTDCalendar,
            showFavoriteRanking: settings.showFavoriteRanking,
            showActionCards: settings.showActionCards
        )
    }

    // MARK: - Todo

    static func intSetData(_ values: Set<Int>) -> Data {
        (try? jsonEncoder.encode(values.sorted())) ?? Data()
    }

    static func intSet(from data: Data) -> Set<Int> {
        guard let array = try? jsonDecoder.decode([Int].self, from: data) else { return [] }
        return Set(array)
    }

    static func yearlyRepeatDaysData(_ values: Set<TodoYearlyRepeatDay>) -> Data {
        (try? jsonEncoder.encode(Array(values))) ?? Data()
    }

    static func yearlyRepeatDays(from data: Data) -> Set<TodoYearlyRepeatDay> {
        guard let array = try? jsonDecoder.decode([TodoYearlyRepeatDay].self, from: data) else { return [] }
        return Set(array)
    }

    static func todoItem(from record: SDTodoRecord) -> TodoItem {
        TodoItem(
            id: record.id,
            title: record.title,
            description: record.todoDescription,
            isCompleted: record.isCompleted,
            status: TodoWorkStatus(rawValue: record.statusRaw) ?? .notStarted,
            priority: TodoPriority(rawValue: record.priorityRaw) ?? .p3,
            createdAt: record.createdAt,
            plannedDate: record.plannedDate,
            endDate: record.endDate,
            workStartedAt: record.workStartedAt,
            completedDate: record.completedDate,
            completionDurationSeconds: record.completionDurationSeconds,
            timeSlotStartHour: record.timeSlotStartHour,
            timeSlotStartMinute: record.timeSlotStartMinute,
            timeSlotEndHour: record.timeSlotEndHour,
            timeSlotEndMinute: record.timeSlotEndMinute,
            plannedTimeSlotHour: record.plannedTimeSlotHour,
            plannedTimeSlotMinute: record.plannedTimeSlotMinute,
            taskCategoryId: record.taskCategoryId,
            repeatMode: TodoRepeatMode(rawValue: record.repeatModeRaw) ?? .none,
            weeklyRepeatWeekdays: intSet(from: record.weeklyRepeatWeekdaysJSON),
            monthlyRepeatDays: intSet(from: record.monthlyRepeatDaysJSON),
            monthlyRepeatUsesLastDayFallback: record.monthlyRepeatUsesLastDayFallback,
            yearlyRepeatDays: yearlyRepeatDays(from: record.yearlyRepeatDaysJSON),
            repeatLimitKind: TodoRepeatLimitKind(rawValue: record.repeatLimitKindRaw) ?? .unset,
            repeatUntilDate: record.repeatUntilDate,
            repeatMaxOccurrences: record.repeatMaxOccurrences,
            customRepeatInterval: record.customRepeatInterval,
            customRepeatPeriod: TodoCustomRepeatPeriod(rawValue: record.customRepeatPeriodRaw) ?? .week,
            recurringCycleStatus: TodoRecurringCycleStatus(rawValue: record.recurringCycleStatusRaw) ?? .active,
            recurringCompletedOccurrences: record.recurringCompletedOccurrences,
            recurringCompletionRateBasis: record.recurringCompletionRateBasis
        )
    }

    static func todoRecord(from item: TodoItem) -> SDTodoRecord {
        SDTodoRecord(
            id: item.id,
            title: item.title,
            todoDescription: item.description,
            isCompleted: item.isCompleted,
            statusRaw: item.status.rawValue,
            priorityRaw: item.priority.rawValue,
            createdAt: item.createdAt,
            plannedDate: item.plannedDate,
            endDate: item.endDate,
            workStartedAt: item.workStartedAt,
            completedDate: item.completedDate,
            completionDurationSeconds: item.completionDurationSeconds,
            timeSlotStartHour: item.timeSlotStartHour,
            timeSlotStartMinute: item.timeSlotStartMinute,
            timeSlotEndHour: item.timeSlotEndHour,
            timeSlotEndMinute: item.timeSlotEndMinute,
            plannedTimeSlotHour: item.plannedTimeSlotHour,
            plannedTimeSlotMinute: item.plannedTimeSlotMinute,
            taskCategoryId: item.taskCategoryId,
            repeatModeRaw: item.repeatMode.rawValue,
            weeklyRepeatWeekdaysJSON: intSetData(item.weeklyRepeatWeekdays),
            monthlyRepeatDaysJSON: intSetData(item.monthlyRepeatDays),
            monthlyRepeatUsesLastDayFallback: item.monthlyRepeatUsesLastDayFallback,
            yearlyRepeatDaysJSON: yearlyRepeatDaysData(item.yearlyRepeatDays),
            repeatLimitKindRaw: item.repeatLimitKind.rawValue,
            repeatUntilDate: item.repeatUntilDate,
            repeatMaxOccurrences: item.repeatMaxOccurrences,
            customRepeatInterval: item.customRepeatInterval,
            customRepeatPeriodRaw: item.customRepeatPeriod.rawValue,
            recurringCycleStatusRaw: item.recurringCycleStatus.rawValue,
            recurringCompletedOccurrences: item.recurringCompletedOccurrences,
            recurringCompletionRateBasis: item.recurringCompletionRateBasis
        )
    }

    // MARK: - Task

    static func taskItem(from record: SDTaskRecord) -> TaskItem {
        TaskItem(
            id: record.id,
            title: record.title,
            description: record.taskDescription,
            isCompleted: record.isCompleted,
            parentId: record.parentId,
            subtasks: []
        )
    }

    static func taskRecord(from item: TaskItem) -> SDTaskRecord {
        SDTaskRecord(
            id: item.id,
            title: item.title,
            taskDescription: item.description,
            isCompleted: item.isCompleted,
            parentId: item.parentId
        )
    }
}

extension OutfitPlan: Codable {
    enum CodingKeys: String, CodingKey {
        case topItemIds, bottomItemIds, shoesItemIds, hatItemIds, accessoryItemIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topItemIds = try container.decodeIfPresent([UUID].self, forKey: .topItemIds) ?? []
        bottomItemIds = try container.decodeIfPresent([UUID].self, forKey: .bottomItemIds) ?? []
        shoesItemIds = try container.decodeIfPresent([UUID].self, forKey: .shoesItemIds) ?? []
        hatItemIds = try container.decodeIfPresent([UUID].self, forKey: .hatItemIds) ?? []
        accessoryItemIds = try container.decodeIfPresent([UUID].self, forKey: .accessoryItemIds) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(topItemIds, forKey: .topItemIds)
        try container.encode(bottomItemIds, forKey: .bottomItemIds)
        try container.encode(shoesItemIds, forKey: .shoesItemIds)
        try container.encode(hatItemIds, forKey: .hatItemIds)
        try container.encode(accessoryItemIds, forKey: .accessoryItemIds)
    }
}
