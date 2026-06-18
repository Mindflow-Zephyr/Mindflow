import SwiftUI
import Combine

// MARK: - Models

struct LifeCategory: Identifiable, Hashable {
    let id: UUID
    var title: String
    var subtitle: String?
    var icon: String
    var parentId: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        icon: String = "folder",
        parentId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.parentId = parentId
    }
}

struct LifeDetailItem: Identifiable, Hashable {
    let id: UUID
    var categoryId: UUID
    var title: String
    var note: String?

    init(id: UUID = UUID(), categoryId: UUID, title: String, note: String? = nil) {
        self.id = id
        self.categoryId = categoryId
        self.title = title
        self.note = note
    }
}

enum LifeAddSheetMode: Equatable {
    case category(parentId: UUID?)
    case detailItem(categoryId: UUID)
}

enum LifeCategoryPanelIntent: Equatable {
    case add(parentId: UUID?)
    case edit(LifeCategory)
}

private enum LifeCategoryIconCatalog {
    static let options = [
        "folder", "tag", "star", "heart", "bookmark",
        "cart", "bag", "gift", "cup.and.saucer", "fork.knife",
        "tshirt", "house", "car", "airplane", "bicycle",
        "book", "camera", "music.note", "leaf", "frying.pan"
    ]
}

// MARK: - Root

struct DashboardView: View {
    @Binding var showingCreateCategory: Bool
    @StateObject private var viewModel = DashboardViewModel()
    @State private var editingCategory: LifeCategory?

    init(showingCreateCategory: Binding<Bool> = .constant(false)) {
        _showingCreateCategory = showingCreateCategory
    }

    private var isPanelVisible: Bool {
        showingCreateCategory || editingCategory != nil
    }

    private func dismissPanel() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            showingCreateCategory = false
            editingCategory = nil
        }
    }

    private func lifePanelMaxHeight(screenHeight: CGFloat) -> CGFloat {
        guard screenHeight.isFinite, screenHeight > 0 else { return 300 }
        return max(1, min(screenHeight * 0.58, 520))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LifeCategoryListScreen(
                    viewModel: viewModel,
                    parentCategory: nil,
                    onEditCategory: { category in
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                            showingCreateCategory = false
                            editingCategory = category
                        }
                    }
                )

                ZStack(alignment: .bottom) {
                    Color.black
                        .opacity(isPanelVisible ? 0.34 : 0)
                        .ignoresSafeArea()
                        .onTapGesture {
                            if isPanelVisible { dismissPanel() }
                        }

                    Group {
                        if let editingCategory {
                            AddLifeCategoryPanel(
                                viewModel: viewModel,
                                panelExpanded: isPanelVisible,
                                intent: .edit(editingCategory),
                                onDismiss: dismissPanel
                            )
                        } else if case .category(let parentId) = viewModel.addSheetMode {
                            AddLifeCategoryPanel(
                                viewModel: viewModel,
                                panelExpanded: isPanelVisible,
                                intent: .add(parentId: parentId),
                                onDismiss: dismissPanel
                            )
                        } else if case .detailItem(let categoryId) = viewModel.addSheetMode {
                            AddLifeDetailPanel(
                                viewModel: viewModel,
                                panelExpanded: isPanelVisible,
                                categoryId: categoryId,
                                onDismiss: dismissPanel
                            )
                        }
                    }
                    .accessibilityHidden(!isPanelVisible)
                    .frame(maxWidth: .infinity, maxHeight: lifePanelMaxHeight(screenHeight: geometry.size.height))
                    .clipShape(lifePanelClipShape)
                    .shadow(color: Color.black.opacity(isPanelVisible ? 0.12 : 0), radius: 12, y: -4)
                    .padding(.bottom, 6)
                    .offset(y: isPanelVisible ? 0 : geometry.size.height)
                    .opacity(isPanelVisible ? 1 : 0)
                }
                .allowsHitTesting(isPanelVisible)
                .zIndex(2)
            }
        }
        .onAppear {
            viewModel.registerListScreen(parentId: nil)
        }
    }

    private var lifePanelClipShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: 16,
            bottomTrailingRadius: 16,
            topTrailingRadius: 20,
            style: .continuous
        )
    }
}

// MARK: - Category List（根级与子级共用）

private struct LifeCategoryListScreen: View {
    @ObservedObject var viewModel: DashboardViewModel
    let parentCategory: LifeCategory?
    var onEditCategory: (LifeCategory) -> Void = { _ in }

    private var categories: [LifeCategory] {
        viewModel.subcategories(of: parentCategory?.id)
    }

