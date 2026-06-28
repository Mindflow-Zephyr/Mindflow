import Foundation
import SwiftData

extension Notification.Name {
    static let mindFlowDataDidReset = Notification.Name("mindFlowDataDidReset")
}

enum MindFlowModelContainerFactory {
    static let schema = Schema([
        SDAppMetadataRecord.self,
        SDLifeCategoryRecord.self,
        SDLifeDetailItemRecord.self,
        SDWardrobeItemRecord.self,
        SDMenuItemRecord.self,
        SDOutfitPlanRecord.self,
        SDOOTDHistoryRecord.self,
        SDOutfitPageSettingsRecord.self,
        SDTodoRecord.self,
        SDTaskRecord.self
    ])

    static let shared: ModelContainer = {
        if let container = makeContainer() {
            return container
        }
        deletePersistentStores()
        if let container = makeContainer() {
            return container
        }
        fatalError("无法创建 SwiftData 容器")
    }()

    private static func makeContainer() -> ModelContainer? {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try? ModelContainer(for: schema, configurations: [configuration])
    }

    private static func deletePersistentStores() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return }

        let fileManager = FileManager.default
        for baseName in ["default.store", "MindFlow.store"] {
            for suffix in ["", "-wal", "-shm"] {
                let url = appSupport.appendingPathComponent(baseName + suffix)
                guard fileManager.fileExists(atPath: url.path) else { continue }
                try? fileManager.removeItem(at: url)
            }
        }
    }
}

@MainActor
final class MindFlowRepository {
    static let shared = MindFlowRepository()

    /// 数据结构版本；递增后会触发全量清除并按最新示例数据重新初始化。
    private static let currentDataSchemaVersion = 2
    private static let dataSchemaVersionKey = "mindflow.dataSchemaVersion"

    let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    private init(container: ModelContainer = MindFlowModelContainerFactory.shared) {
        self.container = container
        bootstrapIfNeeded()
    }

    // MARK: - Bootstrap

    private func bootstrapIfNeeded() {
        let metadata = appMetadata()
        let storedVersion = UserDefaults.standard.integer(forKey: Self.dataSchemaVersionKey)
        if storedVersion < Self.currentDataSchemaVersion {
            performFullReset(metadata: metadata)
            return
        }
        guard !metadata.hasSeeded else { return }
        seedSampleData(into: metadata)
    }

    func resetAllData() {
        performFullReset(metadata: appMetadata())
        NotificationCenter.default.post(name: .mindFlowDataDidReset, object: nil)
    }

    private func performFullReset(metadata: SDAppMetadataRecord) {
        wipeAllRecords(except: metadata)
        clearAuxiliaryUserDefaults()
        metadata.hasSeeded = false
        metadata.nextTaskId = 1
        UserDefaults.standard.set(Self.currentDataSchemaVersion, forKey: Self.dataSchemaVersionKey)
        saveContext()
        seedSampleData(into: metadata)
    }

    private func seedSampleData(into metadata: SDAppMetadataRecord) {
        guard !metadata.hasSeeded else { return }

        let dashboard = DashboardViewModel.makeSampleDashboardState()
        saveDashboard(
            categories: dashboard.categories,
            detailItems: dashboard.detailItems,
            wardrobeItems: dashboard.wardrobeItems,
            menuItems: dashboard.menuItems,
            outfitPlansByCategoryId: dashboard.outfitPlansByCategoryId,
            ootdHistoryRecords: dashboard.ootdHistoryRecords,
            outfitPageCardSettings: dashboard.outfitPageCardSettings
        )

        saveTodos(TodoViewModel.makeSampleTodos())
        saveTasks(TaskSampleData.makeSampleTasks(), nextTaskId: 7)

        metadata.hasSeeded = true
        saveContext()
    }

    private func wipeAllRecords(except metadata: SDAppMetadataRecord) {
        deleteAll(SDLifeCategoryRecord.self)
        deleteAll(SDLifeDetailItemRecord.self)
        deleteAll(SDWardrobeItemRecord.self)
        deleteAll(SDMenuItemRecord.self)
        deleteAll(SDOutfitPlanRecord.self)
        deleteAll(SDOOTDHistoryRecord.self)
        deleteAll(SDOutfitPageSettingsRecord.self)
        deleteAll(SDTodoRecord.self)
        deleteAll(SDTaskRecord.self)

        let otherMetadata = (try? context.fetch(FetchDescriptor<SDAppMetadataRecord>()))?
            .filter { $0.id != metadata.id } ?? []
        for record in otherMetadata {
            context.delete(record)
        }
        saveContext()
    }

