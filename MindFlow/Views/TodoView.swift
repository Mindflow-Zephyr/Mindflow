import SwiftUI
import Combine
import UIKit

/// 新建待办：文本框黑框 + 黑字便于调尺寸；调完后改为 `false` 恢复默认样式
private let addTodoFormDebugTextFieldChrome = false

private func applyMindFlowFormTitleTextFieldDebugChrome(_ tf: UITextField) {
    guard addTodoFormDebugTextFieldChrome else {
        tf.textColor = .label
        tf.backgroundColor = .clear
        tf.layer.borderWidth = 0
        tf.layer.borderColor = nil
        tf.layer.cornerRadius = 0
        tf.clipsToBounds = false
        return
    }
    tf.textColor = .black
    tf.backgroundColor = UIColor(white: 0.94, alpha: 1)
    tf.layer.borderWidth = 2
    tf.layer.borderColor = UIColor.black.cgColor
    tf.layer.cornerRadius = 4
    tf.clipsToBounds = true
}

// MARK: - 待办按一天中的时段分组
enum TodoDayPeriod: Int, CaseIterable, Identifiable {
    case dawn
    case morning
    case afternoon
    case evening

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .dawn: return "凌晨"
        case .morning: return "早上"
        case .afternoon: return "下午"
        case .evening: return "晚上"
        }
    }
}

private enum TodoCardLayoutMetrics {
    /// 「今日待办 / 今日完成」等小标题距卡片顶部的内边距
    static let titleTopInset: CGFloat = 14
    /// 小标题与下方列表的间距
    static let titleBottomInset: CGFloat = 3
    static let titleLineHeight: CGFloat = 22
    static var titleBarHeight: CGFloat { titleTopInset + titleLineHeight + titleBottomInset }
    static let listHorizontalPadding: CGFloat = 8
    static let listBottomPadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 8
    /// 无待办时的内容区高度（尽量紧凑）
    static let emptyStateHeight: CGFloat = 38
    /// 有待办时：在 cardWidth 基础上额外增加的高度，形成固定大卡片
    static let filledCardExtraHeight: CGFloat = 120

    static let emptyActiveMessages = [
        "享受属于你的时间",
        "生活需要一点留白",
        "休息也是计划的一部分"
    ]
}

/// 待办列表行卡片（单条待办）排版，可按需调整数值
private enum TodoRowCardMetrics {
    /// 标题与副标题（时段 / 用时）间距
    static let titleSubtitleSpacing: CGFloat = 5
    /// 已完成「用时」字号（alarm 旁文字与图标同档）
    static let completedDurationFontSize: CGFloat = 13
    /// 分类胶囊字号（比标题 `.headline` 略小，可自行微调）
    static let categoryCapsuleFontSize: CGFloat = 13
    /// 删除线相对文字中心的垂直上移（pt，负值向上）
    static let strikethroughVerticalOffset: CGFloat = -1
    /// 删除线粗细（pt）
    static let strikethroughLineWidth: CGFloat = 1.5
    /// 详情页待办事项 / 备注卡片共用最小高度
    static let detailInlineCardMinHeight: CGFloat = 40
    /// 详情页时间行：三列布局 — 标题列宽（可调试）
    static let detailTimeRowTitleColumnWidth: CGFloat = 100
    /// 详情页时间行：年月日区域列宽（可调试）
    static let detailTimeRowDateColumnWidth: CGFloat = 170
    /// 详情页时间行：时间段区域列宽（可调试）
    static let detailTimeRowSlotColumnWidth: CGFloat = 70
    /// 详情页时间行：标题列左右内边距
    static let detailTimeRowTitleHorizontalInset: CGFloat = 10
    /// 详情页时间胶囊背景色
    static let detailTimeCapsuleFillColor = Color(hex: "#88BDA4")
    /// 详情页时间行高度
    static let detailTimeRowHeight: CGFloat = 40
    /// 详情页备注小标题
    static let detailNoteSectionTitle = "备注"
    /// 详情页备注标题到输入框间距
    static let detailNoteTitleToInputSpacing: CGFloat = 8
    /// 详情页备注输入框字号
    static let detailNoteContentFont: Font = .subheadline.weight(.semibold)
    /// 详情页备注行间距
    static let detailNoteInputLineSpacing: CGFloat = 6
    /// 详情页备注输入区固定可见行数（超出可滚动，无行数限制）
    static let detailNoteInputVisibleLineCount: Int = 5
    /// 详情页备注输入区固定高度（约 5 行文本）
    static var detailNoteInputFixedHeight: CGFloat {
        let base = UIFont.preferredFont(forTextStyle: .subheadline)
        let font = UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
        let lineHeight = font.lineHeight + detailNoteInputLineSpacing
        return lineHeight * CGFloat(detailNoteInputVisibleLineCount) + 8
    }
    /// 详情页备注空态占位文案
    static let detailNoteInputPlaceholder = "添加备注..."
    /// 详情页底部信息行卡片高度（创建 / 时长 / 分类）
    static let detailMetaRowCardHeight: CGFloat = 88
    /// 详情页周几选择条单行高度
    static let detailWeekdayPickerRowHeight: CGFloat = 44
    /// 详情页周几选择条：纵向文字字号（可调试）
    static let detailWeekdayLabelFontSize: CGFloat = 17
    /// 详情页周几选择条：纵向字间距（可调试）
    static let detailWeekdayLabelCharacterSpacing: CGFloat = 2
    /// 详情页周几选择条：时间段列宽（比周几格更宽）
    static let detailWeekdayTimeSlotColumnWidth: CGFloat = 104
    /// 详情页周几选择条：时间段胶囊水平内边距
    static let detailWeekdayTimeSlotHorizontalPadding: CGFloat = 14
    /// 详情页周几选择条：时间段胶囊字号（比时间卡片大一号）
    static let detailWeekdayTimeSlotFont: Font = .title3.weight(.semibold)
    /// 详情页底部信息卡小标题距顶（非比例布局备用）
    static let detailMetaChipTopPadding: CGFloat = 10
    /// 详情页底部信息卡标题/正文整体上移（可调试，负值上移）
    static let detailMetaChipVerticalOffset: CGFloat = -6
    /// 计划时长两行显示时，标题纵向位置比例（可调试，越小越靠上）
    static let detailMetaChipMultilineTitleVerticalRatio: CGFloat = 0.28
    /// 计划时长两行显示时，正文纵向位置比例（可调试，越小越靠上）
    static let detailMetaChipMultilineValueVerticalRatio: CGFloat = 0.68
    /// 详情页「已完成」状态文字色
    static let detailCompletedStatusTextColor = Color(hex: "#D4AF37")
    /// 详情页首卡距顶部的间距
    static let detailPageTopInset: CGFloat = 4
    /// 详情页 ScrollView 额外顶部留白（避免被导航栏遮挡）
    static let detailPageScrollTopInset: CGFloat = 8
    /// 详情页 ScrollView 底部留白（避免底部内容被遮挡）
    static let detailPageScrollBottomInset: CGFloat = MindFlowScrollMetrics.bottomContentInset
    /// 详情页滚动区下边界：与底部自定义导航栏上沿对齐（72 + 46，见 MainTabView）
    static let detailPageBottomNavBarClearance: CGFloat = 118
    /// 详情页待办 / 备注卡片上下内边距（一致）
    static let detailInlineCardVerticalPadding: CGFloat = 14
}

/// 待办卡片动效：收缩（大→小）单独配置，其余切换更轻更快
private enum TodoCardMotion {
    /// 删除/完成最后一个待办：大卡片 → 小卡片
    static let shrink = Animation.spring(duration: 0.68, bounce: 0.34)
    /// 新增第一条待办：小 → 大
    static let grow = Animation.spring(duration: 0.44, bounce: 0.10)
    /// 未完成 / 已完成左右滑切
    static let slide = Animation.spring(duration: 0.38, bounce: 0.06)
    /// 详情页备注卡片行数变化
    static let noteResize = Animation.spring(duration: 0.52, bounce: 0.24)
}

// MARK: - 主程序
struct TodoView: View {
    
    @Binding var showingAddTodo: Bool
    @StateObject private var viewModel = TodoViewModel()     // 界面数据与逻辑模型
    @State private var showCompleted = false  // 未完成/已完成 UI状态
    @State private var showRecurringTasksList = false
    @State private var detailNavigationTodo: TodoItem?  // 要进入哪个待办详情
    @State private var emptyActiveTodoMessage = ""

    init(showingAddTodo: Binding<Bool> = .constant(false)) {
        _showingAddTodo = showingAddTodo
    }

    private func setShowingAddTodo(_ show: Bool) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            showingAddTodo = show
        }
    }

    private func addTodoPanelMaxHeight(screenHeight: CGFloat) -> CGFloat {
        guard screenHeight.isFinite, screenHeight > 0 else { return 400 }
        return max(1, min(screenHeight * 0.78, 680))
    }

    // 自适应卡片宽度：手机屏幕宽度 - 40像素（GeometryReader 首帧可能为 0，需避免负/非有限 frame）
    private func cardSize(for width: CGFloat) -> CGFloat {
        guard width.isFinite, width > 0 else { return 0 }
        return max(0, width - 40)
    }

    /// 未完成 / 已完成卡片左右滑动切换
    private var todoCardSlideAnimation: Animation { TodoCardMotion.slide }

    /// 有待办时的固定卡片高度（列表区域内滚动）
    private func cardFilledHeight(cardWidth: CGFloat) -> CGFloat {
        max(1, cardWidth + TodoCardLayoutMetrics.filledCardExtraHeight)
    }

    /// 仅两种高度：无待办（紧凑）/ 有待办（固定大卡片）
    private func todosCardHeight(hasTodos: Bool, cardWidth: CGFloat) -> CGFloat {
        if hasTodos {
            return cardFilledHeight(cardWidth: cardWidth)
        }
        return TodoCardLayoutMetrics.titleBarHeight
            + TodoCardLayoutMetrics.emptyStateHeight
            + TodoCardLayoutMetrics.listBottomPadding
    }

    private func pickEmptyActiveTodoMessage() {
        emptyActiveTodoMessage = TodoCardLayoutMetrics.emptyActiveMessages.randomElement()
            ?? TodoCardLayoutMetrics.emptyActiveMessages[0]
    }
    
    // 待办事项和完成事项卡片容器
    private func todoCardContainer(width: CGFloat) -> some View {
        let cardWidth = cardSize(for: width)
        let visibleTodos = showCompleted ? viewModel.completedTodos : viewModel.activeTodos
        let cardHeight = todosCardHeight(hasTodos: !visibleTodos.isEmpty, cardWidth: cardWidth)

        return VStack(spacing: 8) {
            Group {
                if showCompleted {
                    completedTodosCard(width: cardWidth)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    activeTodosCard(width: cardWidth)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .todoPanelCardChrome()
            .animation(todoCardSlideAnimation, value: showCompleted)

            HStack(alignment: .top, spacing: 8) {
                TodoTodayInputCard(viewModel: viewModel)
                completedListToggleButton
            }

            TodoRecurringTasksSummaryCard(
                inProgressCount: viewModel.recurringInProgressCount,
                pausedCount: viewModel.recurringPausedCount,
                totalCompletedCount: viewModel.recurringTotalCompletedCount
            ) {
                showRecurringTasksList = true
            }
            .frame(width: cardWidth)

            if let recommendation = viewModel.nextRecommendation {
                TodoNextRecommendationCard(
                    recommendation: recommendation,
                    recommendationType: $viewModel.recommendationType,
                    onCycleRecommendationType: { viewModel.cycleRecommendationType() }
                ) {
                    if let todo = viewModel.todos.first(where: { $0.id == recommendation.todoId }) {
                        detailNavigationTodo = todo
                    }
                }
                .frame(width: cardWidth)
            }

            TodoWeeklyTrendCard(viewModel: viewModel)
                .frame(width: cardWidth)
        }
        .padding(.horizontal, 20)
        .frame(width: max(0, width))
        .onChange(of: viewModel.activeTodos.count) { _, count in
            if count == 0 {
                pickEmptyActiveTodoMessage()
            }
        }
        .onAppear {
            if viewModel.activeTodos.isEmpty {
                pickEmptyActiveTodoMessage()
            }
        }
    }

    private func activeTodosCard(width: CGFloat) -> some View {
        todosCardPanel(
            width: width,
            title: "今日待办",
            todos: viewModel.activeTodos,
            emptyMessage: emptyActiveTodoMessage
        )
    }

    private func completedTodosCard(width: CGFloat) -> some View {
        todosCardPanel(
            width: width,
            title: "今日完成",
            todos: viewModel.completedTodos,
            emptyMessage: "暂无已完成事项",
            groupByPeriod: false
        )
    }

    private func todosCardPanel(
        width: CGFloat,
        title: String,
        todos: [TodoItem],
        emptyMessage: String,
        groupByPeriod: Bool = true
    ) -> some View {
        let hasTodos = !todos.isEmpty
        let cardH = todosCardHeight(hasTodos: hasTodos, cardWidth: width)
        let listAreaHeight = max(
            0,
            cardH - TodoCardLayoutMetrics.titleBarHeight - TodoCardLayoutMetrics.listBottomPadding
        )

        return VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#2B5748"))
                .padding(.horizontal, 16)
                .padding(.top, TodoCardLayoutMetrics.titleTopInset)
                .padding(.bottom, TodoCardLayoutMetrics.titleBottomInset)

            if !hasTodos {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, TodoCardLayoutMetrics.listBottomPadding)
            } else {
                Group {
                    if groupByPeriod {
                        periodGroupedTodosList(
                            viewModel: viewModel,
                            todos: todos,
                            onOpenTodoDetail: { detailNavigationTodo = $0 }
                        )
                    } else {
                        completionSortedTodosList(
                            viewModel: viewModel,
                            todos: todos,
                            onOpenTodoDetail: { detailNavigationTodo = $0 }
                        )
                    }
                }
                .padding(.horizontal, TodoCardLayoutMetrics.listHorizontalPadding)
                .padding(.bottom, TodoCardLayoutMetrics.listBottomPadding)
                .frame(height: listAreaHeight)
            }
        }
        .frame(width: width, height: cardH)
        .background(TodoPanelCardChrome.background)
    }

    /// 按凌晨 / 早上 / 下午 / 晚上分组展示待办。
    /// 必须用 `List` 作为容器，`swipeActions` 在 `ScrollView`+`VStack` 里不会生效。
    private func periodGroupedTodosList(
        viewModel: TodoViewModel,
        todos: [TodoItem],
        onOpenTodoDetail: @escaping (TodoItem) -> Void
    ) -> some View {
        List {
            ForEach(TodoDayPeriod.allCases) { period in
                let items = todos.filter { $0.periodBucket == period }
                if !items.isEmpty {
                    Section {
                        ForEach(items) { todo in
                            TodoCardView(
                                viewModel: viewModel,
                                todo: todo,
                                onOpenDetail: { onOpenTodoDetail(todo) },
                                onDelete: {
                                    viewModel.beginRowSlideOut(id: todo.id, action: .delete)
                                }
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text(period.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#2B5748"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                            .padding(.bottom, 2)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(TodoCardLayoutMetrics.sectionSpacing)
        .scrollContentBackground(.hidden)
        .background(TodoPanelCardChrome.background)
        .environment(\.defaultMinListRowHeight, 1)
        .environment(\.defaultMinListHeaderHeight, 0)
    }

    /// 已完成：不分时段，按完成时间排序平铺
    private func completionSortedTodosList(
        viewModel: TodoViewModel,
        todos: [TodoItem],
        onOpenTodoDetail: @escaping (TodoItem) -> Void
    ) -> some View {
        List {
            ForEach(todos) { todo in
                TodoCardView(
                    viewModel: viewModel,
                    todo: todo,
                    onOpenDetail: { onOpenTodoDetail(todo) },
                    onDelete: {
                        viewModel.beginRowSlideOut(id: todo.id, action: .delete)
                    }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(TodoPanelCardChrome.background)
        .environment(\.defaultMinListRowHeight, 1)
    }

    // 待办卡片下方：未完成 / 已完成列表切换（两态同高同轴，水平滑入滑出）
    private var completedListToggleButton: some View {
        Button(action: {
            withAnimation(todoCardSlideAnimation) {
                showCompleted.toggle()
            }
        }) {
            ZStack {
                todoToggleButtonContent(icon: "checkmark", title: "今日完成")
                    .offset(x: showCompleted ? -100 : 0)
                    .opacity(showCompleted ? 0 : 1)

                todoToggleButtonContent(icon: "list.bullet", title: "今日待办")
                    .offset(x: showCompleted ? 0 : 100)
                    .opacity(showCompleted ? 1 : 0)
            }
            .frame(width: 100, height: 100)
            .clipped()
            .todoPanelCardChrome()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showCompleted ? "查看今日待办" : "查看今日完成")
    }

    private func todoToggleButtonContent(icon: String, title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .frame(width: 28, height: 28)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .frame(width: 72, height: 16, alignment: .center)
        }
        .foregroundColor(Color(hex: "#2B5748"))
        .frame(width: 100, height: 100, alignment: .center)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [Color.white, Color(hex: "#d8f3dc")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        todoCardContainer(width: geometry.size.width)
                    }
                    .mindFlowScrollContentBottomInset()
                    .safeAreaInset(edge: .top, spacing: 8) {
                        HStack(alignment: .center) {
                            Spacer()
                            Text("Mindflow")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }

                    // 面板始终挂在视图树里（收起时移出屏外）：标题 UITextField 已在 window 上，`becomeFirstResponder` 可与面板 spring 同帧触发，减轻「先出面后出键盘」
                    ZStack(alignment: .bottom) {
                        Color.black
                            .opacity(showingAddTodo ? 0.34 : 0)
                            .ignoresSafeArea()
                            .onTapGesture {
                                if showingAddTodo { setShowingAddTodo(false) }
                            }

                        AddTodoSheet(
                            viewModel: viewModel,
                            panelExpanded: showingAddTodo,
                            onDismiss: { setShowingAddTodo(false) }
                        )
                        .accessibilityHidden(!showingAddTodo)
                        .frame(maxWidth: .infinity, maxHeight: addTodoPanelMaxHeight(screenHeight: geometry.size.height))
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 20,
                                bottomLeadingRadius: 16,
                                bottomTrailingRadius: 16,
                                topTrailingRadius: 20,
                                style: .continuous
                            )
                        )
                        .shadow(color: Color.black.opacity(showingAddTodo ? 0.12 : 0), radius: 12, y: -4)
                        .padding(.bottom, 6)
                        .offset(y: showingAddTodo ? 0 : geometry.size.height)
                        .opacity(showingAddTodo ? 1 : 0)
                    }
                    .allowsHitTesting(showingAddTodo)
                    .zIndex(2)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(item: $detailNavigationTodo) { todo in
                    TodoDetailView(viewModel: viewModel, todoId: todo.id)
                }
                .navigationDestination(isPresented: $showRecurringTasksList) {
                    TodoRecurringTasksListView(viewModel: viewModel) { todo in
                        detailNavigationTodo = todo
                    }
                }
                .task {
                    await viewModel.loadTodos()
                }
            }
        }
    }
}

// MARK: - 循环任务汇总 / 列表

private enum TodoRecurringSummaryMetrics {
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 18
    static let titleColumnMinWidth: CGFloat = 96
    static let inProgressGreen = Color(hex: "#52B788")
    static let pausedOrange = Color(hex: "#E8954A")
    static let completedLabel = Color(hex: "#6B7280")
    static let completedCount = Color(hex: "#2B5748")
    static let titleDarkGreen = Color(hex: "#2B5748")
}

private struct TodoRecurringVerticalDashedDivider: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0.5, y: 0))
                path.addLine(to: CGPoint(x: 0.5, y: geometry.size.height))
            }
            .stroke(
                Color.secondary.opacity(0.28),
                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
            )
        }
        .frame(width: 1)
    }
}

private enum TodoTodayInputMetrics {
    static let accent = Color(hex: "#2B5748")
    /// 标题与时间行之间的间距（可调试，增大可整体下移时间区域）
    static let titleToContentSpacing: CGFloat = 10
    /// 时间数字与胶囊额外下移（pt，可调试）
    static let contentTopOffset: CGFloat = 17
}

private enum TodoTodayInputFormatting {
    static func hoursMinutes(from seconds: Int) -> (hours: Int, minutes: Int) {
        let safe = max(0, seconds)
        return (safe / 3600, (safe % 3600) / 60)
    }

    static func deltaBadgeText(minutes: Int) -> String {
        if minutes == 0 { return "较昨日 持平" }
        if minutes > 0 { return "较昨日 +\(minutes)分钟" }
        return "较昨日 \(minutes)分钟"
    }
}

