import SwiftUI

// MARK: - Goal Category Screen

struct GoalCategoryScreen: View {
    @ObservedObject var viewModel: DashboardViewModel
    let category: LifeCategory

    @State private var showingAddGoal = false
    @State private var selectedGoal: GoalItem?
    @State private var listFilter: GoalListFilter = .inProgress

    private var goals: [GoalItem] {
        viewModel.goals(in: category.id)
    }

    private var filteredGoals: [GoalItem] {
        guard let status = listFilter.matchingStatus else { return goals }
        return goals.filter { $0.status == status }
    }

    private var stats: GoalOverviewStats {
        viewModel.goalStats(for: category.id)
    }

    var body: some View {
        ZStack {
            goalPageBackground

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(category.title)
                        .font(.title3.bold())
                        .padding(.horizontal, 20)

                    GoalOverviewCard(
                        stats: stats,
                        selectedFilter: listFilter,
                        onSelectFilter: { filter in
                            listFilter = filter
                        }
                    )
                        .padding(.horizontal, 20)

                    GoalListPanel(
                        goals: filteredGoals,
                        filter: listFilter,
                        onSelect: { selectedGoal = $0 }
                    )
                    .padding(.horizontal, 20)

                    Button {
                        showingAddGoal = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("新建目标")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Color(hex: "#2B5748"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
                .padding(.bottom, 8)
            }
            .mindFlowScrollContentBottomInset()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedGoal) { goal in
            GoalDetailView(viewModel: viewModel, goalId: goal.id)
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalSheet(viewModel: viewModel, categoryId: category.id) {
                showingAddGoal = false
            }
        }
    }
}

private enum GoalCategoryMotion {
    static let overviewSelection = Animation.spring(response: 0.32, dampingFraction: 0.78)
    static var listPageSlide: Animation {
        .spring(
            response: GoalListPanelLayout.pageTurnSpringResponse,
            dampingFraction: GoalListPanelLayout.pageTurnDamping
        )
    }
    static let breakdownExpand = Animation.spring(response: 0.38, dampingFraction: 0.84)
}

private var goalPageBackground: some View {
    LinearGradient(
        colors: [Color.white, Color(hex: "#d8f3dc")],
        startPoint: .top,
        endPoint: .bottom
    )
    .ignoresSafeArea()
}

// MARK: - Overview Card

struct GoalOverviewCard: View {
    let stats: GoalOverviewStats
    let selectedFilter: GoalListFilter
    let onSelectFilter: (GoalListFilter) -> Void

    private let accent = Color(hex: "#2B5748")

    private static let selectionBackground = Color(hex: "#d8f3dc").opacity(0.65)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("目标总览")
                .font(.headline.weight(.bold))
                .foregroundColor(accent)

            HStack(spacing: 0) {
                overviewFilterButton(.all, title: "总目标", value: stats.total)
                overviewDivider
                overviewFilterButton(.completed, title: "已完成", value: stats.completed)
                overviewDivider
                overviewFilterButton(.paused, title: "暂停中", value: stats.paused)
                overviewDivider
                overviewFilterButton(.inProgress, title: "进行中", value: stats.inProgress)
            }
        }
        .padding(16)
        .todoPanelCardChrome()
    }

    private func overviewFilterButton(_ filter: GoalListFilter, title: String, value: Int) -> some View {
        Button {
            onSelectFilter(filter)
        } label: {
            GoalOverviewStatItem(
                title: title,
                value: value,
                isSelected: selectedFilter == filter,
                selectionBackground: Self.selectionBackground
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var overviewDivider: some View {
        Rectangle()
            .fill(Self.selectionBackground)
            .frame(width: 1, height: 28)
    }
}

private struct GoalOverviewStatItem: View {
    let title: String
    let value: Int
    var isSelected: Bool = false
    var selectionBackground: Color

    private let accent = Color(hex: "#2B5748")

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundColor(accent)
            Text(title)
                .font(.caption)
                .foregroundStyle(isSelected ? accent : .secondary)
                .fontWeight(isSelected ? .semibold : .regular)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? selectionBackground : Color.clear)
                .animation(GoalCategoryMotion.overviewSelection, value: isSelected)
        }
        .animation(GoalCategoryMotion.overviewSelection, value: isSelected)
    }
}

// MARK: - Goal List Panel

private enum GoalListPanelLayout {
    static let titleTop: CGFloat = 14
    static let titleToCards: CGFloat = 20
    static let cardsToPage: CGFloat = 6
    static let panelBottom: CGFloat = 8
    /// 与待办清单一致：`listHorizontalPadding(8) + listRowInsets.leading/trailing(4)`
    static let cardHorizontalInset: CGFloat = 12
    /// 页码区域固定高度（不足 5 条 / 单页时也占位，避免切换筛选时卡片高度变化）
    static let pageIndicatorHeight: CGFloat = 22
    /// 翻页滑动阻尼（越大越「沉」、回弹越小）
    static let pageTurnSpringResponse: CGFloat = 0.56
    static let pageTurnDamping: CGFloat = 0.90
    /// 卡片阴影在视口上下预留，避免被裁切
    static let pageShadowInset: CGFloat = 8
}

