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
    var lastWearDate: Date?
    var favoriteScores: WardrobeFavoriteScores

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
        wearCount: Int = 0,
        lastWearDate: Date? = nil,
        favoriteScores: WardrobeFavoriteScores = WardrobeFavoriteScores()
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
        self.favoriteScores = favoriteScores
    }
}

struct WardrobeFavoriteScores: Equatable, Hashable {
    var appearance: Int?
    var fabricComfort: Int?
    var fit: Int?
    var texture: Int?
    var personalPreference: Int?

    var overallScore: Int? {
        guard let value = overallScoreValue else { return nil }
        return Int(value.rounded())
    }

    var overallScoreValue: Double? {
        let values = [appearance, fabricComfort, fit, texture, personalPreference].compactMap { $0 }
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    enum Dimension: String, CaseIterable, Identifiable {
        case appearance
        case texture
        case fit
        case fabricComfort
        case personalPreference

        var id: String { rawValue }

        var title: String {
            switch self {
            case .appearance: "颜值"
            case .fabricComfort: "面料舒适度"
            case .fit: "合身度"
            case .texture: "质感"
            case .personalPreference: "个人喜爱度"
            }
        }

        func value(in scores: WardrobeFavoriteScores) -> Int? {
            switch self {
            case .appearance: scores.appearance
            case .fabricComfort: scores.fabricComfort
            case .fit: scores.fit
            case .texture: scores.texture
            case .personalPreference: scores.personalPreference
            }
        }

        func setValue(_ value: Int?, on scores: inout WardrobeFavoriteScores) {
            let clamped = value.map { min(100, max(0, $0)) }
            switch self {
            case .appearance: scores.appearance = clamped
            case .fabricComfort: scores.fabricComfort = clamped
            case .fit: scores.fit = clamped
            case .texture: scores.texture = clamped
            case .personalPreference: scores.personalPreference = clamped
            }
        }
    }
}

enum WardrobeRankingKind: Hashable {
    case price
    case wearCount
}

struct WardrobeRankingRoute: Hashable {
    let itemId: UUID
    let kind: WardrobeRankingKind
}

struct OOTDHistoryRecord: Identifiable, Equatable {
    let id: UUID
    let categoryId: UUID
    let date: Date
    let plan: OutfitPlan
    var wearCountApplied: Bool

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        date: Date,
        plan: OutfitPlan,
        wearCountApplied: Bool = false
    ) {
        self.id = id
        self.categoryId = categoryId
        self.date = Calendar.current.startOfDay(for: date)
        self.plan = plan
        self.wearCountApplied = wearCountApplied
    }
}

private struct OOTDDateSelection: Identifiable, Hashable {
    let date: Date

    var id: TimeInterval { date.timeIntervalSince1970 }
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

private enum WardrobeSeasonCatalog {
    static let labels = ["春", "夏", "秋", "冬"]

    static func activeLabels(in season: String) -> Set<String> {
        let normalized = season.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.contains("四季") {
            return Set(labels)
        }
        return Set(labels.filter { normalized.contains($0) })
    }

    static func isActive(_ label: String, in season: String) -> Bool {
        activeLabels(in: season).contains(label)
    }

    static func displayString(from active: Set<String>) -> String {
        if active.count == labels.count {
            return "四季"
        }
        return labels.filter { active.contains($0) }.joined()
    }

    static func toggled(_ label: String, in season: String) -> String {
        var active = activeLabels(in: season)
        if active.contains(label) {
            active.remove(label)
        } else {
            active.insert(label)
        }
        return displayString(from: active)
    }
}

private enum WardrobeRowMetrics {
    static let verticalPadding: CGFloat = 13
    static let listRowHeight: CGFloat = 78
    static let listTopInset: CGFloat = 8
    static let pageIndicatorReserve: CGFloat = 16
    static let cardBottomInset: CGFloat = 20
}

/// 穿搭页卡片间距，可按需调整数值。
private enum OutfitPageCardMetrics {
    /// 卡片小标题（如「衣物库」「OOTD」）距卡片顶部的内边距，越小越贴近上沿
    static let titleTopInset: CGFloat = 4
    /// 小标题与下方内容区的间距
    static let titleBottomInset: CGFloat = 6
    /// 标题栏估算高度（用于衣物库卡片总高度计算）
    static var titleBarHeight: CGFloat { titleTopInset + titleBottomInset + 20 }
    /// 卡片内容区底部留白
    static let contentBottomInset: CGFloat = 16
    /// 喜爱度排行卡片：小标题与排名列表的间距
    static let favoriteRankingHeaderBottomSpacing: CGFloat = 14
    /// 排行预览列表行间距
    static let rankingPreviewRowSpacing: CGFloat = 8
}

enum OutfitPageCardKind: String, CaseIterable, Identifiable {
    case wardrobeLibrary
    case ootdPlan
    case ootdCalendar
    case favoriteRanking
    case actionCards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wardrobeLibrary: "衣物库"
        case .ootdPlan: "OOTD"
        case .ootdCalendar: "OOTD 日历"
        case .favoriteRanking: "喜爱度排行"
        case .actionCards: "快捷入口"
        }
    }
}

struct OutfitPageCardSettings: Equatable {
    var showWardrobeLibrary: Bool = true
    var showOOTDPlan: Bool = true
    var showOOTDCalendar: Bool = true
    var showFavoriteRanking: Bool = true
    var showActionCards: Bool = true

    func isVisible(_ kind: OutfitPageCardKind) -> Bool {
        switch kind {
        case .wardrobeLibrary: showWardrobeLibrary
        case .ootdPlan: showOOTDPlan
        case .ootdCalendar: showOOTDCalendar
        case .favoriteRanking: showFavoriteRanking
        case .actionCards: showActionCards
        }
    }

    mutating func setVisible(_ kind: OutfitPageCardKind, visible: Bool) {
        switch kind {
        case .wardrobeLibrary: showWardrobeLibrary = visible
        case .ootdPlan: showOOTDPlan = visible
        case .ootdCalendar: showOOTDCalendar = visible
        case .favoriteRanking: showFavoriteRanking = visible
        case .actionCards: showActionCards = visible
        }
    }
}

enum OutfitHubRankingKind: String, CaseIterable, Identifiable, Hashable {
    case favorite
    case price
    case wearCount
    case costPerWear
    case brandCount
    case consecutiveWearDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .favorite: "喜爱度排行"
        case .price: "价格排行"
        case .wearCount: "穿着次数排行"
        case .costPerWear: "每次穿着费用排行"
        case .brandCount: "品牌持有数排行"
        case .consecutiveWearDays: "连续穿戴天数排行"
        }
    }

    var usesBrandEntries: Bool {
        self == .brandCount
    }
}

struct OutfitBrandRankEntry: Identifiable, Hashable {
    let brand: String
    let count: Int

    var id: String { brand }
}

enum OutfitResearchTimeStore {
    private static let key = "outfitResearchTimeSeconds"

    static var totalSeconds: TimeInterval {
        get { UserDefaults.standard.double(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func add(seconds: TimeInterval) {
        guard seconds > 0 else { return }
        totalSeconds += seconds
    }

    static func formattedDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds.rounded()) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours) 小时 \(minutes) 分钟"
        }
        return "\(minutes) 分钟"
    }
}

enum OutfitTodoCategory {
    static let outfitTaskCategoryId = 8
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
    var topItemIds: [UUID] = []
    var bottomItemIds: [UUID] = []
    var shoesItemIds: [UUID] = []
    var hatItemIds: [UUID] = []
    var accessoryItemIds: [UUID] = []

    func itemIds(for slot: OutfitSlot) -> [UUID] {
        switch slot {
        case .top: topItemIds
        case .bottom: bottomItemIds
        case .shoes: shoesItemIds
        case .hat: hatItemIds
        case .accessory: accessoryItemIds
        }
    }

    mutating func setItemIds(_ ids: [UUID], for slot: OutfitSlot) {
        switch slot {
        case .top: topItemIds = ids
        case .bottom: bottomItemIds = ids
        case .shoes: shoesItemIds = ids
        case .hat: hatItemIds = ids
        case .accessory: accessoryItemIds = ids
        }
    }

    mutating func appendItem(_ id: UUID, for slot: OutfitSlot) {
        var ids = itemIds(for: slot)
        guard !ids.contains(id) else { return }
        ids.append(id)
        setItemIds(ids, for: slot)
    }

    mutating func removeAllReferences(to id: UUID) {
        for slot in OutfitSlot.allCases {
            var ids = itemIds(for: slot)
            ids.removeAll { $0 == id }
            setItemIds(ids, for: slot)
        }
    }
}

enum WardrobeLibrarySortMode: String, CaseIterable, Identifiable {
    case price
    case wearCount
    case color
    case brand

    var id: String { rawValue }

    var title: String {
        switch self {
        case .price: "价格"
        case .wearCount: "次数"
        case .color: "颜色"
        case .brand: "品牌"
        }
    }

    var next: WardrobeLibrarySortMode {
        switch self {
        case .price: .wearCount
        case .wearCount: .color
        case .color: .brand
        case .brand: .price
        }
    }
}

private enum WardrobeColorSort {
    static func order(for colorName: String) -> Int {
        let name = colorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let orderMap: [String: Int] = [
            "白色": 0, "米白": 1, "浅灰": 2, "浅蓝": 3,
            "灰色": 10, "藏青": 20, "军绿": 21, "深灰": 30,
            "黑色": 40
        ]
        return orderMap[name] ?? 15
    }
}

private enum WardrobeColorResolver {
    static let paletteOptions: [(name: String, hex: String)] = [
        ("白色", "#FFFFFF"),
        ("米白", "#FAF7F0"),
        ("浅灰", "#D1D5DB"),
        ("浅蓝", "#BFDBFE"),
        ("灰色", "#9CA3AF"),
        ("藏青", "#1E3A5F"),
        ("军绿", "#4B5320"),
        ("深灰", "#4B5563"),
        ("黑色", "#111827")
    ]

