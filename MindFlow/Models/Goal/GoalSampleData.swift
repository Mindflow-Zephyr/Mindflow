import Foundation

enum GoalSampleData {
    static func makeSampleGoals(for categoryId: UUID) -> [GoalItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let specs: [(String, String?, GoalStatus, Int, Int?, String?)] = [
            ("完成 SwiftUI 进阶课程", "每周 3 次学习", .inProgress, 72, 14, "核心开发"),
            ("减重 5 公斤", "控制饮食 + 运动", .inProgress, 45, 90, nil),
            ("阅读 12 本书", nil, .inProgress, 58, 180, nil),
            ("建立紧急备用金", "存够 6 个月生活费", .inProgress, 30, 120, nil),
            ("完成马拉松训练", "半马完赛", .inProgress, 62, 45, nil),
            ("整理家庭相册", nil, .inProgress, 20, 60, nil),
            ("学习日语 N3", "每日 30 分钟", .inProgress, 38, 150, nil),
            ("装修客厅", "简约风格", .inProgress, 55, 30, nil),
            ("完成年度体检", nil, .inProgress, 80, 7, nil),
            ("通过驾照科目三", nil, .completed, 100, -30, "发布准备"),
            ("完成 Q1 项目交付", nil, .completed, 100, -60, "产品文档"),
            ("养成早睡习惯", "23:00 前入睡", .completed, 100, -90, "生活习惯"),
            ("完成厨房收纳", nil, .completed, 100, -120, "居住整理"),
            ("读完《深度工作》", nil, .completed, 100, -45, "自我提升"),
            ("完成 30 天冥想", nil, .completed, 100, -75, "生活习惯"),
            ("整理衣柜换季", nil, .completed, 100, -100, "居住整理"),
            ("完成摄影作品集", nil, .completed, 100, -150, "核心开发"),
            ("通过英语六级", nil, .completed, 100, -200, "自我提升"),
            ("完成家庭旅行计划", "日本关西", .completed, 100, -180, "旅行计划"),
            ("建立记账习惯", nil, .completed, 100, -210, "财务管理"),
            ("学习游泳", nil, .completed, 100, -240, "运动健康"),
            ("完成副业网站", nil, .completed, 100, -270, "核心开发"),
            ("吉他入门", "时间不够先暂停", .paused, 15, 60, nil),
            ("视频剪辑", nil, .paused, 10, 90, nil),
            ("陶艺体验课", nil, .paused, 5, 120, nil)
        ]

        return specs.map { title, note, status, progress, dayOffset, stageTitle in
            let targetDate = dayOffset.flatMap { calendar.date(byAdding: .day, value: $0, to: today) }
            return GoalItem(
                categoryId: categoryId,
                title: title,
                note: note,
                status: status,
                progress: progress,
                targetDate: targetDate,
                stageTitle: stageTitle
            )
        }
    }
}