private enum GoalListCardMetrics {
    static let verticalPadding: CGFloat = 16
    static let titleToStatusSpacing: CGFloat = 5
    static let statusRowHeight: CGFloat = 20
    /// 与 `.headline` 单行视觉高度对齐（去掉 stageTitle 后卡片实际约 79–84pt，原先 96pt 会留出大量空白）
    static let titleBlockHeight: CGFloat = 22

    static var rowHeight: CGFloat {
        verticalPadding * 2 + titleBlockHeight + titleToStatusSpacing + statusRowHeight
    }
}

private struct GoalListPanel: View {
    let goals: [GoalItem]
    let filter: GoalListFilter
    let onSelect: (GoalItem) -> Void

    private let pageSize = 5
    private let rowSpacing: CGFloat = 8

    @State private var currentPage: Int? = 0

    private var pageCount: Int {
        max(1, Int(ceil(Double(goals.count) / Double(pageSize))))
    }

    private var clampedPage: Int {
        min(max(0, currentPage ?? 0), max(0, pageCount - 1))
    }

    private var fixedPageHeight: CGFloat {
        CGFloat(pageSize) * GoalListCardMetrics.rowHeight + CGFloat(pageSize - 1) * rowSpacing
    }

    private func goalsForPage(_ page: Int) -> [GoalItem] {
        let start = page * pageSize
        guard start < goals.count else { return [] }
        return Array(goals[start..<min(start + pageSize, goals.count)])
    }

    private var listScrollHeight: CGFloat {
        fixedPageHeight + GoalListPanelLayout.pageShadowInset * 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("目标清单")
                .font(.headline.weight(.bold))
                .foregroundColor(Color(hex: "#2B5748"))
                .padding(.horizontal, 16)
                .padding(.top, GoalListPanelLayout.titleTop)

            ZStack(alignment: .topLeading) {
                GoalListPagedScrollView(
                    pageCount: pageCount,
                    fixedPageHeight: fixedPageHeight,
                    rowSpacing: rowSpacing,
                    pageSize: pageSize,
                    currentPage: $currentPage,
                    pageContent: { page in
                        goalsForPage(page)
                    },
                    onSelect: onSelect
                )

                if goals.isEmpty {
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, GoalListPanelLayout.pageShadowInset + 4)
                }
            }
            .frame(height: listScrollHeight, alignment: .top)
            .padding(.top, GoalListPanelLayout.titleToCards)

            Text(pageCount > 1 ? "\(clampedPage + 1) / \(pageCount)" : " ")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: "#2B5748"))
                .frame(maxWidth: .infinity)
                .frame(height: GoalListPanelLayout.pageIndicatorHeight)
                .padding(.top, GoalListPanelLayout.cardsToPage)
                .opacity(pageCount > 1 ? 1 : 0)
        }
        .padding(.bottom, GoalListPanelLayout.panelBottom)
        .animation(nil, value: filter)
        .animation(nil, value: goals.count)
        .background {
            RoundedRectangle(cornerRadius: TodoPanelCardChrome.cornerRadius, style: .continuous)
                .fill(TodoPanelCardChrome.background)
                .shadow(
                    color: TodoPanelCardChrome.shadowColor,
                    radius: TodoPanelCardChrome.shadowRadius,
                    x: 0,
                    y: TodoPanelCardChrome.shadowY
                )
        }
        .onChange(of: filter) { _, _ in
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                currentPage = 0
            }
        }
        .onChange(of: goals.count) { _, _ in
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                currentPage = min(clampedPage, max(0, pageCount - 1))
            }
        }
    }

    private var emptyMessage: String {
        switch filter {
        case .all:
            return "暂无目标，点击下方按钮添加"
        case .completed:
            return "暂无已完成目标"
        case .paused:
            return "暂无暂停中目标"
        case .inProgress:
            return "暂无进行中目标"
        }
    }
}

/// 不用 `TabView(.page)`：系统会注入固定 content inset，导致标题/卡片/页码间距无法按设计调节，负 padding 还会让卡片盖住标题。
private struct GoalListPagedScrollView: View {
    let pageCount: Int
    let fixedPageHeight: CGFloat
    let rowSpacing: CGFloat
    let pageSize: Int
    @Binding var currentPage: Int?
    let pageContent: (Int) -> [GoalItem]
    let onSelect: (GoalItem) -> Void

    private var pageVerticalInset: CGFloat {
        GoalListPanelLayout.pageShadowInset
    }

    private var scrollViewportHeight: CGFloat {
        fixedPageHeight + pageVerticalInset * 2
    }