    static func fillColor(for name: String) -> Color {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = paletteOptions.first(where: { $0.name == trimmed }) {
            return Color(hex: match.hex)
        }
        switch trimmed {
        case "白色", "米白": return Color.white
        case "黑色": return Color(hex: "#111827")
        case "浅蓝": return Color(hex: "#BFDBFE")
        case "浅灰": return Color(hex: "#D1D5DB")
        case "深灰": return Color(hex: "#4B5563")
        case "藏青": return Color(hex: "#1E3A5F")
        case "军绿": return Color(hex: "#4B5320")
        case "灰色": return Color(hex: "#9CA3AF")
        default: return Color(hex: "#E5E7EB")
        }
    }

    static func labelColor(for name: String) -> Color {
        let ui = UIColor(fillColor(for: name))
        var white: CGFloat = 0
        ui.getWhite(&white, alpha: nil)
        return white > 0.65 ? MindFlowFormSheetStyle.accent : Color.white
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
    @State private var wardrobeSortMode: WardrobeLibrarySortMode = .wearCount
    @State private var wardrobeListPage = 0
    @State private var showFavoriteRanking = false
    @State private var ootdCalendarMonth = Date()
    @State private var selectedOOTDDate: OOTDDateSelection?
    @State private var showOOTDRecordDatePicker = false
    @State private var ootdRecordPickerDate = Date()
    @State private var showOOTDRecordedToast = false
    @State private var showRankingsHub = false
    @State private var showResearchTime = false
    @State private var showOutfitSettings = false
    @State private var selectedHubRankingKind: OutfitHubRankingKind?

    private static let wardrobePageSize = 5

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

    private var sortedWardrobeItems: [WardrobeItem] {
        switch wardrobeSortMode {
        case .wearCount:
            return filteredWardrobeItems.sorted { lhs, rhs in
                if lhs.wearCount != rhs.wearCount { return lhs.wearCount > rhs.wearCount }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        case .price:
            return filteredWardrobeItems.sorted { lhs, rhs in
                if lhs.purchasePrice != rhs.purchasePrice { return lhs.purchasePrice > rhs.purchasePrice }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        case .color:
            return filteredWardrobeItems.sorted { lhs, rhs in
                let l = WardrobeColorSort.order(for: lhs.color)
                let r = WardrobeColorSort.order(for: rhs.color)
                if l != r { return l < r }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        case .brand:
            return filteredWardrobeItems.sorted { lhs, rhs in
                let brandCompare = lhs.brand.localizedCompare(rhs.brand)
                if brandCompare != .orderedSame { return brandCompare == .orderedAscending }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        }
    }

    private var wardrobeItemPages: [[WardrobeItem]] {
        let items = sortedWardrobeItems
        guard !items.isEmpty else { return [] }
        return stride(from: 0, to: items.count, by: Self.wardrobePageSize).map { start in
            Array(items[start..<min(start + Self.wardrobePageSize, items.count)])
        }
    }

    private var outfitItems: [WardrobeItem] {
        viewModel.outfitPlanItems(for: category.id)
    }

    private var wardrobeCardAnimation: Animation {
        .smooth(duration: 0.32, extraBounce: 0)
    }

    private var outfitCardSpring: Animation {
        .spring(response: 0.46, dampingFraction: 0.78)
    }

    private var wardrobeLibraryLayoutToken: String {
        [
            String(sortedWardrobeItems.count),
            String(wardrobeListPage),
            String(wardrobeLibraryListRowCount),
            wardrobeSortMode.rawValue,
            selectedWardrobeGroup ?? "",
            selectedWardrobeType ?? "",
            String(wardrobeItemPages.count)
        ].joined(separator: "|")
    }

    private var wardrobeLibraryListRowCount: Int {
        let pages = wardrobeItemPages
        guard !pages.isEmpty else { return 1 }
        if wardrobeListPage == 0 {
            return max(1, pages[0].count)
        }
        return Self.wardrobePageSize
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
                            if viewModel.outfitPageCardSettings.isVisible(.wardrobeLibrary) {
                                wardrobeLibraryCard(width: geometry.size.width)
                                    .animation(wardrobeCardAnimation, value: wardrobeLibraryLayoutToken)
                            }

                            if viewModel.outfitPageCardSettings.isVisible(.ootdPlan) {
                                Group {
                                    if !outfitItems.isEmpty {
                                        outfitPlanCard(width: geometry.size.width)
                                            .transition(
                                                .asymmetric(
                                                    insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                                                    removal: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                                                )
                                            )
                                    }
                                }
                                .animation(outfitCardSpring, value: outfitItems.map(\.id))
                            }

                            if viewModel.outfitPageCardSettings.isVisible(.ootdCalendar) {
                                ootdCalendarCard(width: geometry.size.width)
                            }

                            if viewModel.outfitPageCardSettings.isVisible(.favoriteRanking) {
                                favoriteRankingPreviewCard(width: geometry.size.width)
                            }

                            if viewModel.outfitPageCardSettings.isVisible(.actionCards) {
                                outfitActionCardsRow(width: geometry.size.width)
                            }
                        } else {
                            detailCard(width: geometry.size.width)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
            .overlay(alignment: .top) {
                if showOOTDRecordedToast {
                    MindFlowToastBanner(message: "OOTD已记录")
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
        }
        .modifier(LifePageHeaderStyle())
        .navigationDestination(item: $selectedWardrobeItem) { item in
            WardrobeItemDetailView(viewModel: viewModel, itemId: item.id)
        }
        .navigationDestination(isPresented: $showFavoriteRanking) {
            WardrobeFavoriteRankingView(viewModel: viewModel, categoryId: category.id)
        }
        .sheet(item: $selectedOOTDDate) { selection in
            OOTDHistorySheet(
                viewModel: viewModel,
                categoryId: category.id,
                date: selection.date
            )
        }
        .navigationDestination(isPresented: $showRankingsHub) {
            OutfitRankingsHubView(
                viewModel: viewModel,
                categoryId: category.id,
                selectedKind: $selectedHubRankingKind
            )
        }
        .navigationDestination(item: $selectedHubRankingKind) { kind in
            OutfitRankingFullListView(
                viewModel: viewModel,
                categoryId: category.id,
                kind: kind
            )
        }
        .sheet(isPresented: $showResearchTime) {
            OutfitResearchTimeSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showOutfitSettings) {
            OutfitPageSettingsSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showOOTDRecordDatePicker) {
            OOTDRecordDatePickerSheet(
                selectedDate: $ootdRecordPickerDate,
                onConfirm: {
                    recordOOTD(on: ootdRecordPickerDate)
                    showOOTDRecordDatePicker = false
                }
            )
        }
        .onAppear {
            syncAddSheetRegistration()
            viewModel.applyPendingOOTDWearCounts()
            viewModel.refreshOutfitResearchTime()
        }
        .onChange(of: selectedWardrobeGroup) { _, _ in
            syncAddSheetRegistration()
            wardrobeListPage = 0
        }
        .onChange(of: selectedWardrobeType) { _, _ in
            syncAddSheetRegistration()
            wardrobeListPage = 0
        }
        .onChange(of: wardrobeSortMode) { _, _ in
            wardrobeListPage = 0
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
        let items = sortedWardrobeItems
        let pages = wardrobeItemPages
        let cardW = cardWidth(for: width)
        let subtypes = selectedWardrobeGroup.map { WardrobeCategoryCatalog.types(in: $0) } ?? []
        let displayRowCount = items.isEmpty ? 1 : wardrobeLibraryListRowCount
        let filterHeight: CGFloat = subtypes.isEmpty ? 52 : 96
        let rowSpacing: CGFloat = 8
        let rowsHeight = CGFloat(displayRowCount) * WardrobeRowMetrics.listRowHeight
            + CGFloat(max(0, displayRowCount - 1)) * rowSpacing
        let pageIndicatorReserve = pages.count > 1 ? WardrobeRowMetrics.pageIndicatorReserve : 0
        let listAreaHeight = WardrobeRowMetrics.listTopInset + rowsHeight + pageIndicatorReserve
        let cardH = max(
            260,
            OutfitPageCardMetrics.titleBarHeight
                + filterHeight
                + listAreaHeight
                + WardrobeRowMetrics.cardBottomInset
        )

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("衣物库")
                    .font(.headline)
                    .foregroundStyle(MindFlowFormSheetStyle.accent)

                Spacer(minLength: 8)

                Button {
                    wardrobeSortMode = wardrobeSortMode.next
                } label: {
                    HStack(spacing: 4) {
                        Text(wardrobeSortMode.title)
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, OutfitPageCardMetrics.titleTopInset)
            .padding(.bottom, OutfitPageCardMetrics.titleBottomInset)

            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WardrobeCategoryCatalog.allGroups, id: \.self) { group in
                            WardrobeFilterChip(
                                title: group,
                                isSelected: selectedWardrobeGroup == group
                            ) {
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
                                    selectedWardrobeType = selectedWardrobeType == type ? nil : type
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 8)

            if items.isEmpty {
                Text(emptyWardrobeMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else {
                TabView(selection: $wardrobeListPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { pageIndex, pageItems in
                        Group {
                            if pageIndex == 0 {
                                VStack(spacing: rowSpacing) {
                                    ForEach(pageItems) { item in
                                        wardrobeItemButton(item)
                                    }
                                }
                            } else {
                                VStack(spacing: rowSpacing) {
                                    ForEach(0..<Self.wardrobePageSize, id: \.self) { rowIndex in
                                        if rowIndex < pageItems.count {
                                            wardrobeItemButton(pageItems[rowIndex])
                                        } else {
                                            Color.clear
                                                .frame(height: WardrobeRowMetrics.listRowHeight)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, WardrobeRowMetrics.listTopInset)
                        .padding(.bottom, pageIndicatorReserve > 0 ? pageIndicatorReserve : 2)
                        .padding(.horizontal, 8)
                        .tag(pageIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: pages.count > 1 ? .automatic : .never))
                .frame(height: listAreaHeight)
            }
        }
        .frame(width: cardW, height: cardH)
        .todoPanelCardChrome()
        .padding(.horizontal, 20)
        .frame(width: max(0, width))
        .onChange(of: pages.count) { _, count in
            if wardrobeListPage >= count {
                wardrobeListPage = max(0, count - 1)
            }
        }
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

    private func favoriteRankingPreviewCard(width: CGFloat) -> some View {
        let cardW = cardWidth(for: width)
        let topItems = viewModel.topFavoriteItems(for: category.id, limit: 3)
        let rowHeight: CGFloat = 52
        let rowSpacing = OutfitPageCardMetrics.rankingPreviewRowSpacing
        let rowsHeight = topItems.isEmpty
            ? 44.0
            : CGFloat(topItems.count) * rowHeight + CGFloat(max(0, topItems.count - 1)) * rowSpacing
        let cardH = OutfitPageCardMetrics.titleTopInset
            + OutfitPageCardMetrics.favoriteRankingHeaderBottomSpacing
            + max(rowsHeight, 44)
            + OutfitPageCardMetrics.contentBottomInset

        return Button {
            showFavoriteRanking = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text("喜爱度排行")
                        .font(.headline)
                        .foregroundStyle(MindFlowFormSheetStyle.accent)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                }
                .padding(.horizontal, 16)
                .padding(.top, OutfitPageCardMetrics.titleTopInset)
                .padding(.bottom, OutfitPageCardMetrics.favoriteRankingHeaderBottomSpacing)

                if topItems.isEmpty {
                    Text("暂无评分，进入详情页为衣物打分")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, OutfitPageCardMetrics.contentBottomInset)
                } else {
                    VStack(spacing: rowSpacing) {
                        ForEach(Array(topItems.enumerated()), id: \.element.id) { index, item in
                            WardrobeFavoriteRankingRowView(
                                rank: index + 1,
                                item: item,
                                isCompact: true
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, OutfitPageCardMetrics.contentBottomInset)
                }
            }
            .frame(width: cardW, height: cardH)
            .todoPanelCardChrome()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .frame(width: max(0, width))
    }

    private func outfitActionCardsRow(width: CGFloat) -> some View {
        let cardW = (cardWidth(for: width) - 24) / 3

        return HStack(spacing: 12) {
            outfitActionCard(
                title: "排行榜",
                subtitle: "6 项榜单",
                icon: "list.number",
                width: cardW
            ) {
                showRankingsHub = true
            }
            outfitActionCard(
                title: "投入时间",
                subtitle: OutfitResearchTimeStore.formattedDuration(viewModel.outfitResearchTimeSeconds),
                icon: "clock",
                width: cardW
            ) {
                showResearchTime = true
            }
            outfitActionCard(
                title: "设置",
                subtitle: "卡片显示",
                icon: "gearshape",
                width: cardW
            ) {
                showOutfitSettings = true
            }
        }
        .padding(.horizontal, 20)
        .frame(width: max(0, width))
    }

    private func outfitActionCard(
        title: String,
        subtitle: String,
        icon: String,
        width: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: width, height: 96)
            .todoPanelCardChrome()
        }
        .buttonStyle(.plain)
    }

    private func ootdCalendarCard(width: CGFloat) -> some View {
        let cardW = cardWidth(for: width)
        let markedDates = viewModel.ootdMarkedDates(for: category.id, in: ootdCalendarMonth)
        let gridDays = ootdCalendarGridDays(for: ootdCalendarMonth)
        let cellSize = (cardW - 32 - 6 * 4) / 7
        let gridHeight = cellSize * CGFloat(gridDays.count / 7) + CGFloat(max(0, gridDays.count / 7 - 1)) * 4
        let cardH = OutfitPageCardMetrics.titleTopInset
            + 36
            + OutfitPageCardMetrics.titleBottomInset
            + 20
            + 8
            + gridHeight
            + OutfitPageCardMetrics.contentBottomInset

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("OOTD 日历")
                    .font(.headline)
                    .foregroundStyle(MindFlowFormSheetStyle.accent)

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Button {
                        ootdCalendarMonth = Calendar.current.date(
                            byAdding: .month,
                            value: -1,
                            to: ootdCalendarMonth
                        ) ?? ootdCalendarMonth
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)

                    Text(ootdCalendarMonthTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                        .frame(minWidth: 88)

                    Button {
                        ootdCalendarMonth = Calendar.current.date(
                            byAdding: .month,
                            value: 1,
                            to: ootdCalendarMonth
                        ) ?? ootdCalendarMonth
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, OutfitPageCardMetrics.titleTopInset)
            .padding(.bottom, OutfitPageCardMetrics.titleBottomInset)

            HStack(spacing: 4) {
                ForEach(ootdWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: cellSize)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 4), count: 7),
                spacing: 4
            ) {
                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        ootdCalendarDayCell(day, cellSize: cellSize, markedDates: markedDates)
                    } else {
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: cardW, height: cardH)
        .todoPanelCardChrome()
        .padding(.horizontal, 20)
        .frame(width: max(0, width))
    }

    private var ootdCalendarMonthTitle: String {
        ootdCalendarMonth.formatted(.dateTime.year().month(.wide))
    }

    private var ootdWeekdaySymbols: [String] {
        ["一", "二", "三", "四", "五", "六", "日"]
    }

    private func ootdCalendarGridDays(for month: Date) -> [Date?] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
            let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count
        else { return [] }

        let weekdayIndex = calendar.component(.weekday, from: monthStart)
        let leadingBlanks = (weekdayIndex - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            days.append(calendar.date(byAdding: .day, value: offset, to: monthStart))
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    @ViewBuilder
    private func ootdCalendarDayCell(_ day: Date, cellSize: CGFloat, markedDates: Set<Date>) -> some View {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)
        let hasOOTD = markedDates.contains(dayStart)
        let dayNumber = calendar.component(.day, from: day)

        if hasOOTD {
            Button {
                selectedOOTDDate = OOTDDateSelection(date: dayStart)
            } label: {
                VStack(spacing: 2) {
                    Text("\(dayNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 4, height: 4)
                }
                .frame(width: cellSize, height: cellSize)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(MindFlowFormSheetStyle.accent)
                )
            }
            .buttonStyle(.plain)
        } else {
            Text("\(dayNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.55))
                .frame(width: cellSize, height: cellSize)
        }
    }

    private func wardrobeItemButton(_ item: WardrobeItem) -> some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(outfitCardSpring) {
                    viewModel.assignToOutfitPlan(item)
                }
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
        .frame(minHeight: WardrobeRowMetrics.listRowHeight)
        .mindFlowListRowCardChrome()
    }

    private func outfitPlanCard(width: CGFloat) -> some View {
        let cardW = cardWidth(for: width)
        let outfitItems = viewModel.outfitPlanItems(for: category.id)
        let itemRowHeight: CGFloat = 44
        let bottomInset: CGFloat = 16
        let contentHeight = CGFloat(outfitItems.count) * itemRowHeight
        let cardH = OutfitPageCardMetrics.titleTopInset
            + OutfitPageCardMetrics.titleBottomInset
            + contentHeight
            + bottomInset

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("OOTD")
                    .font(.headline)
                    .foregroundStyle(MindFlowFormSheetStyle.accent)

                Spacer(minLength: 8)

                HStack(spacing: 10) {
                    ootdRecordButton("今日") {
                        recordOOTD(on: Date())
                    }
                    ootdRecordButton("明日") {
                        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                        recordOOTD(on: tomorrow)
                    }
                    ootdRecordButton("日期") {
                        ootdRecordPickerDate = Date()
                        showOOTDRecordDatePicker = true
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, OutfitPageCardMetrics.titleTopInset)
            .padding(.bottom, OutfitPageCardMetrics.titleBottomInset)

            VStack(spacing: 0) {
                ForEach(Array(outfitItems.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider().padding(.leading, 16)
                    }
                    OutfitPlanItemRow(item: item) {
                        withAnimation(outfitCardSpring) {
                            viewModel.removeFromOutfitPlan(item)
                        }
                    }
                    .frame(minHeight: itemRowHeight)
                }
            }
            .padding(.bottom, bottomInset)
        }
        .frame(width: cardW, height: cardH)
        .todoPanelCardChrome()
        .padding(.horizontal, 20)
        .frame(width: max(0, width))
    }

    private func ootdRecordButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
        }
        .buttonStyle(.plain)
    }

    private func recordOOTD(on date: Date) {
        withAnimation(outfitCardSpring) {
            if viewModel.saveOutfitPlan(for: category.id, on: date) {
                presentOOTDRecordedToast()
            }
        }
    }

    private func presentOOTDRecordedToast() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            showOOTDRecordedToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeOut(duration: 0.25)) {
                showOOTDRecordedToast = false
            }
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

private struct OutfitPlanItemRow: View {
    let item: WardrobeItem
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(alignment: .center, spacing: 12) {
                Text(item.wardrobeGroup)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 44, alignment: .leading)

                Text("\(item.brand) · \(item.name)")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct WardrobeItemDetailView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let itemId: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var rankingRoute: WardrobeRankingRoute?
    @State private var showFavoriteRating = false
    @FocusState private var focusedChip: WardrobeDetailChipField?

    private var item: WardrobeItem? {
        viewModel.wardrobeItem(withId: itemId)
    }

    var body: some View {
        Group {
            if let item {
                ScrollView {
                    ZStack(alignment: .top) {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 600)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusedChip = nil
                            }

                        wardrobeItemDetailContent(for: item)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(lifePageBackground)
        .modifier(LifePageHeaderStyle(showsTitle: false))
        .navigationDestination(item: $rankingRoute) { route in
            WardrobeTypeRankingView(viewModel: viewModel, route: route)
        }
        .sheet(isPresented: $showFavoriteRating) {
            WardrobeFavoriteRatingSheet(viewModel: viewModel, itemId: itemId)
        }
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
                WardrobeEditableDetailChip(
                    text: brandBinding(for: item),
                    fontWeight: .bold,
                    placeholder: "品牌",
                    field: .brand,
                    focusedField: $focusedChip
                )
                WardrobeEditableDetailChip(
                    text: nameBinding(for: item),
                    fontWeight: .semibold,
                    usesFlexibleWidth: true,
                    placeholder: "名称",
                    field: .name,
                    focusedField: $focusedChip
                )
            }
            .padding(.horizontal, 20)

            WardrobeSeasonCard(viewModel: viewModel, itemId: item.id) {
                focusedChip = nil
            }
            .padding(.horizontal, 20)

            WardrobePriceStatsCard(
                viewModel: viewModel,
                item: item,
                formatPrice: formatPrice,
                formatCostPerWear: formatCostPerWear,
                onTopTapped: {
                    focusedChip = nil
                    rankingRoute = WardrobeRankingRoute(itemId: item.id, kind: .price)
                }
            )
            .padding(.horizontal, 20)

            WardrobeUsageStatsCard(
                viewModel: viewModel,
                item: item,
                onTopTapped: {
                    focusedChip = nil
                    rankingRoute = WardrobeRankingRoute(itemId: item.id, kind: .wearCount)
                }
            )
            .padding(.horizontal, 20)
            .onTapGesture {
                focusedChip = nil
            }

            HStack(spacing: 12) {
                WardrobeFabricSquareChip(
                    text: fabricBinding(for: item),
                    field: .fabric,
                    focusedField: $focusedChip
                )
                WardrobeColorSquareChip(text: colorBinding(for: item))
                WardrobeFavoriteSquareChip(item: item) {
                    focusedChip = nil
                    showFavoriteRating = true
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button {
                    focusedChip = nil
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
                    focusedChip = nil
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
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    private func formatPrice(_ price: Double) -> String {
        String(format: "¥%.0f", price)
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day())
    }

    private func formatCostPerWear(price: Double, wearCount: Int) -> String {
        guard wearCount > 0 else { return "—" }
        let cost = price / Double(wearCount)
        if abs(cost.rounded() - cost) < 0.05 {
            return String(format: "¥%.0f", cost)
        }
        return String(format: "¥%.1f", cost)
    }

    private func brandBinding(for item: WardrobeItem) -> Binding<String> {
        Binding(
            get: { viewModel.wardrobeItem(withId: item.id)?.brand ?? item.brand },
            set: { viewModel.updateWardrobeBrand(id: item.id, brand: $0) }
        )
    }

    private func nameBinding(for item: WardrobeItem) -> Binding<String> {
        Binding(
            get: { viewModel.wardrobeItem(withId: item.id)?.name ?? item.name },
            set: { viewModel.updateWardrobeName(id: item.id, name: $0) }
        )
    }

    private func colorBinding(for item: WardrobeItem) -> Binding<String> {
        Binding(
            get: { viewModel.wardrobeItem(withId: item.id)?.color ?? item.color },
            set: { viewModel.updateWardrobeColor(id: item.id, color: $0) }
        )
    }

    private func fabricBinding(for item: WardrobeItem) -> Binding<String> {
        Binding(
            get: { viewModel.wardrobeItem(withId: item.id)?.fabric ?? item.fabric },
            set: { viewModel.updateWardrobeFabric(id: item.id, fabric: $0) }
        )
    }
}

private struct WardrobeEditableDetailChip: View {
    @Binding var text: String
    var fontWeight: Font.Weight = .bold
    var usesFlexibleWidth: Bool = false
    var placeholder: String
    var field: WardrobeDetailChipField
    var focusedField: FocusState<WardrobeDetailChipField?>.Binding

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(.title3.weight(fontWeight))
            .foregroundStyle(MindFlowFormSheetStyle.accent)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.65)
            .textFieldStyle(.plain)
            .submitLabel(.done)
            .focused(focusedField, equals: field)
            .onSubmit {
                focusedField.wrappedValue = nil
            }
            .padding(.horizontal, 8)
            .frame(
                width: usesFlexibleWidth ? nil : WardrobeDetailChipMetrics.width,
                height: WardrobeDetailChipMetrics.height
            )
            .frame(maxWidth: usesFlexibleWidth ? .infinity : nil)
            .todoPanelCardChrome()
    }
}

private struct WardrobeSeasonCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    let itemId: UUID
    var onInteract: () -> Void = {}

    private var season: String {
        viewModel.wardrobeItem(withId: itemId)?.season ?? ""
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(WardrobeSeasonCatalog.labels.enumerated()), id: \.offset) { index, label in
                if index > 0 {
                    WardrobeSeasonDashedDivider()
                }
                Button {
                    onInteract()
                    viewModel.toggleWardrobeSeason(id: itemId, label: label)
                } label: {
                    Text(label)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(
                            WardrobeSeasonCatalog.isActive(label, in: season)
                                ? MindFlowFormSheetStyle.accent
                                : Color.secondary.opacity(0.38)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: WardrobeDetailChipMetrics.height)
        .todoPanelCardChrome()
    }
}

private struct WardrobePriceStatsCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    let item: WardrobeItem
    let formatPrice: (Double) -> String
    let formatCostPerWear: (Double, Int) -> String
    let onTopTapped: () -> Void

    @State private var showPurchasePriceEditor = false
    @State private var draftPurchasePrice = ""

    private var currentItem: WardrobeItem {
        viewModel.wardrobeItem(withId: item.id) ?? item
    }

    var body: some View {
        WardrobeFourMetricStatsCard(sectionTitle: "价格统计") {
            WardrobeStatsMetricRow(metrics: [
                WardrobeStatsMetric(
                    title: "买入",
                    value: formatPrice(currentItem.purchasePrice),
                    onTap: {
                        draftPurchasePrice = String(format: "%.0f", currentItem.purchasePrice)
                        showPurchasePriceEditor = true
                    }
                ),
                WardrobeStatsMetric(
                    title: "平均",
                    value: formatPeerAveragePrice(viewModel.averagePurchasePrice(for: currentItem))
                ),
                WardrobeStatsMetric(
                    title: "每次",
                    value: formatCostPerWear(currentItem.purchasePrice, currentItem.wearCount)
                ),
                WardrobeStatsMetric(
                    isTopRank: true,
                    rankNumber: viewModel.rankNumber(for: currentItem, kind: .price),
                    onTap: onTopTapped
                )
            ])
        }
        .sheet(isPresented: $showPurchasePriceEditor) {
            WardrobePurchasePriceEditorSheet(
                priceText: $draftPurchasePrice,
                onConfirm: {
                    let trimmed = draftPurchasePrice.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let price = Double(trimmed), price >= 0 {
                        viewModel.updateWardrobePurchasePrice(id: item.id, price: price)
                    }
                    showPurchasePriceEditor = false
                }
            )
        }
    }

    private func formatPeerAveragePrice(_ average: Double?) -> String {
        guard let average else { return "—" }
        if abs(average.rounded() - average) < 0.05 {
            return String(format: "¥%.0f", average)
        }
        return String(format: "¥%.1f", average)
    }
}

private struct WardrobeUsageStatsCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    let item: WardrobeItem
    let onTopTapped: () -> Void

    @State private var showPurchaseDatePicker = false
    @State private var draftPurchaseDate = Date()

    private var currentItem: WardrobeItem {
        viewModel.wardrobeItem(withId: item.id) ?? item
    }

    var body: some View {
        WardrobeFourMetricStatsCard(sectionTitle: "使用统计") {
            WardrobeStatsMetricRow(
                metrics: [
                WardrobeStatsMetric(
                    title: "买入",
                    usesSplitDateDisplay: true,
                    dateValue: currentItem.purchaseDate,
                    onTap: {
                        draftPurchaseDate = currentItem.purchaseDate
                        showPurchaseDatePicker = true
                    }
                ),
                WardrobeStatsMetric(
                    title: "上次",
                    usesSplitDateDisplay: true,
                    dateValue: currentItem.lastWearDate
                ),
                WardrobeStatsMetric(title: "次数", value: "\(currentItem.wearCount)"),
                WardrobeStatsMetric(
                    isTopRank: true,
                    rankNumber: viewModel.rankNumber(for: currentItem, kind: .wearCount),
                    onTap: onTopTapped
                )
            ],
                rowHeight: 92
            )
        }
        .sheet(isPresented: $showPurchaseDatePicker) {
            WardrobePurchaseDateEditorSheet(
                selectedDate: $draftPurchaseDate,
                onConfirm: {
                    viewModel.updateWardrobePurchaseDate(id: item.id, date: draftPurchaseDate)
                    showPurchaseDatePicker = false
                }
            )
        }
    }
}

private struct WardrobePurchasePriceEditorSheet: View {
    @Binding var priceText: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 4) {
                    Text("¥")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                    TextField("买入价格", text: $priceText)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MindFlowFormSheetStyle.accent.opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 0)
            }
            .padding(.top, 24)
            .background(lifePageBackground)
            .navigationTitle("编辑买入价")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") { onConfirm() }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.height(220)])
    }
}

private struct WardrobePurchaseDateEditorSheet: View {
    @Binding var selectedDate: Date
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    "买入日期",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.horizontal, 12)

                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .background(lifePageBackground)
            .navigationTitle("编辑买入日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") { onConfirm() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .environment(\.locale, Locale(identifier: "zh_CN"))
    }
}

private struct WardrobeFourMetricStatsCard<Content: View>: View {
    let sectionTitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(sectionTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 3)

            content
                .padding(.bottom, 4)
        }
        .todoPanelCardChrome()
    }
}

private struct WardrobeStatsMetric: Identifiable {
    let id = UUID()
    var title: String
    var value: String
    var flexWeight: CGFloat
    var usesSplitDateDisplay: Bool
    var dateValue: Date?
    var isTopRank: Bool
    var rankNumber: Int?
    var onTap: (() -> Void)?

    init(
        title: String = "",
        value: String = "",
        flexWeight: CGFloat = 1,
        usesSplitDateDisplay: Bool = false,
        dateValue: Date? = nil,
        isTopRank: Bool = false,
        rankNumber: Int? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.flexWeight = flexWeight
        self.usesSplitDateDisplay = usesSplitDateDisplay
        self.dateValue = dateValue
        self.isTopRank = isTopRank
        self.rankNumber = rankNumber
        self.onTap = onTap
    }
}

private enum WardrobeStatsDateParts {
    static func year(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    static func monthDay(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

private enum WardrobeRankPalette {
    static func foregroundColor(for rank: Int?) -> Color {
        guard let rank else { return Color(hex: "#9CA3AF") }
        switch rank {
        case 1: return Color(hex: "#D4AF37")
        case 2...4: return Color(hex: "#7c3aed")
        case 5...7: return Color(hex: "#2563eb")
        case 8...10: return Color(hex: "#34C759")
        default: return Color(hex: "#9CA3AF")
        }
    }

    static func showsCrown(for rank: Int?) -> Bool {
        rank == 1
    }

    /// Top1 皇冠倾斜角度，与数字保持一致
    static let crownRotationDegrees: Double = 8
    /// Top1 皇冠相对数字的水平偏移
    static let crownOffsetX: CGFloat = 12
    /// Top1 皇冠相对数字的垂直偏移，越负离数字越远
    static let crownOffsetY: CGFloat = -19
    /// Top 与数字之间的间距
    static let topLabelSpacing: CGFloat = 3
}

private struct WardrobeStatsMetricRow: View {
    let metrics: [WardrobeStatsMetric]
    var rowHeight: CGFloat = WardrobeDetailChipMetrics.height

    private var totalWeight: CGFloat {
        metrics.reduce(0) { $0 + $1.flexWeight }
    }

    var body: some View {
        GeometryReader { geometry in
            let dividerCount = max(0, metrics.count - 1)
            let usableWidth = max(0, geometry.size.width - CGFloat(dividerCount))

            HStack(spacing: 0) {
                ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                    if index > 0 {
                        WardrobeSeasonDashedDivider()
                    }
                    WardrobeStatsMetricCell(metric: metric)
                        .frame(width: usableWidth * metric.flexWeight / totalWeight)
                }
            }
        }
        .frame(height: rowHeight)
    }
}

private struct WardrobeStatsMetricCell: View {
    let metric: WardrobeStatsMetric

    var body: some View {
        Group {
            if let onTap = metric.onTap {
                Button(action: onTap) {
                    cellContent
                }
                .buttonStyle(.plain)
            } else {
                cellContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, metric.isTopRank ? 2 : 4)
    }

    private var cellContent: some View {
        Group {
            if metric.isTopRank {
                WardrobeStatsTopRankContent(rank: metric.rankNumber)
            } else if metric.usesSplitDateDisplay {
                VStack(spacing: 4) {
                    Text(metric.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let date = metric.dateValue {
                        Text(WardrobeStatsDateParts.year(from: date))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)

                        Text(WardrobeStatsDateParts.monthDay(from: date))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    } else {
                        Text("—")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MindFlowFormSheetStyle.accent.opacity(0.45))
                    }
                }
            } else {
                VStack(spacing: 6) {
                    Text(metric.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text(metric.value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.65)
                }
            }
        }
    }
}

private struct WardrobeStatsTopRankContent: View {
    let rank: Int?

    private var rankColor: Color {
        WardrobeRankPalette.foregroundColor(for: rank)
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: WardrobeRankPalette.topLabelSpacing) {
            Text("Top")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .italic()
                .tracking(-1.2)
                .foregroundStyle(rankColor)
                .shadow(color: rankColor.opacity(rank == 1 ? 0.35 : 0.16), radius: rank == 1 ? 2 : 1, y: 1)
                .rotationEffect(.degrees(-8))

            if let rank {
                Text("\(rank)")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(rankColor)
                    .shadow(color: rankColor.opacity(rank == 1 ? 0.35 : 0.16), radius: rank == 1 ? 2 : 1, y: 1)
                    .rotationEffect(.degrees(8))
            } else {
                Text("—")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(rankColor.opacity(0.45))
                    .rotationEffect(.degrees(8))
            }
        }
        .overlay(alignment: .topTrailing) {
            if WardrobeRankPalette.showsCrown(for: rank) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FFE566"), Color(hex: "#D4AF37")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "#D4AF37").opacity(0.45), radius: 1.5, y: 1)
                    .rotationEffect(.degrees(WardrobeRankPalette.crownRotationDegrees))
                    .offset(
                        x: WardrobeRankPalette.crownOffsetX,
                        y: WardrobeRankPalette.crownOffsetY
                    )
            }
        }
    }
}

private struct WardrobeFavoriteSquareChip: View {
    let item: WardrobeItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text("个人喜爱度")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let score = item.favoriteScores.overallScore {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                        Text("分")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                    }
                } else {
                    Text("点击评分")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent.opacity(0.55))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: WardrobeDetailChipMetrics.height)
            .todoPanelCardChrome()
        }
        .buttonStyle(.plain)
    }
}

private struct WardrobeColorSquareChip: View {
    @Binding var text: String
    @State private var showPalette = false