    var body: some View {
        ZStack {
            lifePageBackground

            List {
                if categories.isEmpty {
                    Text("暂无分类，点击底部 + 添加")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 22)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(categories) { category in
                        ZStack {
                            LifeCategoryRow(category: category)

                            NavigationLink {
                                lifeCategoryDestination(for: category)
                            } label: {
                                Color.clear
                            }
                            .opacity(0.02)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                onEditCategory(category)
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(Color(hex: "#2d6a4f"))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    viewModel.deleteCategory(id: category.id)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 100)
            }
        }
        .safeAreaInset(edge: .top) {
            if parentCategory == nil {
                VStack(spacing: 0) {
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
        }
        .navigationTitle(parentCategory?.title ?? "")
        .navigationBarTitleDisplayMode(parentCategory == nil ? .inline : .large)
        .onAppear {
            viewModel.registerListScreen(parentId: parentCategory?.id)
        }
    }

    @ViewBuilder
    private func lifeCategoryDestination(for category: LifeCategory) -> some View {
        if viewModel.hasSubcategories(category.id) {
            LifeCategoryListScreen(
                viewModel: viewModel,
                parentCategory: category,
                onEditCategory: onEditCategory
            )
        } else {
            LifeCategoryDetailView(
                viewModel: viewModel,
                category: category
            )
        }
    }
}

private struct LifeCategoryRow: View {
    let category: LifeCategory

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 16) {
                Image(systemName: category.icon)
                    .font(.title2.weight(.semibold))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.title2.weight(.bold))
                    if let subtitle = category.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .foregroundColor(Color(hex: "#2B5748"))
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Detail（叶子分类：小卡片布局，对齐待办页）

private struct LifeCategoryDetailView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let category: LifeCategory

    private var items: [LifeDetailItem] {
        viewModel.items(in: category.id)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                lifePageBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        HStack {
                            Spacer()
                            Text("Mindflow")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .opacity(0)
                            Spacer()
                        }
                        .frame(height: 0)

                        detailCard(width: geometry.size.width)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.registerDetailScreen(categoryId: category.id)
        }
    }

    private func cardWidth(for screenWidth: CGFloat) -> CGFloat {
        guard screenWidth.isFinite, screenWidth > 0 else { return 0 }
        return max(0, screenWidth - 40)
    }

    private func cardHeight(for screenWidth: CGFloat) -> CGFloat {
        let width = cardWidth(for: screenWidth)
        let base = max(1, width + 120)
        let rows = max(items.count, 1)
        return max(base, CGFloat(rows) * 76 + 48)
    }

    private func detailCard(width: CGFloat) -> some View {
        let cardW = cardWidth(for: width)
        let cardH = cardHeight(for: width)

        return VStack(alignment: .leading, spacing: 0) {
            List {
                if items.isEmpty {
                    Text("暂无内容，点击底部 + 添加")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(items) { item in
                        LifeDetailCardView(item: item)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteDetailItem(id: item.id)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 1)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(width: cardW, height: cardH)
        .todoPanelCardChrome()
        .padding(.horizontal, 20)
        .frame(width: max(0, width))
    }
}

private struct LifeDetailCardView: View {
    let item: LifeDetailItem

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#2B5748"))
        }
        .padding(.vertical, 16)
        .padding(.leading, 16)
        .padding(.trailing, 20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(hex: "#1b4332").opacity(0.22), radius: 4, x: 0, y: 2)
    }
}

private var lifePageBackground: some View {
    LinearGradient(
        colors: [Color.white, Color(hex: "#d8f3dc")],
        startPoint: .top,
        endPoint: .bottom
    )
    .ignoresSafeArea()
}

// MARK: - ViewModel

@MainActor
class DashboardViewModel: ObservableObject {
    @Published private(set) var categories: [LifeCategory] = []
    @Published private(set) var detailItems: [LifeDetailItem] = []
    @Published private(set) var addSheetMode: LifeAddSheetMode = .category(parentId: nil)

    init() {
        loadSampleData()
    }

    func registerListScreen(parentId: UUID?) {
        addSheetMode = .category(parentId: parentId)
    }

    func registerDetailScreen(categoryId: UUID) {
        addSheetMode = .detailItem(categoryId: categoryId)
    }

    func category(withId id: UUID) -> LifeCategory? {
        categories.first { $0.id == id }
    }

    func subcategories(of parentId: UUID?) -> [LifeCategory] {
        categories.filter { $0.parentId == parentId }
    }

    func hasSubcategories(_ categoryId: UUID) -> Bool {
        categories.contains { $0.parentId == categoryId }
    }

    func items(in categoryId: UUID) -> [LifeDetailItem] {
        detailItems.filter { $0.categoryId == categoryId }
    }

    func addCategory(title: String, subtitle: String?, icon: String, parentId: UUID?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let subtitleTrimmed = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        categories.append(
            LifeCategory(
                title: trimmed,
                subtitle: (subtitleTrimmed?.isEmpty == false) ? subtitleTrimmed : nil,
                icon: icon,
                parentId: parentId
            )
        )
    }

    func updateCategory(id: UUID, title: String, subtitle: String?, icon: String) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let subtitleTrimmed = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        categories[index].title = trimmed
        categories[index].subtitle = (subtitleTrimmed?.isEmpty == false) ? subtitleTrimmed : nil
        categories[index].icon = icon
    }

    func deleteCategory(id: UUID) {
        let childIds = categories.filter { $0.parentId == id }.map(\.id)
        for childId in childIds {
            deleteCategory(id: childId)
        }
        detailItems.removeAll { $0.categoryId == id }
        categories.removeAll { $0.id == id }
    }

    func addDetailItem(title: String, note: String?, categoryId: UUID) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let noteTrimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        detailItems.append(
            LifeDetailItem(
                categoryId: categoryId,
                title: trimmed,
                note: (noteTrimmed?.isEmpty == false) ? noteTrimmed : nil
            )
        )
    }