private struct TodoTodayInputCard: View {
    @ObservedObject var viewModel: TodoViewModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            cardContent
        }
    }

    private var cardContent: some View {
        let seconds = viewModel.todayInvestedSeconds
        let (hours, minutes) = TodoTodayInputFormatting.hoursMinutes(from: seconds)
        let deltaMinutes = (viewModel.todayInvestedSeconds - viewModel.yesterdayInvestedSeconds) / 60

        return VStack(alignment: .leading, spacing: TodoTodayInputMetrics.titleToContentSpacing) {
            Text("今日投入")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TodoTodayInputMetrics.accent)

            HStack(alignment: .lastTextBaseline, spacing: 0) {
                timeDisplay(hours: hours, minutes: minutes)
                Spacer(minLength: 6)
                deltaBadge(minutes: deltaMinutes)
            }
            .padding(.top, TodoTodayInputMetrics.contentTopOffset)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100, alignment: .topLeading)
        .todoPanelCardChrome()
    }

    @ViewBuilder
    private func timeDisplay(hours: Int, minutes: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if hours > 0 {
                Text("\(hours)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(hex: "#1A1A1A"))
                Text("小时")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if minutes > 0 || hours == 0 {
                Text("\(minutes)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(hex: "#1A1A1A"))
                Text("分钟")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }

    private func deltaBadge(minutes: Int) -> some View {
        let isUp = minutes > 0
        let tint = isUp ? Color(hex: "#2B5748") : Color.secondary
        return HStack(spacing: 2) {
            if minutes != 0 {
                Image(systemName: isUp ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .bold))
            }
            Text(TodoTodayInputFormatting.deltaBadgeText(minutes: minutes))
                .font(.caption.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "#E8F5E9"))
        .clipShape(Capsule(style: .continuous))
    }
}

private struct TodoRecurringTasksSummaryCard: View {
    let inProgressCount: Int
    let pausedCount: Int
    let totalCompletedCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 0) {
                Text("循环任务")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(TodoRecurringSummaryMetrics.titleDarkGreen)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, TodoRecurringSummaryMetrics.horizontalPadding)

                TodoRecurringVerticalDashedDivider()
                    .padding(.vertical, 12)

                summaryStatColumn(
                    title: "进行中",
                    count: inProgressCount,
                    titleColor: TodoRecurringSummaryMetrics.inProgressGreen,
                    countColor: TodoRecurringSummaryMetrics.inProgressGreen
                )

                TodoRecurringVerticalDashedDivider()
                    .padding(.vertical, 12)

                summaryStatColumn(
                    title: "暂停中",
                    count: pausedCount,
                    titleColor: TodoRecurringSummaryMetrics.pausedOrange,
                    countColor: TodoRecurringSummaryMetrics.pausedOrange
                )

                TodoRecurringVerticalDashedDivider()
                    .padding(.vertical, 12)

                summaryStatColumn(
                    title: "已完成",
                    count: totalCompletedCount,
                    titleColor: TodoRecurringSummaryMetrics.completedLabel,
                    countColor: TodoRecurringSummaryMetrics.completedCount
                )
            }
            .padding(.vertical, TodoRecurringSummaryMetrics.verticalPadding)
            .frame(maxWidth: .infinity)
            .todoPanelCardChrome()
        }
        .buttonStyle(.plain)
    }

    private func summaryStatColumn(title: String, count: Int, titleColor: Color, countColor: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(titleColor)
            Text("\(count)")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(countColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
}

private struct TodoWeeklyTrendDay: Identifiable {
    let weekdayLabel: String
    let investedSeconds: Int
    let isToday: Bool
    var isPeak: Bool = false

    var id: String { weekdayLabel }
}

private enum TodoWeeklyTrendMetrics {
    static let accent = Color(hex: "#2B5748")
    static let barInactive = Color(hex: "#DDEEE8")
    static let barActive = Color(hex: "#2B5748")
    static let totalCapsuleBackground = Color(hex: "#E8F5E9")
    static let barWidth: CGFloat = 22
    static let barCornerRadius: CGFloat = 5
    static let barMaxHeight: CGFloat = 92
    static let barMinHeight: CGFloat = 8
    static let footerBackground = Color(hex: "#E8F5E9")

    static func hoursLabel(seconds: Int) -> String? {
        guard seconds > 0 else { return nil }
        let hours = Double(seconds) / 3600.0
        if hours >= 10 { return String(format: "%.0fh", hours) }
        return String(format: "%.1fh", hours)
    }
}

private struct TodoWeeklyTrendCard: View {
    @ObservedObject var viewModel: TodoViewModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            cardContent
        }
    }

    private var cardContent: some View {
        let days = viewModel.weeklyTrendDays
        let maxSeconds = max(days.map(\.investedSeconds).max() ?? 0, 1)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("本周趋势")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TodoWeeklyTrendMetrics.accent)

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Text("总投入")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(viewModel.weeklyTotalInvestedHoursText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TodoWeeklyTrendMetrics.accent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(TodoWeeklyTrendMetrics.totalCapsuleBackground)
                .clipShape(Capsule(style: .continuous))
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days) { day in
                    trendBar(day: day, maxSeconds: maxSeconds)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            HStack(spacing: 6) {
                Text("本周已完成 ")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TodoWeeklyTrendMetrics.accent)
                + Text("\(viewModel.weeklyCompletedCount)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TodoWeeklyTrendMetrics.accent)
                + Text(" 项")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TodoWeeklyTrendMetrics.accent)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
            .background(TodoWeeklyTrendMetrics.footerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(14)
        .frame(minHeight: 220)
        .todoPanelCardChrome()
    }

    private func trendBar(day: TodoWeeklyTrendDay, maxSeconds: Int) -> some View {
        let ratio = CGFloat(day.investedSeconds) / CGFloat(max(maxSeconds, 1))
        let barHeight = max(
            TodoWeeklyTrendMetrics.barMinHeight,
            TodoWeeklyTrendMetrics.barMaxHeight * ratio
        )
        let isHighlighted = day.isPeak

        return VStack(spacing: 6) {
            Group {
                if let label = TodoWeeklyTrendMetrics.hoursLabel(seconds: day.investedSeconds) {
                    Text(label)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text(" ")
                        .font(.caption2.weight(.medium))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: TodoWeeklyTrendMetrics.barCornerRadius, style: .continuous)
                    .fill(isHighlighted ? TodoWeeklyTrendMetrics.barActive : TodoWeeklyTrendMetrics.barInactive)
                    .frame(width: TodoWeeklyTrendMetrics.barWidth, height: barHeight)

                if isHighlighted {
                    Image(systemName: "star.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 6)
                }
            }
            .frame(height: TodoWeeklyTrendMetrics.barMaxHeight, alignment: .bottom)

            Text(day.weekdayLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TodoWeeklyTrendMetrics.accent)
        }
        .frame(maxWidth: .infinity)
    }
}

private enum TodoRecommendationType: CaseIterable {
    case topPriority
    case mostUrgent
    case outfit
    case fitness
    case game

    var displayName: String {
        switch self {
        case .topPriority: return "最优先"
        case .mostUrgent: return "最紧急"
        case .outfit: return "穿搭推荐"
        case .fitness: return "运动推荐"
        case .game: return "游戏推荐"
        }
    }

    var badgeIcon: String {
        switch self {
        case .topPriority: return "star.fill"
        case .mostUrgent: return "bolt.fill"
        case .outfit: return "tshirt.fill"
        case .fitness: return "figure.run"
        case .game: return "gamecontroller.fill"
        }
    }

    var next: TodoRecommendationType {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self) else { return .topPriority }
        return all[(index + 1) % all.count]
    }

    var theme: TodoRecommendationTheme {
        switch self {
        case .topPriority:
            return TodoRecommendationTheme(
                accent: Color(hex: "#6B5DD3"),
                badgeBackground: Color(hex: "#EDE9FE"),
                iconBackground: Color(hex: "#7C6AE8"),
                arrowButtonBackground: Color(hex: "#F4F1FF")
            )
        case .mostUrgent:
            return TodoRecommendationTheme(
                accent: Color(hex: "#E57373"),
                badgeBackground: Color(hex: "#FFEBEE"),
                iconBackground: Color(hex: "#EF9A9A"),
                arrowButtonBackground: Color(hex: "#FFF5F5")
            )
        case .outfit:
            return TodoRecommendationTheme(
                accent: Color(hex: "#2563EB"),
                badgeBackground: Color(hex: "#DBEAFE"),
                iconBackground: Color(hex: "#3B82F6"),
                arrowButtonBackground: Color(hex: "#EFF6FF")
            )
        case .fitness:
            return TodoRecommendationTheme(
                accent: Color(hex: "#6B7280"),
                badgeBackground: Color(hex: "#F3F4F6"),
                iconBackground: Color(hex: "#9CA3AF"),
                arrowButtonBackground: Color(hex: "#F9FAFB")
            )
        case .game:
            return TodoRecommendationTheme(
                accent: Color(hex: "#38BDF8"),
                badgeBackground: Color(hex: "#E0F2FE"),
                iconBackground: Color(hex: "#7DD3FC"),
                arrowButtonBackground: Color(hex: "#F0F9FF")
            )
        }
    }
}

private struct TodoRecommendationTheme {
    let accent: Color
    let badgeBackground: Color
    let iconBackground: Color
    let arrowButtonBackground: Color
}

private struct TodoNextRecommendation {
    let todoId: Int
    let title: String
    let subtitle: String
    let icon: String
    let estimatedMinutes: Int
    let suggestedStartTime: String
}

private enum TodoNextRecommendationMetrics {
    static let titleColor = Color(hex: "#1A1A1A")
    static let taskBoxBorder = Color(hex: "#E5E7EB")

    static func prioritySortOrder(_ priority: TodoPriority) -> Int {
        switch priority {
        case .p1: return 0
        case .p2: return 1
        case .p3: return 2
        case .p4: return 3
        }
    }
}

private struct TodoNextRecommendationCard: View {
    let recommendation: TodoNextRecommendation
    @Binding var recommendationType: TodoRecommendationType
    let onCycleRecommendationType: () -> Void
    let onOpen: () -> Void

    var body: some View {
        let theme = recommendationType.theme

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                Text("下一项推荐")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(theme.accent)

            Button(action: onOpen) {
                HStack(alignment: .center, spacing: 12) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.iconBackground)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: recommendation.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(TodoNextRecommendationMetrics.titleColor)
                            .multilineTextAlignment(.leading)
                        if !recommendation.subtitle.isEmpty {
                            Text(recommendation.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Circle()
                        .fill(theme.arrowButtonBackground)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(theme.accent)
                        }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(TodoNextRecommendationMetrics.taskBoxBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: 0) {
                recommendationMetaColumn(
                    title: "预计时长",
                    value: "\(recommendation.estimatedMinutes) 分钟",
                    valueColor: theme.accent
                )

                recommendationMetaDivider

                recommendationMetaColumn(
                    title: "建议开始时间",
                    value: recommendation.suggestedStartTime,
                    valueColor: theme.accent
                )

                recommendationMetaDivider

                recommendationTypeBadgeColumn(theme: theme)
            }
        }
        .padding(14)
        .todoPanelCardChrome()
        .animation(.easeInOut(duration: 0.22), value: recommendationType)
    }

    private func recommendationTypeBadgeColumn(theme: TodoRecommendationTheme) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Button(action: onCycleRecommendationType) {
                HStack(spacing: 4) {
                    Image(systemName: recommendationType.badgeIcon)
                        .font(.system(size: 9, weight: .bold))
                    Text(recommendationType.displayName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(theme.badgeBackground)
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 42)
    }

    private var recommendationMetaDivider: some View {
        Rectangle()
            .fill(Color(hex: "#E5E7EB"))
            .frame(width: 1, height: 42)
    }

    private func recommendationMetaColumn(
        title: String,
        value: String,
        valueColor: Color
    ) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TodoRecurringCategorySection: Identifiable {
    let categoryId: Int?
    let title: String

    var id: String {
        if let categoryId { return "category-\(categoryId)" }
        return "category-uncategorized"
    }

    var headerTitle: String { title }
}

private enum TodoRecurringTaskCardMetrics {
    static let accentBarWidth: CGFloat = 4
    static let cornerRadius: CGFloat = 14
    static let horizontalPadding: CGFloat = 14
    static let topSectionVerticalPadding: CGFloat = 14
    static let bottomSectionVerticalPadding: CGFloat = 12
    static let titleFont: Font = .headline.weight(.bold)
    static let statusColumnSpacing: CGFloat = 6
    static let pausedIndicatorWidth: CGFloat = 18
    static let pausedIndicatorHeight: CGFloat = 2.5
    /// 循环任务列表顶部可滚动留白（避免被导航栏遮挡，可调试）
    static let listScrollTopInset: CGFloat = TodoRowCardMetrics.detailPageScrollTopInset + 12
    static let tagBackground = Color(hex: "#E8F5E9")
    static let tagBackgroundYellow = Color(hex: "#FFF3CD")
    static let accentGreen = Color(hex: "#52B788")
    static let accentYellow = Color(hex: "#F4B942")
    static let darkGreen = Color(hex: "#2B5748")
    static let darkYellow = Color(hex: "#B7791F")
    static let shimmerDuration: TimeInterval = 3.0
}

private struct TodoRecurringCompletionBar: View {
    let percent: Int
    let isPaused: Bool

    @State private var animatedFraction: CGFloat = 0
    @State private var shimmerPhase: CGFloat = 0

    private var targetFraction: CGFloat {
        min(1, max(0, CGFloat(percent) / 100))
    }

    private var fillColor: Color {
        isPaused ? TodoRecurringTaskCardMetrics.accentYellow : TodoRecurringTaskCardMetrics.accentGreen
    }

    private var percentColor: Color {
        isPaused ? TodoRecurringTaskCardMetrics.darkYellow : TodoRecurringTaskCardMetrics.darkGreen
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("\(percent)%")
                .font(.headline.weight(.bold))
                .foregroundColor(percentColor)
                .monospacedDigit()

            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let fillWidth = trackWidth * animatedFraction
                let bandWidth = min(24, max(12, fillWidth * 0.35))

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.secondary.opacity(0.16))

                    Capsule(style: .continuous)
                        .fill(fillColor)
                        .frame(width: fillWidth)
                        .overlay {
                            if !isPaused, fillWidth > 6 {
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0),
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: bandWidth)
                                    .offset(x: -bandWidth + shimmerPhase * (fillWidth + bandWidth))
                            }
                        }
                        .clipShape(Capsule(style: .continuous))
                }
            }
            .frame(height: 10)
            .frame(maxWidth: 84)
        }
        .onAppear {
            syncAnimatedFraction(animated: true)
            restartShimmerIfNeeded()
        }
        .onChange(of: percent) { _, _ in
            syncAnimatedFraction(animated: true)
        }
        .onChange(of: isPaused) { _, _ in
            restartShimmerIfNeeded()
        }
    }

    private func syncAnimatedFraction(animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.85)) {
                animatedFraction = targetFraction
            }
        } else {
            animatedFraction = targetFraction
        }
    }

    private func restartShimmerIfNeeded() {
        shimmerPhase = 0
        guard !isPaused else { return }
        withAnimation(.linear(duration: TodoRecurringTaskCardMetrics.shimmerDuration).repeatForever(autoreverses: false)) {
            shimmerPhase = 1
        }
    }
}

private struct TodoRecurringInfinityIndicator: View {
    let isPaused: Bool

    @State private var shimmerPhase: CGFloat = 0

    private var symbolColor: Color {
        isPaused ? TodoRecurringTaskCardMetrics.darkYellow : TodoRecurringTaskCardMetrics.accentGreen
    }

    private let symbolFont = Font.system(size: 40, weight: .bold)

    var body: some View {
        Text("∞")
            .font(symbolFont)
            .foregroundColor(symbolColor)
            .overlay {
                if !isPaused {
                    GeometryReader { geometry in
                        let bandWidth = min(18, geometry.size.width * 0.45)
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.75),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: bandWidth, height: geometry.size.height)
                        .offset(x: -bandWidth + shimmerPhase * (geometry.size.width + bandWidth))
                    }
                    .mask {
                        Text("∞")
                            .font(symbolFont)
                    }
                }
            }
            .frame(height: 46)
            .onAppear {
                restartShimmerIfNeeded()
            }
            .onChange(of: isPaused) { _, _ in
                restartShimmerIfNeeded()
            }
    }

    private func restartShimmerIfNeeded() {
        shimmerPhase = 0
        guard !isPaused else { return }
        withAnimation(.linear(duration: TodoRecurringTaskCardMetrics.shimmerDuration).repeatForever(autoreverses: false)) {
            shimmerPhase = 1
        }
    }
}

private struct TodoRecurringTaskRowCard: View {
    let todo: TodoItem
    let onOpenDetail: () -> Void
    let onToggleRecurringStatus: () -> Void

    private var canToggleRecurringStatus: Bool {
        !todo.isCompleted && todo.repeatMode != .none
    }

    private var isRecurringPaused: Bool {
        !todo.isCompleted && todo.recurringCycleStatus == .paused
    }

    private var themeAccentColor: Color {
        isRecurringPaused ? TodoRecurringTaskCardMetrics.accentYellow : TodoRecurringTaskCardMetrics.accentGreen
    }

    private var themeTagBackground: Color {
        isRecurringPaused ? TodoRecurringTaskCardMetrics.tagBackgroundYellow : TodoRecurringTaskCardMetrics.tagBackground
    }

    private var themeTextColor: Color {
        isRecurringPaused ? TodoRecurringTaskCardMetrics.darkYellow : TodoRecurringTaskCardMetrics.darkGreen
    }

    var body: some View {
        HStack(spacing: 0) {
            themeAccentColor
                .frame(width: TodoRecurringTaskCardMetrics.accentBarWidth)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(todo.title)
                            .font(TodoRecurringTaskCardMetrics.titleFont)
                            .foregroundColor(Color(hex: "#1A1A1A"))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let methodTag = todo.recurringMethodTag {
                            Text(methodTag)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(themeTextColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background {
                                    Capsule(style: .continuous)
                                        .fill(themeTagBackground)
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Color.clear
                        .frame(maxWidth: .infinity)

                    Group {
                        if isRecurringPaused || todo.recurringNextStartTimePhrase() != nil {
                            statusNextStartIndicator
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, TodoRecurringTaskCardMetrics.horizontalPadding)
                .padding(.vertical, TodoRecurringTaskCardMetrics.topSectionVerticalPadding)

                Rectangle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: 1)

                HStack(spacing: 0) {
                    bottomStatColumn(
                        value: "\(todo.recurringCompletedOccurrences) 次",
                        label: "已完成",
                        valueColor: themeTextColor,
                        labelFont: .subheadline.weight(.semibold)
                    )
                    bottomDivider
                    bottomCompletionRateColumn
                    bottomDivider
                    bottomStatusColumn
                }
                .padding(.horizontal, 8)
                .padding(.vertical, TodoRecurringTaskCardMetrics.bottomSectionVerticalPadding)
            }
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: TodoRecurringTaskCardMetrics.cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: TodoRecurringTaskCardMetrics.cornerRadius, style: .continuous))
        .onTapGesture(perform: onOpenDetail)
    }

    @ViewBuilder
    private var statusNextStartIndicator: some View {
        if isRecurringPaused {
            Rectangle()
                .fill(themeTextColor)
                .frame(
                    width: TodoRecurringTaskCardMetrics.pausedIndicatorWidth,
                    height: TodoRecurringTaskCardMetrics.pausedIndicatorHeight
                )
        } else if todo.recurringNextStartTimePhrase() != nil {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                VStack(spacing: 4) {
                    Text(todo.recurringNextStartTimePhrase(at: context.date) ?? "")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text("开始下次任务")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(themeTextColor)
                }
                .multilineTextAlignment(.center)
            }
        }
    }

    private var bottomStatusColumn: some View {
        VStack(spacing: TodoRecurringTaskCardMetrics.statusColumnSpacing) {
            Spacer(minLength: 0)

            Button {
                onToggleRecurringStatus()
            } label: {
                Text(todo.recurringStatusDisplayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule(style: .continuous)
                            .fill(themeTagBackground)
                    }
            }
            .buttonStyle(.plain)
            .disabled(!canToggleRecurringStatus)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
    @ViewBuilder
    private var bottomCompletionRateColumn: some View {
        Group {
            if todo.isInfiniteRepeat {
                TodoRecurringInfinityIndicator(isPaused: isRecurringPaused)
            } else {
                TodoRecurringCompletionBar(
                    percent: todo.recurringCompletionRatePercent ?? 0,
                    isPaused: isRecurringPaused
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func bottomStatColumn(
        value: String,
        label: String,
        valueColor: Color = Color(hex: "#2B5748"),
        valueFont: Font = .headline.weight(.semibold),
        labelFont: Font = .caption2.weight(.semibold)
    ) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(valueFont)
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(labelFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var bottomDivider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .frame(width: 1, height: 44)
    }
}

private struct TodoRecurringTasksListView: View {
    @ObservedObject var viewModel: TodoViewModel
    let onSelectTodo: (TodoItem) -> Void

    private var hasAnyRecurringTodos: Bool {
        !viewModel.recurringIncompleteTodos.isEmpty
    }

    var body: some View {
        Group {
            if !hasAnyRecurringTodos {
                ContentUnavailableView(
                    "暂无循环任务",
                    systemImage: "arrow.triangle.2.circlepath",
                    description: Text("在待办详情中设置循环规则后，会显示在这里")
                )
            } else {
                List {
                    ForEach(viewModel.recurringCategorySections()) { section in
                        let items = viewModel.recurringTodos(in: section.categoryId)
                        Section {
                            ForEach(items) { todo in
                                TodoRecurringTaskRowCard(todo: todo) {
                                    onSelectTodo(todo)
                                } onToggleRecurringStatus: {
                                    viewModel.toggleTodoRecurringCycleStatus(id: todo.id)
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            viewModel.beginRowSlideOut(id: todo.id, action: .delete)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                                }
                        } header: {
                            Text(section.headerTitle)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#2B5748"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 4)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .listSectionSpacing(TodoCardLayoutMetrics.sectionSpacing)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, TodoRecurringTaskCardMetrics.listScrollTopInset, for: .scrollContent)
                .mindFlowScrollContentBottomInset()
            }
        }
        .background {
            LinearGradient(
                colors: [Color.white, Color(hex: "#d8f3dc")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .navigationTitle("循环任务")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TodoWheelPickerBackgroundClearer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            var ancestor: UIView? = uiView.superview
            while let current = ancestor {
                if let picker = current as? UIPickerView {
                    picker.backgroundColor = .clear
                    for subview in picker.subviews {
                        subview.backgroundColor = .clear
                        subview.layer.cornerRadius = 0
                    }
                    break
                }
                ancestor = current.superview
            }
        }
    }
}

private struct TodoWheelPickerClearBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .background(TodoWheelPickerBackgroundClearer())
    }
}

private extension View {
    func todoWheelPickerClearBackground() -> some View {
        modifier(TodoWheelPickerClearBackground())
    }
}

// MARK: - 待办卡片光带（角向动画；未计时 = 动画冻结在某一帧）
private enum TodoLightBandConstants {
    static let rotationPeriod: TimeInterval = 2.6
    static var angularSpeed: Double { 2 * Double.pi / rotationPeriod }
    /// 静止态在周期 **[0, rotationPeriod)** 内对应的时间位置（秒），再换算为相位弧度。
    static let defaultIdleFrameTimeInPeriod: TimeInterval = 2.2
    static var defaultIdleFramePhaseRadians: Double {
        (defaultIdleFrameTimeInPeriod / rotationPeriod) * 2 * Double.pi
    }
}

// MARK: - 待办大卡片统一外观（列表容器、「今日完成」等；无描边，仅白底 + 圆角 + 阴影）
enum TodoPanelCardChrome {
    static let cornerRadius: CGFloat = 16
    static let background = Color.white
    static let shadowColor = Color.black.opacity(0.1)
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 2
}

extension View {
    func todoPanelCardChrome(
        cornerRadius: CGFloat = TodoPanelCardChrome.cornerRadius,
        background: Color = TodoPanelCardChrome.background
    ) -> some View {
        self.background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: TodoPanelCardChrome.shadowColor,
                radius: TodoPanelCardChrome.shadowRadius,
                x: 0,
                y: TodoPanelCardChrome.shadowY
            )
    }
}

// MARK: - Todo Card View
private struct TodoRaisedStrikethroughModifier: ViewModifier {
    let active: Bool
    var color: Color = Color(hex: "#2B5748")
    var verticalOffset: CGFloat = TodoRowCardMetrics.strikethroughVerticalOffset

    func body(content: Content) -> some View {
        content.overlay {
            if active {
                GeometryReader { geo in
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width, height: TodoRowCardMetrics.strikethroughLineWidth)
                        .position(
                            x: geo.size.width / 2,
                            y: geo.size.height / 2 + verticalOffset
                        )
                }
            }
        }
    }
}

private extension View {
    func todoRaisedStrikethrough(_ active: Bool, color: Color = Color(hex: "#2B5748")) -> some View {
        modifier(TodoRaisedStrikethroughModifier(active: active, color: color))
    }
}

struct TodoCardView: View {
    @ObservedObject var viewModel: TodoViewModel
    let todo: TodoItem
    let onOpenDetail: () -> Void
    let onDelete: () -> Void

    /// 侧滑里 SwiftUI 的 `.font(weight:)` 常被系统忽略；用 SymbolConfiguration 才能真正加粗 SF Symbol。
    private static func swipeCheckmarkImage(pointSize: CGFloat = 24, weight: UIImage.SymbolWeight = .heavy) -> Image {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        let uiImage = UIImage(systemName: "checkmark", withConfiguration: config)!
        return Image(uiImage: uiImage).renderingMode(.template)
    }

    /// 滑出位移加在卡片本体上、再挂 `swipeActions`，左右滑共用同一套 List 手势与自定义 `easeOut` 位移
    private var rowSlideOutOffsetX: CGFloat {
        guard viewModel.slidingOutIds.contains(todo.id) else { return 0 }
        let sign = viewModel.slideOutSignById[todo.id] ?? 0
        return sign * TodoViewModel.rowSlideOutOffset
    }

    private static func formatWorkSeconds(_ total: Int) -> String {
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    /// 未完成光带（静止 / 计时旋转）更粗的居中描边
    private static let lightBandStrokeLineWidth: CGFloat = 2.35
    private static var lightBandStrokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: lightBandStrokeLineWidth, lineCap: .round, lineJoin: .round)
    }

    private static func lightBandAngularGradient(angle: Angle) -> AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: Color(hex: "#215B63").opacity(0.2), location: 0.06),
                .init(color: Color(hex: "#215B63"), location: 0.11),
                .init(color: Color(hex: "#79c9b0"), location: 0.15),
                .init(color: Color(hex: "#215B63"), location: 0.19),
                .init(color: Color(hex: "#215B63").opacity(0.25), location: 0.24),
                .init(color: .clear, location: 0.32),
                .init(color: .clear, location: 1.0)
            ]),
            center: .center,
            angle: angle
        )
    }

    /// 未计时：与计时/暂停同一套角向渐变，冻结在 `defaultIdleFrameTimeInPeriod` 对应的那一帧
    private var idleLightBandBorderOverlay: some View {
        pausedLightBandBorderOverlay(phaseRadians: TodoLightBandConstants.defaultIdleFramePhaseRadians)
    }

    /// 计时进行中：角向光带，相位 = 本段基准 + 已运行时长 × 角速度（与暂停帧、冷启动基准连续）
    @ViewBuilder
    private var runningTimerBorderOverlay: some View {
        TimelineView(.animation) { context in
            let since = viewModel.workTimerRunningSince(todoId: todo.id) ?? context.date
            let elapsed = context.date.timeIntervalSince(since)
            let base = viewModel.lightBandRunningBasePhaseRadians(todoId: todo.id)
            let phase = base + elapsed * TodoLightBandConstants.angularSpeed
            RoundedRectangle(cornerRadius: 12)
                .stroke(Self.lightBandAngularGradient(angle: .radians(phase)), style: Self.lightBandStrokeStyle)
        }
    }

    private func pausedLightBandBorderOverlay(phaseRadians: Double) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Self.lightBandAngularGradient(angle: .radians(phaseRadians)), style: Self.lightBandStrokeStyle)
    }