    var body: some View {
        GeometryReader { geometry in
            let pageWidth = geometry.size.width

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<pageCount, id: \.self) { page in
                        let pageGoals = pageContent(page)

                        VStack(spacing: rowSpacing) {
                            ForEach(pageGoals) { goal in
                                Button {
                                    onSelect(goal)
                                } label: {
                                    GoalListCard(goal: goal)
                                }
                                .buttonStyle(.plain)
                            }

                            ForEach(0..<(pageSize - pageGoals.count), id: \.self) { _ in
                                Color.clear
                                    .frame(height: GoalListCardMetrics.rowHeight)
                            }
                        }
                        .padding(.horizontal, GoalListPanelLayout.cardHorizontalInset)
                        .padding(.vertical, pageVerticalInset)
                        .frame(width: pageWidth, height: scrollViewportHeight, alignment: .top)
                        .background(Color.white)
                        .clipped()
                        .id(page)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentPage)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .animation(GoalCategoryMotion.listPageSlide, value: currentPage)
        }
        .frame(height: scrollViewportHeight)
        .clipped()
    }
}

// MARK: - Goal List Card

struct GoalListCard: View {
    let goal: GoalItem

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: GoalListCardMetrics.titleToStatusSpacing) {
                Text(displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: GoalListCardMetrics.titleBlockHeight, alignment: .leading)

                HStack(spacing: 8) {
                    GoalStatusCapsule(status: goal.status)
                    GoalProgressBar(progress: displayProgress, status: goal.status, showsPercentage: true)
                }
                .frame(height: GoalListCardMetrics.statusRowHeight, alignment: .leading)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2B5748"))
        }
        .padding(.vertical, GoalListCardMetrics.verticalPadding)
        .padding(.leading, 16)
        .padding(.trailing, 24)
        .frame(height: GoalListCardMetrics.rowHeight)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color(hex: "#1b4332").opacity(0.22), radius: 4, x: 0, y: 2)
    }

    private var displayProgress: Int {
        goal.status == .completed ? 100 : goal.progress
    }

    private var displayTitle: String {
        goal.title.replacingOccurrences(of: "暂停：", with: "")
    }
}

private struct GoalStatusCapsule: View {
    let status: GoalStatus

    var body: some View {
        Text(status.title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(foregroundColor)
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
        case .inProgress: return Color(hex: "#2563EB")
        case .completed: return Color(hex: "#16A34A")
        case .paused: return Color(hex: "#EA580C")
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .inProgress: return Color(hex: "#DBEAFE")
        case .completed: return Color(hex: "#DCFCE7")
        case .paused: return Color(hex: "#FFEDD5")
        }
    }
}

private struct GoalProgressBar: View {
    let progress: Int
    let status: GoalStatus
    var showsPercentage: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color(hex: "#E8ECE9"))
                    Capsule(style: .continuous)
                        .fill(barColor)
                        .frame(width: max(0, geo.size.width * CGFloat(clampedProgress) / 100))
                }
            }
            .frame(width: 200, height: 5)

            if showsPercentage {
                Text("\(clampedProgress)%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
    }

    private var clampedProgress: Int {
        min(100, max(0, progress))
    }

    private var barColor: Color {
        switch status {
        case .inProgress: return Color(hex: "#2B5748")
        case .completed: return Color(hex: "#16A34A")
        case .paused: return Color(hex: "#EA580C")
        }
    }
}

// MARK: - Goal Detail

struct GoalDetailView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let goalId: UUID

    @Environment(\.dismiss) private var dismiss

    private var goal: GoalItem? {
        viewModel.goal(withId: goalId)
    }

    var body: some View {
        ScrollView {
            if let goal {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(goal.title.replacingOccurrences(of: "暂停：", with: ""))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color(hex: "#2B5748"))

                        if let note = goal.note, !note.isEmpty {
                            Text(note)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)

                    GoalBreakdownCard(viewModel: viewModel, goalId: goalId)

                    if goal.status != .completed {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("进度")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(goal.progress)%")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color(hex: "#2B5748"))
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(goal.progress) },
                                    set: { viewModel.updateGoalProgress(id: goalId, progress: Int($0.rounded())) }
                                ),
                                in: 0...100,
                                step: 1
                            )
                            .tint(Color(hex: "#2B5748"))
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
                    }

                    Button(role: .destructive) {
                        viewModel.deleteGoal(id: goalId)
                        dismiss()
                    } label: {
                        Text("删除目标")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                    )
                }
                .padding(20)
            }
        }
        .mindFlowScrollContentBottomInset()
        .background(goalPageBackground)
        .navigationTitle("目标详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Add Goal Sheet

private struct AddGoalSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    let categoryId: UUID
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var titleText = ""
    @State private var noteText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("目标信息") {
                    TextField("目标名称", text: $titleText)
                    TextField("备注（可选）", text: $noteText, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("新建目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let note = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                        viewModel.addGoal(
                            categoryId: categoryId,
                            title: trimmed,
                            note: note.isEmpty ? nil : note
                        )
                        dismiss()
                        onDismiss()
                    }
                    .disabled(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