    private var fillColor: Color {
        WardrobeColorResolver.fillColor(for: text)
    }

    private var labelColor: Color {
        WardrobeColorResolver.labelColor(for: text)
    }

    private var displayName: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "选择" : trimmed
    }

    var body: some View {
        Button {
            showPalette = true
        } label: {
            VStack(spacing: 6) {
                Text("颜色")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(labelColor.opacity(0.85))

                Text(displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .frame(height: WardrobeDetailChipMetrics.height)
            .background(fillColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MindFlowFormSheetStyle.accent.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPalette) {
            WardrobeColorPaletteSheet(selectedColor: $text)
        }
    }
}

private struct WardrobeColorPaletteSheet: View {
    @Binding var selectedColor: String
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(WardrobeColorResolver.paletteOptions, id: \.name) { option in
                        Button {
                            selectedColor = option.name
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: option.hex))
                                    .frame(height: 52)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(
                                                selectedColor == option.name
                                                    ? MindFlowFormSheetStyle.accent
                                                    : Color.gray.opacity(0.25),
                                                lineWidth: selectedColor == option.name ? 2.5 : 1
                                            )
                                    )

                                Text(option.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(lifePageBackground)
            .navigationTitle("选择颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct WardrobeFabricSquareChip: View {
    @Binding var text: String
    var field: WardrobeDetailChipField
    var focusedField: FocusState<WardrobeDetailChipField?>.Binding

    var body: some View {
        VStack(spacing: 6) {
            Text("面料")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("面料", text: $text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .focused(focusedField, equals: field)
                .onSubmit {
                    focusedField.wrappedValue = nil
                }
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(height: WardrobeDetailChipMetrics.height)
        .todoPanelCardChrome()
    }
}

private struct WardrobeFavoriteScoreCard: View {
    let item: WardrobeItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("个人喜爱度")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let score = item.favoriteScores.overallScore {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(score)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(MindFlowFormSheetStyle.accent)
                            Text("分")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MindFlowFormSheetStyle.accent)
                        }
                    } else {
                        Text("点击评分")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(MindFlowFormSheetStyle.accent.opacity(0.55))
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .todoPanelCardChrome()
        }
        .buttonStyle(.plain)
    }
}

private struct WardrobeFavoriteRatingSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    let itemId: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var draftScores = WardrobeFavoriteScores()

    private var item: WardrobeItem? {
        viewModel.wardrobeItem(withId: itemId)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let item {
                        Text("\(item.brand) · \(item.name)")
                            .font(.headline)
                            .foregroundStyle(MindFlowFormSheetStyle.accent)
                            .padding(.horizontal, 20)
                    }

                    if let preview = draftScores.overallScoreValue {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("综合")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", preview))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(MindFlowFormSheetStyle.accent)
                            Text("分")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MindFlowFormSheetStyle.accent)
                        }
                        .padding(.horizontal, 20)
                    }

                    VStack(spacing: 16) {
                        ForEach(WardrobeFavoriteScores.Dimension.allCases) { dimension in
                            WardrobeFavoriteDimensionSlider(
                                title: dimension.title,
                                value: binding(for: dimension)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(lifePageBackground)
            .navigationTitle("喜爱度评分")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.updateFavoriteScores(id: itemId, scores: draftScores)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let item {
                draftScores = item.favoriteScores
            }
        }
    }

    private func binding(for dimension: WardrobeFavoriteScores.Dimension) -> Binding<Double> {
        Binding(
            get: {
                Double(dimension.value(in: draftScores) ?? 0)
            },
            set: { newValue in
                var updated = draftScores
                dimension.setValue(Int(newValue.rounded()), on: &updated)
                draftScores = updated
            }
        )
    }
}

private struct WardrobeFavoriteDimensionSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                Spacer()
                Text("\(Int(value.rounded()))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                    .monospacedDigit()
            }

            Slider(value: $value, in: 0...100, step: 1)
                .tint(MindFlowFormSheetStyle.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .todoPanelCardChrome()
    }
}

private struct WardrobeFavoriteRankingRowView: View {
    let rank: Int
    let item: WardrobeItem
    var isCompact: Bool = false
    var metricText: String?