    @ViewBuilder
    private var trailingAccessory: some View {
        if todo.isCompleted {
            EmptyView()
        } else if viewModel.showsWorkTimer(todoId: todo.id) {
            Group {
                if viewModel.isWorkTimerRunning(todoId: todo.id) {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(Self.formatWorkSeconds(viewModel.currentWorkSeconds(todoId: todo.id)))
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#2B5748"))
                    }
                } else {
                    Text(Self.formatWorkSeconds(viewModel.currentWorkSeconds(todoId: todo.id)))
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#DB1A1A"))
                }
            }
        } else {
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2B5748"))
        }
    }

    private var cardChrome: some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: TodoRowCardMetrics.titleSubtitleSpacing) {
                    HStack(alignment: .center, spacing: 8) {
                        Button {
                            onOpenDetail()
                        } label: {
                            Text(todo.title)
                                .font(.headline)
                                .foregroundColor(
                                    todo.isCompleted
                                        ? Color(hex: "#2B5748")
                                        : .primary
                                )
                                .todoRaisedStrikethrough(todo.isCompleted)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                        .buttonStyle(.plain)
                        .layoutPriority(1)

                        if !todo.isCompleted, let category = todo.taskCategoryLabel {
                            TodoCategoryCapsule(title: category)
                        }
                    }

                    if todo.isCompleted {
                        if let spent = todo.completionDurationCardSubtitle {
                            Text(spent)
                                .font(.system(
                                    size: TodoRowCardMetrics.completedDurationFontSize,
                                    weight: .medium
                                ))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        Text(todo.todayCardTimeDisplayText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "#2B5748"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trailingAccessory
            }
            .padding(.vertical, 16)
            .padding(.leading, 16)
            .padding(.trailing, 24)
            .background(
                todo.isCompleted
                    ? Color(hex: "#EAECF0")
                    : Color(.systemBackground)
            )
            .cornerRadius(12)
            .overlay {
                if !todo.isCompleted {
                    if viewModel.isWorkTimerRunning(todoId: todo.id) {
                        runningTimerBorderOverlay
                    } else if let phase = viewModel.pausedLightBandPhaseRadians(todoId: todo.id) {
                        pausedLightBandBorderOverlay(phaseRadians: phase)
                    } else {
                        idleLightBandBorderOverlay
                    }
                }
            }
            .shadow(color: Color(hex: "#1b4332").opacity(0.22), radius: 4, x: 0, y: 2)

            if !todo.isCompleted {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Color.clear
                            .frame(width: geo.size.width * 0.58)
                            .allowsHitTesting(false)
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: geo.size.width * 0.42)
                            .onTapGesture {
                                viewModel.toggleWorkTimer(todoId: todo.id)
                            }
                    }
                }
                .allowsHitTesting(true)
            }
        }
    }

    var body: some View {
        cardChrome
            .offset(x: rowSlideOutOffsetX)
            .allowsHitTesting(!viewModel.slidingOutIds.contains(todo.id))
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    if todo.isCompleted {
                        viewModel.beginRowSlideOut(id: todo.id, action: .markIncomplete)
                    } else {
                        viewModel.beginRowSlideOut(id: todo.id, action: .markComplete)
                    }
                } label: {
                    if todo.isCompleted {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.monochrome)
                    } else {
                        Self.swipeCheckmarkImage(pointSize: 24, weight: .medium)
                            .foregroundStyle(.white)
                    }
                }
                .accessibilityLabel(todo.isCompleted ? "恢复" : "完成")
                .tint(todo.isCompleted ? Color(hex: "#d97706") : Color(hex: "#2d6a4f"))
            }
            // 不用 `role: .destructive`（尾随会与 leading 完成两套动画）；图标保持系统默认 `trash` 样式，仅用 `.tint` 接近原 destructive 红底
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("删除")
                .tint(Color.red)
            }
    }
}

// MARK: - 待办「正在做」计时（不计入 Codable，仅存内存）
struct TodoActiveWorkState: Equatable {
    var accumulated: TimeInterval = 0
    var runningSince: Date?
    /// 暂停瞬间冻结的光带相位（弧度），非 nil 时用角向渐变静态渲染
    var pausedLightBandPhaseRadians: Double?
    /// 当前连续运行段的相位基准（每次开始 / 恢复计时写入）
    var runningSegmentBasePhaseRadians: Double = 0
}

// MARK: - Todo ViewModel
@MainActor
class TodoViewModel: ObservableObject {
    enum RowSlideOutAction: Sendable {
        /// 删除：卡片向左滑出视野
        case delete
        /// 未完成 → 完成：向右滑出视野
        case markComplete
        /// 已完成 → 恢复未完成：向左滑出视野
        case markIncomplete
    }

    @Published var todos: [TodoItem] = []
    @Published fileprivate var recommendationType: TodoRecommendationType = .topPriority
    @Published private(set) var activeWorkByTodoId: [Int: TodoActiveWorkState] = [:]
    /// 正在做滑出动画的行（删除 / 完成 / 恢复）
    @Published private(set) var slidingOutIds: Set<Int> = []
    /// +1 向右、-1 向左（与 `slidingOutIds` 同步写入）
    @Published private(set) var slideOutSignById: [Int: CGFloat] = [:]

    /// 滑出位移（约一屏宽，保证整卡移出视野）；时长与曲线见下方常量
    /// iOS 26+：避免 `UIScreen.main`，从当前前台 `UIWindowScene` 取屏宽
    static var rowSlideOutOffset: CGFloat { Self.preferredScreenWidthForSlideOut() }