    func deleteDetailItem(id: UUID) {
        detailItems.removeAll { $0.id == id }
    }

    private func loadSampleData() {
        let clothing = LifeCategory(title: "衣", subtitle: "穿搭与衣物", icon: "tshirt")
        let food = LifeCategory(title: "食", subtitle: "饮食与食材", icon: "fork.knife")
        let homeCook = LifeCategory(title: "家常", subtitle: "在家做饭", icon: "frying.pan", parentId: food.id)
        let diningOut = LifeCategory(title: "外食", subtitle: "餐厅与外卖", icon: "cup.and.saucer", parentId: food.id)
        let housing = LifeCategory(title: "住", subtitle: "居家与空间", icon: "house")
        let travel = LifeCategory(title: "行", subtitle: "出行与交通", icon: "car")

        categories = [clothing, food, homeCook, diningOut, housing, travel]

        detailItems = [
            LifeDetailItem(categoryId: clothing.id, title: "春季通勤穿搭", note: "薄外套 + 休闲裤"),
            LifeDetailItem(categoryId: homeCook.id, title: "本周买菜清单", note: "蔬菜、蛋白、水果"),
            LifeDetailItem(categoryId: diningOut.id, title: "周末探店", note: "日料 / 轻食"),
            LifeDetailItem(categoryId: housing.id, title: "客厅收纳整理"),
            LifeDetailItem(categoryId: travel.id, title: "周末骑行计划", note: "滨河路线 15km")
        ]
    }
}

// MARK: - 新建 / 编辑分类（底部面板，对齐待办）

private struct AddLifeCategoryPanel: View {
    @ObservedObject var viewModel: DashboardViewModel
    var panelExpanded: Bool
    let intent: LifeCategoryPanelIntent
    let onDismiss: () -> Void

    @State private var titleText = ""
    @State private var subtitleText = ""
    @State private var selectedIcon = LifeCategoryIconCatalog.options[0]
    @State private var allowTitleKeyboard = true
    @FocusState private var isSubtitleFieldFocused: Bool

    private var isEditing: Bool {
        if case .edit = intent { return true }
        return false
    }

    private var panelTitle: String {
        isEditing ? "编辑分类" : "新建分类"
    }

    private var submitTitle: String {
        isEditing ? "保存" : "创建"
    }

