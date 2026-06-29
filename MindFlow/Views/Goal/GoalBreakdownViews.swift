import SwiftUI

// MARK: - Goal Breakdown Card

struct GoalBreakdownCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    let goalId: UUID

    @State private var collapsedSectionIds: Set<UUID> = []

    private var sections: [GoalBreakdownSection] {
        viewModel.breakdownSections(for: goalId)
    }

    var body: some View {
        if sections.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("目标拆分")
                    .font(.headline.weight(.bold))
                    .foregroundColor(Color(hex: "#2B5748"))
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                HStack(alignment: .top, spacing: 8) {
                    GoalBreakdownUnifiedRail(
                        sections: sections,
                        collapsedSectionIds: collapsedSectionIds,
                        taskCount: { section in
                            viewModel.breakdownTasks(for: section.id).count
                        },
                        onToggleCollapse: toggleSection
                    )

                    VStack(spacing: 0) {
                        ForEach(sections) { section in
                            GoalBreakdownSectionContent(
                                section: section,
                                tasks: viewModel.breakdownTasks(for: section.id),
                                isCollapsed: collapsedSectionIds.contains(section.id),
                                onTaskTap: { task in
                                    viewModel.updateBreakdownTaskStatus(id: task.id, status: task.status.next)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
            .todoPanelCardChrome()
        }
    }

    private func toggleSection(_ id: UUID) {
        withAnimation(GoalBreakdownMotion.expandCollapse) {
            if collapsedSectionIds.contains(id) {
                collapsedSectionIds.remove(id)
            } else {
                collapsedSectionIds.insert(id)
            }
        }
    }
}

private enum GoalBreakdownMotion {
    static let expandCollapse = Animation.spring(response: 0.38, dampingFraction: 0.84)
}

private enum GoalBreakdownSectionMetrics {
    static let expandNodeSize: CGFloat = 24
    static let headerHeight: CGFloat = 28
    static let trunkStartY: CGFloat = 5
    static let titleFont: Font = .headline.weight(.bold)
    static let progressBarHeight: CGFloat = 8
    static let progressBarWidth: CGFloat = 96
    static let taskRowHeight: CGFloat = 52
    static let taskBranchWidth: CGFloat = 50
    static let sectionBottomPadding: CGFloat = 12
    static let lineWidth: CGFloat = 2
    static let timelineColor = Color(hex: "#2B5748")
    /// 右侧内容区左边距，使子任务标题与短横线末端对齐（rail + spacing + branch 余量）
    static let taskRowLeadingInset: CGFloat = 30

    static func sectionHeight(isCollapsed: Bool, taskCount: Int) -> CGFloat {
        if isCollapsed {
            return headerHeight
        }
        return headerHeight + CGFloat(taskCount) * taskRowHeight + sectionBottomPadding
    }
}

// MARK: - Unified Timeline Rail

private struct GoalBreakdownUnifiedRail: View {
    let sections: [GoalBreakdownSection]
    let collapsedSectionIds: Set<UUID>
    let taskCount: (GoalBreakdownSection) -> Int
    let onToggleCollapse: (UUID) -> Void

    private var sectionHeights: [CGFloat] {
        sections.map { section in
            let collapsed = collapsedSectionIds.contains(section.id)
            return GoalBreakdownSectionMetrics.sectionHeight(
                isCollapsed: collapsed,
                taskCount: taskCount(section)
            )
        }
    }

    private var totalHeight: CGFloat {
        sectionHeights.reduce(0, +)
    }

    private var trunkX: CGFloat {
        GoalBreakdownSectionMetrics.expandNodeSize / 2
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                let color = GoalBreakdownSectionMetrics.timelineColor
                let lineWidth = GoalBreakdownSectionMetrics.lineWidth
                let branchWidth = GoalBreakdownSectionMetrics.taskBranchWidth

                var trunk = Path()
                trunk.move(to: CGPoint(x: trunkX, y: GoalBreakdownSectionMetrics.trunkStartY))
                trunk.addLine(to: CGPoint(x: trunkX, y: totalHeight))
                context.stroke(trunk, with: .color(color), lineWidth: lineWidth)

                var blockTop: CGFloat = 0
                for (index, section) in sections.enumerated() {
                    let collapsed = collapsedSectionIds.contains(section.id)
                    let count = taskCount(section)

                    if !collapsed, count > 0 {
                        for taskIndex in 0..<count {
                            let branchY = blockTop
                                + GoalBreakdownSectionMetrics.headerHeight
                                + (CGFloat(taskIndex) + 0.5) * GoalBreakdownSectionMetrics.taskRowHeight
                            var branch = Path()
                            branch.move(to: CGPoint(x: trunkX, y: branchY))
                            branch.addLine(to: CGPoint(x: trunkX + branchWidth, y: branchY))
                            context.stroke(branch, with: .color(color), lineWidth: lineWidth)
                        }
                    }

                    blockTop += sectionHeights[index]
                }
            }
            .frame(
                width: GoalBreakdownSectionMetrics.expandNodeSize,
                height: totalHeight
            )
            .allowsHitTesting(false)

            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                let blockTop = sectionHeights.prefix(index).reduce(0, +)
                let nodeY = blockTop + (GoalBreakdownSectionMetrics.headerHeight - GoalBreakdownSectionMetrics.expandNodeSize) / 2

                GoalBreakdownExpandNode(
                    isCollapsed: collapsedSectionIds.contains(section.id),
                    action: { onToggleCollapse(section.id) }
                )
                .offset(x: 0, y: nodeY)
            }
        }
        .frame(
            width: GoalBreakdownSectionMetrics.expandNodeSize,
            height: totalHeight
        )
    }
}