    private static func preferredScreenWidthForSlideOut() -> CGFloat {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            if scene.activationState == .foregroundActive || scene.activationState == .foregroundInactive {
                return scene.screen.bounds.width
            }
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return scene.screen.bounds.width
        }
        return 390
    }
    /// 行滑出动画时长（秒）：完成 / 删除 / 恢复共用；改小更快、改大更慢
    static let rowSlideOutDuration: TimeInterval = 0.22
    /// 完成 / 删除 / 恢复共用同一套曲线与时长，仅位移方向（`slideOutSignById` ±1）不同
    static var rowSlideOutAnimation: Animation { .easeOut(duration: rowSlideOutDuration) }

    var activeTodos: [TodoItem] {
        todos.filter { !$0.isCompleted }
    }
    
    var completedTodos: [TodoItem] {
        todos
            .filter(\.isCompleted)
            .sorted { lhs, rhs in
                let left = lhs.completedDate ?? lhs.createdAt
                let right = rhs.completedDate ?? rhs.createdAt
                return left > right
            }
    }

    var recurringTodos: [TodoItem] {
        todos
            .filter { $0.repeatMode != .none }
            .sorted { lhs, rhs in
                let left = lhs.plannedDate ?? lhs.createdAt
                let right = rhs.plannedDate ?? rhs.createdAt
                if left != right { return left < right }
                return lhs.id < rhs.id
            }
    }

    var recurringIncompleteTodos: [TodoItem] {
        recurringTodos.filter { !$0.isCompleted }
    }

    var recurringInProgressCount: Int {
        recurringTodos.filter { !$0.isCompleted && $0.recurringCycleStatus == .active }.count
    }

    var recurringPausedCount: Int {
        recurringTodos.filter { !$0.isCompleted && $0.recurringCycleStatus == .paused }.count
    }

    var recurringTotalCompletedCount: Int {
        recurringTodos.filter(\.isCompleted).count
    }

    fileprivate func recurringCategorySections() -> [TodoRecurringCategorySection] {
        var sections: [TodoRecurringCategorySection] = []
        let listTodos = recurringIncompleteTodos
        for category in TodoLifeCategoryCatalog.available {
            let count = listTodos.filter { $0.taskCategoryId == category.taskCategoryId }.count
            if count > 0 {
                sections.append(
                    TodoRecurringCategorySection(categoryId: category.taskCategoryId, title: category.title)
                )
            }
        }
        let uncategorizedCount = listTodos.filter { todo in
            guard let id = todo.taskCategoryId else { return true }
            return TodoLifeCategoryCatalog.option(for: id) == nil
        }.count
        if uncategorizedCount > 0 {
            sections.append(TodoRecurringCategorySection(categoryId: nil, title: "未分类"))
        }
        return sections
    }

    fileprivate func recurringTodos(in categoryId: Int?) -> [TodoItem] {
        let listTodos = recurringIncompleteTodos
        if let categoryId {
            return listTodos.filter { $0.taskCategoryId == categoryId }
        }
        return listTodos.filter { todo in
            guard let id = todo.taskCategoryId else { return true }
            return TodoLifeCategoryCatalog.option(for: id) == nil
        }
    }

    private let repository = MindFlowRepository.shared

    init() {
        NotificationCenter.default.addObserver(
            forName: .mindFlowDataDidReset,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.loadTodos()
            }
        }
    }

    private func persistTodos() {
        repository.saveTodos(todos)
    }

    func loadTodos() async {
        todos = repository.loadTodos()
    }

    static func makeSampleTodos() -> [TodoItem] {
        makeSampleTodosInternal()
    }

    private static func makeSampleTodosInternal() -> [TodoItem] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        func atTime(on day: Date, hour: Int, minute: Int) -> Date {
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = hour
            components.minute = minute
            components.second = 0
            return calendar.date(from: components) ?? day
        }

        func plan(from date: Date) -> (day: Date, hour: Int, minute: Int) {
            (
                calendar.startOfDay(for: date),
                calendar.component(.hour, from: date),
                calendar.component(.minute, from: date)
            )
        }

        let fitnessPlan = plan(from: calendar.date(byAdding: .day, value: 2, to: atTime(on: today, hour: 14, minute: 20)) ?? now)
        let meditationPlan = plan(from: calendar.date(byAdding: .day, value: 1, to: atTime(on: today, hour: 7, minute: 0)) ?? now)
        let englishPlan = plan(from: calendar.date(byAdding: .minute, value: 45, to: now) ?? now)
        let standPlan = plan(from: calendar.date(byAdding: .hour, value: 3, to: now) ?? now)
        let eyeCarePlan = plan(from: calendar.date(byAdding: .minute, value: 50, to: now) ?? now)
        let accountingPlan = plan(from: calendar.date(byAdding: .day, value: 12, to: atTime(on: today, hour: 21, minute: 0)) ?? now)
        let checkupPlan = plan(from: calendar.date(byAdding: .year, value: 2, to: atTime(on: today, hour: 9, minute: 0)) ?? now)
        let challengePlan = plan(from: calendar.date(byAdding: .day, value: 5, to: atTime(on: today, hour: 8, minute: 0)) ?? now)
        let reviewPlan = plan(from: calendar.date(byAdding: .day, value: 10, to: atTime(on: today, hour: 16, minute: 0)) ?? now)
        let outfitPlan = plan(from: calendar.date(byAdding: .day, value: 3, to: atTime(on: today, hour: 19, minute: 0)) ?? now)
        let challengeDeadline = calendar.date(byAdding: .day, value: 30, to: today) ?? today

        return [
            TodoItem(
                id: 1,
                title: "完成项目文档",
                description: "编写项目说明文档",
                isCompleted: false,
                status: .notStarted,
                priority: .p2,
                createdAt: today,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 9,
                timeSlotEndHour: 12,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId
            ),
            TodoItem(
                id: 26,
                title: "学习 Python 函数",
                description: "掌握函数定义与参数使用",
                isCompleted: false,
                status: .notStarted,
                priority: .p1,
                createdAt: today,
                plannedDate: today,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 20,
                timeSlotStartMinute: 30,
                timeSlotEndHour: 21,
                timeSlotEndMinute: 0,
                plannedTimeSlotHour: 20,
                plannedTimeSlotMinute: 30,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId
            ),
            TodoItem(
                id: 27,
                title: "完成每日游戏任务",
                description: "推进主线关卡",
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: today,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 21,
                timeSlotStartMinute: 0,
                timeSlotEndHour: 21,
                timeSlotEndMinute: 45,
                plannedTimeSlotHour: 21,
                plannedTimeSlotMinute: 0,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId
            ),
            // 周几标签 + 完成率进度条 +「x天后」倒计时
            TodoItem(
                id: 10,
                title: "每周健身 3 次",
                description: "力量 + 有氧",
                isCompleted: false,
                status: .notStarted,
                priority: .p2,
                createdAt: today,
                plannedDate: fitnessPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 14,
                timeSlotStartMinute: 20,
                timeSlotEndHour: 16,
                plannedTimeSlotHour: fitnessPlan.hour,
                plannedTimeSlotMinute: fitnessPlan.minute,
                taskCategoryId: TodoLifeCategoryCatalog.fitnessCategoryId,
                repeatMode: .custom,
                weeklyRepeatWeekdays: [1, 3, 5],
                customRepeatInterval: 1,
                customRepeatPeriod: .week,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 28,
                recurringCompletionRateBasis: 37
            ),
            // 暂停态 + 短横线指示
            TodoItem(
                id: 11,
                title: "晨间冥想",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: meditationPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 7,
                timeSlotEndHour: 7,
                timeSlotEndMinute: 30,
                plannedTimeSlotHour: meditationPlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                customRepeatInterval: 1,
                customRepeatPeriod: .day,
                recurringCycleStatus: .paused,
                recurringCompletedOccurrences: 12,
                recurringCompletionRateBasis: 20
            ),
            // 循环次数上限 + 完成率
            TodoItem(
                id: 12,
                title: "代码审查",
                description: "团队 PR 审查",
                isCompleted: false,
                status: .notStarted,
                priority: .p2,
                createdAt: today,
                plannedDate: meditationPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 10,
                timeSlotEndHour: 11,
                plannedTimeSlotHour: 10,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId,
                repeatMode: .custom,
                repeatLimitKind: .count,
                repeatMaxOccurrences: 24,
                customRepeatInterval: 1,
                customRepeatPeriod: .week,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 18
            ),
            // 无限循环 ∞ 指示
            TodoItem(
                id: 13,
                title: "每日饮水 8 杯",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p4,
                createdAt: today,
                plannedDate: today,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 8,
                timeSlotEndHour: 22,
                plannedTimeSlotHour: 8,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                customRepeatInterval: 1,
                customRepeatPeriod: .day,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 45
            ),
            // 已完成循环（汇总卡「已完成」计数）
            TodoItem(
                id: 14,
                title: "月度穿搭复盘",
                description: nil,
                isCompleted: true,
                status: .completed,
                priority: .p3,
                createdAt: today,
                plannedDate: today,
                completedDate: today,
                completionDurationSeconds: 900,
                timeSlotStartHour: 20,
                timeSlotEndHour: 21,
                taskCategoryId: TodoLifeCategoryCatalog.outfitCategoryId,
                repeatMode: .custom,
                monthlyRepeatDays: [1],
                customRepeatInterval: 1,
                customRepeatPeriod: .month,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 6,
                recurringCompletionRateBasis: 6
            ),
            TodoItem(
                id: 24,
                title: "撰写周报",
                description: nil,
                isCompleted: true,
                status: .completed,
                priority: .p2,
                createdAt: today,
                plannedDate: today,
                completedDate: today,
                completionDurationSeconds: 11_400,
                timeSlotStartHour: 10,
                timeSlotEndHour: 13,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId
            ),
            TodoItem(
                id: 25,
                title: "阅读专业书籍",
                description: nil,
                isCompleted: true,
                status: .completed,
                priority: .p3,
                createdAt: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
                plannedDate: calendar.date(byAdding: .day, value: -1, to: today),
                completedDate: calendar.date(byAdding: .day, value: -1, to: today),
                completionDurationSeconds: 10_620,
                timeSlotStartHour: 20,
                timeSlotEndHour: 21,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId
            ),
            // 工作日标签 +「x分钟后」
            TodoItem(
                id: 15,
                title: "工作日英语听力",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: englishPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: englishPlan.hour,
                timeSlotStartMinute: englishPlan.minute,
                timeSlotEndHour: min(englishPlan.hour + 1, 23),
                plannedTimeSlotHour: englishPlan.hour,
                plannedTimeSlotMinute: englishPlan.minute,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId,
                repeatMode: .custom,
                weeklyRepeatWeekdays: [1, 2, 3, 4, 5],
                customRepeatInterval: 1,
                customRepeatPeriod: .day,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 86,
                recurringCompletionRateBasis: 120
            ),
            // 自定义小时间隔 +「x小时后」
            TodoItem(
                id: 16,
                title: "每 2 小时站立活动",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p4,
                createdAt: today,
                plannedDate: standPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: standPlan.hour,
                timeSlotStartMinute: standPlan.minute,
                timeSlotEndHour: min(standPlan.hour + 1, 23),
                plannedTimeSlotHour: standPlan.hour,
                plannedTimeSlotMinute: standPlan.minute,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                customRepeatInterval: 2,
                customRepeatPeriod: .hour,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 4,
                recurringCompletionRateBasis: 8
            ),
            // 自定义分钟间隔
            TodoItem(
                id: 17,
                title: "每 30 分钟护眼",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p4,
                createdAt: today,
                plannedDate: eyeCarePlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: eyeCarePlan.hour,
                timeSlotStartMinute: eyeCarePlan.minute,
                timeSlotEndHour: eyeCarePlan.hour,
                timeSlotEndMinute: min(eyeCarePlan.minute + 5, 59),
                plannedTimeSlotHour: eyeCarePlan.hour,
                plannedTimeSlotMinute: eyeCarePlan.minute,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                customRepeatInterval: 30,
                customRepeatPeriod: .hour,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 11,
                recurringCompletionRateBasis: 16
            ),
            // 月循环 +「x天后」
            TodoItem(
                id: 18,
                title: "每月 5 号记账",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: accountingPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 21,
                timeSlotEndHour: 22,
                plannedTimeSlotHour: accountingPlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                monthlyRepeatDays: [5],
                customRepeatInterval: 1,
                customRepeatPeriod: .month,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 9,
                recurringCompletionRateBasis: 12
            ),
            // 年循环 +「x年后」
            TodoItem(
                id: 19,
                title: "年度健康体检",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p2,
                createdAt: today,
                plannedDate: checkupPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 9,
                timeSlotEndHour: 11,
                plannedTimeSlotHour: checkupPlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.fitnessCategoryId,
                repeatMode: .custom,
                yearlyRepeatDays: [TodoYearlyRepeatDay(month: 6, day: 15)],
                customRepeatInterval: 1,
                customRepeatPeriod: .year,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 2,
                recurringCompletionRateBasis: 3
            ),
            // 循环截止日
            TodoItem(
                id: 20,
                title: "21 天早起挑战",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p2,
                createdAt: today,
                plannedDate: challengePlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 6,
                timeSlotEndHour: 7,
                plannedTimeSlotHour: challengePlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.lifeCategoryId,
                repeatMode: .custom,
                repeatLimitKind: .deadline,
                repeatUntilDate: challengeDeadline,
                customRepeatInterval: 1,
                customRepeatPeriod: .day,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 14,
                recurringCompletionRateBasis: 21
            ),
            // 隔周循环 +「x周后」
            TodoItem(
                id: 21,
                title: "隔周团队复盘",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: reviewPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 16,
                timeSlotEndHour: 17,
                plannedTimeSlotHour: reviewPlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.workCategoryId,
                repeatMode: .custom,
                customRepeatInterval: 2,
                customRepeatPeriod: .week,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 7,
                recurringCompletionRateBasis: 10
            ),
            // 穿搭分类
            TodoItem(
                id: 22,
                title: "每周日衣橱整理",
                description: nil,
                isCompleted: false,
                status: .notStarted,
                priority: .p3,
                createdAt: today,
                plannedDate: outfitPlan.day,
                completedDate: nil,
                completionDurationSeconds: nil,
                timeSlotStartHour: 19,
                timeSlotEndHour: 20,
                plannedTimeSlotHour: outfitPlan.hour,
                taskCategoryId: TodoLifeCategoryCatalog.outfitCategoryId,
                repeatMode: .custom,
                weeklyRepeatWeekdays: [7],
                customRepeatInterval: 1,
                customRepeatPeriod: .week,
                recurringCycleStatus: .active,
                recurringCompletedOccurrences: 15,
                recurringCompletionRateBasis: 20
            )
        ]
    }

    func addTodo(
        title: String,
        description: String?,
        plannedDate: Date,
        plannedTimeSlotHour: Int,
        plannedTimeSlotMinute: Int,
        plannedDurationMinutes: Int,
        taskCategoryId: Int? = nil,
        priority: TodoPriority = .p3
    ) {
        let newId = (todos.map(\.id).max() ?? 0) + 1
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: plannedDate)
        let (endHour, endMinute) = Self.endTimeComponents(
            startHour: plannedTimeSlotHour,
            startMinute: plannedTimeSlotMinute,
            durationMinutes: plannedDurationMinutes
        )
        let item = TodoItem(
            id: newId,
            title: title,
            description: description,
            isCompleted: false,
            status: .notStarted,
            priority: priority,
            createdAt: Date(),
            plannedDate: dayStart,
            completedDate: nil,
            completionDurationSeconds: nil,
            timeSlotStartHour: plannedTimeSlotHour,
            timeSlotStartMinute: plannedTimeSlotMinute,
            timeSlotEndHour: endHour,
            timeSlotEndMinute: endMinute,
            plannedTimeSlotHour: plannedTimeSlotHour,
            plannedTimeSlotMinute: plannedTimeSlotMinute,
            taskCategoryId: taskCategoryId
        )
        let willGrowActiveCard = todos.filter { !$0.isCompleted }.isEmpty
        if willGrowActiveCard {
            withAnimation(TodoCardMotion.grow) {
                todos.append(item)
            }
        } else {
            todos.append(item)
        }
        persistTodos()
    }

    func updateTodoDescription(id: Int, description: String) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        todos[index].description = trimmed.isEmpty ? nil : description
        persistTodos()
    }

    func toggleTodoWeekday(id: Int, weekday: Int) {
        guard (1...7).contains(weekday),
              let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].weeklyRepeatWeekdays = TodoWeekdayCatalog.toggled(weekday, in: todos[index].weeklyRepeatWeekdays)
        persistTodos()
    }

    func cycleTodoRepeatMode(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        if todos[index].repeatMode == .none {
            todos[index].repeatMode = .custom
            todos[index].recurringCycleStatus = .active
            if todos[index].customRepeatInterval < 1 {
                todos[index].customRepeatInterval = 1
            }
        } else {
            todos[index].repeatMode = .none
        }
        persistTodos()
    }

    func toggleTodoRecurringCycleStatus(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }),
              todos[index].repeatMode != .none else { return }
        todos[index].recurringCycleStatus = todos[index].recurringCycleStatus.toggled
        persistTodos()
    }

    func setTodoRepeatLimitKind(id: Int, kind: TodoRepeatLimitKind) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        switch kind {
        case .unset:
            todos[index].repeatLimitKind = .unset
            todos[index].repeatUntilDate = nil
            todos[index].repeatMaxOccurrences = nil
        case .deadline:
            todos[index].repeatLimitKind = .deadline
            todos[index].repeatMaxOccurrences = nil
        case .count:
            todos[index].repeatLimitKind = .count
            todos[index].repeatUntilDate = nil
            if todos[index].repeatMaxOccurrences == nil {
                todos[index].repeatMaxOccurrences = 1
            }
        }
        persistTodos()
    }

    func updateTodoRepeatUntilDate(id: Int, date: Date) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].repeatLimitKind = .deadline
        todos[index].repeatMaxOccurrences = nil
        todos[index].repeatUntilDate = Calendar.current.startOfDay(for: date)
        persistTodos()
    }

    func updateTodoRepeatMaxOccurrences(id: Int, count: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].repeatLimitKind = .count
        todos[index].repeatUntilDate = nil
        todos[index].repeatMaxOccurrences = max(1, count)
        persistTodos()
    }

    func incrementTodoRepeatMaxOccurrences(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].repeatLimitKind = .count
        todos[index].repeatUntilDate = nil
        let next = (todos[index].repeatMaxOccurrences ?? 0) + 1
        todos[index].repeatMaxOccurrences = next
        persistTodos()
    }

    func decrementTodoRepeatMaxOccurrences(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        guard let count = todos[index].repeatMaxOccurrences else { return }
        if count <= 1 {
            todos[index].repeatMaxOccurrences = nil
            if todos[index].repeatUntilDate == nil {
                todos[index].repeatLimitKind = .unset
            }
        } else {
            todos[index].repeatMaxOccurrences = count - 1
        }
        persistTodos()
    }

    func updateTodoCustomRepeatInterval(id: Int, interval: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].customRepeatInterval = max(1, interval)
        if todos[index].repeatMode != .none {
            todos[index].repeatMode = .custom
        }
        persistTodos()
    }

    func updateTodoCustomRepeatPeriod(id: Int, period: TodoCustomRepeatPeriod) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].customRepeatPeriod = period
        if todos[index].repeatMode != .none {
            todos[index].repeatMode = .custom
        }
        persistTodos()
    }

    func cycleTodoPriority(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].priority = todos[index].priority.next
        persistTodos()
    }

    func updateTodoCategory(id: Int, taskCategoryId: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }),
              TodoLifeCategoryCatalog.option(for: taskCategoryId) != nil else { return }
        todos[index].taskCategoryId = taskCategoryId
        persistTodos()
    }

    func toggleTodoMonthlyRepeatDay(id: Int, day: Int) {
        guard (1...31).contains(day),
              let index = todos.firstIndex(where: { $0.id == id }) else { return }
        if todos[index].monthlyRepeatDays.contains(day) {
            todos[index].monthlyRepeatDays.remove(day)
        } else {
            todos[index].monthlyRepeatDays.insert(day)
        }
        persistTodos()
    }

    func toggleTodoMonthlyRepeatLastDayFallback(id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].monthlyRepeatUsesLastDayFallback.toggle()
        persistTodos()
    }

    func toggleTodoYearlyRepeatDay(id: Int, month: Int, day: Int) {
        guard (1...12).contains(month), (1...31).contains(day),
              let index = todos.firstIndex(where: { $0.id == id }) else { return }
        let anchor = TodoYearlyRepeatDay(month: month, day: day)
        if todos[index].yearlyRepeatDays.contains(anchor) {
            todos[index].yearlyRepeatDays.remove(anchor)
        } else {
            todos[index].yearlyRepeatDays.insert(anchor)
        }
        persistTodos()
    }

    func updateTodoTimeSlot(
        id: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].timeSlotStartHour = startHour
        todos[index].timeSlotStartMinute = startMinute
        todos[index].timeSlotEndHour = endHour
        todos[index].timeSlotEndMinute = endMinute
        persistTodos()
    }

    func updateTodoTimeSlotStart(id: Int, hour: Int, minute: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].timeSlotStartHour = hour
        todos[index].timeSlotStartMinute = minute
        todos[index].createdAt = Self.mergeTime(hour: hour, minute: minute, into: todos[index].createdAt)
        persistTodos()
    }

    @discardableResult
    func tryUpdateTodoTimeSlotStart(id: Int, hour: Int, minute: Int) -> String? {
        guard let index = todos.firstIndex(where: { $0.id == id }) else {
            return "待办不存在"
        }
        var candidate = todos[index]
        candidate.timeSlotStartHour = hour
        candidate.timeSlotStartMinute = minute
        candidate.createdAt = Self.mergeTime(hour: hour, minute: minute, into: candidate.createdAt)
        if let failure = Self.validateSchedule(for: candidate) {
            return failure.alertMessage
        }
        todos[index] = candidate
        persistTodos()
        return nil
    }

    func updateTodoTimeSlotEnd(id: Int, hour: Int, minute: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].timeSlotEndHour = hour
        todos[index].timeSlotEndMinute = minute
        if todos[index].isCompleted, let completedDate = todos[index].completedDate {
            todos[index].completedDate = Self.mergeTime(hour: hour, minute: minute, into: completedDate)
        } else if let endDate = todos[index].endDate {
            todos[index].endDate = Self.mergeTime(hour: hour, minute: minute, into: endDate)
        }
        persistTodos()
    }

    @discardableResult
    func tryUpdateTodoTimeSlotEnd(id: Int, hour: Int, minute: Int) -> String? {
        guard let index = todos.firstIndex(where: { $0.id == id }) else {
            return "待办不存在"
        }
        var candidate = todos[index]
        candidate.timeSlotEndHour = hour
        candidate.timeSlotEndMinute = minute
        if candidate.isCompleted, let completedDate = candidate.completedDate {
            candidate.completedDate = Self.mergeTime(hour: hour, minute: minute, into: completedDate)
        } else if let endDate = candidate.endDate {
            candidate.endDate = Self.mergeTime(hour: hour, minute: minute, into: endDate)
        }
        if let failure = Self.validateSchedule(for: candidate) {
            return failure.alertMessage
        }
        todos[index] = candidate
        persistTodos()
        return nil
    }

    func updateTodoPlannedTimeSlot(id: Int, hour: Int, minute: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].plannedTimeSlotHour = hour
        todos[index].plannedTimeSlotMinute = minute
        if let plannedDate = todos[index].plannedDate {
            todos[index].plannedDate = Self.mergeTime(hour: hour, minute: minute, into: plannedDate)
        }
        persistTodos()
    }

    func updateTodoRepeatMoment(id: Int, hour: Int, minute: Int) {
        updateTodoTimeSlotStart(id: id, hour: hour, minute: minute)
    }

    func updateTodoDate(id: Int, target: TodoDetailDateTarget, date: Date) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        applyTodoDate(date, target: target, to: &todos[index])
        persistTodos()
    }

    @discardableResult
    func tryUpdateTodoDate(id: Int, target: TodoDetailDateTarget, date: Date) -> String? {
        guard let index = todos.firstIndex(where: { $0.id == id }) else {
            return "待办不存在"
        }
        var candidate = todos[index]
        applyTodoDate(date, target: target, to: &candidate)
        if target == .start || target == .end {
            if let failure = Self.validateSchedule(for: candidate) {
                return failure.alertMessage
            }
        }
        todos[index] = candidate
        persistTodos()
        return nil
    }

    private func applyTodoDate(_ date: Date, target: TodoDetailDateTarget, to todo: inout TodoItem) {
        switch target {
        case .start:
            todo.createdAt = Self.mergeCalendarDay(date, into: todo.createdAt)
        case .end:
            let base = todo.completedDate ?? todo.endDate ?? todo.createdAt
            let merged = Self.mergeCalendarDay(date, into: base)
            if todo.isCompleted {
                todo.completedDate = merged
            } else {
                todo.endDate = merged
            }
        case .planned:
            let base = todo.plannedDate ?? todo.createdAt
            todo.plannedDate = Self.mergeCalendarDay(date, into: base)
        }
    }

    static func endTimeComponents(
        startHour: Int,
        startMinute: Int,
        durationMinutes: Int
    ) -> (hour: Int, minute: Int) {
        let start = min(max(startHour, 0), 23) * 60 + min(max(startMinute, 0), 59)
        let end = start + max(1, durationMinutes)
        if end >= 24 * 60 {
            return (24, 0)
        }
        return (end / 60, end % 60)
    }

    static func scheduleStartDateTime(for todo: TodoItem) -> Date {
        mergeTime(
            hour: min(max(todo.plannedTimeSlotHour, 0), 23),
            minute: min(max(todo.plannedTimeSlotMinute, 0), 59),
            into: todo.plannedDate ?? todo.createdAt
        )
    }

    static func isScheduleEndAfterStart(for todo: TodoItem) -> Bool {
        scheduleEndDateTime(for: todo) > scheduleStartDateTime(for: todo)
    }

    private static let maxScheduleSpanSeconds: TimeInterval = 7 * 24 * 3600

    enum ScheduleValidationFailure {
        case endBeforeStart
        case spanExceedsOneWeek

        var alertMessage: String {
            switch self {
            case .endBeforeStart:
                return "结束时间不能早于开始时间"
            case .spanExceedsOneWeek:
                return "开始时间与结束时间的跨度不能超过一周"
            }
        }
    }

    static func validateSchedule(for todo: TodoItem) -> ScheduleValidationFailure? {
        guard isScheduleEndAfterStart(for: todo) else { return .endBeforeStart }
        let span = scheduleEndDateTime(for: todo).timeIntervalSince(scheduleStartDateTime(for: todo))
        if span > maxScheduleSpanSeconds { return .spanExceedsOneWeek }
        return nil
    }

    static func scheduleEndDateTime(for todo: TodoItem) -> Date {
        let base = todo.plannedDate ?? todo.completedDate ?? todo.endDate ?? todo.createdAt
        let endHour = min(max(todo.timeSlotEndHour, 0), 24)
        let endMinute: Int
        let mergeHour: Int
        if endHour == 24 {
            mergeHour = 23
            endMinute = 59
        } else {
            mergeHour = endHour
            endMinute = min(max(todo.timeSlotEndMinute, 0), 59)
        }
        return mergeTime(hour: mergeHour, minute: endMinute, into: base)
    }

    private static func mergeTime(hour: Int, minute: Int, into date: Date) -> Date {
        let cal = Calendar.current
        var components = cal.dateComponents([.year, .month, .day], from: date)
        components.hour = min(max(hour, 0), 23)
        components.minute = min(max(minute, 0), 59)
        components.second = 0
        return cal.date(from: components) ?? date
    }

    private static func mergeCalendarDay(_ day: Date, into existing: Date) -> Date {
        let cal = Calendar.current
        var dayComponents = cal.dateComponents([.year, .month, .day], from: day)
        let timeComponents = cal.dateComponents([.hour, .minute, .second], from: existing)
        dayComponents.hour = timeComponents.hour
        dayComponents.minute = timeComponents.minute
        dayComponents.second = timeComponents.second
        return cal.date(from: dayComponents) ?? day
    }

    private static func applyDurationSeconds(_ durationSeconds: Int, to todo: inout TodoItem) {
        let cal = Calendar.current
        let slot = todo.normalizedTimeSlotHM
        var start = cal.date(bySettingHour: slot.sh, minute: slot.sm, second: 0, of: Date()) ?? Date()
        let end = cal.date(byAdding: .second, value: durationSeconds, to: start) ?? start
        todo.timeSlotEndHour = cal.component(.hour, from: end)
        todo.timeSlotEndMinute = cal.component(.minute, from: end)
        if end <= start {
            todo.timeSlotEndHour = min(24, slot.sh + 1)
            todo.timeSlotEndMinute = slot.sm
        }
    }
    
    func toggleTodo(_ id: Int) async {
        applyToggleTodo(id)
    }

    /// 右滑完成（无列表行动画时仍可用）；带行动画时请用 `beginRowSlideOut(..., .markComplete)`。
    func markCompleteFromSwipe(id: Int) async {
        beginRowSlideOut(id: id, action: .markComplete)
    }

    private func applyToggleTodo(_ id: Int) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].isCompleted.toggle()
        if todos[index].isCompleted {
            let now = Date()
            let todoId = todos[index].id
            let workSeconds = consumeWorkTimerForCompletion(todoId: todoId)
            let duration = todos[index].resolvedCompletionDurationSeconds(timerSeconds: workSeconds)
            todos[index].completedDate = now
            todos[index].completionDurationSeconds = duration
            todos[index].status = .completed
            if todos[index].taskCategoryId == TodoLifeCategoryCatalog.outfitCategoryId {
                OutfitResearchTimeStore.add(seconds: TimeInterval(duration))
            }
        } else {
            todos[index].completedDate = nil
            todos[index].completionDurationSeconds = nil
            todos[index].status = resolvedWorkStatus(for: todos[index])
        }
        persistTodos()
    }

    func beginRowSlideOut(id: Int, action: RowSlideOutAction) {
        guard !slidingOutIds.contains(id), todos.contains(where: { $0.id == id }) else { return }
        switch action {
        case .markComplete:
            guard let t = todos.first(where: { $0.id == id }), !t.isCompleted else { return }
        case .markIncomplete:
            guard let t = todos.first(where: { $0.id == id }), t.isCompleted else { return }
        case .delete:
            break
        }

        let sign: CGFloat = switch action {
        case .delete: -1
        case .markComplete: 1
        case .markIncomplete: -1
        }
        let d = Self.rowSlideOutDuration
        withAnimation(Self.rowSlideOutAnimation) {
            slideOutSignById = slideOutSignById.merging([id: sign], uniquingKeysWith: { _, new in new })
            slidingOutIds = slidingOutIds.union([id])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
            self?.finishRowSlideOut(id: id, action: action)
        }
    }

    private func finishRowSlideOut(id: Int, action: RowSlideOutAction) {
        let cardMotion = cardHeightMotion(after: action, id: id)

        var cleanup = Transaction()
        cleanup.disablesAnimations = true
        withTransaction(cleanup) {
            slidingOutIds = slidingOutIds.subtracting([id])
            slideOutSignById = slideOutSignById.filter { $0.key != id }
        }

        let applyMutation = { [self] in
            switch action {
            case .delete:
                activeWorkByTodoId[id] = nil
                todos.removeAll { $0.id == id }
            case .markComplete, .markIncomplete:
                applyToggleTodo(id)
            }
        }

        switch cardMotion {
        case .shrink:
            withAnimation(TodoCardMotion.shrink, applyMutation)
        case .none:
            var mutation = Transaction()
            mutation.disablesAnimations = true
            withTransaction(mutation, applyMutation)
        }
        persistTodos()
    }

    private enum CardHeightMotion {
        case shrink
        case none
    }

    /// 数据源变更后，当前列表是否会在「有待办 ↔ 无待办」两档高度间切换
    private func cardHeightMotion(after action: RowSlideOutAction, id: Int) -> CardHeightMotion {
        switch action {
        case .delete:
            guard let todo = todos.first(where: { $0.id == id }) else { return .none }
            if todo.isCompleted {
                return todos.filter(\.isCompleted).count == 1 ? .shrink : .none
            }
            return todos.filter { !$0.isCompleted }.count == 1 ? .shrink : .none
        case .markComplete:
            guard todos.contains(where: { $0.id == id && !$0.isCompleted }) else { return .none }
            return todos.filter { !$0.isCompleted }.count == 1 ? .shrink : .none
        case .markIncomplete:
            guard todos.contains(where: { $0.id == id && $0.isCompleted }) else { return .none }
            return todos.filter(\.isCompleted).count == 1 ? .shrink : .none
        }
    }

    /// 删除入口：先左滑出屏，再从数据源移除
    func deleteTodo(_ id: Int) {
        beginRowSlideOut(id: id, action: .delete)
    }

    func resolvedWorkStatus(for todo: TodoItem) -> TodoWorkStatus {
        if todo.isCompleted { return .completed }
        let state = activeWorkByTodoId[todo.id] ?? TodoActiveWorkState()
        if state.runningSince != nil { return .inProgress }
        if state.accumulated > 0.5 || state.pausedLightBandPhaseRadians != nil {
            return .paused
        }
        return .notStarted
    }

    func toggleWorkTimer(todoId: Int) {
        guard todos.contains(where: { $0.id == todoId && !$0.isCompleted }) else { return }
        var state = activeWorkByTodoId[todoId] ?? TodoActiveWorkState()
        let now = Date()
        if let since = state.runningSince {
            let elapsed = now.timeIntervalSince(since)
            state.accumulated += elapsed
            state.runningSince = nil
            state.pausedLightBandPhaseRadians = state.runningSegmentBasePhaseRadians + elapsed * TodoLightBandConstants.angularSpeed
        } else {
            state.runningSince = now
            state.runningSegmentBasePhaseRadians = state.pausedLightBandPhaseRadians ?? TodoLightBandConstants.defaultIdleFramePhaseRadians
            state.pausedLightBandPhaseRadians = nil
            if let index = todos.firstIndex(where: { $0.id == todoId }),
               todos[index].workStartedAt == nil {
                todos[index].workStartedAt = now
            }
        }
        activeWorkByTodoId[todoId] = state
        if let index = todos.firstIndex(where: { $0.id == todoId }) {
            todos[index].status = resolvedWorkStatus(for: todos[index])
        }
        persistTodos()
    }

    func isWorkTimerRunning(todoId: Int) -> Bool {
        activeWorkByTodoId[todoId]?.runningSince != nil
    }

    func workTimerRunningSince(todoId: Int) -> Date? {
        activeWorkByTodoId[todoId]?.runningSince
    }

    func pausedLightBandPhaseRadians(todoId: Int) -> Double? {
        activeWorkByTodoId[todoId]?.pausedLightBandPhaseRadians
    }

    func lightBandRunningBasePhaseRadians(todoId: Int) -> Double {
        activeWorkByTodoId[todoId]?.runningSegmentBasePhaseRadians ?? TodoLightBandConstants.defaultIdleFramePhaseRadians
    }

    func showsWorkTimer(todoId: Int) -> Bool {
        let s = activeWorkByTodoId[todoId] ?? TodoActiveWorkState()
        return s.runningSince != nil || s.accumulated > 0.5 || s.pausedLightBandPhaseRadians != nil
    }

    func currentWorkSeconds(todoId: Int) -> Int {
        var acc = activeWorkByTodoId[todoId]?.accumulated ?? 0
        if let since = activeWorkByTodoId[todoId]?.runningSince {
            acc += Date().timeIntervalSince(since)
        }
        return max(0, Int(acc))
    }

    func investedSeconds(on day: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }

        var total = todos.reduce(into: 0) { partial, todo in
            guard todo.isCompleted,
                  let completedDate = todo.completedDate,
                  completedDate >= start,
                  completedDate < end,
                  let seconds = todo.completionDurationSeconds,
                  seconds > 0 else { return }
            partial += seconds
        }

        if calendar.isDateInToday(day) {
            for todoId in activeWorkByTodoId.keys {
                total += currentWorkSeconds(todoId: todoId)
            }
        }
        return total
    }

    var todayInvestedSeconds: Int {
        investedSeconds(on: Date())
    }

    var yesterdayInvestedSeconds: Int {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return investedSeconds(on: yesterday)
    }

    fileprivate var weeklyTrendDays: [TodoWeeklyTrendDay] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }

        let weekdayLabels = ["一", "二", "三", "四", "五", "六", "日"]
        let days = (0..<7).compactMap { offset -> TodoWeeklyTrendDay? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            return TodoWeeklyTrendDay(
                weekdayLabel: weekdayLabels[offset],
                investedSeconds: investedSeconds(on: day),
                isToday: calendar.isDate(day, inSameDayAs: today)
            )
        }
        let peakSeconds = days.map(\.investedSeconds).max() ?? 0
        guard peakSeconds > 0 else { return days }
        return days.map { day in
            var copy = day
            copy.isPeak = day.investedSeconds == peakSeconds
            return copy
        }
    }

    var weeklyTotalInvestedHoursText: String {
        let totalSeconds = weeklyTrendDays.reduce(0) { $0 + $1.investedSeconds }
        let hours = Double(totalSeconds) / 3600.0
        if hours >= 10 {
            return String(format: "%.0fh", hours)
        }
        return String(format: "%.1fh", hours)
    }

    var weeklyCompletedCount: Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: Date())
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: today) else { return 0 }
        return todos.filter { todo in
            guard todo.isCompleted, let completedDate = todo.completedDate else { return false }
            return interval.contains(completedDate)
        }.count
    }

    func cycleRecommendationType() {
        recommendationType = recommendationType.next
    }

    fileprivate var nextRecommendation: TodoNextRecommendation? {
        guard let todo = recommendedTodo(for: recommendationType) else { return nil }

        let estimatedMinutes = max(1, todo.timeSlotDurationSeconds / 60)
        let categoryIcon: String = {
            if todo.title.contains("Python") {
                return "chevron.left.forwardslash.chevron.right"
            }
            if todo.title.contains("游戏") {
                return "gamecontroller.fill"
            }
            return todo.taskCategoryId.flatMap { TodoLifeCategoryCatalog.option(for: $0)?.icon }
                ?? "chevron.left.forwardslash.chevron.right"
        }()

        return TodoNextRecommendation(
            todoId: todo.id,
            title: todo.title,
            subtitle: todo.description ?? "",
            icon: categoryIcon,
            estimatedMinutes: estimatedMinutes,
            suggestedStartTime: todo.plannedTimeSlotDisplayText
        )
    }

    private func recommendedTodo(for type: TodoRecommendationType) -> TodoItem? {
        let candidates = candidateTodos(for: type)
        switch type {
        case .topPriority:
            return candidates.min(by: compareByPriorityThenStartTime)
        case .mostUrgent:
            return candidates.min(by: compareByScheduledDateThenPriority)
        case .outfit, .fitness, .game:
            return candidates.min(by: compareByPriorityThenStartTime)
        }
    }

    private func candidateTodos(for type: TodoRecommendationType) -> [TodoItem] {
        switch type {
        case .topPriority, .mostUrgent:
            return activeTodos.filter { $0.repeatMode == .none }
        case .outfit:
            return activeTodos.filter { $0.taskCategoryId == TodoLifeCategoryCatalog.outfitCategoryId }
        case .fitness:
            return activeTodos.filter { $0.taskCategoryId == TodoLifeCategoryCatalog.fitnessCategoryId }
        case .game:
            return activeTodos.filter { todo in
                todo.title.contains("游戏") || (todo.description?.contains("游戏") == true)
            }
        }
    }

    private func compareByPriorityThenStartTime(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        let leftOrder = TodoNextRecommendationMetrics.prioritySortOrder(lhs.priority)
        let rightOrder = TodoNextRecommendationMetrics.prioritySortOrder(rhs.priority)
        if leftOrder != rightOrder { return leftOrder < rightOrder }
        if lhs.timeSlotStartHour != rhs.timeSlotStartHour {
            return lhs.timeSlotStartHour < rhs.timeSlotStartHour
        }
        return lhs.timeSlotStartMinute < rhs.timeSlotStartMinute
    }

    private func compareByScheduledDateThenPriority(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        let leftDate = scheduledDate(for: lhs)
        let rightDate = scheduledDate(for: rhs)
        if leftDate != rightDate { return leftDate < rightDate }
        return compareByPriorityThenStartTime(lhs, rhs)
    }

    private func scheduledDate(for todo: TodoItem) -> Date {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: todo.plannedDate ?? todo.createdAt)
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = min(max(todo.plannedTimeSlotHour, 0), 23)
        components.minute = min(max(todo.plannedTimeSlotMinute, 0), 59)
        return calendar.date(from: components) ?? day
    }

    /// 结束计时并返回累计秒数（清空该条待办的计时状态）
    private func consumeWorkTimerForCompletion(todoId: Int) -> Int {
        var state = activeWorkByTodoId.removeValue(forKey: todoId) ?? TodoActiveWorkState()
        if let since = state.runningSince {
            state.accumulated += Date().timeIntervalSince(since)
            state.runningSince = nil
        }
        return max(0, Int(state.accumulated))
    }
}

// MARK: - Todo Model
enum TodoWorkStatus: String, Codable, CaseIterable, Hashable {
    case notStarted
    case inProgress
    case paused
    case completed

    var displayName: String {
        switch self {
        case .notStarted: return "未开始"
        case .inProgress: return "进行中"
        case .paused: return "暂停"
        case .completed: return "已完成"
        }
    }
}

enum TodoPriority: String, Codable, CaseIterable, Hashable {
    case p1
    case p2
    case p3
    case p4

    var displayName: String {
        rawValue.uppercased()
    }

    var next: TodoPriority {
        switch self {
        case .p1: return .p2
        case .p2: return .p3
        case .p3: return .p4
        case .p4: return .p1
        }
    }
}

// MARK: - 待办重复规则

enum TodoRepeatLimitKind: String, Codable, CaseIterable {
    case unset
    case deadline
    case count

    var displayName: String {
        switch self {
        case .unset: return ""
        case .deadline: return "截止时间"
        case .count: return "循环次数"
        }
    }
}

