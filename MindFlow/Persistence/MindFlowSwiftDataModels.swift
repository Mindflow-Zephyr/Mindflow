import Foundation
import SwiftData

// MARK: - App Metadata

@Model
final class SDAppMetadataRecord {
    @Attribute(.unique) var id: String
    var hasSeeded: Bool
    var nextTaskId: Int

    init(id: String = "default", hasSeeded: Bool = false, nextTaskId: Int = 1) {
        self.id = id
        self.hasSeeded = hasSeeded
        self.nextTaskId = nextTaskId
    }
}

// MARK: - Life / Dashboard

@Model
final class SDLifeCategoryRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var icon: String
    var accentHex: String
    var parentId: UUID?

    init(id: UUID, title: String, icon: String, accentHex: String, parentId: UUID?) {
        self.id = id
        self.title = title
        self.icon = icon
        self.accentHex = accentHex
        self.parentId = parentId
    }
}

@Model
final class SDLifeDetailItemRecord {
    @Attribute(.unique) var id: UUID
    var categoryId: UUID
    var title: String
    var note: String?

    init(id: UUID, categoryId: UUID, title: String, note: String?) {
        self.id = id
        self.categoryId = categoryId
        self.title = title
        self.note = note
    }
}

@Model
final class SDWardrobeItemRecord {
    @Attribute(.unique) var id: UUID
    var categoryId: UUID
    var name: String
    var wardrobeGroup: String
    var wardrobeType: String
    var brand: String
    var color: String
    var fabric: String
    var season: String
    var purchasePrice: Double
    var purchaseDate: Date
    var wearCount: Int
    var lastWearDate: Date?
    var scoreAppearance: Int?
    var scoreFabricComfort: Int?
    var scoreFit: Int?
    var scoreTexture: Int?
    var scorePersonalPreference: Int?

    init(
        id: UUID,
        categoryId: UUID,
        name: String,
        wardrobeGroup: String,
        wardrobeType: String,
        brand: String,
        color: String,
        fabric: String,
        season: String,
        purchasePrice: Double,
        purchaseDate: Date,
        wearCount: Int,
        lastWearDate: Date?,
        scoreAppearance: Int?,
        scoreFabricComfort: Int?,
        scoreFit: Int?,
        scoreTexture: Int?,
        scorePersonalPreference: Int?
    ) {
        self.id = id
        self.categoryId = categoryId
        self.name = name
        self.wardrobeGroup = wardrobeGroup
        self.wardrobeType = wardrobeType
        self.brand = brand
        self.color = color
        self.fabric = fabric
        self.season = season
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.wearCount = wearCount
        self.lastWearDate = lastWearDate
        self.scoreAppearance = scoreAppearance
        self.scoreFabricComfort = scoreFabricComfort
        self.scoreFit = scoreFit
        self.scoreTexture = scoreTexture
        self.scorePersonalPreference = scorePersonalPreference
    }
}

@Model
final class SDMenuItemRecord {
    @Attribute(.unique) var id: UUID
    var categoryId: UUID
    var name: String
    var cuisineRaw: String
    var statusRaw: String
    var cookCount: Int

    init(id: UUID, categoryId: UUID, name: String, cuisineRaw: String, statusRaw: String, cookCount: Int) {
        self.id = id
        self.categoryId = categoryId
        self.name = name
        self.cuisineRaw = cuisineRaw
        self.statusRaw = statusRaw
        self.cookCount = cookCount
    }
}

@Model
final class SDOutfitPlanRecord {
    @Attribute(.unique) var categoryId: UUID
    var planJSON: Data

    init(categoryId: UUID, planJSON: Data) {
        self.categoryId = categoryId
        self.planJSON = planJSON
    }
}

@Model
final class SDOOTDHistoryRecord {
    @Attribute(.unique) var id: UUID
    var categoryId: UUID
    var date: Date
    var planJSON: Data
    var wearCountApplied: Bool

    init(id: UUID, categoryId: UUID, date: Date, planJSON: Data, wearCountApplied: Bool) {
        self.id = id
        self.categoryId = categoryId
        self.date = date
        self.planJSON = planJSON
        self.wearCountApplied = wearCountApplied
    }
}

@Model
final class SDOutfitPageSettingsRecord {
    @Attribute(.unique) var id: String
    var showWardrobeLibrary: Bool
    var showOOTDPlan: Bool
    var showOOTDCalendar: Bool
    var showFavoriteRanking: Bool
    var showActionCards: Bool

    init(
        id: String = "default",
        showWardrobeLibrary: Bool = true,
        showOOTDPlan: Bool = true,
        showOOTDCalendar: Bool = true,
        showFavoriteRanking: Bool = true,
        showActionCards: Bool = true
    ) {
        self.id = id
        self.showWardrobeLibrary = showWardrobeLibrary
        self.showOOTDPlan = showOOTDPlan
        self.showOOTDCalendar = showOOTDCalendar
        self.showFavoriteRanking = showFavoriteRanking
        self.showActionCards = showActionCards
    }
}