    private var inputFieldChrome: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(MindFlowFormSheetStyle.accent, lineWidth: 1.5)
    }

    private var sheetDragHandle: some View {
        Capsule()
            .fill(Color(hex: "#C7C7CC"))
            .frame(width: 36, height: 4)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetDragHandle

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(panelTitle)
                            .font(.headline)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                        MindFlowFormTitleTextField(
                            text: $titleText,
                            placeholder: "分类名称",
                            wantsKeyboard: panelExpanded && allowTitleKeyboard && !isSubtitleFieldFocused
                        )
                        .frame(maxWidth: .infinity, minHeight: MindFlowFormSheetStyle.fieldContentMinHeight, alignment: .leading)
                        .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
                        .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
                        .background(inputFieldChrome)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("副标题")
                            .font(.headline)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                        TextField("简要描述（选填）", text: $subtitleText)
                            .font(MindFlowFormSheetStyle.fieldFont)
                            .lineLimit(1)
                            .focused($isSubtitleFieldFocused)
                            .frame(maxWidth: .infinity, minHeight: MindFlowFormSheetStyle.fieldContentMinHeight, alignment: .leading)
                            .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
                            .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
                            .background(inputFieldChrome)
                    }

                    iconPickerSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)

            Button(action: submit) {
                Text(submitTitle)
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
            .disabled(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .background(Color.white)
        .onAppear {
            applyIntent(intent)
        }
        .onChange(of: panelExpanded) { _, open in
            if open {
                applyIntent(intent)
            } else {
                resetForm()
            }
        }
        .onChange(of: intent) { _, newIntent in
            applyIntent(newIntent)
        }
    }

    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("图标")
                .font(.headline)
                .foregroundStyle(MindFlowFormSheetStyle.accent)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LifeCategoryIconCatalog.options, id: \.self) { iconName in
                        let isSelected = selectedIcon == iconName
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedIcon = iconName
                            }
                        } label: {
                            Image(systemName: iconName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(isSelected ? MindFlowFormSheetStyle.accent : Color.secondary)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(isSelected ? MindFlowFormSheetStyle.accentFill : Color.clear)
                                )
                                .overlay(
                                    Circle()
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
        }
        .accessibilityLabel("分类图标")
    }

    private func applyIntent(_ intent: LifeCategoryPanelIntent) {
        switch intent {
        case .add:
            resetForm()
        case .edit(let category):
            titleText = category.title
            subtitleText = category.subtitle ?? ""
            selectedIcon = category.icon
            allowTitleKeyboard = true
        }
    }

    private func resetForm() {
        titleText = ""
        subtitleText = ""
        selectedIcon = LifeCategoryIconCatalog.options[0]
        allowTitleKeyboard = true
        isSubtitleFieldFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func submit() {
        let title = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let subtitle = subtitleText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch intent {
        case .add(let parentId):
            viewModel.addCategory(
                title: title,
                subtitle: subtitle.isEmpty ? nil : subtitle,
                icon: selectedIcon,
                parentId: parentId
            )
        case .edit(let category):
            viewModel.updateCategory(
                id: category.id,
                title: title,
                subtitle: subtitle.isEmpty ? nil : subtitle,
                icon: selectedIcon
            )
        }

        resetForm()
        onDismiss()
    }
}

// MARK: - 新建详情记录（底部面板，对齐待办）

private struct AddLifeDetailPanel: View {
    @ObservedObject var viewModel: DashboardViewModel
    var panelExpanded: Bool
    let categoryId: UUID
    let onDismiss: () -> Void

    @State private var titleText = ""
    @State private var noteText = ""
    @State private var allowTitleKeyboard = true
    @FocusState private var isNoteFieldFocused: Bool

    private var inputFieldChrome: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(MindFlowFormSheetStyle.accent, lineWidth: 1.5)
    }

    private var sheetDragHandle: some View {
        Capsule()
            .fill(Color(hex: "#C7C7CC"))
            .frame(width: 36, height: 4)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetDragHandle

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("新建记录")
                            .font(.headline)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                        MindFlowFormTitleTextField(
                            text: $titleText,
                            placeholder: "标题",
                            wantsKeyboard: panelExpanded && allowTitleKeyboard && !isNoteFieldFocused
                        )
                        .frame(maxWidth: .infinity, minHeight: MindFlowFormSheetStyle.fieldContentMinHeight, alignment: .leading)
                        .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
                        .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
                        .background(inputFieldChrome)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注")
                            .font(.headline)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                        TextField("别忘了...", text: $noteText)
                            .font(MindFlowFormSheetStyle.fieldFont)
                            .lineLimit(1)
                            .focused($isNoteFieldFocused)
                            .frame(maxWidth: .infinity, minHeight: MindFlowFormSheetStyle.fieldContentMinHeight, alignment: .leading)
                            .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
                            .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
                            .background(inputFieldChrome)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)

            Button(action: submit) {
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
            .disabled(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .background(Color.white)
        .onChange(of: panelExpanded) { _, open in
            if !open {
                titleText = ""
                noteText = ""
                allowTitleKeyboard = true
                isNoteFieldFocused = false
            }
        }
    }

    private func submit() {
        let title = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        viewModel.addDetailItem(
            title: title,
            note: noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : noteText,
            categoryId: categoryId
        )
        titleText = ""
        noteText = ""
        onDismiss()
    }
}

#Preview {
    NavigationView {
        DashboardView()
    }
}