enum TodoCustomRepeatPeriod: String, Codable, CaseIterable {
    case year
    case month
    case week
    case day
    case hour
    case minute

    /// 滚轮展示顺序（不含分钟）
    static let wheelOrder: [TodoCustomRepeatPeriod] = [.hour, .day, .week, .month, .year]

    var displayName: String {
        switch self {
        case .year: return "年"
        case .month: return "月"
        case .week: return "周"
        case .day: return "天"
        case .hour: return "小时"
        case .minute: return "分钟"
        }
    }

    /// 循环规则滚轮展示用（如「时」而非「小时」）
    var wheelDisplayName: String {
        switch self {
        case .hour: return "时"
        default: return displayName
        }
    }

    /// 间隔为 1 时的规则文案（如「每天」「每周」）
    var singularIntervalLabel: String {
        switch self {
        case .day: return "每天"
        case .week: return "每周"
        case .month: return "每月"
        case .year: return "每年"
        case .hour: return "每小时"
        case .minute: return "每分钟"
        }
    }

    func recurringTag(interval: Int) -> String {
        let value = max(1, interval)
        if value == 1 { return singularIntervalLabel }
        return "每\(value)\(displayName)"
    }
}

/// 循环任务周期状态（与任务计时「进行中/暂停」无关）
enum TodoRecurringCycleStatus: String, Codable, CaseIterable {
    case active
    case paused

    var displayName: String {
        switch self {
        case .active: return "进行中"
        case .paused: return "暂停中"
        }
    }

    var toggled: TodoRecurringCycleStatus {
        switch self {
        case .active: return .paused
        case .paused: return .active
        }
    }
}

enum TodoRepeatMode: String, Codable, CaseIterable {
    case none
    case weekly
    case monthly
    case yearly
    case custom

    var displayName: String {
        switch self {
        case .none: return "不循环"
        case .weekly: return "周循环"
        case .monthly: return "月循环"
        case .yearly: return "年循环"
        case .custom: return "循环"
        }
    }

    /// 待办详情循环芯片：仅「不循环 / 循环」
    var cycleChipDisplayName: String {
        switch self {
        case .none: return "不循环"
        case .weekly, .monthly, .yearly, .custom: return "循环"
        }
    }

    var usesRepeatLimit: Bool {
        self != .none
    }

    var next: TodoRepeatMode {
        switch self {
        case .none: return .custom
        case .weekly, .monthly, .yearly, .custom: return .none
        }
    }
}

struct TodoYearlyRepeatDay: Hashable, Codable {
    var month: Int
    var day: Int
}

struct TodoItem: Identifiable, Codable, Hashable {
    let id: Int
    var title: String
    var description: String?
    var isCompleted: Bool
    var status: TodoWorkStatus
    var priority: TodoPriority
    /// 创建时间
    var createdAt: Date
    /// 计划日期（仅日期语义；nil 时回退到 createdAt）
    var plannedDate: Date?
    /// 结束日期（未完成时；nil 时回退到 completedDate 或 createdAt）
    var endDate: Date?
    /// 首次开始计时的时刻
    var workStartedAt: Date?
    var completedDate: Date?
    /// 完成该任务所用耗时（秒），仅在已完成时有值；由完成时刻与 `createdAt` 差值写入
    var completionDurationSeconds: Int?
    /// 时间段开始（0–23 点），未设置时解码默认为 0
    var timeSlotStartHour: Int
    /// 开始分钟 0–59
    var timeSlotStartMinute: Int
    /// 时间段结束（0–24 点；24 仅表示当日 24:00，须与分钟 0 搭配）
    var timeSlotEndHour: Int
    /// 结束分钟 0–59（`timeSlotEndHour == 24` 时忽略，视为 0）
    var timeSlotEndMinute: Int
    /// 计划时间段（时、分），与开始/结束时间段独立
    var plannedTimeSlotHour: Int
    var plannedTimeSlotMinute: Int
    /// 待办分类 ID，对应 `TodoLifeCategoryCatalog`
    var taskCategoryId: Int?
    /// 重复模式
    var repeatMode: TodoRepeatMode
    /// 周重复：1=周一 … 7=周日
    var weeklyRepeatWeekdays: Set<Int>
    /// 月重复：每月第几天 1…31
    var monthlyRepeatDays: Set<Int>
    /// 月重复：所选 29/30/31 在无该日月份时是否改为当月最后一天
    var monthlyRepeatUsesLastDayFallback: Bool
    /// 年重复：月-日
    var yearlyRepeatDays: Set<TodoYearlyRepeatDay>
    /// 周/年重复：截止时间与循环次数二选一；均未设置时为无限循环
    var repeatLimitKind: TodoRepeatLimitKind
    /// 重复截止日期（`repeatLimitKind == .deadline` 时有效）
    var repeatUntilDate: Date?
    /// 最大循环次数（`repeatLimitKind == .count` 时有效）
    var repeatMaxOccurrences: Int?
    /// 自定义循环：间隔数值
    var customRepeatInterval: Int
    /// 自定义循环：间隔单位
    var customRepeatPeriod: TodoCustomRepeatPeriod
    /// 循环周期状态：进行中 / 暂停中
    var recurringCycleStatus: TodoRecurringCycleStatus
    /// 累计完成循环次数（展示用）
    var recurringCompletedOccurrences: Int
    /// 完成率分母；未设置时回退到 `repeatMaxOccurrences`
    var recurringCompletionRateBasis: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, description, isCompleted, status, priority, createdAt, plannedDate, endDate, workStartedAt, completedDate
        case completionDurationSeconds
        case timeSlotStartHour, timeSlotStartMinute, timeSlotEndHour, timeSlotEndMinute
        case plannedTimeSlotHour, plannedTimeSlotMinute
        case taskCategoryId
        case repeatMode
        case weeklyRepeatWeekdays
        case monthlyRepeatDays
        case monthlyRepeatUsesLastDayFallback
        case yearlyRepeatDays
        case repeatLimitKind
        case repeatUntilDate
        case repeatMaxOccurrences
        case customRepeatInterval
        case customRepeatPeriod
        case recurringCycleStatus
        case recurringCompletedOccurrences
        case recurringCompletionRateBasis
    }

    init(
        id: Int,
        title: String,
        description: String?,
        isCompleted: Bool,
        status: TodoWorkStatus = .notStarted,
        priority: TodoPriority = .p3,
        createdAt: Date,
        plannedDate: Date? = nil,
        endDate: Date? = nil,
        workStartedAt: Date? = nil,
        completedDate: Date?,
        completionDurationSeconds: Int? = nil,
        timeSlotStartHour: Int = 0,
        timeSlotStartMinute: Int = 0,
        timeSlotEndHour: Int = 1,
        timeSlotEndMinute: Int = 0,
        plannedTimeSlotHour: Int? = nil,
        plannedTimeSlotMinute: Int? = nil,
        taskCategoryId: Int? = nil,
        repeatMode: TodoRepeatMode = .none,
        weeklyRepeatWeekdays: Set<Int> = [],
        monthlyRepeatDays: Set<Int> = [],
        monthlyRepeatUsesLastDayFallback: Bool = false,
        yearlyRepeatDays: Set<TodoYearlyRepeatDay> = [],
        repeatLimitKind: TodoRepeatLimitKind = .unset,
        repeatUntilDate: Date? = nil,
        repeatMaxOccurrences: Int? = nil,
        customRepeatInterval: Int = 1,
        customRepeatPeriod: TodoCustomRepeatPeriod = .week,
        recurringCycleStatus: TodoRecurringCycleStatus = .active,
        recurringCompletedOccurrences: Int = 0,
        recurringCompletionRateBasis: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.status = isCompleted ? .completed : status
        self.priority = priority
        self.createdAt = createdAt
        let dayStart = Calendar.current.startOfDay(for: createdAt)
        self.plannedDate = plannedDate ?? dayStart
        self.endDate = endDate ?? dayStart
        self.workStartedAt = workStartedAt
        self.completedDate = completedDate
        self.completionDurationSeconds = completionDurationSeconds
        self.timeSlotStartHour = timeSlotStartHour
        self.timeSlotStartMinute = timeSlotStartMinute
        self.timeSlotEndHour = timeSlotEndHour
        self.timeSlotEndMinute = timeSlotEndMinute
        self.plannedTimeSlotHour = plannedTimeSlotHour ?? timeSlotStartHour
        self.plannedTimeSlotMinute = plannedTimeSlotMinute ?? timeSlotStartMinute
        self.taskCategoryId = taskCategoryId
        self.repeatMode = repeatMode
        self.weeklyRepeatWeekdays = weeklyRepeatWeekdays
        self.monthlyRepeatDays = monthlyRepeatDays
        self.monthlyRepeatUsesLastDayFallback = monthlyRepeatUsesLastDayFallback
        self.yearlyRepeatDays = yearlyRepeatDays
        self.repeatLimitKind = repeatLimitKind
        self.repeatUntilDate = repeatUntilDate
        self.repeatMaxOccurrences = repeatMaxOccurrences
        self.customRepeatInterval = max(1, customRepeatInterval)
        self.customRepeatPeriod = customRepeatPeriod
        self.recurringCycleStatus = repeatMode == .none ? .active : recurringCycleStatus
        self.recurringCompletedOccurrences = max(0, recurringCompletedOccurrences)
        self.recurringCompletionRateBasis = recurringCompletionRateBasis
        normalizeLegacyRepeatMode()
    }

    /// 将旧版周/月/年循环统一迁移为「循环」模式
    mutating func normalizeLegacyRepeatMode() {
        switch repeatMode {
        case .weekly:
            repeatMode = .custom
            customRepeatInterval = max(1, customRepeatInterval)
            customRepeatPeriod = .week
        case .monthly:
            repeatMode = .custom
            customRepeatInterval = max(1, customRepeatInterval)
            customRepeatPeriod = .month
        case .yearly:
            repeatMode = .custom
            customRepeatInterval = max(1, customRepeatInterval)
            customRepeatPeriod = .year
        case .none, .custom:
            break
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        status = try container.decodeIfPresent(TodoWorkStatus.self, forKey: .status)
            ?? (isCompleted ? .completed : .notStarted)
        priority = try container.decodeIfPresent(TodoPriority.self, forKey: .priority) ?? .p3
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        plannedDate = try container.decodeIfPresent(Date.self, forKey: .plannedDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        workStartedAt = try container.decodeIfPresent(Date.self, forKey: .workStartedAt)
        completedDate = try container.decodeIfPresent(Date.self, forKey: .completedDate)
        completionDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .completionDurationSeconds)
        timeSlotStartHour = try container.decodeIfPresent(Int.self, forKey: .timeSlotStartHour) ?? 0
        timeSlotStartMinute = try container.decodeIfPresent(Int.self, forKey: .timeSlotStartMinute) ?? 0
        timeSlotEndHour = try container.decodeIfPresent(Int.self, forKey: .timeSlotEndHour) ?? 1
        timeSlotEndMinute = try container.decodeIfPresent(Int.self, forKey: .timeSlotEndMinute) ?? 0
        plannedTimeSlotHour = try container.decodeIfPresent(Int.self, forKey: .plannedTimeSlotHour) ?? timeSlotStartHour
        plannedTimeSlotMinute = try container.decodeIfPresent(Int.self, forKey: .plannedTimeSlotMinute) ?? timeSlotStartMinute
        taskCategoryId = try container.decodeIfPresent(Int.self, forKey: .taskCategoryId)
        repeatMode = try container.decodeIfPresent(TodoRepeatMode.self, forKey: .repeatMode) ?? .none
        if let days = try container.decodeIfPresent([Int].self, forKey: .weeklyRepeatWeekdays) {
            weeklyRepeatWeekdays = Set(days.filter { (1...7).contains($0) })
        } else {
            weeklyRepeatWeekdays = []
        }
        if let days = try container.decodeIfPresent([Int].self, forKey: .monthlyRepeatDays) {
            monthlyRepeatDays = Set(days.filter { (1...31).contains($0) })
        } else {
            monthlyRepeatDays = []
        }
        monthlyRepeatUsesLastDayFallback = try container.decodeIfPresent(
            Bool.self,
            forKey: .monthlyRepeatUsesLastDayFallback
        ) ?? false
        if let anchors = try container.decodeIfPresent([TodoYearlyRepeatDay].self, forKey: .yearlyRepeatDays) {
            yearlyRepeatDays = Set(anchors.filter { (1...12).contains($0.month) && (1...31).contains($0.day) })
        } else {
            yearlyRepeatDays = []
        }
        if repeatMode == .none, !weeklyRepeatWeekdays.isEmpty {
            repeatMode = .custom
            customRepeatInterval = 1
            customRepeatPeriod = .week
        }
        repeatLimitKind = try container.decodeIfPresent(TodoRepeatLimitKind.self, forKey: .repeatLimitKind) ?? .unset
        repeatUntilDate = try container.decodeIfPresent(Date.self, forKey: .repeatUntilDate)
        repeatMaxOccurrences = try container.decodeIfPresent(Int.self, forKey: .repeatMaxOccurrences)
        if repeatUntilDate == nil, repeatMaxOccurrences == nil {
            repeatLimitKind = .unset
        }
        customRepeatInterval = max(1, try container.decodeIfPresent(Int.self, forKey: .customRepeatInterval) ?? 1)
        customRepeatPeriod = try container.decodeIfPresent(TodoCustomRepeatPeriod.self, forKey: .customRepeatPeriod) ?? .week
        recurringCycleStatus = try container.decodeIfPresent(
            TodoRecurringCycleStatus.self,
            forKey: .recurringCycleStatus
        ) ?? .active
        recurringCompletedOccurrences = max(
            0,
            try container.decodeIfPresent(Int.self, forKey: .recurringCompletedOccurrences) ?? 0
        )
        recurringCompletionRateBasis = try container.decodeIfPresent(Int.self, forKey: .recurringCompletionRateBasis)
        let dayStart = Calendar.current.startOfDay(for: createdAt)
        if plannedDate == nil {
            plannedDate = dayStart
        }
        if endDate == nil {
            endDate = dayStart
        }
        normalizeLegacyRepeatMode()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(status, forKey: .status)
        try container.encode(priority, forKey: .priority)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(plannedDate, forKey: .plannedDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(workStartedAt, forKey: .workStartedAt)
        try container.encodeIfPresent(completedDate, forKey: .completedDate)
        try container.encodeIfPresent(completionDurationSeconds, forKey: .completionDurationSeconds)
        try container.encode(timeSlotStartHour, forKey: .timeSlotStartHour)
        try container.encode(timeSlotStartMinute, forKey: .timeSlotStartMinute)
        try container.encode(timeSlotEndHour, forKey: .timeSlotEndHour)
        try container.encode(timeSlotEndMinute, forKey: .timeSlotEndMinute)
        try container.encode(plannedTimeSlotHour, forKey: .plannedTimeSlotHour)
        try container.encode(plannedTimeSlotMinute, forKey: .plannedTimeSlotMinute)
        try container.encodeIfPresent(taskCategoryId, forKey: .taskCategoryId)
        try container.encode(repeatMode, forKey: .repeatMode)
        try container.encode(Array(weeklyRepeatWeekdays.sorted()), forKey: .weeklyRepeatWeekdays)
        try container.encode(Array(monthlyRepeatDays.sorted()), forKey: .monthlyRepeatDays)
        try container.encode(monthlyRepeatUsesLastDayFallback, forKey: .monthlyRepeatUsesLastDayFallback)
        try container.encode(Array(yearlyRepeatDays).sorted {
            $0.month != $1.month ? $0.month < $1.month : $0.day < $1.day
        }, forKey: .yearlyRepeatDays)
        try container.encode(repeatLimitKind, forKey: .repeatLimitKind)
        try container.encodeIfPresent(repeatUntilDate, forKey: .repeatUntilDate)
        try container.encodeIfPresent(repeatMaxOccurrences, forKey: .repeatMaxOccurrences)
        try container.encode(customRepeatInterval, forKey: .customRepeatInterval)
        try container.encode(customRepeatPeriod, forKey: .customRepeatPeriod)
        try container.encode(recurringCycleStatus, forKey: .recurringCycleStatus)
        try container.encode(recurringCompletedOccurrences, forKey: .recurringCompletedOccurrences)
        try container.encodeIfPresent(recurringCompletionRateBasis, forKey: .recurringCompletionRateBasis)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension TodoItem {
    var isRecurring: Bool { repeatMode != .none }

    /// 月重复：将所选「日」解析为指定年月的实际触发日；无该日且未开启月末回退时返回 nil（跳过该月）
    static func resolvedMonthlyRepeatDay(
        _ selectedDay: Int,
        month: Int,
        year: Int,
        usesLastDayFallback: Bool,
        calendar: Calendar = .current
    ) -> Int? {
        guard (1...31).contains(selectedDay),
              let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return nil
        }
        let lastDay = dayRange.count
        if selectedDay <= lastDay { return selectedDay }
        return usesLastDayFallback ? lastDay : nil
    }

    /// 判断指定日期是否命中月重复规则（以计划日期为锚点）
    func matchesMonthlyRepeat(on date: Date, calendar: Calendar = .current) -> Bool {
        guard repeatMode == .monthly, let plannedDate else { return false }
        let anchorDay = calendar.component(.day, from: plannedDate)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        return Self.resolvedMonthlyRepeatDay(
            anchorDay,
            month: month,
            year: year,
            usesLastDayFallback: monthlyRepeatUsesLastDayFallback,
            calendar: calendar
        ) == day
    }

    /// 判断指定日期是否命中周重复规则（以计划日期的星期为锚点，周一=1 … 周日=7）
    func matchesWeeklyRepeat(on date: Date, calendar: Calendar = .current) -> Bool {
        guard repeatMode == .weekly, let plannedDate else { return false }
        return Self.weekdayIndex(for: date, calendar: calendar)
            == Self.weekdayIndex(for: plannedDate, calendar: calendar)
    }

    /// 判断指定日期是否命中年重复规则（以计划日期的月-日为锚点）
    func matchesYearlyRepeat(on date: Date, calendar: Calendar = .current) -> Bool {
        guard repeatMode == .yearly, let plannedDate else { return false }
        let plannedMonth = calendar.component(.month, from: plannedDate)
        let plannedDay = calendar.component(.day, from: plannedDate)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return month == plannedMonth && day == plannedDay
    }

    /// 判断指定日期是否命中自定义循环规则（以计划日期为锚点）
    func matchesCustomRepeat(on date: Date, calendar: Calendar = .current) -> Bool {
        guard repeatMode == .custom, let plannedDate else { return false }
        let anchor = calendar.startOfDay(for: plannedDate)
        let target = calendar.startOfDay(for: date)
        guard target >= anchor else { return false }

        let interval = max(1, customRepeatInterval)
        switch customRepeatPeriod {
        case .minute, .hour:
            guard let anchorDateTime = plannedDateTimeAnchor(calendar: calendar) else { return false }
            let targetDateTime = calendar.date(
                bySettingHour: min(max(plannedTimeSlotHour, 0), 23),
                minute: min(max(plannedTimeSlotMinute, 0), 59),
                second: 0,
                of: target
            ) ?? target
            guard targetDateTime >= anchorDateTime else { return false }
            let delta: Int
            if customRepeatPeriod == .minute {
                delta = calendar.dateComponents([.minute], from: anchorDateTime, to: targetDateTime).minute ?? 0
            } else {
                delta = calendar.dateComponents([.hour], from: anchorDateTime, to: targetDateTime).hour ?? 0
            }
            guard delta >= 0 else { return false }
            return delta % interval == 0
        case .day:
            let days = calendar.dateComponents([.day], from: anchor, to: target).day ?? 0
            return days % interval == 0
        case .week:
            let days = calendar.dateComponents([.day], from: anchor, to: target).day ?? 0
            guard days >= 0, days % 7 == 0 else { return false }
            return (days / 7) % interval == 0
        case .month:
            let months = calendar.dateComponents([.month], from: anchor, to: target).month ?? 0
            guard months >= 0, months % interval == 0 else { return false }
            guard let expected = calendar.date(byAdding: .month, value: months, to: anchor) else { return false }
            return calendar.isDate(expected, inSameDayAs: target)
        case .year:
            let years = calendar.dateComponents([.year], from: anchor, to: target).year ?? 0
            guard years >= 0, years % interval == 0 else { return false }
            guard let expected = calendar.date(byAdding: .year, value: years, to: anchor) else { return false }
            return calendar.isDate(expected, inSameDayAs: target)
        }
    }

    func matchesRepeat(on date: Date, calendar: Calendar = .current) -> Bool {
        switch repeatMode {
        case .none: return false
        case .weekly: return matchesWeeklyRepeat(on: date, calendar: calendar)
        case .monthly: return matchesMonthlyRepeat(on: date, calendar: calendar)
        case .yearly: return matchesYearlyRepeat(on: date, calendar: calendar)
        case .custom: return matchesCustomRepeat(on: date, calendar: calendar)
        }
    }

    static func weekdayIndex(for date: Date, calendar: Calendar = .current) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 ? 7 : weekday - 1
    }

    /// 规范化后的起止（时、分）；结束可表示为 24:00；非法时回退为 0:00–1:00
    var normalizedTimeSlotHM: (sh: Int, sm: Int, eh: Int, em: Int) {
        var sh = min(max(timeSlotStartHour, 0), 23)
        var sm = min(max(timeSlotStartMinute, 0), 59)
        var eh = min(max(timeSlotEndHour, 0), 24)
        var em = min(max(timeSlotEndMinute, 0), 59)
        if eh == 24 { em = 0 }
        let sMin = sh * 60 + sm
        var eMin: Int
        if eh == 24 {
            eMin = 24 * 60
        } else {
            eMin = eh * 60 + em
        }
        if eMin <= sMin {
            return (0, 0, 1, 0)
        }
        if eh == 24 {
            return (sh, sm, 24, 0)
        }
        return (sh, sm, eh, em)
    }

    /// 兼容旧逻辑：仅整点起止小时（用于分组等仅需小时的场景）
    var normalizedTimeSlot: (start: Int, end: Int) {
        let h = normalizedTimeSlotHM
        return (h.sh, h.eh == 24 ? 24 : h.eh)
    }

    /// 根据任务开始小时归入四个时段之一
    var periodBucket: TodoDayPeriod {
        let start = normalizedTimeSlotHM.sh
        switch start {
        case 0..<6: return .dawn
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        default: return .evening
        }
    }

    var timeSlotDisplayText: String {
        "\(plannedDateOnlyDisplayText) \(plannedTimeSlotDisplayText)"
    }

    /// 今日待办卡片副标题：仅显示开始时刻
    var todayCardTimeDisplayText: String {
        timeSlotStartDisplayText
    }

    var timeSlotStartDisplayText: String {
        let c = normalizedTimeSlotHM
        return String(format: "%02d:%02d", c.sh, c.sm)
    }

    var timeSlotEndDisplayText: String {
        let c = normalizedTimeSlotHM
        if c.eh == 24 { return "24:00" }
        return String(format: "%02d:%02d", c.eh, c.em)
    }

    /// 详情页：开始时间段（直接读存储值，避免非法区间被展示成 0:00）
    var detailStartSlotDisplayText: String {
        String(
            format: "%02d:%02d",
            min(max(timeSlotStartHour, 0), 23),
            min(max(timeSlotStartMinute, 0), 59)
        )
    }

    /// 详情页：结束时间段（直接读存储值）
    var detailEndSlotDisplayText: String {
        let endHour = min(max(timeSlotEndHour, 0), 24)
        if endHour == 24 { return "24:00" }
        return String(
            format: "%02d:%02d",
            endHour,
            min(max(timeSlotEndMinute, 0), 59)
        )
    }

    var plannedTimeSlotDisplayText: String {
        let hour = min(max(plannedTimeSlotHour, 0), 23)
        let minute = min(max(plannedTimeSlotMinute, 0), 59)
        return String(format: "%02d:%02d", hour, minute)
    }

    /// 计划时段时长文案，如「3 小时」
    var timeSlotDurationDisplayText: String {
        Self.durationDisplayText(seconds: timeSlotDurationSeconds)
    }

    var timeSlotDurationUsesMultilineDisplay: Bool {
        timeSlotDurationDisplayText.contains("\n")
    }

    /// 投入时长文案；未开始计时时返回 nil（展示占位横线）
    func investedDurationDisplayText(liveTimerSeconds: Int) -> String? {
        if isCompleted, let sec = completionDurationSeconds, sec >= 0 {
            return Self.durationDisplayText(seconds: sec)
        }
        if liveTimerSeconds > 0 {
            return Self.durationDisplayText(seconds: liveTimerSeconds)
        }
        if workStartedAt == nil {
            return nil
        }
        return "0 分钟"
    }

    static func durationDisplayText(seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) 秒" }
        if seconds < 3600 {
            let m = seconds / 60
            return m == 1 ? "1 分钟" : "\(m) 分钟"
        }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if m == 0 { return h == 1 ? "1 小时" : "\(h) 小时" }
        let hourText = h == 1 ? "1 小时" : "\(h) 小时"
        let minuteText = m == 1 ? "1 分钟" : "\(m) 分钟"
        return "\(hourText)\n\(minuteText)"
    }

    /// 详情页：创建日期 yyyy-MM-dd
    var createdDateOnlyDisplayText: String {
        TodoDetailDateFormatting.dateOnly.string(from: createdAt)
    }

    /// 详情页：计划日期 yyyy-MM-dd
    var plannedDateOnlyDisplayText: String {
        TodoDetailDateFormatting.dateOnly.string(from: plannedDate ?? createdAt)
    }

    /// 详情页：循环截止日期 yyyy-MM-dd
    var repeatUntilDateOnlyDisplayText: String? {
        repeatUntilDate.map { TodoDetailDateFormatting.dateOnly.string(from: $0) }
    }

    var isInfiniteRepeat: Bool {
        repeatUntilDate == nil && repeatMaxOccurrences == nil
    }

    var repeatDeadlineSummaryText: String {
        repeatUntilDateOnlyDisplayText ?? "—"
    }

    var repeatCountSummaryText: String {
        repeatMaxOccurrences.map { "\($0) 次" } ?? "—"
    }

    var recurringNextOccurrenceStart: Date {
        plannedDateTimeAnchor() ?? plannedDate ?? createdAt
    }

    func plannedDateTimeAnchor(calendar: Calendar = .current) -> Date? {
        let base = plannedDate ?? createdAt
        var components = calendar.dateComponents([.year, .month, .day], from: base)
        components.hour = min(max(plannedTimeSlotHour, 0), 23)
        components.minute = min(max(plannedTimeSlotMinute, 0), 59)
        components.second = 0
        return calendar.date(from: components)
    }

    func recurringNextStartTimePhrase(at now: Date = Date()) -> String? {
        let target = recurringNextOccurrenceStart
        guard target > now else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now, to: target)
        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        if years >= 1 {
            return "\(years)年后"
        }
        if months >= 1 {
            return "\(months)月后"
        }
        if days >= 7 {
            let weeks = days / 7
            return "\(weeks)周后"
        }
        if days >= 1 {
            return "\(days)天后"
        }
        if hours >= 1 {
            return "\(hours)小时后"
        }
        if minutes >= 1 {
            return "\(minutes)分钟后"
        }
        return "马上"
    }

    /// 循环方法标签（不含次数、截止等规则）
    var recurringMethodTag: String? {
        guard repeatMode != .none else { return nil }
        if !weeklyRepeatWeekdays.isEmpty,
           let weekLabel = TodoWeekdayCatalog.compactWeeklyTag(from: weeklyRepeatWeekdays) {
            return weekLabel
        }
        return customRepeatPeriod.recurringTag(interval: customRepeatInterval)
    }

    var recurringCompletionRatePercent: Int? {
        let basis = recurringCompletionRateBasis ?? repeatMaxOccurrences
        guard let basis, basis > 0 else { return nil }
        return min(100, (recurringCompletedOccurrences * 100 + basis / 2) / basis)
    }

    var recurringStatusDisplayName: String {
        if isCompleted { return "已完成" }
        return recurringCycleStatus.displayName
    }

    /// 详情页：实际开始日期（首次计时）
    var workStartedDateOnlyDisplayText: String? {
        workStartedAt.map { TodoDetailDateFormatting.dateOnly.string(from: $0) }
    }

    /// 详情页：实际开始时间段
    var workStartedSlotDisplayText: String? {
        workStartedAt.map { TodoDetailDateFormatting.timeOnly.string(from: $0) }
    }

    /// 详情页：实际完成日期
    var actualCompletedDateOnlyDisplayText: String? {
        completedDate.map { TodoDetailDateFormatting.dateOnly.string(from: $0) }
    }

    /// 详情页：实际完成时间段
    var actualCompletedSlotDisplayText: String? {
        completedDate.map { TodoDetailDateFormatting.timeOnly.string(from: $0) }
    }

    /// 详情页：结束日期 yyyy-MM-dd
    var endDateOnlyDisplayText: String {
        if let completedDate {
            return TodoDetailDateFormatting.dateOnly.string(from: completedDate)
        }
        return TodoDetailDateFormatting.dateOnly.string(from: endDate ?? createdAt)
    }

    func date(for target: TodoDetailDateTarget) -> Date {
        switch target {
        case .start:
            return createdAt
        case .end:
            return completedDate ?? endDate ?? createdAt
        case .planned:
            return plannedDate ?? createdAt
        }
    }

    /// 计划时间段的总时长（秒）：按开始/结束的完整日期时间差计算
    var timeSlotDurationSeconds: Int {
        let start = TodoViewModel.scheduleStartDateTime(for: self)
        let end = TodoViewModel.scheduleEndDateTime(for: self)
        return max(0, Int(end.timeIntervalSince(start)))
    }

    /// 完成用时：优先计时器累计；未计时时取计划时间段全长
    func resolvedCompletionDurationSeconds(timerSeconds: Int) -> Int {
        if timerSeconds > 0 {
            return timerSeconds
        }
        return timeSlotDurationSeconds
    }

    /// 待办关联的生活分类名称，如「穿搭」
    var taskCategoryLabel: String? {
        guard let id = taskCategoryId else { return nil }
        return TodoLifeCategoryCatalog.option(for: id)?.title
    }

    /// 列表已完成卡片副标题：已用时：2 分钟
    var completionDurationCardSubtitle: String? {
        guard let text = completionDurationDisplayText else { return nil }
        let body = text.replacingOccurrences(of: "用时 ", with: "")
        return "已用时：\(body)"
    }

    /// 卡片/详情用紧凑用时：3h、45m、30s、2d 等
    var completionDurationCompactText: String? {
        guard isCompleted, let sec = completionDurationSeconds, sec >= 0 else { return nil }
        if sec < 60 {
            return "\(sec)s"
        }
        if sec < 3600 {
            let m = sec / 60
            let s = sec % 60
            return s == 0 ? "\(m)m" : "\(m)m\(s)s"
        }
        if sec < 86_400 {
            let h = sec / 3600
            let m = (sec % 3600) / 60
            return m == 0 ? "\(h)h" : "\(h)h\(m)m"
        }
        let d = sec / 86_400
        let rem = sec % 86_400
        let h = rem / 3600
        return h == 0 ? "\(d)d" : "\(d)d\(h)h"
    }

    /// 完成耗时展示文案（详情等完整句式），未完成或无数据时为 `nil`
    var completionDurationDisplayText: String? {
        guard isCompleted, let sec = completionDurationSeconds, sec >= 0 else { return nil }
        if sec < 60 {
            return "用时 \(sec) 秒"
        }
        if sec < 3600 {
            let m = sec / 60
            let s = sec % 60
            return s == 0 ? "用时 \(m) 分钟" : "用时 \(m) 分 \(s) 秒"
        }
        if sec < 86_400 {
            let h = sec / 3600
            let m = (sec % 3600) / 60
            return m == 0 ? "用时 \(h) 小时" : "用时 \(h) 小时 \(m) 分钟"
        }
        let d = sec / 86_400
        let rem = sec % 86_400
        let h = rem / 3600
        if h == 0 {
            return "用时 \(d) 天"
        }
        return "用时 \(d) 天 \(h) 小时"
    }
}

