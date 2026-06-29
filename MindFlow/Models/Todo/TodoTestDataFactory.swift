import Foundation

/// 批量生成自测用待办数据
enum TodoTestDataFactory {
    private static let titleTemplates: [String] = [
        "回复工作邮件", "整理项目文档", "团队站会准备", "代码审查 PR", "更新周报",
        "学习 Swift 并发", "阅读技术文章", "备份工作文件", "规划下周任务", "客户电话跟进",
        "晨跑 5 公里", "力量训练", "拉伸放松", "游泳 30 分钟", "瑜伽课",
        "超市采购", "整理客厅", "洗碗与厨房清洁", "浇花", "取快递",
        "搭配明日穿搭", "整理衣橱", "清洗运动鞋", "熨烫衬衫", "配饰收纳",
        "写读书笔记", "冥想 10 分钟", "每日饮水提醒", "护眼休息", "记账",
        "预约体检", "缴纳水电费", "联系朋友", "规划周末出行", "整理相册",
        "复习英语单词", "练习吉他", "看纪录片", "打扫卫生间", "换床品",
        "准备便当", "遛狗", "车辆保养预约", "整理书桌", "删除无用 App",
        "写感谢消息", "复盘今日待办", "设定明日三件事", "整理下载文件夹", "更新密码库"
    ]

    static func makeTestTodos(count: Int, startingId: Int) -> [TodoItem] {
        guard count > 0 else { return [] }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let categoryIds: [Int?] = [
            TodoLifeCategoryCatalog.workCategoryId,
            TodoLifeCategoryCatalog.fitnessCategoryId,
            TodoLifeCategoryCatalog.lifeCategoryId,
            TodoLifeCategoryCatalog.outfitCategoryId,
            nil
        ]
        let priorities: [TodoPriority] = [.p1, .p2, .p3, .p4]

        return (0..<count).map { offset in
            let id = startingId + offset
            let dayOffset = (offset % 38) - 7
            let plannedDay = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let startHour = 6 + (offset * 3) % 16
            let startMinute = (offset * 11) % 60
            let durationMinutes = 15 + (offset * 7) % 105
            let endComponents = TodoScheduling.endTimeComponents(
                startHour: startHour,
                startMinute: startMinute,
                durationMinutes: durationMinutes
            )
            let isCompleted = offset % 10 < 3
            let titleBase = titleTemplates[offset % titleTemplates.count]
            let title = "\(titleBase) #\(id)"
            let categoryId = categoryIds[offset % categoryIds.count]
            let priority = priorities[offset % priorities.count]
            let createdAt = calendar.date(byAdding: .hour, value: -(offset % 48), to: Date()) ?? Date()

            var item = TodoItem(
                id: id,
                title: title,
                description: offset % 4 == 0 ? "自测数据 · 索引 \(offset + 1)/\(count)" : nil,
                isCompleted: isCompleted,
                status: isCompleted ? .completed : .notStarted,
                priority: priority,
                createdAt: createdAt,
                plannedDate: plannedDay,
                completedDate: isCompleted ? plannedDay : nil,
                completionDurationSeconds: isCompleted ? durationMinutes * 60 : nil,
                timeSlotStartHour: startHour,
                timeSlotStartMinute: startMinute,
                timeSlotEndHour: endComponents.hour,
                timeSlotEndMinute: endComponents.minute,
                plannedTimeSlotHour: startHour,
                plannedTimeSlotMinute: startMinute,
                taskCategoryId: categoryId
            )

            if offset % 7 == 0 {
                item.repeatMode = .custom
                item.customRepeatInterval = 1 + (offset % 3)
                item.customRepeatPeriod = [.day, .week, .month][offset % 3]
                item.recurringCycleStatus = offset % 14 == 0 ? .paused : .active
                item.recurringCompletedOccurrences = offset % 20
                item.recurringCompletionRateBasis = 30
                if offset % 2 == 0 {
                    item.weeklyRepeatWeekdays = Set([1, 3, 5])
                }
            }

            return item
        }
    }
}