    private var rankColor: Color {
        WardrobeRankPalette.foregroundColor(for: rank)
    }

    private var trailingText: String {
        if let metricText {
            return metricText
        }
        if let score = item.favoriteScores.overallScore {
            return "\(score)分"
        }
        return "未评分"
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(isCompact ? .subheadline.weight(.bold) : .headline.weight(.bold))
                .foregroundStyle(rankColor)
                .frame(width: 32, alignment: .leading)

            Text("\(item.brand) · \(item.name)")
                .font(isCompact ? .subheadline.weight(.medium) : .body.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(trailingText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(rankColor)
                .lineLimit(1)
        }
        .padding(.vertical, isCompact ? 10 : 14)
        .padding(.horizontal, isCompact ? 12 : 16)
        .mindFlowListRowCardChrome()
    }
}

private struct WardrobeFavoriteRankingView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let categoryId: UUID

    @State private var selectedWardrobeGroup: String?
    @State private var selectedWardrobeType: String?
    @State private var selectedDetailItemId: UUID?

    private var rankedItems: [WardrobeItem] {
        viewModel.favoriteRankingItems(
            in: categoryId,
            wardrobeGroup: selectedWardrobeGroup,
            wardrobeType: selectedWardrobeType
        )
    }

    private var subtypes: [String] {
        selectedWardrobeGroup.map { WardrobeCategoryCatalog.types(in: $0) } ?? []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(WardrobeCategoryCatalog.allGroups, id: \.self) { group in
                                WardrobeFilterChip(
                                    title: group,
                                    isSelected: selectedWardrobeGroup == group
                                ) {
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
                        .padding(.horizontal, 20)
                    }

                    if !subtypes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(subtypes, id: \.self) { type in
                                    WardrobeFilterChip(
                                        title: type,
                                        isSelected: selectedWardrobeType == type
                                    ) {
                                        selectedWardrobeType = selectedWardrobeType == type ? nil : type
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }

                if rankedItems.isEmpty {
                    Text("该分类暂无衣物")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(rankedItems.enumerated()), id: \.element.id) { index, item in
                            Button {
                                selectedDetailItemId = item.id
                            } label: {
                                WardrobeFavoriteRankingRowView(rank: index + 1, item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(lifePageBackground)
        .navigationTitle("喜爱度排行")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedDetailItemId) { itemId in
            WardrobeItemDetailView(viewModel: viewModel, itemId: itemId)
        }
    }
}

private struct WardrobeTypeRankingView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let route: WardrobeRankingRoute

    @State private var selectedDetailItemId: UUID?

    private var item: WardrobeItem? {
        viewModel.wardrobeItem(withId: route.itemId)
    }

    private var rankedEntries: [(rank: Int, item: WardrobeItem)] {
        guard let item else { return [] }
        return viewModel.rankedPeers(for: item, kind: route.kind)
    }

    private var pageTitle: String {
        guard let item else { return "排名" }
        switch route.kind {
        case .price:
            return "\(item.wardrobeType) · 价格排名"
        case .wearCount:
            return "\(item.wardrobeType) · 穿着排名"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(rankedEntries, id: \.item.id) { entry in
                    Button {
                        selectedDetailItemId = entry.item.id
                    } label: {
                        WardrobeRankingRowView(
                            rank: entry.rank,
                            item: entry.item,
                            kind: route.kind,
                            isCurrent: entry.item.id == route.itemId
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(lifePageBackground)
        .navigationTitle(pageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedDetailItemId) { itemId in
            WardrobeItemDetailView(viewModel: viewModel, itemId: itemId)
        }
    }
}

private struct WardrobeRankingRowView: View {
    let rank: Int
    let item: WardrobeItem
    let kind: WardrobeRankingKind
    let isCurrent: Bool

    private var rankColor: Color {
        WardrobeRankPalette.foregroundColor(for: rank)
    }

    private var metricText: String {
        switch kind {
        case .price:
            return String(format: "¥%.0f", item.purchasePrice)
        case .wearCount:
            return "\(item.wearCount)次"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Text("#\(rank)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(rankColor)
                    .frame(width: 36, alignment: .leading)

                if WardrobeRankPalette.showsCrown(for: rank) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "#D4AF37"))
                        .offset(x: 5, y: -8)
                }
            }
            .frame(width: 36, alignment: .leading)

            Text("\(item.brand) · \(item.name)")
                .font(.body.weight(isCurrent ? .semibold : .regular))
                .foregroundStyle(rankColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(metricText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(rankColor)
        }
        .mindFlowListRowCardPadding()
        .mindFlowListRowCardChrome()
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: MindFlowListRowCardStyle.cornerRadius, style: .continuous)
                    .stroke(rankColor, lineWidth: 1.5)
            }
        }
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

private struct MindFlowToastBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(MindFlowFormSheetStyle.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .todoPanelCardChrome()
            .padding(.horizontal, 20)
    }
}

private struct OOTDRecordDatePickerSheet: View {
    @Binding var selectedDate: Date
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.horizontal, 12)

                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .background(lifePageBackground)
            .navigationTitle("记录日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") { onConfirm() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .environment(\.locale, Locale(identifier: "zh_CN"))
    }
}

private struct OOTDHistorySheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    let categoryId: UUID
    let date: Date

    @Environment(\.dismiss) private var dismiss

    private var record: OOTDHistoryRecord? {
        viewModel.ootdRecord(for: categoryId, on: date)
    }

    private var displayItems: [WardrobeItem] {
        viewModel.ootdDisplayItems(for: categoryId, on: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if displayItems.isEmpty {
                    Text("该日暂无穿着记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                } else if let record {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(OutfitSlot.allCases.enumerated()), id: \.element.id) { index, slot in
                            let items = viewModel.outfitItems(for: record.plan, slot: slot)
                            if !items.isEmpty {
                                if index > 0 {
                                    Divider().padding(.leading, 16)
                                }
                                ForEach(items) { item in
                                    OutfitPlanItemRow(item: item, onRemove: {})
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider().padding(.leading, 16)
                            }
                            OutfitPlanItemRow(item: item, onRemove: {})
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(lifePageBackground)
            .navigationTitle(date.formatted(.dateTime.year().month().day()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
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
    var showsTitle: Bool = true

    func body(content: Content) -> some View {
        content
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsTitle {
                    ToolbarItem(placement: .principal) {
                        LifeMindflowTitle()
                    }
                }
            }
    }
}

private enum WardrobeDetailChipField: Hashable {
    case brand
    case name
    case color
    case fabric
}

private var lifePageBackground: some View {
    LinearGradient(
        colors: [Color.white, Color(hex: "#d8f3dc")],
        startPoint: .top,
        endPoint: .bottom
    )
    .ignoresSafeArea()
}

private struct OutfitRankingsHubView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let categoryId: UUID
    @Binding var selectedKind: OutfitHubRankingKind?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(OutfitHubRankingKind.allCases) { kind in
                    OutfitRankingPreviewSection(
                        viewModel: viewModel,
                        categoryId: categoryId,
                        kind: kind,
                        onShowAll: { selectedKind = kind }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(lifePageBackground)
        .navigationTitle("排行榜")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct OutfitRankingPreviewSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let categoryId: UUID
    let kind: OutfitHubRankingKind
    let onShowAll: () -> Void

    private var rowSpacing: CGFloat {
        OutfitPageCardMetrics.rankingPreviewRowSpacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(kind.title)
                    .font(.headline)
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                Spacer(minLength: 8)
                Button("查看全部", action: onShowAll)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
            }
            .padding(.horizontal, 16)
            .padding(.top, OutfitPageCardMetrics.titleTopInset)
            .padding(.bottom, OutfitPageCardMetrics.favoriteRankingHeaderBottomSpacing)

            if kind.usesBrandEntries {
                let brands = Array(viewModel.outfitBrandRanking(in: categoryId).prefix(3))
                if brands.isEmpty {
                    emptyRankingPlaceholder
                } else {
                    VStack(spacing: rowSpacing) {
                        ForEach(Array(brands.enumerated()), id: \.element.id) { index, entry in
                            OutfitHubBrandRankingRowView(
                                rank: index + 1,
                                brand: entry.brand,
                                count: entry.count,
                                isCompact: true
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, OutfitPageCardMetrics.contentBottomInset)
                }
            } else {
                let items = Array(viewModel.outfitRankingItems(in: categoryId, kind: kind).prefix(3))
                if items.isEmpty {
                    emptyRankingPlaceholder
                } else {
                    VStack(spacing: rowSpacing) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            WardrobeFavoriteRankingRowView(
                                rank: index + 1,
                                item: item,
                                isCompact: true,
                                metricText: viewModel.outfitRankingMetric(for: item, kind: kind)
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, OutfitPageCardMetrics.contentBottomInset)
                }
            }
        }
        .todoPanelCardChrome()
    }

    private var emptyRankingPlaceholder: some View {
        Text("暂无数据")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, OutfitPageCardMetrics.contentBottomInset)
    }
}

private struct OutfitRankingFullListView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let categoryId: UUID
    let kind: OutfitHubRankingKind

    @State private var selectedDetailItemId: UUID?

    var body: some View {
        ScrollView {
            if kind.usesBrandEntries {
                let brands = viewModel.outfitBrandRanking(in: categoryId)
                if brands.isEmpty {
                    emptyListPlaceholder
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(brands.enumerated()), id: \.element.id) { index, entry in
                            OutfitHubBrandRankingRowView(
                                rank: index + 1,
                                brand: entry.brand,
                                count: entry.count
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                }
            } else {
                let items = viewModel.outfitRankingItems(in: categoryId, kind: kind)
                if items.isEmpty {
                    emptyListPlaceholder
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            Button {
                                selectedDetailItemId = item.id
                            } label: {
                                WardrobeFavoriteRankingRowView(
                                    rank: index + 1,
                                    item: item,
                                    metricText: viewModel.outfitRankingMetric(for: item, kind: kind)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                }
            }
        }
        .padding(.bottom, 24)
        .background(lifePageBackground)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedDetailItemId) { itemId in
            WardrobeItemDetailView(viewModel: viewModel, itemId: itemId)
        }
    }

    private var emptyListPlaceholder: some View {
        Text("暂无数据")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
    }
}

private struct OutfitHubBrandRankingRowView: View {
    let rank: Int
    let brand: String
    let count: Int
    var isCompact: Bool = false

    private var rankColor: Color {
        WardrobeRankPalette.foregroundColor(for: rank)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(isCompact ? .subheadline.weight(.bold) : .headline.weight(.bold))
                .foregroundStyle(rankColor)
                .frame(width: 32, alignment: .leading)

            Text(brand.isEmpty ? "未命名品牌" : brand)
                .font(isCompact ? .subheadline.weight(.medium) : .body.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(count)件")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(rankColor)
        }
        .padding(.vertical, isCompact ? 10 : 14)
        .padding(.horizontal, isCompact ? 12 : 16)
        .mindFlowListRowCardChrome()
    }
}

private struct OutfitResearchTimeSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("研究穿搭累计时长")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(OutfitResearchTimeStore.formattedDuration(viewModel.outfitResearchTimeSeconds))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(MindFlowFormSheetStyle.accent)

                Text("完成「穿搭」分类的待办任务后，任务计时会自动累计到这里。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(lifePageBackground)
            .navigationTitle("投入时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(280)])
    }
}

private struct OutfitPageSettingsSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("穿搭页卡片") {
                    ForEach(OutfitPageCardKind.allCases) { kind in
                        Toggle(isOn: binding(for: kind)) {
                            Text(kind.title)
                                .foregroundStyle(MindFlowFormSheetStyle.accent)
                        }
                        .tint(MindFlowFormSheetStyle.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(lifePageBackground)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func binding(for kind: OutfitPageCardKind) -> Binding<Bool> {
        Binding(
            get: { viewModel.outfitPageCardSettings.isVisible(kind) },
            set: { viewModel.setOutfitCardVisible(kind, visible: $0) }
        )
    }
}

// MARK: - ViewModel

@MainActor
class DashboardViewModel: ObservableObject {
    @Published private(set) var categories: [LifeCategory] = []
    @Published private(set) var detailItems: [LifeDetailItem] = []
    @Published private(set) var wardrobeItems: [WardrobeItem] = []
    @Published private(set) var outfitPlansByCategoryId: [UUID: OutfitPlan] = [:]
    @Published private(set) var ootdHistoryRecords: [OOTDHistoryRecord] = []
    @Published var outfitPageCardSettings = OutfitPageCardSettings()
    @Published private(set) var outfitResearchTimeSeconds: TimeInterval = OutfitResearchTimeStore.totalSeconds
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
        applyPendingOOTDWearCounts()
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

    func outfitItems(for slot: OutfitSlot, categoryId: UUID) -> [WardrobeItem] {
        outfitPlan(for: categoryId)
            .itemIds(for: slot)
            .compactMap { wardrobeItem(withId: $0) }
    }

    func outfitPlanItems(for categoryId: UUID) -> [WardrobeItem] {
        OutfitSlot.allCases.flatMap { outfitItems(for: $0, categoryId: categoryId) }
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
        plan.appendItem(item.id, for: slot)
        outfitPlansByCategoryId[item.categoryId] = plan
    }

    func removeFromOutfitPlan(_ item: WardrobeItem) {
        var plan = outfitPlan(for: item.categoryId)
        plan.removeAllReferences(to: item.id)
        outfitPlansByCategoryId[item.categoryId] = plan
    }

    @discardableResult
    func saveOutfitPlan(for categoryId: UUID, on date: Date) -> Bool {
        let plan = outfitPlan(for: categoryId)
        let items = outfitPlanItems(for: categoryId)
        guard !items.isEmpty else { return false }

        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        let shouldApplyWearCountNow = day < today

        if shouldApplyWearCountNow {
            for item in items {
                incrementWearCount(for: item.id, wearDate: day)
            }
        } else {
            for item in items {
                updateLastWearDate(for: item.id, on: day)
            }
        }

        ootdHistoryRecords.removeAll { $0.categoryId == categoryId && $0.date == day }
        ootdHistoryRecords.append(
            OOTDHistoryRecord(
                categoryId: categoryId,
                date: day,
                plan: plan,
                wearCountApplied: shouldApplyWearCountNow
            )
        )
        outfitPlansByCategoryId[categoryId] = OutfitPlan()
        return true
    }

    func applyPendingOOTDWearCounts() {
        let today = Calendar.current.startOfDay(for: Date())
        for index in ootdHistoryRecords.indices {
            var record = ootdHistoryRecords[index]
            guard !record.wearCountApplied, record.date < today else { continue }

            let items = outfitPlanDisplayItems(for: record.plan)
            for item in items {
                incrementWearCount(for: item.id, wearDate: record.date)
            }
            record.wearCountApplied = true
            ootdHistoryRecords[index] = record
        }
    }

    func ootdMarkedDates(for categoryId: UUID, in month: Date) -> Set<Date> {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }

        var dates = Set(
            ootdHistoryRecords
                .filter { $0.categoryId == categoryId && interval.contains($0.date) }
                .map(\.date)
        )

        for item in wardrobeItems(in: categoryId) {
            guard let lastWearDate = item.lastWearDate else { continue }
            let day = calendar.startOfDay(for: lastWearDate)
            if interval.contains(day) {
                dates.insert(day)
            }
        }

        return dates
    }

    func ootdRecord(for categoryId: UUID, on date: Date) -> OOTDHistoryRecord? {
        let day = Calendar.current.startOfDay(for: date)
        return ootdHistoryRecords.first { $0.categoryId == categoryId && $0.date == day }
    }

    func ootdDisplayItems(for categoryId: UUID, on date: Date) -> [WardrobeItem] {
        let day = Calendar.current.startOfDay(for: date)
        if let record = ootdRecord(for: categoryId, on: day) {
            return outfitPlanDisplayItems(for: record.plan)
        }
        return wardrobeItems(in: categoryId).filter { item in
            guard let lastWearDate = item.lastWearDate else { return false }
            return Calendar.current.startOfDay(for: lastWearDate) == day
        }
    }

    func outfitItems(for plan: OutfitPlan, slot: OutfitSlot) -> [WardrobeItem] {
        plan.itemIds(for: slot).compactMap { wardrobeItem(withId: $0) }
    }

    func outfitPlanDisplayItems(for plan: OutfitPlan) -> [WardrobeItem] {
        OutfitSlot.allCases.flatMap { outfitItems(for: plan, slot: $0) }
    }

    private func incrementWearCount(for itemId: UUID, wearDate: Date? = nil) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == itemId }) else { return }
        wardrobeItems[index].wearCount += 1
        let resolvedDate = wearDate ?? Date()
        wardrobeItems[index].lastWearDate = Calendar.current.startOfDay(for: resolvedDate)
    }

    private func updateLastWearDate(for itemId: UUID, on date: Date) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == itemId }) else { return }
        wardrobeItems[index].lastWearDate = Calendar.current.startOfDay(for: date)
    }

    func updateWardrobeBrand(id: UUID, brand: String) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == id }) else { return }
        wardrobeItems[index].brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func updateWardrobeName(id: UUID, name: String) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == id }) else { return }
        wardrobeItems[index].name = name
    }