private enum AddTodoFormMode: String, CaseIterable, Identifiable {
    case task
    case list
    case voice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .task: return "待办"
        case .list: return "清单"
        case .voice: return "语音"
        }
    }

    var icon: String {
        switch self {
        case .task: return "doc.text"
        case .list: return "list.bullet"
        case .voice: return "mic.fill"
        }
    }
}

// MARK: - 新建待办（自定义底部面板）
private struct AddTodoSheet: View {
    private enum PlannedTimeField { case date, timeSlot, duration }

    @ObservedObject var viewModel: TodoViewModel
    var panelExpanded: Bool
    let onDismiss: () -> Void
    @State private var formMode: AddTodoFormMode = .task
    @State private var selectedCategoryId: Int = TodoLifeCategoryCatalog.available[0].taskCategoryId
    @State private var selectedPriority: TodoPriority = .p3
    @State private var showsCategoryPicker = false
    @State private var titleText = ""
    @State private var descriptionText = ""
    @State private var plannedDate: Date
    @State private var plannedTime: Date
    @State private var durationHours: Int = 1
    @State private var durationMinutes: Int = 0
    @State private var expandedPlannedField: PlannedTimeField?
    @State private var draftPlannedDate: Date
    @State private var draftPlannedTime: Date
    @State private var draftDurationHours: Int = 1
    @State private var draftDurationMinutes: Int = 0
    @State private var allowTitleKeyboard = true
    @FocusState private var isNotesFieldFocused: Bool

    private static let timeHMFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "H:mm"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    private static let dateYMDFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    init(viewModel: TodoViewModel, panelExpanded: Bool, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.panelExpanded = panelExpanded
        self.onDismiss = onDismiss
        let today = Calendar.current.startOfDay(for: Date())
        let time = Self.defaultPlannedTime()
        _plannedDate = State(initialValue: today)
        _plannedTime = State(initialValue: time)
        _draftPlannedDate = State(initialValue: today)
        _draftPlannedTime = State(initialValue: time)
    }

    private static func defaultPlannedTime() -> Date {
        let cal = Calendar.current
        let now = Date()
        return cal.date(from: cal.dateComponents([.year, .month, .day, .hour, .minute], from: now)) ?? now
    }

    private func applyDefaultTimeSlot() {
        let today = Calendar.current.startOfDay(for: Date())
        let time = Self.defaultPlannedTime()
        plannedDate = today
        plannedTime = time
        durationHours = 1
        durationMinutes = 0
        expandedPlannedField = nil
        selectedCategoryId = TodoLifeCategoryCatalog.available[0].taskCategoryId
        selectedPriority = .p3
        formMode = .task
        titleText = ""
        descriptionText = ""
        allowTitleKeyboard = true
    }

    private func dismissAllInputs() {
        isNotesFieldFocused = false
        expandedPlannedField = nil
        allowTitleKeyboard = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func submitTodo() {
        let t = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cal = Calendar.current
        let hour = cal.component(.hour, from: plannedTime)
        let minute = cal.component(.minute, from: plannedTime)
        viewModel.addTodo(
            title: t.isEmpty ? "未命名待办" : t,
            description: d.isEmpty ? nil : d,
            plannedDate: plannedDate,
            plannedTimeSlotHour: hour,
            plannedTimeSlotMinute: minute,
            plannedDurationMinutes: max(1, durationHours * 60 + durationMinutes),
            taskCategoryId: selectedCategoryId,
            priority: selectedPriority
        )
        titleText = ""
        descriptionText = ""
        dismissAllInputs()
        onDismiss()
    }

    private var sheetDragHandle: some View {
        Capsule()
            .fill(Color(hex: "#C7C7CC"))
            .frame(width: 36, height: 4)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var modeSelectorBar: some View {
        HStack(spacing: 8) {
            ForEach(AddTodoFormMode.allCases) { mode in
                let isSelected = formMode == mode
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        formMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.caption.weight(.semibold))
                        Text(mode.title)
                            .font(.subheadline.weight(.semibold))
                        if mode == .voice {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "#F5B301"))
                        }
                    }
                    .foregroundStyle(isSelected ? Color.white : MindFlowFormSheetStyle.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isSelected ? MindFlowFormSheetStyle.accentAction : Color.clear)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(MindFlowFormSheetStyle.accentAction, lineWidth: isSelected ? 0 : 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(mode != .task)
                .opacity(mode == .task ? 1 : 0.45)
            }
        }
    }

    private var addTodoInputFieldChrome: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(MindFlowFormSheetStyle.accent, lineWidth: 1.5)
    }

    private var titleFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("新建待办")
                .font(.headline)
                .foregroundStyle(MindFlowFormSheetStyle.accent)
            MindFlowFormTitleTextField(
                text: $titleText,
                placeholder: "我想…",
                wantsKeyboard: panelExpanded && formMode == .task && allowTitleKeyboard
            )
            .frame(maxWidth: .infinity, minHeight: MindFlowFormSheetStyle.fieldContentMinHeight, alignment: .leading)
            .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
            .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
            .background(addTodoInputFieldChrome)
        }
    }

    private var descriptionFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注")
                .font(.headline)
                .foregroundStyle(MindFlowFormSheetStyle.accent)
            TextField("别忘了...", text: $descriptionText)
                .font(MindFlowFormSheetStyle.fieldFont)
                .lineLimit(1)
                .focused($isNotesFieldFocused)
                .frame(maxWidth: .infinity, minHeight: MindFlowFormSheetStyle.fieldContentMinHeight, alignment: .leading)
                .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
                .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
                .background(addTodoInputFieldChrome)
        }
    }

    private var selectedCategoryOption: TodoLifeCategoryOption? {
        TodoLifeCategoryCatalog.option(for: selectedCategoryId)
    }

    @ViewBuilder
    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分类")
                .font(.headline)
                .foregroundStyle(MindFlowFormSheetStyle.accent)
            Button {
                dismissAllInputs()
                showsCategoryPicker = true
            } label: {
                HStack(spacing: 10) {
                    if let category = selectedCategoryOption {
                        Text(category.title)
                            .font(MindFlowFormSheetStyle.fieldFont)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                    } else {
                        Text("选择分类")
                            .font(MindFlowFormSheetStyle.fieldFont)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: MindFlowFormSheetStyle.fieldContentMinHeight, alignment: .leading)
                .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
                .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
                .background(addTodoInputFieldChrome)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("任务分类")
        }
    }

    @ViewBuilder
    private var priorityPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("优先级")
                .font(.headline)
                .foregroundStyle(MindFlowFormSheetStyle.accent)
            HStack(spacing: 8) {
                ForEach(TodoPriority.allCases, id: \.self) { priority in
                    let isSelected = selectedPriority == priority
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedPriority = priority
                        }
                    } label: {
                        Text(priority.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? Color.white : MindFlowFormSheetStyle.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(isSelected ? MindFlowFormSheetStyle.accentAction : Color.clear)
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(MindFlowFormSheetStyle.accentAction, lineWidth: isSelected ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func timeButtonLabel(_ date: Date) -> String {
        Self.timeHMFormatter.string(from: date)
    }

    private func dateButtonLabel(_ date: Date) -> String {
        Self.dateYMDFormatter.string(from: date)
    }

    private func durationCompactText() -> String {
        if durationHours > 0, durationMinutes > 0 { return "\(durationHours)时\(durationMinutes)分" }
        if durationHours > 0 { return "\(durationHours)时" }
        if durationMinutes > 0 { return "\(durationMinutes)分" }
        return "1时"
    }

    private func beginEditingPlannedField(_ field: PlannedTimeField) {
        if expandedPlannedField == field {
            withAnimation(.easeInOut(duration: 0.2)) {
                cancelPlannedPicker()
            }
            return
        }
        draftPlannedDate = plannedDate
        draftPlannedTime = plannedTime
        draftDurationHours = durationHours
        draftDurationMinutes = durationMinutes
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedPlannedField = field
        }
    }

    private func cancelPlannedPicker() {
        expandedPlannedField = nil
    }

    private func confirmPlannedPicker() {
        guard let field = expandedPlannedField else { return }
        switch field {
        case .date:
            plannedDate = Calendar.current.startOfDay(for: draftPlannedDate)
        case .timeSlot:
            plannedTime = draftPlannedTime
        case .duration:
            durationHours = draftDurationHours
            durationMinutes = draftDurationMinutes
            if durationHours == 0, durationMinutes == 0 {
                durationHours = 1
            }
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedPlannedField = nil
        }
    }

    @ViewBuilder
    private func plannedTimeCell(
        label: String,
        value: String,
        field: PlannedTimeField
    ) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
            Button {
                beginEditingPlannedField(field)
            } label: {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, minHeight: 22)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                MindFlowFormSheetStyle.accent.opacity(0.55),
                                lineWidth: 1
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private let timePickerWheelHeight: CGFloat = 148
    private let timePickerConfirmBarHeight: CGFloat = 44
    private var timePickerPanelHeight: CGFloat { timePickerWheelHeight + timePickerConfirmBarHeight }

    @ViewBuilder
    private var plannedTimePickerWheels: some View {
        VStack(spacing: 0) {
            Group {
                if expandedPlannedField == .date {
                    DatePicker("", selection: $draftPlannedDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                } else if expandedPlannedField == .timeSlot {
                    DatePicker("", selection: $draftPlannedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                } else if expandedPlannedField == .duration {
                    HStack(spacing: 0) {
                        Picker("时", selection: $draftDurationHours) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour) 小时").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        Picker("分", selection: $draftDurationMinutes) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text("\(minute) 分钟").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: timePickerWheelHeight)

            Divider()

            HStack {
                Button("取消") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        cancelPlannedPicker()
                    }
                }
                .foregroundStyle(.secondary)
                Spacer()
                Button("确定") {
                    confirmPlannedPicker()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accentAction)
            }
            .padding(.horizontal, 16)
            .frame(height: timePickerConfirmBarHeight)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
    }

    @ViewBuilder
    private var plannedTimeSection: some View {
        HStack(alignment: .bottom, spacing: 8) {
            plannedTimeCell(
                label: "计划日期",
                value: dateButtonLabel(plannedDate),
                field: .date
            )
            plannedTimeCell(
                label: "计划时间",
                value: timeButtonLabel(plannedTime),
                field: .timeSlot
            )
            plannedTimeCell(
                label: "计划用时",
                value: durationCompactText(),
                field: .duration
            )
        }
        .overlay(alignment: .bottom) {
            if expandedPlannedField != nil {
                plannedTimePickerWheels
                    .offset(y: -(timePickerPanelHeight + 6))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: expandedPlannedField)
        .zIndex(expandedPlannedField == nil ? 0 : 2)
        .padding(.top, expandedPlannedField == nil ? 0 : timePickerPanelHeight + 6)
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetDragHandle

            modeSelectorBar
                .padding(.horizontal, 20)
                .padding(.top, 12)

            if formMode == .task {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        titleFieldSection
                        descriptionFieldSection
                        categoryPickerSection
                        priorityPickerSection
                        plannedTimeSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                }
                .scrollDismissesKeyboard(.interactively)
                .mindFlowScrollContentBottomInset()

                Button(action: submitTodo) {
                    Text("创建")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule(style: .continuous)
                                .fill(MindFlowFormSheetStyle.accentAction)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 14)
            } else {
                Spacer(minLength: 0)
                Text("即将推出")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                Spacer(minLength: 0)
            }
        }
        .background(Color.white)
        .sheet(isPresented: $showsCategoryPicker) {
            TodoDetailCategoryPickerSheet(
                selectedCategoryId: selectedCategoryId,
                onSelect: { categoryId in
                    selectedCategoryId = categoryId
                }
            )
        }
        .onChange(of: panelExpanded) { _, open in
            if open {
                applyDefaultTimeSlot()
            } else {
                dismissAllInputs()
                titleText = ""
                descriptionText = ""
            }
        }
    }
}

// MARK: - 待办详情（轻触标题进入）
private struct TodoCategoryCapsule: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: TodoRowCardMetrics.categoryCapsuleFontSize, weight: .semibold))
            .foregroundColor(Color(hex: "#2B5748"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .strokeBorder(Color(hex: "#2B5748").opacity(0.32), lineWidth: 1)
            )
            .fixedSize()
    }
}

private enum TodoDetailDateFormatting {
    static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()
}

private struct TodoDetailDashedDivider: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
            }
            .stroke(
                Color(hex: "#2B5748").opacity(0.22),
                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
            )
        }
        .frame(height: 1)
    }
}

private struct TodoDetailVerticalDashedDivider: View {
    var verticalPadding: CGFloat = 10

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 1)
            .overlay {
                GeometryReader { geometry in
                    Path { path in
                        path.move(to: CGPoint(x: 0.5, y: 0))
                        path.addLine(to: CGPoint(x: 0.5, y: geometry.size.height))
                    }
                    .stroke(
                        Color(hex: "#2B5748").opacity(0.22),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
                }
            }
            .padding(.vertical, verticalPadding)
    }
}

private struct TodoDetailTitleCard: View {
    let todo: TodoItem

    var body: some View {
        Text(todo.title)
            .font(.headline.weight(.semibold))
            .foregroundColor(Color(hex: "#2B5748"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: TodoRowCardMetrics.detailInlineCardMinHeight, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.vertical, TodoRowCardMetrics.detailInlineCardVerticalPadding)
            .todoPanelCardChrome()
    }
}

private struct TodoDetailTimePlaceholderDash: View {
    var body: some View {
        Text("—")
            .font(.headline.weight(.semibold))
            .foregroundStyle(MindFlowFormSheetStyle.accent)
            .frame(minWidth: 36)
    }
}

private struct TodoDetailTimeValueCapsule: View {
    let text: String
    var lineLimit: Int = 1

    var body: some View {
        Text(text)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(TodoRowCardMetrics.detailTimeCapsuleFillColor)
            )
            .fixedSize(horizontal: true, vertical: true)
    }
}

enum TodoDetailDateTarget {
    case start
    case end
    case planned
}

private enum TodoDetailTimeEditContext: Identifiable {
    case startDate
    case endDate
    case plannedDate
    case startTime
    case endTime
    case plannedTime

    var id: Self { self }

    var sheetTitle: String {
        switch self {
        case .startDate: return "开始日期"
        case .endDate: return "结束日期"
        case .plannedDate: return "计划日期"
        case .startTime: return "开始时间"
        case .endTime: return "结束时间"
        case .plannedTime: return "计划时间"
        }
    }

    var isDate: Bool {
        switch self {
        case .startDate, .endDate, .plannedDate: return true
        case .startTime, .endTime, .plannedTime: return false
        }
    }

    var dateTarget: TodoDetailDateTarget? {
        switch self {
        case .startDate: return .start
        case .endDate: return .end
        case .plannedDate: return .planned
        default: return nil
        }
    }
}

private enum TodoDetailCalendarMetrics {
    static let panelCornerRadius: CGFloat = 14
    static let panelInnerPadding: CGFloat = 14
    static let cellSpacing: CGFloat = 5
    static let cellCornerRadius: CGFloat = 10
    static let monthControlSize: CGFloat = 30
    static let gridMinCellSize: CGFloat = 48
    static let sheetHorizontalPadding: CGFloat = 20
    static let sheetTopPadding: CGFloat = 10
    static let sheetBottomPadding: CGFloat = 16
    static let navigationBarAllowance: CGFloat = 44
    static let weekdayHeaderHeight: CGFloat = 20
    static let weekdayHeaderBottomSpacing: CGFloat = 8
    /// 月历网格固定 6 行高度，避免 Sheet 随月份变化伸缩
    static let calendarGridRowCount: Int = 6
}

private enum TodoDetailMomentPickerMetrics {
    static let wheelHeight: CGFloat = 152
    static let verticalPadding: CGFloat = 12
    static let navigationBarAllowance: CGFloat = 44
    static let sheetExtraHeight: CGFloat = 16
    static var sheetHeight: CGFloat {
        wheelHeight + verticalPadding * 2 + navigationBarAllowance + sheetExtraHeight
    }
}

private struct TodoDetailNoteTextView: UIViewRepresentable {
    @Binding var text: String
    var onEndEditing: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.font = Self.noteFont
        textView.textColor = UIColor(Color(hex: "#2B5748"))
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = true
        textView.returnKeyType = .default
        textView.text = Self.sanitizeLegacyText(text)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        guard !context.coordinator.isUpdatingText else { return }
        guard textView.markedTextRange == nil else { return }
        guard !textView.isFirstResponder else { return }

