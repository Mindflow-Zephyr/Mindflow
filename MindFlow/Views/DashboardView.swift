import SwiftUI
import Combine
import UIKit

// MARK: - Models

struct LifeCategory: Identifiable, Hashable {
    let id: UUID
    var title: String
    var icon: String
    var accentHex: String
    var parentId: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        icon: String = "folder",
        accentHex: String = LifeCategoryColorCatalog.defaultHex,
        parentId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.accentHex = accentHex
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

struct WardrobeItem: Identifiable, Hashable {
    let id: UUID
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

    init(
        id: UUID = UUID(),
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
        wearCount: Int = 0
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
    }
}

enum LifeAddSheetMode: Equatable {
    case category(parentId: UUID?)
    case detailItem(categoryId: UUID)
    case wardrobeItem(categoryId: UUID)
}

enum WardrobePanelIntent: Equatable {
    case add(categoryId: UUID, wardrobeGroup: String?, wardrobeType: String?)
    case edit(WardrobeItem)
}

enum LifeCategoryPanelIntent: Equatable {
    case add(parentId: UUID?)
    case edit(LifeCategory)
}

private enum WardrobeCategoryCatalog {
    static let groups: [(group: String, types: [String])] = [
        ("上装", ["T恤", "衬衫", "POLO", "毛衣", "外套"]),
        ("下装", ["牛仔裤", "西裤", "短裤", "运动裤"]),
        ("鞋子", ["运动鞋", "皮鞋", "乐福鞋", "凉鞋"]),
        ("配饰", ["手表", "帽子", "眼镜", "包"])
    ]

    static var allGroups: [String] {
        groups.map(\.group)
    }

    static func types(in group: String) -> [String] {
        groups.first { $0.group == group }?.types ?? []
    }
}

private enum WardrobeFilterChipMetrics {
    static let width: CGFloat = 76
    static let height: CGFloat = 36
}

private enum LifePageTypography {
    static let categorySubtitle = Font.title3.bold()

    static var categorySubtitleMinHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .title3).lineHeight.rounded(.up) + 4
    }
}

private enum WardrobeDetailChipMetrics {
    static let width: CGFloat = 120
    static let height: CGFloat = 80
}

private enum WardrobeRowMetrics {
    static let verticalPadding: CGFloat = 13
    static let listRowHeight: CGFloat = 78
}

enum OutfitSlot: String, CaseIterable, Identifiable {
    case top = "上装"
    case bottom = "下装"
    case shoes = "鞋子"
    case hat = "帽子"
    case accessory = "配饰"

    var id: String { rawValue }
}

struct OutfitPlan: Equatable {
    var topItemId: UUID?
    var bottomItemId: UUID?
    var shoesItemId: UUID?
    var hatItemId: UUID?
    var accessoryItemId: UUID?

    func itemId(for slot: OutfitSlot) -> UUID? {
        switch slot {
        case .top: topItemId
        case .bottom: bottomItemId
        case .shoes: shoesItemId
        case .hat: hatItemId
        case .accessory: accessoryItemId
        }
    }

    mutating func setItem(_ id: UUID?, for slot: OutfitSlot) {
        switch slot {
        case .top: topItemId = id
        case .bottom: bottomItemId = id
        case .shoes: shoesItemId = id
        case .hat: hatItemId = id
        case .accessory: accessoryItemId = id
        }
    }
}

private enum LifeCategoryIconCatalog {
    static let options = [
        "folder", "tag", "star", "heart", "bookmark",
        "cart", "bag", "gift", "cup.and.saucer", "fork.knife",
        "tshirt", "house", "car", "airplane", "bicycle",
        "book", "camera", "music.note", "leaf", "frying.pan"
    ]
}

private enum LifeCategoryColorCatalog {
    static let defaultHex = "#2B5748"

    static let options: [(name: String, hex: String)] = [
        ("深绿", "#2B5748"),
        ("墨绿", "#2d6a4f"),
        ("森林", "#1b4332"),
        ("青绿", "#40916c"),
        ("红色", "#D64545"),
        ("蓝色", "#2563eb"),
        ("紫色", "#7c3aed"),
        ("橙色", "#ea580c"),
        ("白色", "#ffffff"),
        ("黑色", "#111827"),
        ("红", "#FF3B30"),
        ("橙", "#FF9500"),
        ("黄", "#FFCC00"),
        ("绿", "#34C759"),
        ("青", "#32ADE6"),
        ("蓝", "#007AFF"),
        ("紫", "#AF52DE")
    ]

    static func name(for hex: String) -> String {
        options.first { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }?.name ?? "自定义"
    }
}

// MARK: - Root

struct DashboardView: View {
    @Binding var showingCreateCategory: Bool
    @StateObject private var viewModel = DashboardViewModel()
    @State private var navigationPath = NavigationPath()

    init(showingCreateCategory: Binding<Bool> = .constant(false)) {
        _showingCreateCategory = showingCreateCategory
    }

    private var isCategoryPanelVisible: Bool {
        viewModel.categoryPanelIntent != nil
    }

    private var isDetailPanelVisible: Bool {
        viewModel.detailPanelCategoryId != nil
    }

    private var isWardrobePanelVisible: Bool {
        viewModel.wardrobePanelIntent != nil
    }

    private var isPanelVisible: Bool {
        isCategoryPanelVisible || isDetailPanelVisible || isWardrobePanelVisible
    }

