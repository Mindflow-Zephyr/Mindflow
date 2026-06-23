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
    static let titleBottomInset: CGFloat = 12
    static let titleLineHeight: CGFloat = 22
    static var titleBarHeight: CGFloat { titleTopInset + titleLineHeight + titleBottomInset }
    static let listHorizontalPadding: CGFloat = 8
    static let listBottomPadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 14
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
    static let titleSubtitleSpacing: CGFloat = 10
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
    /// 详情页时间行：标题列
    static let detailTimeRowTitleWidth: CGFloat = 100
    /// 详情页时间行：标题列左右内边距
    static let detailTimeRowTitleHorizontalInset: CGFloat = 10
    /// 详情页时间行：年月日列宽度（各行对齐，可调试）
    static let detailTimeRowDateWidth: CGFloat = 110
    /// 详情页时间行：时间段列宽度（各行对齐，可调试）
    static let detailTimeRowSlotWidth: CGFloat = 72
    /// 详情页时间行：年月日与时间段整体右移（可调试）
    static let detailTimeRowDateSlotGroupOffset: CGFloat = 10
    /// 详情页时间行：年月日与时间段间距（各行一致，保证时间段列对齐）
    static let detailTimeRowDateToSlotSpacing: CGFloat = 30
    /// 详情页时间胶囊背景色
    static let detailTimeCapsuleFillColor = Color(hex: "#88BDA4")
    /// 详情页时间行高度
    static let detailTimeRowHeight: CGFloat = 40
    /// 详情页备注小标题距顶
    static let detailNoteTitleTopPadding: CGFloat = 6
    /// 详情页备注标题到输入框间距
    static let detailNoteTitleToInputSpacing: CGFloat = 8
    /// 详情页备注输入框最小高度
    static let detailNoteInputMinHeight: CGFloat = 36
    /// 详情页备注输入框字号
    static let detailNoteContentFont: Font = .subheadline.weight(.semibold)
    /// 详情页备注输入框水平内边距
    static let detailNoteInputHorizontalPadding: CGFloat = 10
    /// 详情页备注输入框垂直内边距
    static let detailNoteInputVerticalPadding: CGFloat = 6
    /// 详情页备注输入框垂直微调（可调试，正值下移，作用于整块输入区）
    static let detailNoteInputVerticalOffset: CGFloat = 6
    /// 详情页备注换行测量时的宽度安全边距（略小于可见宽，避免 TextField 出现 …）
    static let detailNoteInputWidthSafetyMargin: CGFloat = 6
    /// 详情页备注行数增加时的展开动画
    static let detailNoteExpandAnimation: Animation = .easeInOut(duration: 0.22)
    /// 详情页底部信息行卡片高度（创建 / 时长 / 分类）
    static let detailMetaRowCardHeight: CGFloat = 88
    /// 详情页底部信息卡小标题距顶（非比例布局备用）
    static let detailMetaChipTopPadding: CGFloat = 10
    /// 详情页底部信息卡标题/正文整体上移（可调试，负值上移）
    static let detailMetaChipVerticalOffset: CGFloat = -6
    /// 详情页首卡距顶部的间距
    static let detailPageTopInset: CGFloat = 4
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
}

// MARK: - 主程序
struct TodoView: View {
    
    @Binding var showingAddTodo: Bool
    @StateObject private var viewModel = TodoViewModel()     // 界面数据与逻辑模型
    @State private var showCompleted = false  // 未完成/已完成 UI状态
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
        guard screenHeight.isFinite, screenHeight > 0 else { return 300 }
        return max(1, min(screenHeight * 0.58, 520))
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