        let sanitized = Self.sanitizeLegacyText(text)
        if textView.text != sanitized {
            let selectedRange = textView.selectedRange
            textView.text = sanitized
            let clampedLocation = min(
                max(0, selectedRange.location),
                (sanitized as NSString).length
            )
            textView.selectedRange = NSRange(location: clampedLocation, length: 0)
        }
    }

    static let noteFont: UIFont = {
        let base = UIFont.preferredFont(forTextStyle: .subheadline)
        return UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
    }()

    static func sanitizeLegacyText(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{E000}", with: "\n")
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: TodoDetailNoteTextView
        var isUpdatingText = false

        init(parent: TodoDetailNoteTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            isUpdatingText = true
            parent.text = textView.text ?? ""
            isUpdatingText = false
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.markedTextRange == nil {
                isUpdatingText = true
                parent.text = textView.text ?? ""
                isUpdatingText = false
            }
            parent.onEndEditing()
        }
    }
}

private struct TodoDetailNoteCard: View {
    let initialText: String
    let onSave: (String) -> Void
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: TodoRowCardMetrics.detailNoteTitleToInputSpacing) {
            Text(TodoRowCardMetrics.detailNoteSectionTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .frame(maxWidth: .infinity, alignment: .center)

            ZStack(alignment: .topLeading) {
                TodoDetailNoteTextView(
                    text: $draft,
                    onEndEditing: {
                        onSave(draft)
                    }
                )
                .frame(maxWidth: .infinity)
                .frame(height: TodoRowCardMetrics.detailNoteInputFixedHeight)

                if draft.isEmpty {
                    Text(TodoRowCardMetrics.detailNoteInputPlaceholder)
                        .font(TodoRowCardMetrics.detailNoteContentFont)
                        .foregroundStyle(Color.secondary.opacity(0.42))
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, TodoRowCardMetrics.detailInlineCardVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .todoPanelCardChrome()
        .onAppear {
            draft = TodoDetailNoteTextView.sanitizeLegacyText(initialText)
        }
        .onChange(of: initialText) { _, newValue in
            let normalized = TodoDetailNoteTextView.sanitizeLegacyText(newValue)
            if draft != normalized {
                draft = normalized
            }
        }
    }
}

private enum TodoWeekdayCatalog {
    /// 单行顺序：周一 → 周日
    static let displayOrder = [1, 2, 3, 4, 5, 6, 7]

    static func isActive(_ weekday: Int, in days: Set<Int>) -> Bool {
        days.contains(weekday)
    }

    static func toggled(_ weekday: Int, in days: Set<Int>) -> Set<Int> {
        var updated = days
        if updated.contains(weekday) {
            updated.remove(weekday)
        } else {
            updated.insert(weekday)
        }
        return updated
    }

    static func label(for weekday: Int) -> String {
        switch weekday {
        case 1: return "周一"
        case 2: return "周二"
        case 3: return "周三"
        case 4: return "周四"
        case 5: return "周五"
        case 6: return "周六"
        case 7: return "周日"
        default: return ""
        }
    }

    static func compactWeeklyTag(from days: Set<Int>) -> String? {
        let workdays: Set<Int> = [1, 2, 3, 4, 5]
        if days == workdays { return "工作日" }

        let chars = displayOrder
            .filter { days.contains($0) }
            .compactMap { weekday -> String? in
                switch weekday {
                case 1: return "一"
                case 2: return "二"
                case 3: return "三"
                case 4: return "四"
                case 5: return "五"
                case 6: return "六"
                case 7: return "日"
                default: return nil
                }
            }
        guard !chars.isEmpty else { return nil }
        return "每周" + chars.joined(separator: "、")
    }

    static func displayString(from days: Set<Int>) -> String {
        if let compact = compactWeeklyTag(from: days) {
            return compact
        }
        return displayOrder
            .filter { days.contains($0) }
            .map { label(for: $0) }
            .joined(separator: " ")
    }
}

private struct TodoDetailRepeatDashedDivider: View {
    var verticalPadding: CGFloat = 14

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 1)
            .overlay {
                GeometryReader { geometry in
                    Path { path in
                        path.move(to: CGPoint(x: 0.5, y: 0))
                        path.addLine(to: CGPoint(x: 0.5, y: geometry.size.height))
                    }
                    .stroke(
                        Color.gray.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
                }
            }
            .padding(.vertical, verticalPadding)
    }
}

private struct TodoVerticalWeekdayLabel: View {
    let text: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: TodoRowCardMetrics.detailWeekdayLabelCharacterSpacing) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                Text(String(character))
                    .font(.system(
                        size: TodoRowCardMetrics.detailWeekdayLabelFontSize,
                        weight: .semibold
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .foregroundStyle(
            isActive ? MindFlowFormSheetStyle.accent : Color.secondary.opacity(0.38)
        )
    }
}

private struct TodoDetailWeekdayPickerCard: View {
    let selectedDays: Set<Int>
    let onToggle: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(TodoWeekdayCatalog.displayOrder.enumerated()), id: \.offset) { index, weekday in
                if index > 0 {
                    TodoDetailRepeatDashedDivider(verticalPadding: 10)
                }
                Button {
                    onToggle(weekday)
                } label: {
                    TodoVerticalWeekdayLabel(
                        text: TodoWeekdayCatalog.label(for: weekday),
                        isActive: TodoWeekdayCatalog.isActive(weekday, in: selectedDays)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: TodoRowCardMetrics.detailMetaRowCardHeight)
        .todoPanelCardChrome()
    }
}

private enum MindFlowChineseCalendarFormatting {
    static let locale = Locale(identifier: "zh_CN")

    static let monthTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()
}

private struct MindFlowMonthCalendarPicker: View {
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        cal.locale = Locale(identifier: "zh_CN")
        return cal
    }

    init(selectedDate: Binding<Date>, displayedMonth: Binding<Date>) {
        _selectedDate = selectedDate
        _displayedMonth = displayedMonth
    }

    static func preferredHeight(for month: Date) -> CGFloat {
        fixedPreferredHeight
    }

    static var fixedPreferredHeight: CGFloat {
        let rows = CGFloat(TodoDetailCalendarMetrics.calendarGridRowCount)
        let cellSize = TodoDetailCalendarMetrics.gridMinCellSize
        let gridHeight = rows * cellSize + max(0, rows - 1) * TodoDetailCalendarMetrics.cellSpacing
        return gridHeight
            + 12
            + TodoDetailCalendarMetrics.panelInnerPadding * 2
            + 38
            + TodoDetailCalendarMetrics.weekdayHeaderHeight
            + TodoDetailCalendarMetrics.weekdayHeaderBottomSpacing
    }

    static func monthStart(for date: Date) -> Date {
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: date)
        ) ?? date
    }

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = max(0, geometry.size.width - TodoDetailCalendarMetrics.panelInnerPadding * 2)
            let cellSize = cellSize(for: contentWidth)
            let gridDays = Self.gridDays(for: displayedMonth, calendar: calendar)
            let rowCount = TodoDetailCalendarMetrics.calendarGridRowCount
            let gridHeight = CGFloat(rowCount) * cellSize
                + CGFloat(max(0, rowCount - 1)) * TodoDetailCalendarMetrics.cellSpacing

            VStack(spacing: 12) {
                monthHeader

                HStack(spacing: TodoDetailCalendarMetrics.cellSpacing) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: cellSize)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: TodoDetailCalendarMetrics.weekdayHeaderHeight)

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(cellSize), spacing: TodoDetailCalendarMetrics.cellSpacing),
                        count: 7
                    ),
                    spacing: TodoDetailCalendarMetrics.cellSpacing
                ) {
                    ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                        if let day {
                            dayCell(day, cellSize: cellSize)
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
                .frame(height: gridHeight)
            }
            .padding(TodoDetailCalendarMetrics.panelInnerPadding)
            .background(
                RoundedRectangle(cornerRadius: TodoDetailCalendarMetrics.panelCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TodoDetailCalendarMetrics.panelCornerRadius, style: .continuous)
                    .stroke(MindFlowFormSheetStyle.accent.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 3)
        }
        .frame(height: Self.fixedPreferredHeight)
        .animation(.easeInOut(duration: 0.22), value: displayedMonth)
        .environment(\.locale, MindFlowChineseCalendarFormatting.locale)
    }

    private var monthHeader: some View {
        HStack(spacing: 8) {
            monthControlButton(systemName: "chevron.left") {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            }

            VStack(spacing: 2) {
                Text(MindFlowChineseCalendarFormatting.monthTitle.string(from: displayedMonth))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
            }
            .frame(maxWidth: .infinity)

            monthControlButton(systemName: "chevron.right") {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            }
        }
    }

    private func cellSize(for width: CGFloat) -> CGFloat {
        max(
            TodoDetailCalendarMetrics.gridMinCellSize,
            (width - TodoDetailCalendarMetrics.cellSpacing * 6) / 7
        )
    }

    private var weekdaySymbols: [String] {
        ["一", "二", "三", "四", "五", "六", "日"]
    }

    private func monthControlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .frame(
                    width: TodoDetailCalendarMetrics.monthControlSize,
                    height: TodoDetailCalendarMetrics.monthControlSize
                )
                .background(
                    Circle()
                        .fill(MindFlowFormSheetStyle.accent.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }

    private static func gridDays(for month: Date, calendar: Calendar) -> [Date?] {
        var cal = calendar
        cal.firstWeekday = 2
        guard
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: month)),
            let dayCount = cal.range(of: .day, in: .month, for: monthStart)?.count
        else { return [] }

        let weekdayIndex = cal.component(.weekday, from: monthStart)
        let leadingBlanks = (weekdayIndex - cal.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            days.append(cal.date(byAdding: .day, value: offset, to: monthStart))
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private static func gridDays(for month: Date) -> [Date?] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return gridDays(for: month, calendar: cal)
    }

    private func gridDays(for month: Date) -> [Date?] {
        Self.gridDays(for: month, calendar: calendar)
    }

    @ViewBuilder
    private func dayCell(_ day: Date, cellSize: CGFloat) -> some View {
        let dayStart = calendar.startOfDay(for: day)
        let isSelected = calendar.isDate(dayStart, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(dayStart)
        let dayNumber = calendar.component(.day, from: day)

        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedDate = dayStart
            }
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: TodoDetailCalendarMetrics.cellCornerRadius, style: .continuous)
                        .fill(MindFlowFormSheetStyle.accent)
                        .shadow(color: MindFlowFormSheetStyle.accent.opacity(0.28), radius: 4, y: 2)
                } else if isToday {
                    RoundedRectangle(cornerRadius: TodoDetailCalendarMetrics.cellCornerRadius, style: .continuous)
                        .stroke(MindFlowFormSheetStyle.accent.opacity(0.55), lineWidth: 1.5)
                }

                Text("\(dayNumber)")
                    .font(isSelected ? .subheadline.weight(.bold) : .subheadline.weight(.medium))
                    .foregroundStyle(
                        isSelected
                            ? Color.white
                            : (isToday ? MindFlowFormSheetStyle.accent : Color.secondary.opacity(0.62))
                    )
            }
            .frame(width: cellSize, height: cellSize)
        }
        .buttonStyle(.plain)
    }
}

private var todoDetailSheetBackground: some View {
    LinearGradient(
        colors: [Color.white, Color(hex: "#d8f3dc")],
        startPoint: .top,
        endPoint: .bottom
    )
    .ignoresSafeArea()
}

private struct TodoDetailSheetNavigationBar: ViewModifier {
    let title: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消", action: onCancel)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("确定", action: onConfirm)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                }
            }
            .tint(MindFlowFormSheetStyle.accent)
    }
}

private extension View {
    func todoDetailSheetNavigationBar(
        title: String,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(TodoDetailSheetNavigationBar(title: title, onCancel: onCancel, onConfirm: onConfirm))
    }
}

private struct TodoDetailDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    @State private var calendarMonth: Date
    @State private var showTimeRangeAlert = false
    @State private var scheduleAlertMessage = ""
    private let initialDate: Date
    let title: String
    let onConfirm: (Date) -> String?

    init(date: Date, title: String, onConfirm: @escaping (Date) -> String?) {
        initialDate = date
        _date = State(initialValue: date)
        _calendarMonth = State(initialValue: MindFlowMonthCalendarPicker.monthStart(for: date))
        self.title = title
        self.onConfirm = onConfirm
    }

    private var sheetHeight: CGFloat {
        TodoDetailCalendarMetrics.navigationBarAllowance
            + TodoDetailCalendarMetrics.sheetTopPadding
            + MindFlowMonthCalendarPicker.fixedPreferredHeight
            + TodoDetailCalendarMetrics.sheetBottomPadding
    }

    var body: some View {
        NavigationStack {
            MindFlowMonthCalendarPicker(
                selectedDate: $date,
                displayedMonth: $calendarMonth
            )
            .padding(.horizontal, TodoDetailCalendarMetrics.sheetHorizontalPadding)
            .padding(.top, TodoDetailCalendarMetrics.sheetTopPadding)
            .padding(.bottom, TodoDetailCalendarMetrics.sheetBottomPadding)
            .background(todoDetailSheetBackground)
            .todoDetailSheetNavigationBar(title: title, onCancel: { dismiss() }) {
                if let errorMessage = onConfirm(date) {
                    date = initialDate
                    calendarMonth = MindFlowMonthCalendarPicker.monthStart(for: initialDate)
                    scheduleAlertMessage = errorMessage
                    showTimeRangeAlert = true
                } else {
                    dismiss()
                }
            }
        }
        .alert("时间无效", isPresented: $showTimeRangeAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text(scheduleAlertMessage)
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .environment(\.locale, MindFlowChineseCalendarFormatting.locale)
    }
}

private struct TodoDetailMomentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var time: Date
    @State private var showTimeRangeAlert = false
    @State private var scheduleAlertMessage = ""
    private let initialHour: Int
    private let initialMinute: Int
    let title: String
    let onConfirm: (Int, Int) -> String?

    init(hour: Int, minute: Int, title: String, onConfirm: @escaping (Int, Int) -> String?) {
        initialHour = hour
        initialMinute = minute
        _time = State(initialValue: Self.dateFromHourMinute(hour: hour, minute: minute))
        self.title = title
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: TodoDetailMomentPickerMetrics.wheelHeight)
                .padding(.vertical, TodoDetailMomentPickerMetrics.verticalPadding)
                .background(todoDetailSheetBackground)
                .todoDetailSheetNavigationBar(title: title, onCancel: { dismiss() }) {
                    let cal = Calendar.current
                    let hour = cal.component(.hour, from: time)
                    let minute = cal.component(.minute, from: time)
                    if let errorMessage = onConfirm(hour, minute) {
                        time = Self.dateFromHourMinute(hour: initialHour, minute: initialMinute)
                        scheduleAlertMessage = errorMessage
                        showTimeRangeAlert = true
                    } else {
                        dismiss()
                    }
                }
        }
        .alert("时间无效", isPresented: $showTimeRangeAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text(scheduleAlertMessage)
        }
        .presentationDetents([.height(TodoDetailMomentPickerMetrics.sheetHeight)])
        .presentationDragIndicator(.visible)
    }

    private static func dateFromHourMinute(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

private struct TodoDetailRepeatModeCard: View {
    let mode: TodoRepeatMode
    let action: () -> Void

    var body: some View {
        ZStack {
            Text(mode.cycleChipDisplayName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .frame(maxWidth: .infinity)
                .id(mode)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: TodoRowCardMetrics.detailMetaRowCardHeight)
        .clipped()
        .animation(TodoCardMotion.slide, value: mode)
        .todoPanelCardChrome()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(TodoCardMotion.slide) {
                action()
            }
        }
    }
}

private enum TodoDetailMonthlyRepeatMetrics {
    static let gridColumns = 7
    static let cellSpacing: CGFloat = 6
    static let rowSpacing: CGFloat = 8
    static let cellSize: CGFloat = 34
    static let cellCornerRadius: CGFloat = 10
    static let cardHorizontalPadding: CGFloat = 14
    static let cardVerticalPadding: CGFloat = 14
    static let endDayBadgeDays = [29, 30, 31]
    static let endDayBadgeHorizontalPadding: CGFloat = 9
    static let endDayBadgeVerticalPadding: CGFloat = 5
    static let connectorLineHeight: CGFloat = 1
    static let connectorLineMinWidth: CGFloat = 10
    static let connectorLineMaxWidth: CGFloat = 28
    static let fallbackCapsuleHorizontalPadding: CGFloat = 12
    static let fallbackCapsuleVerticalPadding: CGFloat = 8
}

private struct TodoDetailMonthlyRepeatEndDayBadge: View {
    let day: Int

    var body: some View {
        Text("\(day)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(MindFlowFormSheetStyle.accent)
            .padding(.horizontal, TodoDetailMonthlyRepeatMetrics.endDayBadgeHorizontalPadding)
            .padding(.vertical, TodoDetailMonthlyRepeatMetrics.endDayBadgeVerticalPadding)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.white)
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(MindFlowFormSheetStyle.accent, lineWidth: 1)
                    }
            }
    }
}

private struct TodoDetailMonthlyRepeatLastDayFallbackCapsule: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("无该日的月份设置为该月最后一天")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : MindFlowFormSheetStyle.accent)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, TodoDetailMonthlyRepeatMetrics.fallbackCapsuleHorizontalPadding)
                .padding(.vertical, TodoDetailMonthlyRepeatMetrics.fallbackCapsuleVerticalPadding)
                .background {
                    Capsule(style: .continuous)
                        .fill(isSelected ? MindFlowFormSheetStyle.accent : Color.white)
                        .overlay {
                            if !isSelected {
                                Capsule(style: .continuous)
                                    .stroke(MindFlowFormSheetStyle.accent, lineWidth: 1)
                            }
                        }
                }
        }
        .buttonStyle(.plain)
    }
}

private struct TodoDetailMonthlyRepeatLastDayFallbackRow: View {
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(TodoDetailMonthlyRepeatMetrics.endDayBadgeDays, id: \.self) { day in
                    TodoDetailMonthlyRepeatEndDayBadge(day: day)
                }
            }

            Capsule(style: .continuous)
                .fill(MindFlowFormSheetStyle.accent.opacity(0.42))
                .frame(
                    width: TodoDetailMonthlyRepeatMetrics.connectorLineMaxWidth,
                    height: TodoDetailMonthlyRepeatMetrics.connectorLineHeight
                )
                .frame(minWidth: TodoDetailMonthlyRepeatMetrics.connectorLineMinWidth)

            TodoDetailMonthlyRepeatLastDayFallbackCapsule(
                isSelected: isSelected,
                action: onToggle
            )
        }
    }
}

private struct TodoDetailMonthlyRepeatGridCard: View {
    let selectedDays: Set<Int>
    let usesLastDayFallback: Bool
    let onToggleDay: (Int) -> Void
    let onToggleLastDayFallback: () -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: TodoDetailMonthlyRepeatMetrics.cellSpacing),
        count: TodoDetailMonthlyRepeatMetrics.gridColumns
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(
                columns: columns,
                spacing: TodoDetailMonthlyRepeatMetrics.rowSpacing
            ) {
                ForEach(1...31, id: \.self) { day in
                    Button {
                        onToggleDay(day)
                    } label: {
                        TodoDetailMonthlyRepeatDayCell(
                            day: day,
                            isSelected: selectedDays.contains(day),
                            usesCapsuleRing: TodoDetailMonthlyRepeatMetrics.endDayBadgeDays.contains(day)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            TodoDetailDashedDivider()
                .padding(.vertical, 2)

            TodoDetailMonthlyRepeatLastDayFallbackRow(
                isSelected: usesLastDayFallback,
                onToggle: onToggleLastDayFallback
            )
        }
        .padding(.horizontal, TodoDetailMonthlyRepeatMetrics.cardHorizontalPadding)
        .padding(.vertical, TodoDetailMonthlyRepeatMetrics.cardVerticalPadding)
        .todoPanelCardChrome()
    }
}

private struct TodoDetailMonthlyRepeatDayCell: View {
    let day: Int
    let isSelected: Bool
    var usesCapsuleRing: Bool = false

    var body: some View {
        Text("\(day)")
            .font(.subheadline.weight(isSelected ? .bold : .medium))
            .foregroundStyle(
                isSelected
                    ? Color.white
                    : (usesCapsuleRing ? MindFlowFormSheetStyle.accent : Color.secondary.opacity(0.62))
            )
            .frame(maxWidth: .infinity)
            .frame(height: TodoDetailMonthlyRepeatMetrics.cellSize)
            .background {
                if isSelected {
                    RoundedRectangle(
                        cornerRadius: TodoDetailMonthlyRepeatMetrics.cellCornerRadius,
                        style: .continuous
                    )
                    .fill(MindFlowFormSheetStyle.accent)
                    .shadow(
                        color: MindFlowFormSheetStyle.accent.opacity(0.22),
                        radius: 3,
                        y: 1
                    )
                } else if usesCapsuleRing {
                    Capsule(style: .continuous)
                        .fill(Color.white)
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(MindFlowFormSheetStyle.accent, lineWidth: 1)
                        }
                }
            }
            .contentShape(Rectangle())
    }
}

private struct TodoDetailYearlyRepeatCalendarCard: View {
    let selectedDays: Set<TodoYearlyRepeatDay>
    let onToggle: (Int, Int) -> Void

    @State private var displayedMonth = Date()

    var body: some View {
        MindFlowOOTDStyleCalendarCard(
            displayedMonth: $displayedMonth,
            isDayMarked: { day in
                let calendar = Calendar.current
                let anchor = TodoYearlyRepeatDay(
                    month: calendar.component(.month, from: day),
                    day: calendar.component(.day, from: day)
                )
                return selectedDays.contains(anchor)
            },
            onDayTap: { day in
                let calendar = Calendar.current
                onToggle(
                    calendar.component(.month, from: day),
                    calendar.component(.day, from: day)
                )
            },
            dayInteraction: .toggleSelect
        )
    }
}

private struct TodoDetailPriorityChip: View {
    @ObservedObject var viewModel: TodoViewModel
    let todoId: Int

    private var todo: TodoItem? {
        viewModel.todos.first(where: { $0.id == todoId })
    }

    var body: some View {
        GeometryReader { geometry in
            let verticalOffset = TodoRowCardMetrics.detailMetaChipVerticalOffset
            let priority = todo?.priority ?? .p3
            ZStack {
                Text("优先级")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 3 + verticalOffset
                    )

                Text(priority.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .id(priority)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .animation(TodoCardMotion.slide, value: priority)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 2 / 3 + verticalOffset
                    )
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: TodoRowCardMetrics.detailMetaRowCardHeight)
        .todoPanelCardChrome()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(TodoCardMotion.slide) {
                viewModel.cycleTodoPriority(id: todoId)
            }
        }
    }
}

private struct TodoDetailRepeatSection: View {
    @ObservedObject var viewModel: TodoViewModel
    let todoId: Int

    private var todo: TodoItem? {
        viewModel.todos.first(where: { $0.id == todoId })
    }

    var body: some View {
        TodoDetailRepeatModeCard(mode: todo?.repeatMode ?? .none) {
            viewModel.cycleTodoRepeatMode(id: todoId)
        }
    }
}

private struct TodoDetailRepeatLimitCountControl: View {
    let count: Int?
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        if let count {
            HStack(spacing: 8) {
                Button(action: onDecrement) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent.opacity(0.72))
                        .frame(width: 28, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text("\(count) 次")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(minWidth: 36)

                Button(action: onIncrement) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent.opacity(0.72))
                        .frame(width: 28, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } else {
            TodoDetailTimePlaceholderDash()
        }
    }
}