// MARK: - Section Content (right column)

private struct GoalBreakdownSectionContent: View {
    let section: GoalBreakdownSection
    let tasks: [GoalBreakdownTask]
    let isCollapsed: Bool
    let onTaskTap: (GoalBreakdownTask) -> Void

    private var completedCount: Int {
        tasks.filter { $0.status == .completed }.count
    }

    private var sectionHeight: CGFloat {
        GoalBreakdownSectionMetrics.sectionHeight(isCollapsed: isCollapsed, taskCount: tasks.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GoalBreakdownSectionHeader(
                title: section.title,
                completedCount: completedCount,
                totalCount: tasks.count
            )

            if !isCollapsed {
                VStack(spacing: 0) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        GoalBreakdownTaskRow(task: task) {
                            onTaskTap(task)
                        }

                        if index < tasks.count - 1 {
                            Divider()
                                .padding(.leading, GoalBreakdownSectionMetrics.taskRowLeadingInset)
                        }
                    }
                }
                .padding(.bottom, GoalBreakdownSectionMetrics.sectionBottomPadding)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                    )
                )
            }
        }
        .frame(height: sectionHeight, alignment: .top)
        .animation(GoalBreakdownMotion.expandCollapse, value: isCollapsed)
    }
}

private struct GoalBreakdownExpandNode: View {
    let isCollapsed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(
                        width: GoalBreakdownSectionMetrics.expandNodeSize,
                        height: GoalBreakdownSectionMetrics.expandNodeSize
                    )
                Circle()
                    .strokeBorder(GoalBreakdownSectionMetrics.timelineColor, lineWidth: 1.5)
                    .frame(
                        width: GoalBreakdownSectionMetrics.expandNodeSize,
                        height: GoalBreakdownSectionMetrics.expandNodeSize
                    )
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(GoalBreakdownSectionMetrics.timelineColor)
                    .rotationEffect(.degrees(isCollapsed ? 0 : 180))
                    .animation(GoalBreakdownMotion.expandCollapse, value: isCollapsed)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct GoalBreakdownSectionHeader: View {
    let title: String
    let completedCount: Int
    let totalCount: Int

    private let accent = Color(hex: "#2B5748")
    private let muted = Color(hex: "#9CA3AF")

    private var isFullyComplete: Bool {
        totalCount > 0 && completedCount == totalCount
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(GoalBreakdownSectionMetrics.titleFont)
                .foregroundStyle(accent)
                .lineLimit(1)

            Spacer(minLength: 8)

            HStack(alignment: .center, spacing: 8) {
                GoalBreakdownSectionProgressBar(
                    completed: completedCount,
                    total: totalCount
                )
                .frame(
                    width: GoalBreakdownSectionMetrics.progressBarWidth,
                    height: GoalBreakdownSectionMetrics.progressBarHeight
                )

                HStack(spacing: 0) {
                    Text("\(completedCount)")
                        .foregroundStyle(completedCount > 0 ? accent : muted)
                    Text("/")
                        .foregroundStyle(isFullyComplete ? accent : muted)
                    Text("\(totalCount)")
                        .foregroundStyle(isFullyComplete ? accent : muted)
                }
                .font(.subheadline.weight(.semibold))
                .fixedSize()
            }
        }
        .frame(height: GoalBreakdownSectionMetrics.headerHeight, alignment: .center)
    }
}

private struct GoalBreakdownSectionProgressBar: View {
    let completed: Int
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color(hex: "#E5E7EB"))
                Capsule(style: .continuous)
                    .fill(Color(hex: "#2B5748"))
                    .frame(width: total > 0 ? geo.size.width * CGFloat(completed) / CGFloat(total) : 0)
            }
        }
    }
}

private struct GoalBreakdownTaskRow: View {
    let task: GoalBreakdownTask
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                GoalBreakdownTaskStatusCapsule(status: task.status)
            }
            .padding(.leading, GoalBreakdownSectionMetrics.taskRowLeadingInset)
            .padding(.trailing, 12)
            .frame(height: GoalBreakdownSectionMetrics.taskRowHeight, alignment: .center)
        }
        .buttonStyle(.plain)
    }
}

private struct GoalBreakdownTaskStatusCapsule: View {
    let status: GoalBreakdownTaskStatus

    var body: some View {
        Text(status.title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(backgroundColor)
            )
            .fixedSize()
    }

    private var foregroundColor: Color {
        switch status {
        case .notStarted: return Color(hex: "#6B7280")
        case .inProgress: return Color(hex: "#2563EB")
        case .completed: return Color(hex: "#16A34A")
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .notStarted: return Color(hex: "#F3F4F6")
        case .inProgress: return Color(hex: "#DBEAFE")
        case .completed: return Color(hex: "#DCFCE7")
        }
    }
}