// MARK: - Todo

@Model
final class SDTodoRecord {
    @Attribute(.unique) var id: Int
    var title: String
    var todoDescription: String?
    var isCompleted: Bool
    var statusRaw: String
    var priorityRaw: String
    var createdAt: Date
    var plannedDate: Date?
    var endDate: Date?
    var workStartedAt: Date?
    var completedDate: Date?
    var completionDurationSeconds: Int?
    var timeSlotStartHour: Int
    var timeSlotStartMinute: Int
    var timeSlotEndHour: Int
    var timeSlotEndMinute: Int
    var plannedTimeSlotHour: Int
    var plannedTimeSlotMinute: Int
    var taskCategoryId: Int?
    var repeatModeRaw: String
    var weeklyRepeatWeekdaysJSON: Data
    var monthlyRepeatDaysJSON: Data
    var monthlyRepeatUsesLastDayFallback: Bool
    var yearlyRepeatDaysJSON: Data
    var repeatLimitKindRaw: String
    var repeatUntilDate: Date?
    var repeatMaxOccurrences: Int?
    var customRepeatInterval: Int
    var customRepeatPeriodRaw: String
    var recurringCycleStatusRaw: String
    var recurringCompletedOccurrences: Int
    var recurringCompletionRateBasis: Int?

    init(
        id: Int,
        title: String,
        todoDescription: String?,
        isCompleted: Bool,
        statusRaw: String,
        priorityRaw: String,
        createdAt: Date,
        plannedDate: Date?,
        endDate: Date?,
        workStartedAt: Date?,
        completedDate: Date?,
        completionDurationSeconds: Int?,
        timeSlotStartHour: Int,
        timeSlotStartMinute: Int,
        timeSlotEndHour: Int,
        timeSlotEndMinute: Int,
        plannedTimeSlotHour: Int,
        plannedTimeSlotMinute: Int,
        taskCategoryId: Int?,
        repeatModeRaw: String,
        weeklyRepeatWeekdaysJSON: Data,
        monthlyRepeatDaysJSON: Data,
        monthlyRepeatUsesLastDayFallback: Bool,
        yearlyRepeatDaysJSON: Data,
        repeatLimitKindRaw: String,
        repeatUntilDate: Date?,
        repeatMaxOccurrences: Int?,
        customRepeatInterval: Int,
        customRepeatPeriodRaw: String,
        recurringCycleStatusRaw: String,
        recurringCompletedOccurrences: Int,
        recurringCompletionRateBasis: Int?
    ) {
        self.id = id
        self.title = title
        self.todoDescription = todoDescription
        self.isCompleted = isCompleted
        self.statusRaw = statusRaw
        self.priorityRaw = priorityRaw
        self.createdAt = createdAt
        self.plannedDate = plannedDate
        self.endDate = endDate
        self.workStartedAt = workStartedAt
        self.completedDate = completedDate
        self.completionDurationSeconds = completionDurationSeconds
        self.timeSlotStartHour = timeSlotStartHour
        self.timeSlotStartMinute = timeSlotStartMinute
        self.timeSlotEndHour = timeSlotEndHour
        self.timeSlotEndMinute = timeSlotEndMinute
        self.plannedTimeSlotHour = plannedTimeSlotHour
        self.plannedTimeSlotMinute = plannedTimeSlotMinute
        self.taskCategoryId = taskCategoryId
        self.repeatModeRaw = repeatModeRaw
        self.weeklyRepeatWeekdaysJSON = weeklyRepeatWeekdaysJSON
        self.monthlyRepeatDaysJSON = monthlyRepeatDaysJSON
        self.monthlyRepeatUsesLastDayFallback = monthlyRepeatUsesLastDayFallback
        self.yearlyRepeatDaysJSON = yearlyRepeatDaysJSON
        self.repeatLimitKindRaw = repeatLimitKindRaw
        self.repeatUntilDate = repeatUntilDate
        self.repeatMaxOccurrences = repeatMaxOccurrences
        self.customRepeatInterval = customRepeatInterval
        self.customRepeatPeriodRaw = customRepeatPeriodRaw
        self.recurringCycleStatusRaw = recurringCycleStatusRaw
        self.recurringCompletedOccurrences = recurringCompletedOccurrences
        self.recurringCompletionRateBasis = recurringCompletionRateBasis
    }
}

// MARK: - Task

@Model
final class SDTaskRecord {
    @Attribute(.unique) var id: Int
    var title: String
    var taskDescription: String?
    var isCompleted: Bool
    var parentId: Int?

    init(id: Int, title: String, taskDescription: String?, isCompleted: Bool, parentId: Int?) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.isCompleted = isCompleted
        self.parentId = parentId
    }
}