private struct TodoDetailRepeatLimitSegment<Value: View>: View {
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void
    @ViewBuilder var value: () -> Value

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: onSelect)

            GeometryReader { geometry in
                let verticalOffset = TodoRowCardMetrics.detailMetaChipVerticalOffset
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isSelected ? MindFlowFormSheetStyle.accent : Color.secondary.opacity(0.38))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 3 + verticalOffset
                    )

                Group {
                    if isSelected {
                        value()
                    } else {
                        TodoDetailTimePlaceholderDash()
                    }
                }
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height * 2 / 3 + verticalOffset
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct TodoDetailRepeatLimitCard: View {
    @ObservedObject var viewModel: TodoViewModel
    let todoId: Int
    var cardHeight: CGFloat = TodoRowCardMetrics.detailMetaRowCardHeight
    @State private var showsUntilDatePicker = false

    private var todo: TodoItem? {
        viewModel.todos.first(where: { $0.id == todoId })
    }

    var body: some View {
        if let todo {
            HStack(spacing: 0) {
                TodoDetailRepeatLimitSegment(
                    title: TodoRepeatLimitKind.deadline.displayName,
                    isSelected: todo.repeatLimitKind == .deadline,
                    onSelect: {
                        withAnimation(TodoCardMotion.slide) {
                            viewModel.setTodoRepeatLimitKind(id: todoId, kind: .deadline)
                        }
                        if todo.repeatUntilDate == nil {
                            showsUntilDatePicker = true
                        }
                    },
                    value: {
                        Button {
                            showsUntilDatePicker = true
                        } label: {
                            if let text = todo.repeatUntilDateOnlyDisplayText {
                                TodoDetailTimeValueCapsule(text: text)
                            } else {
                                TodoDetailTimePlaceholderDash()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                )

                TodoDetailRepeatDashedDivider(verticalPadding: 10)

                TodoDetailRepeatLimitSegment(
                    title: TodoRepeatLimitKind.count.displayName,
                    isSelected: todo.repeatLimitKind == .count,
                    onSelect: {
                        withAnimation(TodoCardMotion.slide) {
                            viewModel.setTodoRepeatLimitKind(id: todoId, kind: .count)
                        }
                    },
                    value: {
                        TodoDetailRepeatLimitCountControl(
                            count: todo.repeatMaxOccurrences,
                            onDecrement: {
                                viewModel.decrementTodoRepeatMaxOccurrences(id: todoId)
                            },
                            onIncrement: {
                                viewModel.incrementTodoRepeatMaxOccurrences(id: todoId)
                            }
                        )
                    }
                )
            }
            .frame(height: cardHeight)
            .animation(TodoCardMotion.slide, value: todo.repeatLimitKind)
            .todoPanelCardChrome()
            .sheet(isPresented: $showsUntilDatePicker) {
                TodoDetailDatePickerSheet(
                    date: todo.repeatUntilDate ?? todo.plannedDate ?? todo.createdAt,
                    title: "截止时间"
                ) { date in
                    viewModel.updateTodoRepeatUntilDate(id: todoId, date: date)
                    return nil
                }
            }
        }
    }
}

private final class TodoClippingPickerHostView: UIView {
    let picker: UIPickerView

    init(picker: UIPickerView) {
        self.picker = picker
        super.init(frame: .zero)
        clipsToBounds = true
        isExclusiveTouch = true
        picker.isExclusiveTouch = true
        addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.leadingAnchor.constraint(equalTo: leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: trailingAnchor),
            picker.topAnchor.constraint(equalTo: topAnchor),
            picker.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}

private final class TodoWheelPickerView: UIPickerView {
    private var lastPaintedSelection: Int = -1

    override func layoutSubviews() {
        super.layoutSubviews()
        TodoPickerBackgroundUtility.clearSelectionBackground(in: self)
        let row = selectedRow(inComponent: 0)
        guard row >= 0, row != lastPaintedSelection else { return }
        lastPaintedSelection = row
        reloadAllComponents()
    }
}

private enum TodoWheelPickerLabelStyle {
    static let accent = UIColor(red: 0.17, green: 0.34, blue: 0.28, alpha: 1)
    static let selectedFontSize: CGFloat = 22
    static let adjacentFontSize: CGFloat = 18
    static let adjacentAlpha: CGFloat = 0.8

    static func apply(to label: UILabel, row: Int, selectedRow: Int, text: String) {
        label.text = text
        label.textAlignment = .center
        label.backgroundColor = .clear
        if selectedRow < 0 || row == selectedRow {
            label.alpha = 1
            label.font = .systemFont(ofSize: selectedFontSize, weight: .semibold)
            label.textColor = accent
        } else if abs(row - selectedRow) == 1 {
            label.alpha = adjacentAlpha
            label.font = .systemFont(ofSize: adjacentFontSize, weight: .semibold)
            label.textColor = accent
        } else {
            label.alpha = 0.35
            label.font = .systemFont(ofSize: adjacentFontSize, weight: .medium)
            label.textColor = accent
        }
    }
}

private final class TodoClearBackgroundPickerView: UIPickerView {
    override func layoutSubviews() {
        super.layoutSubviews()
        TodoPickerBackgroundUtility.clearSelectionBackground(in: self)
    }
}

private enum TodoPickerBackgroundUtility {
    static func clearSelectionBackground(in picker: UIPickerView) {
        picker.backgroundColor = .clear
        for (index, subview) in picker.subviews.enumerated() {
            subview.backgroundColor = .clear
            subview.layer.cornerRadius = 0
            if index == 1 {
                subview.isHidden = true
            }
            for nested in subview.subviews {
                nested.backgroundColor = .clear
                nested.layer.cornerRadius = 0
            }
        }
    }
}

private struct TodoVerticalNumberWheelPicker: UIViewRepresentable {
    @Binding var selection: Int
    let values: [Int]

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, values: values)
    }

    func makeUIView(context: Context) -> UIView {
        let picker = TodoWheelPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        TodoPickerBackgroundUtility.clearSelectionBackground(in: picker)
        return TodoClippingPickerHostView(picker: picker)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let host = uiView as? TodoClippingPickerHostView else { return }
        let picker = host.picker
        context.coordinator.selection = selection
        context.coordinator.values = values
        picker.reloadAllComponents()
        if let index = values.firstIndex(of: selection) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        TodoPickerBackgroundUtility.clearSelectionBackground(in: picker)
        if let wheelPicker = picker as? TodoWheelPickerView {
            wheelPicker.setNeedsLayout()
        }
    }

    final class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        var selection: Int
        var values: [Int]
        private let onSelect: (Int) -> Void

        init(selection: Binding<Int>, values: [Int]) {
            self.selection = selection.wrappedValue
            self.values = values
            self.onSelect = { selection.wrappedValue = $0 }
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            values.count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            28
        }

        func pickerView(
            _ pickerView: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            TodoWheelPickerLabelStyle.apply(
                to: label,
                row: row,
                selectedRow: pickerView.selectedRow(inComponent: component),
                text: "\(values[row])"
            )
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            guard values.indices.contains(row) else { return }
            selection = values[row]
            onSelect(values[row])
            pickerView.reloadAllComponents()
        }
    }
}

private struct TodoVerticalPeriodWheelPicker: UIViewRepresentable {
    @Binding var selection: TodoCustomRepeatPeriod
    let options: [TodoCustomRepeatPeriod]

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, options: options)
    }

    func makeUIView(context: Context) -> UIView {
        let picker = TodoWheelPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        TodoPickerBackgroundUtility.clearSelectionBackground(in: picker)
        return TodoClippingPickerHostView(picker: picker)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let host = uiView as? TodoClippingPickerHostView else { return }
        let picker = host.picker
        context.coordinator.selection = selection
        context.coordinator.options = options
        picker.reloadAllComponents()
        if let index = options.firstIndex(of: selection) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        TodoPickerBackgroundUtility.clearSelectionBackground(in: picker)
        if let wheelPicker = picker as? TodoWheelPickerView {
            wheelPicker.setNeedsLayout()
        }
    }

    final class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        var selection: TodoCustomRepeatPeriod
        var options: [TodoCustomRepeatPeriod]
        private let onSelect: (TodoCustomRepeatPeriod) -> Void

        init(selection: Binding<TodoCustomRepeatPeriod>, options: [TodoCustomRepeatPeriod]) {
            self.selection = selection.wrappedValue
            self.options = options
            self.onSelect = { selection.wrappedValue = $0 }
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            options.count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            28
        }

        func pickerView(
            _ pickerView: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            TodoWheelPickerLabelStyle.apply(
                to: label,
                row: row,
                selectedRow: pickerView.selectedRow(inComponent: component),
                text: options[row].wheelDisplayName
            )
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            guard options.indices.contains(row) else { return }
            selection = options[row]
            onSelect(options[row])
            pickerView.reloadAllComponents()
        }
    }
}

private struct TodoDetailCustomRepeatCard: View {
    @ObservedObject var viewModel: TodoViewModel
    let todoId: Int

    private enum Metrics {
        static let wheelHeight: CGFloat = 84
        static let intervalRange = Array(1...99)
        static let labelFont: Font = .title2.weight(.semibold)
        static let wheelItemFont: Font = .title2.weight(.semibold)
        static let intervalPickerWidth: CGFloat = 52
        static let periodPickerWidth: CGFloat = 56
        /// 「每」/滚轮/「循环一次」之间的统一间距（可调试）
        static let segmentSpacing: CGFloat = 8
    }

    private var todo: TodoItem? {
        viewModel.todos.first(where: { $0.id == todoId })
    }

    var body: some View {
        if todo != nil {
            intervalPickerRow
        }
    }

    private var intervalPickerRow: some View {
        HStack(spacing: Metrics.segmentSpacing) {
            Text("每")
                .font(Metrics.labelFont)
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .padding(.leading, 14)

            TodoVerticalNumberWheelPicker(
                selection: intervalBinding,
                values: Metrics.intervalRange
            )
            .frame(width: Metrics.intervalPickerWidth, height: Metrics.wheelHeight)
            .clipped()
            .contentShape(Rectangle())
            .zIndex(1)

            TodoVerticalPeriodWheelPicker(
                selection: periodBinding,
                options: TodoCustomRepeatPeriod.wheelOrder
            )
            .frame(width: Metrics.periodPickerWidth, height: Metrics.wheelHeight)
            .clipped()
            .contentShape(Rectangle())
            .zIndex(0)

            Text("循环一次")
                .font(Metrics.labelFont)
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.trailing, 14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: TodoRowCardMetrics.detailMetaRowCardHeight)
        .todoPanelCardChrome()
    }

    private var intervalBinding: Binding<Int> {
        Binding(
            get: {
                viewModel.todos.first(where: { $0.id == todoId })?.customRepeatInterval ?? 1
            },
            set: { viewModel.updateTodoCustomRepeatInterval(id: todoId, interval: $0) }
        )
    }

    private var periodBinding: Binding<TodoCustomRepeatPeriod> {
        Binding(
            get: {
                viewModel.todos.first(where: { $0.id == todoId })?.customRepeatPeriod ?? .week
            },
            set: { viewModel.updateTodoCustomRepeatPeriod(id: todoId, period: $0) }
        )
    }
}

private struct TodoDetailTimeScheduleCapsuleColumn<Content: View>: View {
    let width: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            content()
        }
        .frame(width: width)
    }
}

private struct TodoDetailTimeScheduleRow: View {
    let title: String
    let dateText: String?
    let slotText: String?
    var onDateTap: (() -> Void)? = nil
    var onSlotTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TodoRowCardMetrics.detailTimeRowTitleHorizontalInset)
                .frame(width: TodoRowCardMetrics.detailTimeRowTitleColumnWidth, alignment: .center)

            TodoDetailVerticalDashedDivider(verticalPadding: 4)

            Group {
                if let onDateTap, let dateText {
                    Button(action: onDateTap) {
                        TodoDetailTimeScheduleCapsuleColumn(width: TodoRowCardMetrics.detailTimeRowDateColumnWidth) {
                            TodoDetailTimeValueCapsule(text: dateText)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    TodoDetailTimeScheduleCapsuleColumn(width: TodoRowCardMetrics.detailTimeRowDateColumnWidth) {
                        TodoDetailTimePlaceholderDash()
                    }
                }
            }

            TodoDetailVerticalDashedDivider(verticalPadding: 4)

            Group {
                if let onSlotTap, let slotText {
                    Button(action: onSlotTap) {
                        ZStack {
                            TodoDetailTimeValueCapsule(text: slotText, lineLimit: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                } else if let slotText {
                    ZStack {
                        TodoDetailTimeValueCapsule(text: slotText, lineLimit: 2)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ZStack {
                        TodoDetailTimePlaceholderDash()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(minHeight: TodoRowCardMetrics.detailTimeRowHeight)
    }
}

private struct TodoDetailTimeScheduleCard: View {
    let plannedDateText: String
    let plannedSlotText: String
    let startDateText: String?
    let startSlotText: String?
    let endDateText: String?
    let endSlotText: String?
    let onPlannedDateTap: () -> Void
    let onPlannedSlotTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TodoDetailTimeScheduleRow(
                title: "开始时间",
                dateText: startDateText,
                slotText: startSlotText
            )

            TodoDetailDashedDivider()
                .padding(.vertical, 8)

            TodoDetailTimeScheduleRow(
                title: "结束时间",
                dateText: endDateText,
                slotText: endSlotText
            )

            TodoDetailDashedDivider()
                .padding(.vertical, 8)

            TodoDetailTimeScheduleRow(
                title: "计划时间",
                dateText: plannedDateText,
                slotText: plannedSlotText,
                onDateTap: onPlannedDateTap,
                onSlotTap: onPlannedSlotTap
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .todoPanelCardChrome()
    }
}

private struct TodoDetailMetaChip: View {
    let title: String
    let value: String?
    var uniformTypography: Bool = false
    var usesProportionalVerticalLayout: Bool = false
    var usesCompactTypography: Bool = false
    var valueColor: Color = MindFlowFormSheetStyle.accent

    private var titleFont: Font {
        if usesProportionalVerticalLayout {
            return .subheadline.weight(.semibold)
        }
        return uniformTypography ? .headline.weight(.semibold) : .caption.weight(.semibold)
    }

    private var titleColor: Color {
        if usesProportionalVerticalLayout {
            return Color.secondary
        }
        return uniformTypography ? MindFlowFormSheetStyle.accent : Color.secondary
    }

    private var valueFont: Font {
        if usesProportionalVerticalLayout {
            if usesCompactTypography { return .subheadline.weight(.semibold) }
            return .title3.weight(.semibold)
        }
        return .headline.weight(.semibold)
    }

    private var titleVerticalRatio: CGFloat {
        if usesProportionalVerticalLayout, usesCompactTypography {
            return TodoRowCardMetrics.detailMetaChipMultilineTitleVerticalRatio
        }
        return 1.0 / 3.0
    }

    private var valueVerticalRatio: CGFloat {
        if usesProportionalVerticalLayout, usesCompactTypography {
            return TodoRowCardMetrics.detailMetaChipMultilineValueVerticalRatio
        }
        return 2.0 / 3.0
    }

    var body: some View {
        Group {
            if usesProportionalVerticalLayout {
                GeometryReader { geometry in
                    let verticalOffset = TodoRowCardMetrics.detailMetaChipVerticalOffset
                    ZStack {
                        Text(title)
                            .font(titleFont)
                            .foregroundStyle(titleColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height * titleVerticalRatio + verticalOffset
                            )

                        if let value {
                            Text(value)
                                .font(valueFont)
                                .foregroundStyle(valueColor)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .minimumScaleFactor(0.7)
                                .position(
                                    x: geometry.size.width / 2,
                                    y: geometry.size.height * valueVerticalRatio + verticalOffset
                                )
                        } else {
                            TodoDetailTimePlaceholderDash()
                                .position(
                                    x: geometry.size.width / 2,
                                    y: geometry.size.height * valueVerticalRatio + verticalOffset
                                )
                        }
                    }
                }
            } else {
                ZStack {
                    if let value {
                        Text(value)
                            .font(valueFont)
                            .foregroundStyle(valueColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        TodoDetailTimePlaceholderDash()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }

                    VStack(spacing: 0) {
                        Text(title)
                            .font(titleFont)
                            .foregroundStyle(titleColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.top, TodoRowCardMetrics.detailMetaChipTopPadding)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: TodoRowCardMetrics.detailMetaRowCardHeight)
        .todoPanelCardChrome()
    }
}

private struct TodoDetailCategoryChip: View {
    @ObservedObject var viewModel: TodoViewModel
    let todoId: Int
    @State private var showsCategoryPicker = false

    private var todo: TodoItem? {
        viewModel.todos.first(where: { $0.id == todoId })
    }

    var body: some View {
        TodoDetailMetaChip(
            title: "分类",
            value: todo?.taskCategoryLabel,
            usesProportionalVerticalLayout: true
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showsCategoryPicker = true
        }
        .sheet(isPresented: $showsCategoryPicker) {
            TodoDetailCategoryPickerSheet(
                selectedCategoryId: todo?.taskCategoryId,
                onSelect: { categoryId in
                    viewModel.updateTodoCategory(id: todoId, taskCategoryId: categoryId)
                }
            )
        }
    }
}

private struct TodoDetailCategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let selectedCategoryId: Int?
    let onSelect: (Int) -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(TodoLifeCategoryCatalog.available) { category in
                        categoryCard(for: category)
                    }
                }
                .padding(16)
            }
            .scrollContentBackground(.hidden)
            .mindFlowScrollContentBottomInset()
            .background(todoDetailSheetBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("选择分类")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                }
            }
            .tint(MindFlowFormSheetStyle.accent)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func categoryCard(for category: TodoLifeCategoryOption) -> some View {
        let isSelected = selectedCategoryId == category.taskCategoryId
        return Button {
            onSelect(category.taskCategoryId)
            dismiss()
        } label: {
            Text(category.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? MindFlowFormSheetStyle.accent : Color(hex: "#2B5748").opacity(0.72))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? MindFlowFormSheetStyle.accentFill : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isSelected ? MindFlowFormSheetStyle.accent.opacity(0.38) : MindFlowFormSheetStyle.fieldBorder,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct TodoDetailInfoCard: View {
    let title: String
    let value: String
    var icon: String? = nil
    var valueFont: Font = .headline.weight(.semibold)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)

            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(hex: "#2B5748"))
                }
                Text(value)
                    .font(valueFont)
                    .foregroundColor(Color(hex: "#2B5748"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .todoPanelCardChrome()
    }
}

struct TodoDetailView: View {
    @ObservedObject var viewModel: TodoViewModel
    let todoId: Int
    @State private var activeTimeEdit: TodoDetailTimeEditContext?

    private var todo: TodoItem? {
        viewModel.todos.first(where: { $0.id == todoId })
    }

    private var noteInitialText: String {
        todo?.description ?? ""
    }

    var body: some View {
        if let todo {
            detailContent(for: todo)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private func detailContent(for todo: TodoItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TodoDetailTitleCard(todo: todo)
                    .padding(.horizontal, 20)
                    .onTapGesture { dismissNoteKeyboard() }

                TodoDetailNoteCard(
                    initialText: noteInitialText,
                    onSave: { viewModel.updateTodoDescription(id: todoId, description: $0) }
                )
                    .padding(.horizontal, 20)

                TodoDetailTimeScheduleCard(
                    plannedDateText: todo.plannedDateOnlyDisplayText,
                    plannedSlotText: todo.plannedTimeSlotDisplayText,
                    startDateText: todo.workStartedDateOnlyDisplayText,
                    startSlotText: todo.workStartedSlotDisplayText,
                    endDateText: todo.actualCompletedDateOnlyDisplayText,
                    endSlotText: todo.actualCompletedSlotDisplayText,
                    onPlannedDateTap: { presentTimeEdit(.plannedDate, todo: todo) },
                    onPlannedSlotTap: { presentTimeEdit(.plannedTime, todo: todo) }
                )
                .padding(.horizontal, 20)

                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 12) {
                        TodoDetailMetaChip(
                            title: "计划时长",
                            value: todo.timeSlotDurationDisplayText,
                            usesProportionalVerticalLayout: true,
                            usesCompactTypography: todo.timeSlotDurationUsesMultilineDisplay
                        )
                        TodoDetailMetaChip(
                            title: "状态",
                            value: viewModel.resolvedWorkStatus(for: todo).displayName,
                            usesProportionalVerticalLayout: true,
                            valueColor: viewModel.resolvedWorkStatus(for: todo) == .completed
                                ? TodoRowCardMetrics.detailCompletedStatusTextColor
                                : MindFlowFormSheetStyle.accent
                        )
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 12) {
                        TodoDetailMetaChip(
                            title: "投入时长",
                            value: todo.investedDurationDisplayText(
                                liveTimerSeconds: viewModel.currentWorkSeconds(todoId: todo.id)
                            ),
                            usesProportionalVerticalLayout: true
                        )
                        TodoDetailPriorityChip(
                            viewModel: viewModel,
                            todoId: todo.id
                        )
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 12) {
                        TodoDetailCategoryChip(
                            viewModel: viewModel,
                            todoId: todo.id
                        )
                        TodoDetailRepeatSection(
                            viewModel: viewModel,
                            todoId: todo.id
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .onTapGesture { dismissNoteKeyboard() }

                if todo.repeatMode != .none {
                    TodoDetailCustomRepeatCard(
                        viewModel: viewModel,
                        todoId: todo.id
                    )
                    .padding(.horizontal, 20)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                }

                if todo.repeatMode.usesRepeatLimit {
                    TodoDetailRepeatLimitCard(
                        viewModel: viewModel,
                        todoId: todo.id
                    )
                    .padding(.horizontal, 20)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                }
            }
            .animation(TodoCardMotion.slide, value: todo.repeatMode)
            .padding(.top, TodoRowCardMetrics.detailPageTopInset)
        }
        .contentMargins(.top, TodoRowCardMetrics.detailPageScrollTopInset, for: .scrollContent)
        .mindFlowScrollContentBottomInset()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear
                .frame(height: TodoRowCardMetrics.detailPageBottomNavBarClearance)
                .accessibilityHidden(true)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(item: $activeTimeEdit) { context in
            timeEditSheet(for: context, todo: todo)
        }
        .background {
            LinearGradient(
                colors: [Color.white, Color(hex: "#d8f3dc")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(
            LinearGradient(
                colors: [Color.white, Color.white.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            ),
            for: .navigationBar
        )
    }

    private func dismissNoteKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func presentTimeEdit(_ context: TodoDetailTimeEditContext, todo: TodoItem) {
        dismissNoteKeyboard()
        activeTimeEdit = context
    }

    @ViewBuilder
    private func timeEditSheet(for context: TodoDetailTimeEditContext, todo: TodoItem) -> some View {
        if context.isDate, let target = context.dateTarget {
            TodoDetailDatePickerSheet(
                date: todo.date(for: target),
                title: context.sheetTitle
            ) { date in
                switch target {
                case .start, .end:
                    return viewModel.tryUpdateTodoDate(id: todo.id, target: target, date: date)
                case .planned:
                    viewModel.updateTodoDate(id: todo.id, target: target, date: date)
                    return nil
                }
            }
        } else {
            momentPickerSheet(for: context, todo: todo)
        }
    }

    private func momentPickerSheet(for context: TodoDetailTimeEditContext, todo: TodoItem) -> some View {
        let hour: Int
        let minute: Int
        switch context {
        case .startTime:
            hour = min(max(todo.timeSlotStartHour, 0), 23)
            minute = min(max(todo.timeSlotStartMinute, 0), 59)
        case .endTime:
            let endHour = min(max(todo.timeSlotEndHour, 0), 24)
            if endHour == 24 {
                hour = 23
                minute = 59
            } else {
                hour = endHour
                minute = min(max(todo.timeSlotEndMinute, 0), 59)
            }
        case .plannedTime:
            hour = min(max(todo.plannedTimeSlotHour, 0), 23)
            minute = min(max(todo.plannedTimeSlotMinute, 0), 59)
        default:
            hour = min(max(todo.timeSlotStartHour, 0), 23)
            minute = min(max(todo.timeSlotStartMinute, 0), 59)
        }
        return TodoDetailMomentPickerSheet(
            hour: hour,
            minute: minute,
            title: context.sheetTitle
        ) { h, m in
            switch context {
            case .startTime:
                return viewModel.tryUpdateTodoTimeSlotStart(id: todo.id, hour: h, minute: m)
            case .endTime:
                return viewModel.tryUpdateTodoTimeSlotEnd(id: todo.id, hour: h, minute: m)
            case .plannedTime:
                viewModel.updateTodoPlannedTimeSlot(id: todo.id, hour: h, minute: m)
                return nil
            default:
                return nil
            }
        }
    }
}