    private func dismissPanel() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            showingCreateCategory = false
            viewModel.closeAllPanels()
        }
    }

    private func lifePanelMaxHeight(screenHeight: CGFloat) -> CGFloat {
        guard screenHeight.isFinite, screenHeight > 0 else { return 300 }
        return max(1, min(screenHeight * 0.58, 520))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                NavigationStack(path: $navigationPath) {
                    LifeCategoryListScreen(
                        viewModel: viewModel,
                        parentCategory: nil,
                        navigationPath: $navigationPath
                    )
                    .navigationDestination(for: LifeCategory.self) { category in
                        lifeCategoryDestination(for: category)
                    }
                }

                lifePanelOverlay(screenHeight: geometry.size.height)
            }
        }
        .onAppear {
            viewModel.registerListScreen(parentId: nil)
        }
        .onChange(of: showingCreateCategory) { _, show in
            guard show else { return }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                viewModel.presentPanelForAddMode()
            }
        }
    }

    @ViewBuilder
    private func lifePanelOverlay(screenHeight: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(isPanelVisible ? 0.34 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    if isPanelVisible { dismissPanel() }
                }

            AddLifeCategoryPanel(
                viewModel: viewModel,
                panelExpanded: isCategoryPanelVisible,
                intent: viewModel.categoryPanelIntent ?? .add(parentId: nil),
                onDismiss: dismissPanel
            )
            .accessibilityHidden(!isCategoryPanelVisible)
            .frame(maxWidth: .infinity, maxHeight: lifePanelMaxHeight(screenHeight: screenHeight))
            .clipShape(lifePanelClipShape)
            .shadow(color: Color.black.opacity(isCategoryPanelVisible ? 0.12 : 0), radius: 12, y: -4)
            .padding(.bottom, 6)
            .offset(y: isCategoryPanelVisible ? 0 : screenHeight)
            .opacity(isCategoryPanelVisible ? 1 : 0)

            AddLifeDetailPanel(
                viewModel: viewModel,
                panelExpanded: isDetailPanelVisible,
                categoryId: viewModel.detailPanelCategoryId ?? UUID(),
                onDismiss: dismissPanel
            )
            .accessibilityHidden(!isDetailPanelVisible)
            .frame(maxWidth: .infinity, maxHeight: lifePanelMaxHeight(screenHeight: screenHeight))
            .clipShape(lifePanelClipShape)
            .shadow(color: Color.black.opacity(isDetailPanelVisible ? 0.12 : 0), radius: 12, y: -4)
            .padding(.bottom, 6)
            .offset(y: isDetailPanelVisible ? 0 : screenHeight)
            .opacity(isDetailPanelVisible ? 1 : 0)

            AddLifeWardrobePanel(
                viewModel: viewModel,
                panelExpanded: isWardrobePanelVisible,
                intent: viewModel.wardrobePanelIntent ?? .add(categoryId: UUID(), wardrobeGroup: nil, wardrobeType: nil),
                onDismiss: dismissPanel
            )
            .accessibilityHidden(!isWardrobePanelVisible)
            .frame(maxWidth: .infinity, maxHeight: lifePanelMaxHeight(screenHeight: screenHeight))
            .clipShape(lifePanelClipShape)
            .shadow(color: Color.black.opacity(isWardrobePanelVisible ? 0.12 : 0), radius: 12, y: -4)
            .padding(.bottom, 6)
            .offset(y: isWardrobePanelVisible ? 0 : screenHeight)
            .opacity(isWardrobePanelVisible ? 1 : 0)
        }
        .allowsHitTesting(isPanelVisible)
        .zIndex(2)
    }

    @ViewBuilder
    private func lifeCategoryDestination(for category: LifeCategory) -> some View {
        if viewModel.hasSubcategories(category.id) {
            LifeCategoryListScreen(
                viewModel: viewModel,
                parentCategory: category,
                navigationPath: $navigationPath
            )
        } else {
            LifeCategoryDetailView(
                viewModel: viewModel,
                category: category
            )
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
    @Binding var navigationPath: NavigationPath

    @State private var categorySearchText = ""

    private var categories: [LifeCategory] {
        viewModel.subcategories(of: parentCategory?.id)
    }

    private var categorySearchResults: [LifeCategory] {
        viewModel.searchCategories(matching: categorySearchText)
    }

    private var isRootScreen: Bool {
        parentCategory == nil
    }

    var body: some View {
        ZStack {
            lifePageBackground

            List {
                if let parentCategory {
                    Text(parentCategory.title)
                        .font(LifePageTypography.categorySubtitle)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 8, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                if categories.isEmpty {
                    Text("暂无分类，点击底部 + 添加")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 22)
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(categories) { category in
                        LifeCategoryCardView(
                            viewModel: viewModel,
                            category: category,
                            onNavigate: { navigationPath.append(category) },
                            onEdit: { viewModel.presentCategoryEdit(category) }
                        )
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 100)
            }
        }
        .safeAreaInset(edge: .top, spacing: 14) {
            if isRootScreen {
                LifeCategorySearchBar(
                    text: $categorySearchText,
                    results: categorySearchResults,
                    onSelect: navigateToCategory
                )
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)
            }
        }
        .modifier(LifePageHeaderStyle())
        .onAppear {
            viewModel.registerListScreen(parentId: parentCategory?.id)
        }
    }

    private func navigateToCategory(_ category: LifeCategory) {
        let path = viewModel.pathToCategory(category.id)
        navigationPath = NavigationPath()
        for item in path {
            navigationPath.append(item)
        }
        categorySearchText = ""
    }
}

private struct LifeCategorySearchBar: View {
    @Binding var text: String
    let results: [LifeCategory]
    let onSelect: (LifeCategory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(MindFlowFormSheetStyle.accent)

                TextField("搜索分类", text: $text)
                    .font(MindFlowFormSheetStyle.fieldFont)
                    .submitLabel(.search)
                    .onSubmit {
                        if let first = results.first {
                            onSelect(first)
                        }
                    }
            }
            .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
            .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MindFlowFormSheetStyle.accent, lineWidth: 1.5)
            )

            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if results.isEmpty {
                    Text("未找到相关分类")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                } else {
                    VStack(spacing: 8) {
                        ForEach(results) { category in
                            Button {
                                onSelect(category)
                            } label: {
                                LifeCategoryRow(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct LifeCategoryCardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let category: LifeCategory
    let onNavigate: () -> Void
    let onEdit: () -> Void

    private var rowSlideOutOffsetX: CGFloat {
        guard viewModel.slidingOutCategoryIds.contains(category.id) else { return 0 }
        let sign = viewModel.categorySlideOutSignById[category.id] ?? -1
        return sign * DashboardViewModel.rowSlideOutOffset
    }

    var body: some View {
        LifeCategoryRow(category: category)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .gesture(
                LongPressGesture(minimumDuration: 0.2)
                    .onEnded { _ in
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                            onEdit()
                        }
                    }
                    .exclusively(before: TapGesture().onEnded {
                        onNavigate()
                    })
            )
            .offset(x: rowSlideOutOffsetX)
            .allowsHitTesting(!viewModel.slidingOutCategoryIds.contains(category.id))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    viewModel.deleteCategoryFromSwipe(id: category.id)
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("删除")
                .tint(Color.red)
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

                Text(category.title)
                    .font(.title2.weight(.bold))
            }
            .foregroundColor(Color(hex: category.accentHex))
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
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

    @State private var selectedWardrobeItem: WardrobeItem?
    @State private var selectedWardrobeGroup: String? = "上装"
    @State private var selectedWardrobeType: String? = "T恤"

    private var items: [LifeDetailItem] {
        viewModel.items(in: category.id)
    }

    private var wardrobeItems: [WardrobeItem] {
        viewModel.wardrobeItems(in: category.id)
    }

    private var filteredWardrobeItems: [WardrobeItem] {
        var result = wardrobeItems
        if let group = selectedWardrobeGroup {
            result = result.filter { $0.wardrobeGroup == group }
        }
        if let type = selectedWardrobeType {
            result = result.filter { $0.wardrobeType == type }
        }
        return result
    }

    private var isOutfitCategory: Bool {
        category.title == "穿搭"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                lifePageBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(category.title)
                            .font(LifePageTypography.categorySubtitle)
                            .padding(.horizontal, 20)

                        if isOutfitCategory {
                            wardrobeLibraryCard(width: geometry.size.width)
                            outfitPlanCard(width: geometry.size.width)
                        } else {
                            detailCard(width: geometry.size.width)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
        }
        .modifier(LifePageHeaderStyle())
        .navigationDestination(item: $selectedWardrobeItem) { item in
            WardrobeItemDetailView(viewModel: viewModel, itemId: item.id)
        }
        .onAppear {
            syncAddSheetRegistration()
        }
        .onChange(of: selectedWardrobeGroup) { _, _ in
            syncAddSheetRegistration()
        }
        .onChange(of: selectedWardrobeType) { _, _ in
            syncAddSheetRegistration()
        }
    }

    private func syncAddSheetRegistration() {
        viewModel.registerDetailScreen(
            categoryId: category.id,
            wardrobeGroup: isOutfitCategory ? selectedWardrobeGroup : nil,
            wardrobeType: isOutfitCategory ? selectedWardrobeType : nil
        )
    }

    private func wardrobeLibraryCard(width: CGFloat) -> some View {
        let items = filteredWardrobeItems
        let cardW = cardWidth(for: width)
        let subtypes = selectedWardrobeGroup.map { WardrobeCategoryCatalog.types(in: $0) } ?? []
        let useGroupedSections = selectedWardrobeGroup == nil && selectedWardrobeType == nil
        let groupedCount = useGroupedSections
            ? WardrobeCategoryCatalog.allGroups.reduce(0) { partial, group in
                partial + (items.contains { $0.wardrobeGroup == group } ? 1 : 0)
            }
            : 0
        let rowCount = max(items.count, 1)
        let filterHeight: CGFloat = subtypes.isEmpty ? 52 : 96
        let sectionHeaderHeight = CGFloat(groupedCount * 36)
        let cardH = max(260, CGFloat(rowCount) * WardrobeRowMetrics.listRowHeight + filterHeight + sectionHeaderHeight + 72)

        return VStack(alignment: .leading, spacing: 0) {
            Text("衣物库")
                .font(.headline)
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WardrobeCategoryCatalog.allGroups, id: \.self) { group in
                            WardrobeFilterChip(
                                title: group,
                                isSelected: selectedWardrobeGroup == group
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedWardrobeGroup == group {
                                        selectedWardrobeGroup = nil
                                        selectedWardrobeType = nil
                                    } else {
                                        selectedWardrobeGroup = group
                                        selectedWardrobeType = nil
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if !subtypes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(subtypes, id: \.self) { type in
                                WardrobeFilterChip(
                                    title: type,
                                    isSelected: selectedWardrobeType == type
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedWardrobeType = selectedWardrobeType == type ? nil : type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 12)

            List {
                if items.isEmpty {
                    Text(emptyWardrobeMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
                        .listRowBackground(Color.clear)
                } else if useGroupedSections {
                    ForEach(WardrobeCategoryCatalog.allGroups, id: \.self) { group in
                        let itemsInGroup = items.filter { $0.wardrobeGroup == group }
                        if !itemsInGroup.isEmpty {
                            Section {
                                ForEach(itemsInGroup) { item in
                                    wardrobeItemButton(item)
                                }
                            } header: {
                                Text(group)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                                    .textCase(nil)
                            }
                        }
                    }
                } else {
                    ForEach(items) { item in
                        wardrobeItemButton(item)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 1)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: cardW, height: cardH)
        .todoPanelCardChrome()
        .padding(.horizontal, 20)
        .frame(width: max(0, width))
    }

    private var emptyWardrobeMessage: String {
        if selectedWardrobeType != nil {
            return "该品种暂无衣物"
        }
        if selectedWardrobeGroup != nil {
            return "该分类暂无衣物"
        }
        return "暂无衣物，点击底部 + 添加"
    }

    private func wardrobeItemButton(_ item: WardrobeItem) -> some View {
        HStack(spacing: 0) {
            Button {
                viewModel.assignToOutfitPlan(item)
            } label: {
                WardrobeItemRowContent(item: item)
            }
            .buttonStyle(.plain)

            Button {
                selectedWardrobeItem = item
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#2B5748"))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, WardrobeRowMetrics.verticalPadding)
        .padding(.leading, MindFlowListRowCardStyle.leadingPadding)
        .padding(.trailing, 8)
        .mindFlowListRowCardChrome()
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .listRowBackground(Color.clear)
    }

    private func outfitPlanCard(width: CGFloat) -> some View {
        let cardW = cardWidth(for: width)
        let rowHeight: CGFloat = 44
        let cardH = 20 + 12 + CGFloat(OutfitSlot.allCases.count) * rowHeight + 16

        return VStack(alignment: .leading, spacing: 0) {
            Text("今日穿搭")
                .font(.headline)
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(Array(OutfitSlot.allCases.enumerated()), id: \.element.id) { index, slot in
                    if index > 0 {
                        Divider().padding(.leading, 16)
                    }
                    OutfitPlanSlotRow(
                        slot: slot,
                        item: viewModel.outfitItem(for: slot, categoryId: category.id)
                    )
                    .frame(minHeight: rowHeight)
                }
            }
            .padding(.bottom, 8)
        }
        .frame(width: cardW, height: cardH)
        .todoPanelCardChrome()
        .padding(.horizontal, 20)
        .frame(width: max(0, width))
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
                        LifeDetailItemCardView(
                            viewModel: viewModel,
                            item: item
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
                        .listRowBackground(Color.clear)
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

private struct WardrobeFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : MindFlowFormSheetStyle.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(
                    width: WardrobeFilterChipMetrics.width,
                    height: WardrobeFilterChipMetrics.height
                )
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? MindFlowFormSheetStyle.accentAction : Color.clear)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            isSelected ? MindFlowFormSheetStyle.accentAction : MindFlowFormSheetStyle.fieldBorder,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct WardrobeItemRowContent: View {
    let item: WardrobeItem

    private var subtitleText: String {
        let price = String(format: "¥%.0f", item.purchasePrice)
        let wear = "穿着\(item.wearCount)次"
        if item.color.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(price) · \(wear)"
        }
        return "\(price) · \(item.color) · \(wear)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(item.brand) · \(item.name)")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(subtitleText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct OutfitPlanSlotRow: View {
    let slot: OutfitSlot
    let item: WardrobeItem?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(slot.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .frame(width: 44, alignment: .leading)

            if let item {
                Text("\(item.brand) · \(item.name)")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct WardrobeItemDetailView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let itemId: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    private var item: WardrobeItem? {
        viewModel.wardrobeItem(withId: itemId)
    }

    var body: some View {
        Group {
            if let item {
                ScrollView {
                    wardrobeItemDetailContent(for: item)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(lifePageBackground)
        .modifier(LifePageHeaderStyle())
        .alert("删除这件衣物？", isPresented: $showDeleteConfirmation) {
            Button("删除", role: .destructive) {
                viewModel.deleteWardrobeItem(id: itemId)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复。")
        }
        .onAppear {
            if let item {
                viewModel.registerDetailScreen(
                    categoryId: item.categoryId,
                    wardrobeGroup: item.wardrobeGroup,
                    wardrobeType: item.wardrobeType
                )
            }
        }
        .onChange(of: viewModel.wardrobeItems) { _, _ in
            if viewModel.wardrobeItem(withId: itemId) == nil {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private func wardrobeItemDetailContent(for item: WardrobeItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 10) {
                WardrobeDetailChip(
                    text: item.brand,
                    fontWeight: .bold
                )
                WardrobeDetailChip(
                    text: item.name,
                    fontWeight: .semibold,
                    usesFlexibleWidth: true
                )
            }
            .padding(.horizontal, 20)

            WardrobeSeasonCard(season: item.season)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                WardrobeDetailInfoRow(title: "品类", value: "\(item.wardrobeGroup) · \(item.wardrobeType)")
                wardrobeDetailDivider
                WardrobeDetailInfoRow(title: "颜色", value: item.color)
                wardrobeDetailDivider
                WardrobeDetailInfoRow(title: "面料", value: item.fabric)
                wardrobeDetailDivider
                WardrobeDetailInfoRow(title: "购买价格", value: formatPrice(item.purchasePrice))
                wardrobeDetailDivider
                WardrobeDetailInfoRow(title: "购买日期", value: formatDate(item.purchaseDate))
            }
            .padding(.vertical, 4)
            .frame(minHeight: LifePageTypography.categorySubtitleMinHeight + 48)
            .todoPanelCardChrome()
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                        viewModel.presentWardrobeEdit(item)
                    }
                } label: {
                    Text("编辑")
                        .font(.headline)
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MindFlowFormSheetStyle.accent, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    showDeleteConfirmation = true
                } label: {
                    Text("删除")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.red)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }

    private var wardrobeDetailDivider: some View {
        Divider().padding(.leading, 88)
    }

    private func formatPrice(_ price: Double) -> String {
        String(format: "¥%.0f", price)
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day())
    }
}

private struct WardrobeDetailChip: View {
    let text: String
    var fontWeight: Font.Weight = .bold
    var usesFlexibleWidth: Bool = false

    var body: some View {
        Text(text)
            .font(.title3.weight(fontWeight))
            .foregroundStyle(MindFlowFormSheetStyle.accent)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.65)
            .frame(
                width: usesFlexibleWidth ? nil : WardrobeDetailChipMetrics.width,
                height: WardrobeDetailChipMetrics.height
            )
            .frame(maxWidth: usesFlexibleWidth ? .infinity : nil)
            .todoPanelCardChrome()
    }
}

private struct WardrobeSeasonCard: View {
    let season: String

    private let seasons = ["春", "夏", "秋", "冬"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(seasons.enumerated()), id: \.offset) { index, label in
                if index > 0 {
                    WardrobeSeasonDashedDivider()
                }
                Text(label)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isActive(label) ? MindFlowFormSheetStyle.accent : Color.secondary.opacity(0.38))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: WardrobeDetailChipMetrics.height)
        .todoPanelCardChrome()
    }

    private func isActive(_ label: String) -> Bool {
        let normalized = season.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.contains("四季") {
            return true
        }
        return normalized.contains(label)
    }
}

private struct WardrobeSeasonDashedDivider: View {
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
            .padding(.vertical, 14)
    }
}

private struct WardrobeDetailInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct LifeDetailItemCardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let item: LifeDetailItem

    private var rowSlideOutOffsetX: CGFloat {
        guard viewModel.slidingOutDetailItemIds.contains(item.id) else { return 0 }
        let sign = viewModel.detailItemSlideOutSignById[item.id] ?? -1
        return sign * DashboardViewModel.rowSlideOutOffset
    }

    var body: some View {
        LifeDetailCardView(item: item)
            .offset(x: rowSlideOutOffsetX)
            .allowsHitTesting(!viewModel.slidingOutDetailItemIds.contains(item.id))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    viewModel.deleteDetailItemFromSwipe(id: item.id)
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("删除")
                .tint(Color.red)
            }
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
        .mindFlowListRowCardPadding()
        .mindFlowListRowCardChrome()
    }
}

private struct LifeMindflowTitle: View {
    var body: some View {
        Text("Mindflow")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
    }
}

private struct LifePageHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    LifeMindflowTitle()
                }
            }
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
    @Published private(set) var wardrobeItems: [WardrobeItem] = []
    @Published private(set) var outfitPlansByCategoryId: [UUID: OutfitPlan] = [:]
    @Published private(set) var addSheetMode: LifeAddSheetMode = .category(parentId: nil)
    @Published private(set) var categoryPanelIntent: LifeCategoryPanelIntent?
    @Published private(set) var detailPanelCategoryId: UUID?
    @Published private(set) var wardrobePanelIntent: WardrobePanelIntent?
    private(set) var wardrobeAddDefaultGroup: String?
    private(set) var wardrobeAddDefaultType: String?
    @Published private(set) var slidingOutCategoryIds: Set<UUID> = []
    @Published private(set) var categorySlideOutSignById: [UUID: CGFloat] = [:]
    @Published private(set) var slidingOutDetailItemIds: Set<UUID> = []
    @Published private(set) var detailItemSlideOutSignById: [UUID: CGFloat] = [:]

    static var rowSlideOutOffset: CGFloat { preferredScreenWidthForSlideOut() }

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

    static let rowSlideOutDuration: TimeInterval = 0.22
    static var rowSlideOutAnimation: Animation { .easeOut(duration: rowSlideOutDuration) }

    init() {
        loadSampleData()
    }

    func registerListScreen(parentId: UUID?) {
        addSheetMode = .category(parentId: parentId)
        wardrobeAddDefaultGroup = nil
        wardrobeAddDefaultType = nil
    }

    func registerDetailScreen(
        categoryId: UUID,
        wardrobeGroup: String? = nil,
        wardrobeType: String? = nil
    ) {
        if category(withId: categoryId)?.title == "穿搭" {
            addSheetMode = .wardrobeItem(categoryId: categoryId)
            wardrobeAddDefaultGroup = wardrobeGroup
            wardrobeAddDefaultType = wardrobeType
        } else {
            addSheetMode = .detailItem(categoryId: categoryId)
            wardrobeAddDefaultGroup = nil
            wardrobeAddDefaultType = nil
        }
    }

    func presentPanelForAddMode() {
        wardrobePanelIntent = nil
        switch addSheetMode {
        case .category(let parentId):
            detailPanelCategoryId = nil
            categoryPanelIntent = .add(parentId: parentId)
        case .detailItem(let categoryId):
            categoryPanelIntent = nil
            detailPanelCategoryId = categoryId
        case .wardrobeItem(let categoryId):
            categoryPanelIntent = nil
            detailPanelCategoryId = nil
            wardrobePanelIntent = .add(
                categoryId: categoryId,
                wardrobeGroup: wardrobeAddDefaultGroup,
                wardrobeType: wardrobeAddDefaultType
            )
        }
    }

    func presentWardrobeEdit(_ item: WardrobeItem) {
        categoryPanelIntent = nil
        detailPanelCategoryId = nil
        wardrobePanelIntent = .edit(item)
    }

    func presentCategoryEdit(_ category: LifeCategory) {
        detailPanelCategoryId = nil
        wardrobePanelIntent = nil
        categoryPanelIntent = .edit(category)
    }

    func closeAllPanels() {
        categoryPanelIntent = nil
        detailPanelCategoryId = nil
        wardrobePanelIntent = nil
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

    func wardrobeItems(in categoryId: UUID) -> [WardrobeItem] {
        wardrobeItems.filter { $0.categoryId == categoryId }
    }

    func wardrobeItem(withId id: UUID) -> WardrobeItem? {
        wardrobeItems.first { $0.id == id }
    }

    func outfitPlan(for categoryId: UUID) -> OutfitPlan {
        outfitPlansByCategoryId[categoryId] ?? OutfitPlan()
    }

    func outfitItem(for slot: OutfitSlot, categoryId: UUID) -> WardrobeItem? {
        guard let itemId = outfitPlan(for: categoryId).itemId(for: slot) else { return nil }
        return wardrobeItem(withId: itemId)
    }

    func outfitSlot(for item: WardrobeItem) -> OutfitSlot {
        if item.wardrobeType == "帽子" {
            return .hat
        }
        switch item.wardrobeGroup {
        case "上装": return .top
        case "下装": return .bottom
        case "鞋子": return .shoes
        case "配饰": return .accessory
        default: return .accessory
        }
    }

    func assignToOutfitPlan(_ item: WardrobeItem) {
        let slot = outfitSlot(for: item)
        var plan = outfitPlan(for: item.categoryId)
        plan.setItem(item.id, for: slot)
        outfitPlansByCategoryId[item.categoryId] = plan
        incrementWearCount(for: item.id)
    }

    private func incrementWearCount(for itemId: UUID) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == itemId }) else { return }
        wardrobeItems[index].wearCount += 1
    }

    func addWardrobeItem(
        categoryId: UUID,
        name: String,
        wardrobeGroup: String,
        wardrobeType: String,
        brand: String,
        color: String,
        fabric: String,
        season: String,
        purchasePrice: Double,
        purchaseDate: Date
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        wardrobeItems.append(
            WardrobeItem(
                categoryId: categoryId,
                name: trimmedName,
                wardrobeGroup: wardrobeGroup,
                wardrobeType: wardrobeType,
                brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
                color: color.trimmingCharacters(in: .whitespacesAndNewlines),
                fabric: fabric.trimmingCharacters(in: .whitespacesAndNewlines),
                season: season.trimmingCharacters(in: .whitespacesAndNewlines),
                purchasePrice: purchasePrice,
                purchaseDate: purchaseDate
            )
        )
    }

    func updateWardrobeItem(
        id: UUID,
        name: String,
        wardrobeGroup: String,
        wardrobeType: String,
        brand: String,
        color: String,
        fabric: String,
        season: String,
        purchasePrice: Double,
        purchaseDate: Date
    ) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        wardrobeItems[index].name = trimmedName
        wardrobeItems[index].wardrobeGroup = wardrobeGroup
        wardrobeItems[index].wardrobeType = wardrobeType
        wardrobeItems[index].brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        wardrobeItems[index].color = color.trimmingCharacters(in: .whitespacesAndNewlines)
        wardrobeItems[index].fabric = fabric.trimmingCharacters(in: .whitespacesAndNewlines)
        wardrobeItems[index].season = season.trimmingCharacters(in: .whitespacesAndNewlines)
        wardrobeItems[index].purchasePrice = purchasePrice
        wardrobeItems[index].purchaseDate = purchaseDate
    }

    func deleteWardrobeItem(id: UUID) {
        wardrobeItems.removeAll { $0.id == id }
        for (categoryId, var plan) in outfitPlansByCategoryId {
            var changed = false
            for slot in OutfitSlot.allCases {
                if plan.itemId(for: slot) == id {
                    plan.setItem(nil, for: slot)
                    changed = true
                }
            }
            if changed {
                outfitPlansByCategoryId[categoryId] = plan
            }
        }
    }

    func searchCategories(matching query: String) -> [LifeCategory] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        return categories
            .filter { $0.title.lowercased().contains(trimmed) }
            .sorted { lhs, rhs in
                if lhs.title.count != rhs.title.count {
                    return lhs.title.count < rhs.title.count
                }
                return lhs.title.localizedCompare(rhs.title) == .orderedAscending
            }
    }

    func pathToCategory(_ categoryId: UUID) -> [LifeCategory] {
        guard var current = categories.first(where: { $0.id == categoryId }) else { return [] }
        var path: [LifeCategory] = [current]
        while let parentId = current.parentId,
              let parent = categories.first(where: { $0.id == parentId }) {
            path.insert(parent, at: 0)
            current = parent
        }
        return path
    }

    func breadcrumb(for category: LifeCategory) -> String {
        pathToCategory(category.id).map(\.title).joined(separator: " › ")
    }

    func addCategory(title: String, icon: String, accentHex: String, parentId: UUID?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        categories.append(
            LifeCategory(
                title: trimmed,
                icon: icon,
                accentHex: accentHex,
                parentId: parentId
            )
        )
    }

    func updateCategory(id: UUID, title: String, icon: String, accentHex: String) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        categories[index].title = trimmed
        categories[index].icon = icon
        categories[index].accentHex = accentHex
    }

    func deleteCategory(id: UUID) {
        removeCategoryTree(id: id)
    }

    func deleteCategoryFromSwipe(id: UUID) {
        beginCategorySlideOut(id: id)
    }

    func deleteDetailItem(id: UUID) {
        detailItems.removeAll { $0.id == id }
    }

    func deleteDetailItemFromSwipe(id: UUID) {
        beginDetailItemSlideOut(id: id)
    }

    private func beginCategorySlideOut(id: UUID) {
        guard !slidingOutCategoryIds.contains(id), categories.contains(where: { $0.id == id }) else { return }
        withAnimation(Self.rowSlideOutAnimation) {
            categorySlideOutSignById[id] = -1
            slidingOutCategoryIds.insert(id)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.rowSlideOutDuration) { [weak self] in
            self?.finishCategorySlideOut(id: id)
        }
    }

    private func finishCategorySlideOut(id: UUID) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            slidingOutCategoryIds.remove(id)
            categorySlideOutSignById[id] = nil
            removeCategoryTree(id: id)
        }
    }

    private func beginDetailItemSlideOut(id: UUID) {
        guard !slidingOutDetailItemIds.contains(id), detailItems.contains(where: { $0.id == id }) else { return }
        withAnimation(Self.rowSlideOutAnimation) {
            detailItemSlideOutSignById[id] = -1
            slidingOutDetailItemIds.insert(id)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.rowSlideOutDuration) { [weak self] in
            self?.finishDetailItemSlideOut(id: id)
        }
    }

    private func finishDetailItemSlideOut(id: UUID) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            slidingOutDetailItemIds.remove(id)
            detailItemSlideOutSignById[id] = nil
            detailItems.removeAll { $0.id == id }
        }
    }

    private func removeCategoryTree(id: UUID) {
        let childIds = categories.filter { $0.parentId == id }.map(\.id)
        for childId in childIds {
            removeCategoryTree(id: childId)
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

    private func loadSampleData() {
        let clothing = LifeCategory(title: "穿搭", icon: "tshirt")
        let food = LifeCategory(title: "饮食", icon: "fork.knife")
        let homeCook = LifeCategory(title: "家常", icon: "frying.pan", parentId: food.id)
        let diningOut = LifeCategory(title: "外食", icon: "cup.and.saucer", parentId: food.id)
        let housing = LifeCategory(title: "居住", icon: "house")
        let travel = LifeCategory(title: "旅行", icon: "car")

        categories = [clothing, food, homeCook, diningOut, housing, travel]

        let calendar = Calendar.current
        let sampleDates: [Date] = [
            calendar.date(from: DateComponents(year: 2025, month: 3, day: 12)) ?? .now,
            calendar.date(from: DateComponents(year: 2024, month: 11, day: 5)) ?? .now,
            calendar.date(from: DateComponents(year: 2025, month: 1, day: 18)) ?? .now
        ]

        wardrobeItems = [
            WardrobeItem(
                categoryId: clothing.id,
                name: "纯棉圆领T恤",
                wardrobeGroup: "上装",
                wardrobeType: "T恤",
                brand: "Uniqlo",
                color: "白色",
                fabric: "棉",
                season: "春夏",
                purchasePrice: 99,
                purchaseDate: sampleDates[0],
                wearCount: 12
            ),
            WardrobeItem(
                categoryId: clothing.id,
                name: "轻薄牛津衬衫",
                wardrobeGroup: "上装",
                wardrobeType: "衬衫",
                brand: "Uniqlo",
                color: "浅蓝",
                fabric: "棉",
                season: "春夏",
                purchasePrice: 199,
                purchaseDate: sampleDates[0],
                wearCount: 5
            ),
            WardrobeItem(
                categoryId: clothing.id,
                name: "直筒休闲西裤",
                wardrobeGroup: "下装",
                wardrobeType: "西裤",
                brand: "ZARA",
                color: "深灰",
                fabric: "涤棉",
                season: "四季",
                purchasePrice: 359,
                purchaseDate: sampleDates[1],
                wearCount: 8
            ),
            WardrobeItem(
                categoryId: clothing.id,
                name: "白色运动鞋",
                wardrobeGroup: "鞋子",
                wardrobeType: "运动鞋",
                brand: "Nike",
                color: "白色",
                fabric: "皮革/网面",
                season: "春夏秋",
                purchasePrice: 699,
                purchaseDate: sampleDates[2],
                wearCount: 3
            )
        ]

        detailItems = [
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
    @State private var selectedIcon = LifeCategoryIconCatalog.options[0]
    @State private var selectedAccentHex = LifeCategoryColorCatalog.defaultHex
    @State private var showColorPalette = false
    @State private var showIconPalette = false
    @State private var allowTitleKeyboard = true

    private let scrollHorizontalPadding: CGFloat = 20
    private let sectionTitleLeadingInset: CGFloat = 10
    private let paletteOptionSize: CGFloat = 28
    private let iconPaletteOptionSize: CGFloat = 36
    private let colorLabelSpacing: CGFloat = 10
    private let pickerCardSpacing: CGFloat = 10
    private let pickerCardCornerRadius: CGFloat = 12
    private let pickerCardMinHeight: CGFloat = 44
    private let colorCardHorizontalPadding: CGFloat = 16

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

    private func sectionLeadingInset<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Color.clear
                .frame(width: sectionTitleLeadingInset)
            content()
        }
    }

    private var nameInputField: some View {
        MindFlowFormTitleTextField(
            text: $titleText,
            placeholder: "分类名称",
            wantsKeyboard: panelExpanded && allowTitleKeyboard
        )
        .frame(maxWidth: .infinity, minHeight: MindFlowFormSheetStyle.fieldContentMinHeight, alignment: .leading)
        .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
        .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
        .background(inputFieldChrome)
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetDragHandle

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    sectionLeadingInset {
                        Text(panelTitle)
                            .font(.headline)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        nameInputField
                        appearancePickerSection
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, scrollHorizontalPadding)
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
            .padding(.horizontal, scrollHorizontalPadding)
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

    private var selectedColorSwatch: some View {
        Circle()
            .fill(Color(hex: selectedAccentHex))
            .frame(width: 20, height: 20)
            .overlay {
                if selectedAccentHex.lowercased() == "#ffffff" {
                    Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                }
            }
    }

    private var pickerCardChrome: some View {
        RoundedRectangle(cornerRadius: pickerCardCornerRadius, style: .continuous)
            .stroke(MindFlowFormSheetStyle.fieldBorder, lineWidth: 1)
    }

    private var appearancePickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: pickerCardSpacing) {
                colorPickerCard
                iconPickerCard
            }

            if showColorPalette {
                colorPaletteOptions
            }

            if showIconPalette {
                iconPaletteOptions
            }
        }
    }

    private var colorPickerCard: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showColorPalette.toggle()
                if showColorPalette { showIconPalette = false }
            }
        } label: {
            HStack(spacing: colorLabelSpacing) {
                Text("颜色")
                    .font(.headline)
                Spacer(minLength: 0)
                selectedColorSwatch
                Image(systemName: showColorPalette ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(MindFlowFormSheetStyle.accent)
            .padding(.leading, colorCardHorizontalPadding)
            .padding(.trailing, colorCardHorizontalPadding)
            .frame(maxWidth: .infinity, minHeight: pickerCardMinHeight)
            .background(pickerCardChrome)
            .contentShape(RoundedRectangle(cornerRadius: pickerCardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var iconPickerCard: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showIconPalette.toggle()
                if showIconPalette { showColorPalette = false }
            }
        } label: {
            HStack(spacing: colorLabelSpacing) {
                Text("图标")
                    .font(.headline)
                Spacer(minLength: 0)
                Image(systemName: selectedIcon)
                    .font(.body.weight(.semibold))
                    .frame(width: 20, height: 20)
                Image(systemName: showIconPalette ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(MindFlowFormSheetStyle.accent)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: pickerCardMinHeight)
            .background(pickerCardChrome)
            .contentShape(RoundedRectangle(cornerRadius: pickerCardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var colorPaletteOptions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LifeCategoryColorCatalog.options, id: \.hex) { option in
                    let isSelected = selectedAccentHex == option.hex
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedAccentHex = option.hex
                        }
                    } label: {
                        Circle()
                            .fill(Color(hex: option.hex))
                            .frame(width: paletteOptionSize, height: paletteOptionSize)
                            .overlay {
                                if isSelected {
                                    Circle()
                                        .strokeBorder(MindFlowFormSheetStyle.accent, lineWidth: 2)
                                } else if option.hex.lowercased() == "#ffffff" {
                                    Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.name)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .accessibilityLabel("分类颜色选项")
    }

    private var iconPaletteOptions: some View {
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
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(isSelected ? MindFlowFormSheetStyle.accent : Color.secondary)
                            .frame(width: iconPaletteOptionSize, height: iconPaletteOptionSize)
                            .background(
                                Circle()
                                    .fill(isSelected ? MindFlowFormSheetStyle.accentFill : Color.clear)
                            )
                            .overlay {
                                if isSelected {
                                    Circle()
                                        .strokeBorder(MindFlowFormSheetStyle.accent, lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(iconName)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .accessibilityLabel("分类图标选项")
    }

    private func applyIntent(_ intent: LifeCategoryPanelIntent) {
        switch intent {
        case .add:
            resetForm()
        case .edit(let category):
            titleText = category.title
            selectedIcon = category.icon
            selectedAccentHex = category.accentHex
            allowTitleKeyboard = true
        }
    }

    private func resetForm() {
        titleText = ""
        selectedIcon = LifeCategoryIconCatalog.options[0]
        selectedAccentHex = LifeCategoryColorCatalog.defaultHex
        showColorPalette = false
        showIconPalette = false
        allowTitleKeyboard = true
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

        switch intent {
        case .add(let parentId):
            viewModel.addCategory(
                title: title,
                icon: selectedIcon,
                accentHex: selectedAccentHex,
                parentId: parentId
            )
        case .edit(let category):
            viewModel.updateCategory(
                id: category.id,
                title: title,
                icon: selectedIcon,
                accentHex: selectedAccentHex
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

// MARK: - 新建 / 编辑衣物（底部面板，对齐待办）

private struct AddLifeWardrobePanel: View {
    @ObservedObject var viewModel: DashboardViewModel
    var panelExpanded: Bool
    let intent: WardrobePanelIntent
    let onDismiss: () -> Void

    @State private var nameText = ""
    @State private var brandText = ""
    @State private var colorText = ""
    @State private var fabricText = ""
    @State private var seasonText = ""
    @State private var priceText = ""
    @State private var purchaseDate = Date()
    @State private var selectedGroup = WardrobeCategoryCatalog.allGroups[0]
    @State private var selectedType = WardrobeCategoryCatalog.types(in: WardrobeCategoryCatalog.allGroups[0])[0]
    @State private var allowTitleKeyboard = true

    private var isEditing: Bool {
        if case .edit = intent { return true }
        return false
    }

    private var panelTitle: String {
        isEditing ? "编辑衣物" : "新建衣物"
    }

    private var submitTitle: String {
        isEditing ? "保存" : "创建"
    }

    private var categoryId: UUID {
        switch intent {
        case .add(let categoryId, _, _):
            return categoryId
        case .edit(let item):
            return item.categoryId
        }
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

    private var subtypeOptions: [String] {
        WardrobeCategoryCatalog.types(in: selectedGroup)
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetDragHandle

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    wardrobeFieldSection(title: panelTitle) {
                        MindFlowFormTitleTextField(
                            text: $nameText,
                            placeholder: "衣物名称",
                            wantsKeyboard: panelExpanded && allowTitleKeyboard
                        )
                        .frame(maxWidth: .infinity, minHeight: MindFlowFormSheetStyle.fieldContentMinHeight, alignment: .leading)
                        .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
                        .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
                        .background(inputFieldChrome)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("大分类")
                            .font(.headline)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(WardrobeCategoryCatalog.allGroups, id: \.self) { group in
                                    WardrobeFilterChip(
                                        title: group,
                                        isSelected: selectedGroup == group
                                    ) {
                                        selectedGroup = group
                                        let types = WardrobeCategoryCatalog.types(in: group)
                                        if !types.contains(selectedType) {
                                            selectedType = types.first ?? selectedType
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("细分类")
                            .font(.headline)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(subtypeOptions, id: \.self) { type in
                                    WardrobeFilterChip(
                                        title: type,
                                        isSelected: selectedType == type
                                    ) {
                                        selectedType = type
                                    }
                                }
                            }
                        }
                    }

                    wardrobeFieldSection(title: "品牌") {
                        wardrobeTextField(text: $brandText, placeholder: "品牌")
                    }

                    wardrobeFieldSection(title: "颜色") {
                        wardrobeTextField(text: $colorText, placeholder: "颜色")
                    }

                    wardrobeFieldSection(title: "面料") {
                        wardrobeTextField(text: $fabricText, placeholder: "面料")
                    }

                    wardrobeFieldSection(title: "季节") {
                        wardrobeTextField(text: $seasonText, placeholder: "季节")
                    }

                    wardrobeFieldSection(title: "购买价格") {
                        wardrobeTextField(text: $priceText, placeholder: "价格", keyboard: .decimalPad)
                    }

                    wardrobeFieldSection(title: "购买日期") {
                        DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
                            .padding(.vertical, 8)
                            .background(inputFieldChrome)
                    }
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
            .disabled(nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
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

    private func wardrobeFieldSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(MindFlowFormSheetStyle.accent)
            content()
        }
    }

    private func wardrobeTextField(
        text: Binding<String>,
        placeholder: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        TextField(placeholder, text: text)
            .font(MindFlowFormSheetStyle.fieldFont)
            .keyboardType(keyboard)
            .frame(maxWidth: .infinity, minHeight: MindFlowFormSheetStyle.fieldContentMinHeight, alignment: .leading)
            .padding(.horizontal, MindFlowFormSheetStyle.fieldHorizontalPadding)
            .padding(.vertical, MindFlowFormSheetStyle.fieldVerticalPadding)
            .background(inputFieldChrome)
    }

    private func applyIntent(_ intent: WardrobePanelIntent) {
        switch intent {
        case .add(_, let wardrobeGroup, let wardrobeType):
            resetForm()
            if let wardrobeGroup, WardrobeCategoryCatalog.allGroups.contains(wardrobeGroup) {
                selectedGroup = wardrobeGroup
            }
            if let wardrobeType, WardrobeCategoryCatalog.types(in: selectedGroup).contains(wardrobeType) {
                selectedType = wardrobeType
            }
            allowTitleKeyboard = true
        case .edit(let item):
            nameText = item.name
            brandText = item.brand
            colorText = item.color
            fabricText = item.fabric
            seasonText = item.season
            priceText = String(format: "%.0f", item.purchasePrice)
            purchaseDate = item.purchaseDate
            selectedGroup = item.wardrobeGroup
            selectedType = item.wardrobeType
            allowTitleKeyboard = true
        }
    }

    private func resetForm() {
        nameText = ""
        brandText = ""
        colorText = ""
        fabricText = ""
        seasonText = ""
        priceText = ""
        purchaseDate = Date()
        selectedGroup = WardrobeCategoryCatalog.allGroups[0]
        selectedType = WardrobeCategoryCatalog.types(in: selectedGroup)[0]
        allowTitleKeyboard = true
    }

    private func submit() {
        let name = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let price = Double(priceText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

        switch intent {
        case .add:
            viewModel.addWardrobeItem(
                categoryId: categoryId,
                name: name,
                wardrobeGroup: selectedGroup,
                wardrobeType: selectedType,
                brand: brandText,
                color: colorText,
                fabric: fabricText,
                season: seasonText,
                purchasePrice: price,
                purchaseDate: purchaseDate
            )
        case .edit(let item):
            viewModel.updateWardrobeItem(
                id: item.id,
                name: name,
                wardrobeGroup: selectedGroup,
                wardrobeType: selectedType,
                brand: brandText,
                color: colorText,
                fabric: fabricText,
                season: seasonText,
                purchasePrice: price,
                purchaseDate: purchaseDate
            )
        }

        resetForm()
        onDismiss()
    }
}

#Preview {
    DashboardView()
}