    private func deleteAll<Record: PersistentModel>(_ type: Record.Type) {
        let records = (try? context.fetch(FetchDescriptor<Record>())) ?? []
        for record in records {
            context.delete(record)
        }
    }

    private func clearAuxiliaryUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "outfitResearchTimeSeconds")
        defaults.removeObject(forKey: "mindflow.dailyWater.date")
        defaults.removeObject(forKey: "mindflow.dailyWater.ml")
    }

    private func appMetadata() -> SDAppMetadataRecord {
        let descriptor = FetchDescriptor<SDAppMetadataRecord>(
            predicate: #Predicate { $0.id == "default" }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let record = SDAppMetadataRecord()
        context.insert(record)
        return record
    }

    func saveContext() {
        do {
            try context.save()
        } catch {
            print("SwiftData 保存失败: \(error)")
        }
    }

    // MARK: - Dashboard

    struct DashboardState {
        var categories: [LifeCategory]
        var detailItems: [LifeDetailItem]
        var wardrobeItems: [WardrobeItem]
        var menuItems: [MenuItem]
        var outfitPlansByCategoryId: [UUID: OutfitPlan]
        var ootdHistoryRecords: [OOTDHistoryRecord]
        var outfitPageCardSettings: OutfitPageCardSettings
    }

    func loadDashboard() -> DashboardState {
        let categories = (try? context.fetch(FetchDescriptor<SDLifeCategoryRecord>()))?
            .map(MindFlowDataMapper.lifeCategory(from:)) ?? []
        let detailItems = (try? context.fetch(FetchDescriptor<SDLifeDetailItemRecord>()))?
            .map(MindFlowDataMapper.lifeDetailItem(from:)) ?? []
        let wardrobeItems = (try? context.fetch(FetchDescriptor<SDWardrobeItemRecord>()))?
            .map(MindFlowDataMapper.wardrobeItem(from:)) ?? []
        let menuItems = (try? context.fetch(FetchDescriptor<SDMenuItemRecord>()))?
            .compactMap(MindFlowDataMapper.menuItem(from:)) ?? []
        let outfitPlans = (try? context.fetch(FetchDescriptor<SDOutfitPlanRecord>())) ?? []
        let outfitPlansByCategoryId = Dictionary(
            uniqueKeysWithValues: outfitPlans.map { ($0.categoryId, MindFlowDataMapper.outfitPlan(from: $0.planJSON)) }
        )
        let ootdHistoryRecords = (try? context.fetch(FetchDescriptor<SDOOTDHistoryRecord>()))?
            .map(MindFlowDataMapper.ootdHistoryRecord(from:)) ?? []
        let settingsRecord = (try? context.fetch(FetchDescriptor<SDOutfitPageSettingsRecord>(
            predicate: #Predicate { $0.id == "default" }
        )))?.first
        let outfitPageCardSettings = settingsRecord.map(MindFlowDataMapper.outfitPageSettings(from:))
            ?? OutfitPageCardSettings()

        return DashboardState(
            categories: categories,
            detailItems: detailItems,
            wardrobeItems: wardrobeItems,
            menuItems: menuItems,
            outfitPlansByCategoryId: outfitPlansByCategoryId,
            ootdHistoryRecords: ootdHistoryRecords,
            outfitPageCardSettings: outfitPageCardSettings
        )
    }

    func saveDashboard(
        categories: [LifeCategory],
        detailItems: [LifeDetailItem],
        wardrobeItems: [WardrobeItem],
        menuItems: [MenuItem],
        outfitPlansByCategoryId: [UUID: OutfitPlan],
        ootdHistoryRecords: [OOTDHistoryRecord],
        outfitPageCardSettings: OutfitPageCardSettings
    ) {
        syncUUIDRecords(
            existing: (try? context.fetch(FetchDescriptor<SDLifeCategoryRecord>())) ?? [],
            desiredIDs: Set(categories.map(\.id)),
            recordID: \.id,
            models: categories,
            modelID: \.id,
            insert: MindFlowDataMapper.lifeCategoryRecord(from:),
            update: { record, model in
                record.title = model.title
                record.icon = model.icon
                record.accentHex = model.accentHex
                record.parentId = model.parentId
            }
        )

        syncUUIDRecords(
            existing: (try? context.fetch(FetchDescriptor<SDLifeDetailItemRecord>())) ?? [],
            desiredIDs: Set(detailItems.map(\.id)),
            recordID: \.id,
            models: detailItems,
            modelID: \.id,
            insert: MindFlowDataMapper.lifeDetailItemRecord(from:),
            update: { record, model in
                record.categoryId = model.categoryId
                record.title = model.title
                record.note = model.note
            }
        )

        syncUUIDRecords(
            existing: (try? context.fetch(FetchDescriptor<SDWardrobeItemRecord>())) ?? [],
            desiredIDs: Set(wardrobeItems.map(\.id)),
            recordID: \.id,
            models: wardrobeItems,
            modelID: \.id,
            insert: MindFlowDataMapper.wardrobeItemRecord(from:),
            update: { record, model in
                record.categoryId = model.categoryId
                record.name = model.name
                record.wardrobeGroup = model.wardrobeGroup
                record.wardrobeType = model.wardrobeType
                record.brand = model.brand
                record.color = model.color
                record.fabric = model.fabric
                record.season = model.season
                record.purchasePrice = model.purchasePrice
                record.purchaseDate = model.purchaseDate
                record.wearCount = model.wearCount
                record.lastWearDate = model.lastWearDate
                record.scoreAppearance = model.favoriteScores.appearance
                record.scoreFabricComfort = model.favoriteScores.fabricComfort
                record.scoreFit = model.favoriteScores.fit
                record.scoreTexture = model.favoriteScores.texture
                record.scorePersonalPreference = model.favoriteScores.personalPreference
            }
        )

        syncUUIDRecords(
            existing: (try? context.fetch(FetchDescriptor<SDMenuItemRecord>())) ?? [],
            desiredIDs: Set(menuItems.map(\.id)),
            recordID: \.id,
            models: menuItems,
            modelID: \.id,
            insert: MindFlowDataMapper.menuItemRecord(from:),
            update: { record, model in
                record.categoryId = model.categoryId
                record.name = model.name
                record.cuisineRaw = model.cuisine.rawValue
                record.statusRaw = model.status.rawValue
                record.cookCount = model.cookCount
            }
        )

        let existingPlans = (try? context.fetch(FetchDescriptor<SDOutfitPlanRecord>())) ?? []
        let desiredPlanIDs = Set(outfitPlansByCategoryId.keys)
        for record in existingPlans where !desiredPlanIDs.contains(record.categoryId) {
            context.delete(record)
        }
        for (categoryId, plan) in outfitPlansByCategoryId {
            if let record = existingPlans.first(where: { $0.categoryId == categoryId }) {
                record.planJSON = MindFlowDataMapper.outfitPlanData(plan)
            } else {
                context.insert(SDOutfitPlanRecord(
                    categoryId: categoryId,
                    planJSON: MindFlowDataMapper.outfitPlanData(plan)
                ))
            }
        }

        syncUUIDRecords(
            existing: (try? context.fetch(FetchDescriptor<SDOOTDHistoryRecord>())) ?? [],
            desiredIDs: Set(ootdHistoryRecords.map(\.id)),
            recordID: \.id,
            models: ootdHistoryRecords,
            modelID: \.id,
            insert: MindFlowDataMapper.ootdHistoryEntity(from:),
            update: { record, model in
                record.categoryId = model.categoryId
                record.date = model.date
                record.planJSON = MindFlowDataMapper.outfitPlanData(model.plan)
                record.wearCountApplied = model.wearCountApplied
            }
        )

        let settingsDescriptor = FetchDescriptor<SDOutfitPageSettingsRecord>(
            predicate: #Predicate { $0.id == "default" }
        )
        if let settingsRecord = try? context.fetch(settingsDescriptor).first {
            settingsRecord.showWardrobeLibrary = outfitPageCardSettings.showWardrobeLibrary
            settingsRecord.showOOTDPlan = outfitPageCardSettings.showOOTDPlan
            settingsRecord.showOOTDCalendar = outfitPageCardSettings.showOOTDCalendar
            settingsRecord.showFavoriteRanking = outfitPageCardSettings.showFavoriteRanking
            settingsRecord.showActionCards = outfitPageCardSettings.showActionCards
        } else {
            context.insert(MindFlowDataMapper.outfitPageSettingsRecord(from: outfitPageCardSettings))
        }

        saveContext()
    }

    // MARK: - Todo

    func loadTodos() -> [TodoItem] {
        let records = (try? context.fetch(FetchDescriptor<SDTodoRecord>())) ?? []
        return records.map(MindFlowDataMapper.todoItem(from:)).sorted { $0.id < $1.id }
    }

    func saveTodos(_ todos: [TodoItem]) {
        syncIntRecords(
            existing: (try? context.fetch(FetchDescriptor<SDTodoRecord>())) ?? [],
            desiredIDs: Set(todos.map(\.id)),
            recordID: \.id,
            models: todos,
            modelID: \.id,
            insert: MindFlowDataMapper.todoRecord(from:),
            update: { record, model in
                let fresh = MindFlowDataMapper.todoRecord(from: model)
                record.title = fresh.title
                record.todoDescription = fresh.todoDescription
                record.isCompleted = fresh.isCompleted
                record.statusRaw = fresh.statusRaw
                record.priorityRaw = fresh.priorityRaw
                record.createdAt = fresh.createdAt
                record.plannedDate = fresh.plannedDate
                record.endDate = fresh.endDate
                record.workStartedAt = fresh.workStartedAt
                record.completedDate = fresh.completedDate
                record.completionDurationSeconds = fresh.completionDurationSeconds
                record.timeSlotStartHour = fresh.timeSlotStartHour
                record.timeSlotStartMinute = fresh.timeSlotStartMinute
                record.timeSlotEndHour = fresh.timeSlotEndHour
                record.timeSlotEndMinute = fresh.timeSlotEndMinute
                record.plannedTimeSlotHour = fresh.plannedTimeSlotHour
                record.plannedTimeSlotMinute = fresh.plannedTimeSlotMinute
                record.taskCategoryId = fresh.taskCategoryId
                record.repeatModeRaw = fresh.repeatModeRaw
                record.weeklyRepeatWeekdaysJSON = fresh.weeklyRepeatWeekdaysJSON
                record.monthlyRepeatDaysJSON = fresh.monthlyRepeatDaysJSON
                record.monthlyRepeatUsesLastDayFallback = fresh.monthlyRepeatUsesLastDayFallback
                record.yearlyRepeatDaysJSON = fresh.yearlyRepeatDaysJSON
                record.repeatLimitKindRaw = fresh.repeatLimitKindRaw
                record.repeatUntilDate = fresh.repeatUntilDate
                record.repeatMaxOccurrences = fresh.repeatMaxOccurrences
                record.customRepeatInterval = fresh.customRepeatInterval
                record.customRepeatPeriodRaw = fresh.customRepeatPeriodRaw
                record.recurringCycleStatusRaw = fresh.recurringCycleStatusRaw
                record.recurringCompletedOccurrences = fresh.recurringCompletedOccurrences
                record.recurringCompletionRateBasis = fresh.recurringCompletionRateBasis
            }
        )
        saveContext()
    }

    // MARK: - Task

    func loadTasks() -> (tasks: [TaskItem], nextTaskId: Int) {
        let records = (try? context.fetch(FetchDescriptor<SDTaskRecord>())) ?? []
        let tasks = records.map(MindFlowDataMapper.taskItem(from:))
        let metadata = appMetadata()
        let computedNext = (tasks.map(\.id).max() ?? 0) + 1
        let nextTaskId = max(metadata.nextTaskId, computedNext)
        return (tasks, nextTaskId)
    }

    func saveTasks(_ tasks: [TaskItem], nextTaskId: Int? = nil) {
        syncIntRecords(
            existing: (try? context.fetch(FetchDescriptor<SDTaskRecord>())) ?? [],
            desiredIDs: Set(tasks.map(\.id)),
            recordID: \.id,
            models: tasks,
            modelID: \.id,
            insert: MindFlowDataMapper.taskRecord(from:),
            update: { record, model in
                record.title = model.title
                record.taskDescription = model.description
                record.isCompleted = model.isCompleted
                record.parentId = model.parentId
            }
        )
        if let nextTaskId {
            appMetadata().nextTaskId = nextTaskId
        }
        saveContext()
    }

    // MARK: - Sync Helpers

    private func syncUUIDRecords<Record: PersistentModel, Model>(
        existing: [Record],
        desiredIDs: Set<UUID>,
        recordID: KeyPath<Record, UUID>,
        models: [Model],
        modelID: KeyPath<Model, UUID>,
        insert: (Model) -> Record,
        update: (Record, Model) -> Void
    ) {
        for record in existing where !desiredIDs.contains(record[keyPath: recordID]) {
            context.delete(record)
        }
        for model in models {
            let id = model[keyPath: modelID]
            if let record = existing.first(where: { $0[keyPath: recordID] == id }) {
                update(record, model)
            } else {
                context.insert(insert(model))
            }
        }
    }

    private func syncIntRecords<Record: PersistentModel, Model>(
        existing: [Record],
        desiredIDs: Set<Int>,
        recordID: KeyPath<Record, Int>,
        models: [Model],
        modelID: KeyPath<Model, Int>,
        insert: (Model) -> Record,
        update: (Record, Model) -> Void
    ) {
        for record in existing where !desiredIDs.contains(record[keyPath: recordID]) {
            context.delete(record)
        }
        for model in models {
            let id = model[keyPath: modelID]
            if let record = existing.first(where: { $0[keyPath: recordID] == id }) {
                update(record, model)
            } else {
                context.insert(insert(model))
            }
        }
    }
}