    func updateWardrobeColor(id: UUID, color: String) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == id }) else { return }
        wardrobeItems[index].color = color.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func updateWardrobeFabric(id: UUID, fabric: String) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == id }) else { return }
        wardrobeItems[index].fabric = fabric.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func updateWardrobePurchasePrice(id: UUID, price: Double) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == id }) else { return }
        wardrobeItems[index].purchasePrice = max(0, price)
    }

    func updateWardrobePurchaseDate(id: UUID, date: Date) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == id }) else { return }
        wardrobeItems[index].purchaseDate = date
    }

    func toggleWardrobeSeason(id: UUID, label: String) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == id }) else { return }
        wardrobeItems[index].season = WardrobeSeasonCatalog.toggled(label, in: wardrobeItems[index].season)
    }

    /// 同分类 + 同品种（如所有 T 恤）的购买均价。
    func averagePurchasePrice(for item: WardrobeItem) -> Double? {
        let peers = peers(matching: item)
        guard !peers.isEmpty else { return nil }
        let total = peers.reduce(0.0) { $0 + $1.purchasePrice }
        return total / Double(peers.count)
    }

    func peers(matching item: WardrobeItem) -> [WardrobeItem] {
        wardrobeItems.filter {
            $0.categoryId == item.categoryId
                && $0.wardrobeGroup == item.wardrobeGroup
                && $0.wardrobeType == item.wardrobeType
        }
    }

    func rankedPeers(for item: WardrobeItem, kind: WardrobeRankingKind) -> [(rank: Int, item: WardrobeItem)] {
        let sorted: [WardrobeItem]
        switch kind {
        case .price:
            sorted = peers(matching: item).sorted { lhs, rhs in
                if lhs.purchasePrice != rhs.purchasePrice {
                    return lhs.purchasePrice > rhs.purchasePrice
                }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        case .wearCount:
            sorted = peers(matching: item).sorted { lhs, rhs in
                if lhs.wearCount != rhs.wearCount {
                    return lhs.wearCount > rhs.wearCount
                }
                let lhsLast = lhs.lastWearDate ?? .distantPast
                let rhsLast = rhs.lastWearDate ?? .distantPast
                if lhsLast != rhsLast {
                    return lhsLast > rhsLast
                }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        }
        return sorted.enumerated().map { (index, peer) in (index + 1, peer) }
    }

    func rankNumber(for item: WardrobeItem, kind: WardrobeRankingKind) -> Int? {
        rankedPeers(for: item, kind: kind).first(where: { $0.item.id == item.id })?.rank
    }

    func rankDisplay(for item: WardrobeItem, kind: WardrobeRankingKind) -> String {
        let ranked = rankedPeers(for: item, kind: kind)
        guard !ranked.isEmpty,
              let entry = ranked.first(where: { $0.item.id == item.id }) else {
            return "—"
        }
        return "\(entry.rank)/\(ranked.count)"
    }

    func favoriteRankingItems(
        in categoryId: UUID,
        wardrobeGroup: String? = nil,
        wardrobeType: String? = nil
    ) -> [WardrobeItem] {
        var result = wardrobeItems.filter { $0.categoryId == categoryId }
        if let wardrobeGroup {
            result = result.filter { $0.wardrobeGroup == wardrobeGroup }
        }
        if let wardrobeType {
            result = result.filter { $0.wardrobeType == wardrobeType }
        }
        return result.sorted { lhs, rhs in
            let lhsScore = lhs.favoriteScores.overallScore
            let rhsScore = rhs.favoriteScores.overallScore
            switch (lhsScore, rhsScore) {
            case let (l?, r?):
                if l != r { return l > r }
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                break
            }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }
    }

    func topFavoriteItems(for categoryId: UUID, limit: Int) -> [WardrobeItem] {
        Array(
            favoriteRankingItems(in: categoryId)
                .filter { $0.favoriteScores.overallScore != nil }
                .prefix(limit)
        )
    }

    func refreshOutfitResearchTime() {
        outfitResearchTimeSeconds = OutfitResearchTimeStore.totalSeconds
    }

    func setOutfitCardVisible(_ kind: OutfitPageCardKind, visible: Bool) {
        outfitPageCardSettings.setVisible(kind, visible: visible)
    }

    func outfitRankingItems(in categoryId: UUID, kind: OutfitHubRankingKind) -> [WardrobeItem] {
        let items = wardrobeItems(in: categoryId)
        switch kind {
        case .favorite:
            return favoriteRankingItems(in: categoryId).filter { $0.favoriteScores.overallScore != nil }
        case .price:
            return items.sorted { lhs, rhs in
                if lhs.purchasePrice != rhs.purchasePrice { return lhs.purchasePrice > rhs.purchasePrice }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        case .wearCount:
            return items.sorted { lhs, rhs in
                if lhs.wearCount != rhs.wearCount { return lhs.wearCount > rhs.wearCount }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        case .costPerWear:
            return items.sorted { lhs, rhs in
                let l = costPerWearValue(for: lhs)
                let r = costPerWearValue(for: rhs)
                if l != r { return l < r }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        case .consecutiveWearDays:
            return items.sorted { lhs, rhs in
                let l = consecutiveWearDays(for: lhs)
                let r = consecutiveWearDays(for: rhs)
                if l != r { return l > r }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        case .brandCount:
            return items
        }
    }

    func outfitBrandRanking(in categoryId: UUID) -> [OutfitBrandRankEntry] {
        let grouped = Dictionary(grouping: wardrobeItems(in: categoryId)) { item in
            let brand = item.brand.trimmingCharacters(in: .whitespacesAndNewlines)
            return brand.isEmpty ? "未命名品牌" : brand
        }
        return grouped
            .map { OutfitBrandRankEntry(brand: $0.key, count: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.brand.localizedCompare(rhs.brand) == .orderedAscending
            }
    }

    func outfitRankingMetric(for item: WardrobeItem, kind: OutfitHubRankingKind) -> String {
        switch kind {
        case .favorite:
            if let score = item.favoriteScores.overallScore { return "\(score)分" }
            return "未评分"
        case .price:
            return String(format: "¥%.0f", item.purchasePrice)
        case .wearCount:
            return "\(item.wearCount)次"
        case .costPerWear:
            let cost = costPerWearValue(for: item)
            if item.wearCount == 0 { return "—" }
            if abs(cost.rounded() - cost) < 0.05 {
                return String(format: "¥%.0f/次", cost)
            }
            return String(format: "¥%.1f/次", cost)
        case .consecutiveWearDays:
            return "\(consecutiveWearDays(for: item))天"
        case .brandCount:
            return item.brand
        }
    }

    func consecutiveWearDays(for item: WardrobeItem) -> Int {
        let calendar = Calendar.current
        let wearDates = ootdHistoryRecords
            .filter { record in
                outfitPlanDisplayItems(for: record.plan).contains { $0.id == item.id }
            }
            .map { calendar.startOfDay(for: $0.date) }
        let uniqueDates = Array(Set(wearDates)).sorted()
        guard !uniqueDates.isEmpty else { return 0 }

        var best = 1
        var current = 1
        for index in 1..<uniqueDates.count {
            let dayGap = calendar.dateComponents([.day], from: uniqueDates[index - 1], to: uniqueDates[index]).day ?? 0
            if dayGap == 1 {
                current += 1
            } else {
                best = max(best, current)
                current = 1
            }
        }
        return max(best, current)
    }

    private func costPerWearValue(for item: WardrobeItem) -> Double {
        guard item.wearCount > 0 else { return .infinity }
        return item.purchasePrice / Double(item.wearCount)
    }

    func updateFavoriteScores(id: UUID, scores: WardrobeFavoriteScores) {
        guard let index = wardrobeItems.firstIndex(where: { $0.id == id }) else { return }
        wardrobeItems[index].favoriteScores = scores
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
            let before = plan
            plan.removeAllReferences(to: id)
            if plan != before {
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
            calendar.date(from: DateComponents(year: 2025, month: 1, day: 18)) ?? .now,
            calendar.date(from: DateComponents(year: 2024, month: 8, day: 20)) ?? .now,
            calendar.date(from: DateComponents(year: 2025, month: 5, day: 2)) ?? .now,
            calendar.date(from: DateComponents(year: 2024, month: 6, day: 15)) ?? .now,
            calendar.date(from: DateComponents(year: 2025, month: 2, day: 28)) ?? .now
        ]
        let recentWearDates: [Date] = [
            calendar.date(byAdding: .day, value: -2, to: Date()) ?? .now,
            calendar.date(byAdding: .day, value: -5, to: Date()) ?? .now,
            calendar.date(byAdding: .day, value: -1, to: Date()) ?? .now,
            calendar.date(byAdding: .day, value: -12, to: Date()) ?? .now,
            calendar.date(byAdding: .day, value: -8, to: Date()) ?? .now,
            calendar.date(byAdding: .day, value: -20, to: Date()) ?? .now,
            calendar.date(byAdding: .day, value: -3, to: Date()) ?? .now
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
                wearCount: 12,
                lastWearDate: recentWearDates[0],
                favoriteScores: WardrobeFavoriteScores(
                    appearance: 86, fabricComfort: 88, fit: 84, texture: 85, personalPreference: 90
                )
            ),
            WardrobeItem(
                categoryId: clothing.id,
                name: "重磅纯棉T恤",
                wardrobeGroup: "上装",
                wardrobeType: "T恤",
                brand: "MUJI",
                color: "黑色",
                fabric: "棉",
                season: "四季",
                purchasePrice: 149,
                purchaseDate: sampleDates[3],
                wearCount: 22,
                lastWearDate: recentWearDates[1],
                favoriteScores: WardrobeFavoriteScores(
                    appearance: 92, fabricComfort: 95, fit: 90, texture: 94, personalPreference: 96
                )
            ),
            WardrobeItem(
                categoryId: clothing.id,
                name: "速干运动T恤",
                wardrobeGroup: "上装",
                wardrobeType: "T恤",
                brand: "Nike",
                color: "灰色",
                fabric: "聚酯纤维",
                season: "春夏秋",
                purchasePrice: 199,
                purchaseDate: sampleDates[4],
                wearCount: 8,
                lastWearDate: recentWearDates[2],
                favoriteScores: WardrobeFavoriteScores(
                    appearance: 90, fabricComfort: 82, fit: 88, texture: 86, personalPreference: 92
                )
            ),
            WardrobeItem(
                categoryId: clothing.id,
                name: "复古印花T恤",
                wardrobeGroup: "上装",
                wardrobeType: "T恤",
                brand: "Gap",
                color: "藏青",
                fabric: "棉",
                season: "春夏",
                purchasePrice: 129,
                purchaseDate: sampleDates[5],
                wearCount: 15,
                lastWearDate: recentWearDates[3],
                favoriteScores: WardrobeFavoriteScores(
                    appearance: 78, fabricComfort: 80, fit: 76, texture: 79, personalPreference: 82
                )
            ),
            WardrobeItem(
                categoryId: clothing.id,
                name: "基础打底T恤",
                wardrobeGroup: "上装",
                wardrobeType: "T恤",
                brand: "H&M",
                color: "米白",
                fabric: "棉",
                season: "四季",
                purchasePrice: 59,
                purchaseDate: sampleDates[6],
                wearCount: 3,
                lastWearDate: recentWearDates[4]
            ),
            WardrobeItem(
                categoryId: clothing.id,
                name: "丝光棉T恤",
                wardrobeGroup: "上装",
                wardrobeType: "T恤",
                brand: "COS",
                color: "浅灰",
                fabric: "丝光棉",
                season: "春夏",
                purchasePrice: 259,
                purchaseDate: sampleDates[2],
                wearCount: 5,
                lastWearDate: recentWearDates[5]
            ),
            WardrobeItem(
                categoryId: clothing.id,
                name: "宽松版型T恤",
                wardrobeGroup: "上装",
                wardrobeType: "T恤",
                brand: "ZARA",
                color: "军绿",
                fabric: "棉",
                season: "春夏秋",
                purchasePrice: 119,
                purchaseDate: sampleDates[1],
                wearCount: 9,
                lastWearDate: recentWearDates[6]
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
                wearCount: 5,
                lastWearDate: recentWearDates[2]
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
                wearCount: 8,
                lastWearDate: recentWearDates[3],
                favoriteScores: WardrobeFavoriteScores(
                    appearance: 84, fabricComfort: 86, fit: 88, texture: 85, personalPreference: 87
                )
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
                wearCount: 3,
                lastWearDate: recentWearDates[4],
                favoriteScores: WardrobeFavoriteScores(
                    appearance: 91, fabricComfort: 88, fit: 90, texture: 89, personalPreference: 93
                )
            )
        ]

        var samplePlan1 = OutfitPlan()
        samplePlan1.appendItem(wardrobeItems[0].id, for: .top)
        samplePlan1.appendItem(wardrobeItems[8].id, for: .bottom)
        samplePlan1.appendItem(wardrobeItems[9].id, for: .shoes)

        var samplePlan2 = OutfitPlan()
        samplePlan2.appendItem(wardrobeItems[1].id, for: .top)
        samplePlan2.appendItem(wardrobeItems[8].id, for: .bottom)

        var samplePlan3 = OutfitPlan()
        samplePlan3.appendItem(wardrobeItems[6].id, for: .top)
        samplePlan3.appendItem(wardrobeItems[9].id, for: .shoes)

        ootdHistoryRecords = [
            OOTDHistoryRecord(
                categoryId: clothing.id,
                date: calendar.date(byAdding: .day, value: -1, to: Date()) ?? .now,
                plan: samplePlan1,
                wearCountApplied: true
            ),
            OOTDHistoryRecord(
                categoryId: clothing.id,
                date: calendar.date(byAdding: .day, value: -4, to: Date()) ?? .now,
                plan: samplePlan2,
                wearCountApplied: true
            ),
            OOTDHistoryRecord(
                categoryId: clothing.id,
                date: calendar.date(byAdding: .day, value: -9, to: Date()) ?? .now,
                plan: samplePlan3,
                wearCountApplied: true
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