            HStack {
                Spacer(minLength: 0)
                completedListToggleButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
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
                        VStack(alignment: .leading, spacing: 30) {
                            // App标题占位
                            HStack {
                                Spacer()
                                Text("Mindflow")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .opacity(0) // 隐藏但占位
                                Spacer()
                            }
                            .frame(height: 0)
                            .padding(.top, 0)
                            
                            // 待办事项卡片（列表可为空，仍显示以便新建）
                            todoCardContainer(width: geometry.size.width)
                        }
                    }
                    .safeAreaInset(edge: .top) {
                        VStack(spacing: 0) {
                            // App标题置顶
                            HStack(alignment: .center) {
                                Spacer()
                                Text("Mindflow")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 30)
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
                .task {
                    await viewModel.loadTodos()
                }
            }
        }
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
    func todoPanelCardChrome(cornerRadius: CGFloat = TodoPanelCardChrome.cornerRadius) -> some View {
        background(TodoPanelCardChrome.background)
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
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2B5748"))
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
                        Text(todo.timeSlotDisplayText)
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
                    ? Color(hex: "#2d6a4f").opacity(0.1)
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
    
    func loadTodos() async {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? today

        todos = [
            TodoItem(id: 1, title: "完成项目文档", description: "编写项目说明文档", isCompleted: false, status: .notStarted, priority: .p1, createdAt: today, completedDate: nil, completionDurationSeconds: nil, timeSlotStartHour: 9, timeSlotEndHour: 12, taskCategoryId: TodoLifeCategoryCatalog.outfitCategoryId),
            TodoItem(id: 2, title: "代码审查", description: "审查团队代码", isCompleted: true, status: .completed, priority: .p2, createdAt: yesterday, completedDate: yesterday, completionDurationSeconds: 120, timeSlotStartHour: 0, timeSlotEndHour: 1, taskCategoryId: TodoLifeCategoryCatalog.outfitCategoryId),
            TodoItem(id: 3, title: "准备会议", description: nil, isCompleted: false, status: .inProgress, priority: .p3, createdAt: today, completedDate: nil, completionDurationSeconds: nil, timeSlotStartHour: 14, timeSlotEndHour: 17, taskCategoryId: TodoLifeCategoryCatalog.outfitCategoryId),
            TodoItem(id: 4, title: "晚间复盘", description: nil, isCompleted: false, status: .paused, priority: .p4, createdAt: twoDaysAgo, completedDate: nil, completionDurationSeconds: nil, timeSlotStartHour: 20, timeSlotEndHour: 22, taskCategoryId: TodoLifeCategoryCatalog.outfitCategoryId)
        ]
    }

    func addTodo(
        title: String,
        description: String?,
        timeSlotStartHour: Int,
        timeSlotStartMinute: Int,
        timeSlotEndHour: Int,
        timeSlotEndMinute: Int,
        taskCategoryId: Int? = nil
    ) {
        let newId = (todos.map(\.id).max() ?? 0) + 1
        let item = TodoItem(
            id: newId,
            title: title,
            description: description,
            isCompleted: false,
            status: .notStarted,
            createdAt: Date(),
            completedDate: nil,
            completionDurationSeconds: nil,
            timeSlotStartHour: timeSlotStartHour,
            timeSlotStartMinute: timeSlotStartMinute,
            timeSlotEndHour: timeSlotEndHour,
            timeSlotEndMinute: timeSlotEndMinute,
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
    }

    func updateTodoDescription(id: Int, description: String) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        todos[index].description = trimmed.isEmpty ? nil : description
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
            let todoId = todos[index].id
            let workState = activeWorkByTodoId[todoId]
            let hasPausedWork = (workState?.accumulated ?? 0) > 0.5 || workState?.pausedLightBandPhaseRadians != nil
            todos[index].status = hasPausedWork ? .paused : .notStarted
        }
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
        }
        activeWorkByTodoId[todoId] = state
        if let index = todos.firstIndex(where: { $0.id == todoId }) {
            todos[index].status = state.runningSince == nil ? .paused : .inProgress
        }
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
    /// 待办分类 ID，对应 `TodoLifeCategoryCatalog`
    var taskCategoryId: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, description, isCompleted, status, priority, createdAt, completedDate
        case completionDurationSeconds
        case timeSlotStartHour, timeSlotStartMinute, timeSlotEndHour, timeSlotEndMinute
        case taskCategoryId
    }

    init(
        id: Int,
        title: String,
        description: String?,
        isCompleted: Bool,
        status: TodoWorkStatus = .notStarted,
        priority: TodoPriority = .p3,
        createdAt: Date,
        completedDate: Date?,
        completionDurationSeconds: Int? = nil,
        timeSlotStartHour: Int = 0,
        timeSlotStartMinute: Int = 0,
        timeSlotEndHour: Int = 1,
        timeSlotEndMinute: Int = 0,
        taskCategoryId: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.status = isCompleted ? .completed : status
        self.priority = priority
        self.createdAt = createdAt
        self.completedDate = completedDate
        self.completionDurationSeconds = completionDurationSeconds
        self.timeSlotStartHour = timeSlotStartHour
        self.timeSlotStartMinute = timeSlotStartMinute
        self.timeSlotEndHour = timeSlotEndHour
        self.timeSlotEndMinute = timeSlotEndMinute
        self.taskCategoryId = taskCategoryId
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
        completedDate = try container.decodeIfPresent(Date.self, forKey: .completedDate)
        completionDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .completionDurationSeconds)
        timeSlotStartHour = try container.decodeIfPresent(Int.self, forKey: .timeSlotStartHour) ?? 0
        timeSlotStartMinute = try container.decodeIfPresent(Int.self, forKey: .timeSlotStartMinute) ?? 0
        timeSlotEndHour = try container.decodeIfPresent(Int.self, forKey: .timeSlotEndHour) ?? 1
        timeSlotEndMinute = try container.decodeIfPresent(Int.self, forKey: .timeSlotEndMinute) ?? 0
        taskCategoryId = try container.decodeIfPresent(Int.self, forKey: .taskCategoryId)
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
        try container.encodeIfPresent(completedDate, forKey: .completedDate)
        try container.encodeIfPresent(completionDurationSeconds, forKey: .completionDurationSeconds)
        try container.encode(timeSlotStartHour, forKey: .timeSlotStartHour)
        try container.encode(timeSlotStartMinute, forKey: .timeSlotStartMinute)
        try container.encode(timeSlotEndHour, forKey: .timeSlotEndHour)
        try container.encode(timeSlotEndMinute, forKey: .timeSlotEndMinute)
        try container.encodeIfPresent(taskCategoryId, forKey: .taskCategoryId)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension TodoItem {
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
        let c = normalizedTimeSlotHM
        func p(_ m: Int) -> String { String(format: "%02d", m) }
        if c.eh == 24 {
            return "\(c.sh):\(p(c.sm)) - 24:00"
        }
        return "\(c.sh):\(p(c.sm)) - \(c.eh):\(p(c.em))"
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

    /// 计划时段时长文案，如「3 小时」
    var timeSlotDurationDisplayText: String {
        Self.durationDisplayText(seconds: timeSlotDurationSeconds)
    }

    /// 投入时长文案（已完成取记录；未完成取计时器累计）
    func investedDurationDisplayText(liveTimerSeconds: Int) -> String {
        if isCompleted, let sec = completionDurationSeconds, sec >= 0 {
            return Self.durationDisplayText(seconds: sec)
        }
        if liveTimerSeconds > 0 {
            return Self.durationDisplayText(seconds: liveTimerSeconds)
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
        return "\(h) 小时 \(m) 分钟"
    }

    /// 详情页：创建日期 yyyy-MM-dd
    var createdDateOnlyDisplayText: String {
        TodoDetailDateFormatting.dateOnly.string(from: createdAt)
    }

    /// 详情页：计划日期 yyyy-MM-dd
    var plannedDateOnlyDisplayText: String {
        createdDateOnlyDisplayText
    }

    /// 计划时间段的总时长（秒）
    var timeSlotDurationSeconds: Int {
        let c = normalizedTimeSlotHM
        let startMin = c.sh * 60 + c.sm
        let endMin = c.eh == 24 ? 24 * 60 : c.eh * 60 + c.em
        return max(0, (endMin - startMin) * 60)
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
    private enum TimeField { case start, end, duration }

    @ObservedObject var viewModel: TodoViewModel
    var panelExpanded: Bool
    let onDismiss: () -> Void
    @State private var formMode: AddTodoFormMode = .task
    @State private var selectedCategoryId: Int = TodoLifeCategoryCatalog.available[0].taskCategoryId
    @State private var titleText = ""
    @State private var descriptionText = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var durationHours: Int = 1
    @State private var durationMinutes: Int = 0
    @State private var showsEndTime = false
    @State private var showsDuration = false
    @State private var expandedTimeField: TimeField?
    @State private var draftStartTime: Date
    @State private var draftEndTime: Date
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

    init(viewModel: TodoViewModel, panelExpanded: Bool, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.panelExpanded = panelExpanded
        self.onDismiss = onDismiss
        _startTime = State(initialValue: Self.defaultStartTime())
        _endTime = State(initialValue: Self.defaultStartTime())
        let start = Self.defaultStartTime()
        _draftStartTime = State(initialValue: start)
        _draftEndTime = State(initialValue: start)
    }

    private static func defaultStartTime() -> Date {
        let cal = Calendar.current
        let now = Date()
        return cal.date(from: cal.dateComponents([.year, .month, .day, .hour, .minute], from: now)) ?? now
    }

    private static func endDateIfNotAfterStart(start: Date, end: Date) -> Date {
        let cal = Calendar.current
        let s = cal.component(.hour, from: start) * 60 + cal.component(.minute, from: start)
        let e = cal.component(.hour, from: end) * 60 + cal.component(.minute, from: end)
        if e > s { return end }
        return cal.date(byAdding: .hour, value: 1, to: start) ?? end
    }

    private var totalDurationMinutes: Int {
        durationHours * 60 + durationMinutes
    }

    private func applyDefaultTimeSlot() {
        let start = Self.defaultStartTime()
        startTime = start
        endTime = start
        durationHours = 1
        durationMinutes = 0
        showsEndTime = false
        showsDuration = false
        expandedTimeField = nil
        selectedCategoryId = TodoLifeCategoryCatalog.available[0].taskCategoryId
        formMode = .task
        titleText = ""
        descriptionText = ""
        allowTitleKeyboard = true
    }

    private func dismissAllInputs() {
        isNotesFieldFocused = false
        expandedTimeField = nil
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
        let resolvedEnd: Date
        if showsEndTime {
            resolvedEnd = Self.endDateIfNotAfterStart(start: startTime, end: endTime)
        } else if showsDuration {
            resolvedEnd = Calendar.current.date(
                byAdding: .minute,
                value: max(1, totalDurationMinutes),
                to: startTime
            ) ?? startTime
        } else {
            resolvedEnd = Self.endDateIfNotAfterStart(start: startTime, end: endTime)
        }
        let sh = cal.component(.hour, from: startTime)
        let sm = cal.component(.minute, from: startTime)
        let eh = cal.component(.hour, from: resolvedEnd)
        let em = cal.component(.minute, from: resolvedEnd)
        viewModel.addTodo(
            title: t.isEmpty ? "未命名待办" : t,
            description: d.isEmpty ? nil : d,
            timeSlotStartHour: sh,
            timeSlotStartMinute: sm,
            timeSlotEndHour: eh,
            timeSlotEndMinute: em,
            taskCategoryId: selectedCategoryId
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

    @ViewBuilder
    private var categoryPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TodoLifeCategoryCatalog.available) { category in
                    let isSelected = selectedCategoryId == category.taskCategoryId
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedCategoryId = category.taskCategoryId
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.caption.weight(.semibold))
                            Text(category.title)
                                .font(.subheadline)
                        }
                        .foregroundStyle(isSelected ? MindFlowFormSheetStyle.accent : Color.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isSelected ? MindFlowFormSheetStyle.accentFill : Color.clear)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    isSelected ? MindFlowFormSheetStyle.accent : MindFlowFormSheetStyle.fieldBorder,
                                    style: StrokeStyle(
                                        lineWidth: 1,
                                        dash: isSelected ? [] : [4, 3]
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .accessibilityLabel("任务分类")
    }

    private func timeButtonLabel(_ date: Date) -> String {
        Self.timeHMFormatter.string(from: date)
    }

    private func durationCompactText() -> String {
        let h = durationHours
        let m = durationMinutes
        if h > 0, m > 0 { return "\(h)时\(m)分" }
        if h > 0 { return "\(h)时" }
        if m > 0 { return "\(m)分" }
        return "0分"
    }

    private func minutesFromStartToEnd(start: Date, end: Date) -> Int {
        max(0, Int(end.timeIntervalSince(start) / 60))
    }

    private func applyDurationToEndTime() {
        let total = max(1, totalDurationMinutes)
        let cal = Calendar.current
        endTime = cal.date(byAdding: .minute, value: total, to: startTime) ?? startTime
        showsEndTime = true
        showsDuration = true
    }

    private func applyEndTimeToDuration() {
        let total = max(1, minutesFromStartToEnd(start: startTime, end: endTime))
        durationHours = total / 60
        durationMinutes = total % 60
        showsDuration = true
        showsEndTime = true
    }

    private func splitDurationIntoDraft(_ totalMinutes: Int) {
        let total = max(1, totalMinutes)
        draftDurationHours = min(23, total / 60)
        draftDurationMinutes = total % 60
        if draftDurationHours == 0, draftDurationMinutes == 0 {
            draftDurationMinutes = 1
        }
    }

    private func beginEditingTimeField(_ field: TimeField, onActivate: (() -> Void)? = nil) {
        if expandedTimeField == field {
            withAnimation(.easeInOut(duration: 0.2)) {
                cancelTimePicker()
            }
            return
        }
        onActivate?()
        draftStartTime = startTime
        draftEndTime = endTime
        draftDurationHours = durationHours
        draftDurationMinutes = durationMinutes
        if field == .duration, !showsDuration {
            splitDurationIntoDraft(totalDurationMinutes)
        }
        if field == .end, !showsEndTime {
            draftEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedTimeField = field
        }
    }

    private func cancelTimePicker() {
        expandedTimeField = nil
    }

    private func confirmTimePicker() {
        guard let field = expandedTimeField else { return }
        switch field {
        case .start:
            startTime = draftStartTime
            if showsDuration {
                applyDurationToEndTime()
            } else if showsEndTime {
                applyEndTimeToDuration()
            }
        case .end:
            endTime = draftEndTime
            applyEndTimeToDuration()
        case .duration:
            durationHours = draftDurationHours
            durationMinutes = draftDurationMinutes
            applyDurationToEndTime()
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedTimeField = nil
        }
    }

    @ViewBuilder
    private func timeSlotCell(
        label: String,
        value: String?,
        field: TimeField,
        onActivate: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button {
                beginEditingTimeField(field, onActivate: onActivate)
            } label: {
                Group {
                    if let value {
                        Text(value)
                            .font(.subheadline)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    } else {
                        Text(" ")
                            .font(.subheadline)
                            .accessibilityLabel("未设置")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 22)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            value == nil ? MindFlowFormSheetStyle.fieldBorder : MindFlowFormSheetStyle.accent.opacity(0.55),
                            style: StrokeStyle(
                                lineWidth: 1,
                                dash: value == nil ? [4, 3] : []
                            )
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
    private var timePickerWheels: some View {
        VStack(spacing: 0) {
            Group {
                if expandedTimeField == .start {
                    DatePicker("", selection: $draftStartTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                } else if expandedTimeField == .end {
                    DatePicker("", selection: $draftEndTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                } else if expandedTimeField == .duration {
                    HStack(spacing: 0) {
                        Picker("时", selection: $draftDurationHours) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h) 小时").tag(h)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        Picker("分", selection: $draftDurationMinutes) {
                            ForEach(0..<60, id: \.self) { m in
                                Text("\(m) 分钟").tag(m)
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
                        cancelTimePicker()
                    }
                }
                .foregroundStyle(.secondary)
                Spacer()
                Button("确定") {
                    confirmTimePicker()
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
    private var timeSlotSection: some View {
        HStack(alignment: .bottom, spacing: 8) {
            timeSlotCell(
                label: "起始",
                value: timeButtonLabel(startTime),
                field: .start
            )
            timeSlotCell(
                label: "用时",
                value: showsDuration ? durationCompactText() : nil,
                field: .duration,
                onActivate: {
                    guard !showsDuration else { return }
                    splitDurationIntoDraft(totalDurationMinutes)
                }
            )
            timeSlotCell(
                label: "结束",
                value: showsEndTime ? timeButtonLabel(endTime) : nil,
                field: .end
            )
        }
        .overlay(alignment: .bottom) {
            if expandedTimeField != nil {
                timePickerWheels
                    .offset(y: -(timePickerPanelHeight + 6))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: expandedTimeField)
        .zIndex(expandedTimeField == nil ? 0 : 2)
        .padding(.top, expandedTimeField == nil ? 0 : timePickerPanelHeight + 6)
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
                        timeSlotSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                }
                .scrollDismissesKeyboard(.interactively)

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
            .todoRaisedStrikethrough(todo.isCompleted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: TodoRowCardMetrics.detailInlineCardMinHeight, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.vertical, TodoRowCardMetrics.detailInlineCardVerticalPadding)
            .todoPanelCardChrome()
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
            .fixedSize(horizontal: lineLimit == 1, vertical: true)
    }
}

private enum TodoDetailNoteLineLayout {
    private static var noteUIFont: UIFont {
        let base = UIFont.preferredFont(forTextStyle: .subheadline)
        let descriptor = base.fontDescriptor.withSymbolicTraits(.traitBold) ?? base.fontDescriptor
        let bold = UIFont(descriptor: descriptor, size: base.pointSize)
        return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: bold)
    }

    static func availableTextWidth(containerWidth: CGFloat) -> CGFloat {
        let raw = containerWidth - TodoRowCardMetrics.detailNoteInputHorizontalPadding * 2
        return max(0, raw - TodoRowCardMetrics.detailNoteInputWidthSafetyMargin)
    }

    static func textWidth(_ text: String) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        return ceil((text as NSString).size(withAttributes: [.font: noteUIFont]).width)
    }

    static func fitsSingleLine(_ text: String, containerWidth: CGFloat) -> Bool {
        let available = availableTextWidth(containerWidth: containerWidth)
        guard available > 0 else { return true }
        if text.isEmpty { return true }
        return textWidth(text) <= available
    }

    static func splitOverflow(_ text: String, containerWidth: CGFloat) -> (head: String, tail: String) {
        let available = availableTextWidth(containerWidth: containerWidth)
        guard available > 0, !text.isEmpty else { return (text, "") }

        if fitsSingleLine(text, containerWidth: containerWidth) {
            return (text, "")
        }

        var lo = 0
        var hi = text.count
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            let prefix = String(text.prefix(mid))
            if textWidth(prefix) <= available {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        if lo == 0 {
            return (String(text.prefix(1)), String(text.dropFirst(1)))
        }
        return (String(text.prefix(lo)), String(text.dropFirst(lo)))
    }

    static func reflowLines(_ lines: [String], containerWidth: CGFloat) -> [String] {
        guard containerWidth > 0 else { return lines.isEmpty ? [""] : lines }

        let source = lines.joined(separator: "\n")
        if source.isEmpty { return [""] }

        var result: [String] = []
        var remainder = source
        while !remainder.isEmpty {
            if fitsSingleLine(remainder, containerWidth: containerWidth) {
                result.append(remainder)
                break
            }
            let (head, tail) = splitOverflow(remainder, containerWidth: containerWidth)
            result.append(head)
            remainder = tail
        }
        return result.isEmpty ? [""] : result
    }
}

private struct TodoDetailNoteInputField: View {
    @Binding var text: String
    let lineIndex: Int
    @FocusState.Binding var focusedLineIndex: Int?
    var showsTopBorder: Bool = true
    var showsBottomBorder: Bool = true
    var placeholder: String = "轻触输入备注…"

    private var borderColor: Color {
        Color(hex: "#2B5748").opacity(0.22)
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .font(TodoRowCardMetrics.detailNoteContentFont)
            .foregroundColor(Color(hex: "#2B5748"))
            .textFieldStyle(.plain)
            .focused($focusedLineIndex, equals: lineIndex)
            .submitLabel(.next)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, TodoRowCardMetrics.detailNoteInputHorizontalPadding)
            .padding(.vertical, TodoRowCardMetrics.detailNoteInputVerticalPadding)
            .frame(maxWidth: .infinity, minHeight: TodoRowCardMetrics.detailNoteInputMinHeight, alignment: .leading)
            .overlay(alignment: .top) {
                if showsTopBorder {
                    Rectangle()
                        .fill(borderColor)
                        .frame(height: 1)
                }
            }
            .overlay(alignment: .bottom) {
                if showsBottomBorder {
                    Rectangle()
                        .fill(borderColor)
                        .frame(height: 1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { focusedLineIndex = lineIndex }
    }
}

private struct TodoDetailNoteCard: View {
    @Binding var text: String
    @State private var lines: [String] = [""]
    @State private var containerWidth: CGFloat = 0
    @FocusState private var focusedLineIndex: Int?

    var body: some View {
        VStack(spacing: TodoRowCardMetrics.detailNoteTitleToInputSpacing) {
            Text("备注")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, TodoRowCardMetrics.detailNoteTitleTopPadding)

            VStack(spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                    TodoDetailNoteInputField(
                        text: lineBinding(at: index),
                        lineIndex: index,
                        focusedLineIndex: $focusedLineIndex,
                        showsTopBorder: index == 0,
                        showsBottomBorder: true,
                        placeholder: index == 0 ? "轻触输入备注…" : ""
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .animation(TodoRowCardMetrics.detailNoteExpandAnimation, value: lines.count)
            .padding(.top, TodoRowCardMetrics.detailNoteInputVerticalOffset)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.width
            } action: { newWidth in
                guard newWidth > 0, newWidth != containerWidth else { return }
                containerWidth = newWidth
                reflowAllLines()
            }
        }
        .padding(.bottom, TodoRowCardMetrics.detailInlineCardVerticalPadding)
        .frame(maxWidth: .infinity)
        .todoPanelCardChrome()
        .onAppear {
            syncLinesFromText()
            if containerWidth > 0 {
                reflowAllLines()
            }
        }
        .onChange(of: text) { _, newValue in
            let joined = lines.joined(separator: "\n")
            if joined != newValue {
                syncLinesFromText()
            }
        }
    }

    private func lineBinding(at index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < lines.count else { return "" }
                return lines[index]
            },
            set: { newValue in
                updateLine(at: index, to: newValue)
            }
        )
    }

    private func syncLinesFromText() {
        if text.isEmpty {
            lines = [""]
        } else {
            let split = text.components(separatedBy: "\n")
            lines = split.isEmpty ? [""] : split
        }
        if containerWidth > 0 {
            reflowAllLines()
        }
    }

    private func reflowAllLines() {
        guard containerWidth > 0 else { return }
        let reflowed = TodoDetailNoteLineLayout.reflowLines(lines, containerWidth: containerWidth)
        if reflowed != lines {
            lines = reflowed
            commitLines()
        }
    }

    private func commitLines() {
        let joined = lines.joined(separator: "\n")
        if joined != text {
            text = joined
        }
    }

    private func updateLine(at index: Int, to newValue: String) {
        guard index < lines.count else { return }

        if newValue.isEmpty, index > 0, lines.count > 1 {
            withAnimation(TodoRowCardMetrics.detailNoteExpandAnimation) {
                lines.remove(at: index)
            }
            commitLines()
            return
        }

        guard containerWidth > 0 else {
            lines[index] = newValue
            commitLines()
            return
        }

        if TodoDetailNoteLineLayout.fitsSingleLine(newValue, containerWidth: containerWidth) {
            lines[index] = newValue
            commitLines()
            return
        }

        let (head, tail) = TodoDetailNoteLineLayout.splitOverflow(newValue, containerWidth: containerWidth)
        lines[index] = head

        guard !tail.isEmpty else {
            commitLines()
            return
        }

        if index + 1 < lines.count {
            lines[index + 1] = tail + lines[index + 1]
        } else {
            withAnimation(TodoRowCardMetrics.detailNoteExpandAnimation) {
                lines.append(tail)
            }
            focusedLineIndex = index + 1
        }

        if index + 1 < lines.count,
           !TodoDetailNoteLineLayout.fitsSingleLine(lines[index + 1], containerWidth: containerWidth) {
            let overflow = lines[index + 1]
            updateLine(at: index + 1, to: overflow)
        }

        commitLines()
    }
}

private struct TodoDetailTimeScheduleRow: View {
    let title: String
    let dateText: String
    let slotText: String

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TodoRowCardMetrics.detailTimeRowTitleHorizontalInset)
                .frame(width: TodoRowCardMetrics.detailTimeRowTitleWidth, alignment: .center)

            TodoDetailVerticalDashedDivider(verticalPadding: 4)

            HStack(alignment: .center, spacing: 0) {
                TodoDetailTimeValueCapsule(text: dateText)
                    .frame(width: TodoRowCardMetrics.detailTimeRowDateWidth, alignment: .center)

                Color.clear
                    .frame(width: TodoRowCardMetrics.detailTimeRowDateToSlotSpacing)

                TodoDetailTimeValueCapsule(text: slotText, lineLimit: 2)
                    .frame(width: TodoRowCardMetrics.detailTimeRowSlotWidth, alignment: .center)

                Spacer(minLength: 0)
            }
            .padding(.leading, TodoRowCardMetrics.detailTimeRowDateSlotGroupOffset)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: TodoRowCardMetrics.detailTimeRowHeight)
    }
}

private struct TodoDetailTimeScheduleCard: View {
    let plannedDateText: String
    let plannedSlotText: String
    let startDateText: String
    let startSlotText: String
    let endDateText: String
    let endSlotText: String

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
                slotText: plannedSlotText
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .todoPanelCardChrome()
    }
}

private struct TodoDetailMetaChip: View {
    let title: String
    let value: String
    var uniformTypography: Bool = false
    var usesProportionalVerticalLayout: Bool = false
    var usesCompactTypography: Bool = false

    private var titleFont: Font {
        if usesProportionalVerticalLayout {
            if usesCompactTypography { return .caption.weight(.semibold) }
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
                                y: geometry.size.height / 3 + verticalOffset
                            )

                        Text(value)
                            .font(valueFont)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height * 2 / 3 + verticalOffset
                            )
                    }
                }
            } else {
                ZStack {
                    Text(value)
                        .font(valueFont)
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

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

    private var todo: TodoItem? {
        viewModel.todos.first(where: { $0.id == todoId })
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { todo?.description ?? "" },
            set: { viewModel.updateTodoDescription(id: todoId, description: $0) }
        )
    }

    private static let detailDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

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

                TodoDetailNoteCard(text: noteBinding)
                    .padding(.horizontal, 20)

                TodoDetailTimeScheduleCard(
                    plannedDateText: todo.plannedDateOnlyDisplayText,
                    plannedSlotText: todo.timeSlotStartDisplayText,
                    startDateText: todo.createdDateOnlyDisplayText,
                    startSlotText: todo.timeSlotStartDisplayText,
                    endDateText: todo.createdDateOnlyDisplayText,
                    endSlotText: todo.timeSlotEndDisplayText
                )
                .padding(.horizontal, 20)

                HStack(alignment: .top, spacing: 12) {
                    TodoDetailMetaChip(
                        title: "计划时长",
                        value: todo.timeSlotDurationDisplayText,
                        usesProportionalVerticalLayout: true
                    )
                    VStack(spacing: 12) {
                        TodoDetailMetaChip(
                            title: "投入时长",
                            value: todo.investedDurationDisplayText(
                                liveTimerSeconds: viewModel.currentWorkSeconds(todoId: todo.id)
                            ),
                            usesProportionalVerticalLayout: true
                        )
                        TodoDetailMetaChip(
                            title: "优先级",
                            value: todo.priority.displayName,
                            usesProportionalVerticalLayout: true
                        )
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 12) {
                        if let category = todo.taskCategoryLabel {
                            TodoDetailMetaChip(
                                title: "分类",
                                value: category,
                                usesProportionalVerticalLayout: true
                            )
                        }
                        TodoDetailMetaChip(
                            title: "状态",
                            value: todo.status.displayName,
                            usesProportionalVerticalLayout: true
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)

                if todo.isCompleted {
                    if let spent = todo.completionDurationCompactText {
                        TodoDetailInfoCard(
                            title: "完成用时",
                            value: spent,
                            icon: "alarm"
                        )
                        .padding(.horizontal, 20)
                    }
                    if let done = todo.completedDate {
                        TodoDetailInfoCard(
                            title: "完成时间",
                            value: Self.detailDateFormatter.string(from: done),
                            icon: "checkmark.circle"
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, TodoRowCardMetrics.detailPageTopInset)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: "#d8f3dc")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
