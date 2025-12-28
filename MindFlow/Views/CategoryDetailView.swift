/*
整体结构


*/
import SwiftUI
import Combine

// MARK: - Color Extension for Hex Support
extension Color {
    /// 从十六进制字符串创建颜色
    /// 支持格式: "#FF0000" 或 "FF0000"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct CategoryDetailView: View {
    let categoryId: Int
    @StateObject private var viewModel = CategoryDetailViewModel()
    @State private var showingAddItem = false
    @State private var showingAddProperty = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let category = viewModel.category {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Category Header
                        VStack(alignment: .center, spacing: 12) {
                            Text(category.name)
                                .font(.system(size: 32, weight: .bold))
                            
                            HStack {
                                Image(systemName: "list.number")
                                Text("\(viewModel.items.count) 个商品")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Items List
                        if viewModel.items.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bag.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("还没有商品")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("点击 + 添加第一个商品")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                                    ItemCardViewWrapper(
                                        item: item,
                                        onDelete: {
                                            Task {
                                                await viewModel.deleteItem(item.id)
                                            }
                                        },
                                        onUpdateColorTier: { tier in
                                            Task {
                                                await viewModel.updateColorTier(itemId: item.id, tier: tier)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddItem = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .refreshable {
            await viewModel.loadData(categoryId: categoryId)
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView(categoryId: categoryId, viewModel: viewModel)
        }
        .task {
            await viewModel.loadData(categoryId: categoryId)
        }
    }
}

// MARK: - Item Card View Wrapper (for swipe actions)
struct ItemCardViewWrapper: View {
    let item: Item
    let onDelete: () -> Void
    let onUpdateColorTier: (String) -> Void
    
    @State private var showingEdit = false
    
    var body: some View {
        ItemCardView(
            item: item,
            onDelete: onDelete,
            onUpdateColorTier: onUpdateColorTier,
            showEdit: $showingEdit
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
            
            Button {
                showingEdit = true
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

// MARK: - Item Card View
struct ItemCardView: View {
    let item: Item
    let onDelete: () -> Void
    let onUpdateColorTier: (String) -> Void
    @Binding var showEdit: Bool
    
    @State private var showingColorTierPicker = false
    @State private var showingDeleteAlert = false
    @State private var isExpanded = false
    
    
    // MARK: - 商品名颜色配置（根据颜色等级返回深色版本）
    // 在这里可以修改每个等级对应的商品名颜色
    var itemNameColor: Color {
        switch item.colorTier {
        case "gold": // 完美 - 金色深色版本
            return Color(hex: "#76520e")  // 深金色
        case "purple": // 优秀 - 紫色深色版本
            return Color(hex: "#5a189a")  // 深紫色
        case "blue": // 普通 - 蓝色深色版本
            return Color(hex: "#023e8a")  // 深蓝色
        default: // gray - 劣质 - 灰色深色版本
            return Color(hex: "#212529")  // 深灰色
        }
    }
    
    // MARK: - 渐变颜色配置
    // 在这里可以修改每个等级的颜色渐变
    // 返回数组中的第一个颜色是顶部颜色，第二个是底部颜色
    // 
    // 使用方式：
    // 1. 使用 Hex 格式（推荐）：Color(hex: "#FFD700") 或 Color(hex: "FFD700")
    // 2. 使用 RGB 格式：Color(red: 1.0, green: 0.84, blue: 0.0)
    // 
    // Hex 颜色值示例：
    // - 金色：#FFD700, #FFA500
    // - 紫色：#9D4EDD, #6A1B9A
    // - 蓝色：#4A90E2, #2E5C8A
    // - 灰色：#808080, #4A4A4A
    var gradientColors: [Color] {
        switch item.colorTier {
        case "gold": // 完美 - 金色渐变
            // 可以修改这两个颜色来改变金色渐变
            // 格式：Color(hex: "#颜色代码")
            return [
                Color(hex: "#f9dc5c"),  // 顶部：亮金色 (#FFD700)
                Color(hex: "#ffe97f")   // 底部：深金色 (#FFA500)
            ]
        case "purple": // 优秀 - 紫色渐变
            // 可以修改这两个颜色来改变紫色渐变
            return [
                Color(hex: "#c19ee0"),  // 顶部：亮紫色 (#9D4EDD)
                Color(hex: "#dec9e9")   // 底部：深紫色 (#6A1B9A)
            ]
        case "blue": // 普通 - 蓝色渐变
            // 可以修改这两个颜色来改变蓝色渐变
            return [
                Color(hex: "#0096c7"),  // 顶部：亮蓝色 (#4A90E2)
                Color(hex: "#ade8f4")   // 底部：深蓝色 (#2E5C8A)
            ]
        default: // gray - 劣质 - 灰色渐变
            // 可以修改这两个颜色来改变灰色渐变
            return [
                Color(hex: "#6C757D"),  // 顶部：浅灰色 (#808080)
                Color(hex: "#a6a2a2")   // 底部：深灰色 (#4A4A4A)
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    // 品牌名（如果有）
                    if let brand = item.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(itemNameColor)
                        
                        // 商品名
                        Text(item.name)
                            .font(.headline)
                            .foregroundColor(itemNameColor)
                    } else {
                        // 如果没有品牌名，只显示商品名
                        Text(item.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(itemNameColor)
                    }
                }
                
                Spacer()
                
                // 展开/收起箭头（在右侧，使用与商品名相同的颜色）
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(itemNameColor)
                        .frame(width: 28, height: 28)
                }
            }
            
            // 展开时显示详情
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let price = item.price {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                            Text(price)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    if let notes = item.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(nil)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 100) // 增加最小高度
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,      // 渐变从左上角开始
                endPoint: .bottomTrailing      // 渐变到右下角结束
            )
            .opacity(0.3)  // 增加透明度，可以调整这个值（0.0-1.0）
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
        .sheet(isPresented: $showingColorTierPicker) {
            ColorTierPickerView(
                currentTier: item.colorTier,
                onSelect: { tier in
                    onUpdateColorTier(tier)
                    showingColorTierPicker = false
                }
            )
        }
        .onChange(of: showEdit, initial: false) { _, newValue in
            if newValue {
                showingColorTierPicker = true
                showEdit = false
            }
        }
    }
}

// MARK: - Color Tier Badge
struct ColorTierBadge: View {
    let tier: String
    
    var tierInfo: (name: String, color: Color) {
        switch tier {
        case "gold": return ("完美", .yellow)
        case "purple": return ("优秀", Color(red: 0.6, green: 0.3, blue: 0.9))
        case "blue": return ("普通", .blue)
        default: return ("劣质", .gray)
        }
    }
    
    var body: some View {
        Text(tierInfo.name)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tierInfo.color)
            .cornerRadius(8)
    }
}

// MARK: - Color Tier Picker
struct ColorTierPickerView: View {
    let currentTier: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    let tiers = [
        ("gold", "完美", Color.yellow),
        ("purple", "优秀", Color(red: 0.6, green: 0.3, blue: 0.9)),
        ("blue", "普通", Color.blue),
        ("gray", "劣质", Color.gray)
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tiers, id: \.0) { tier, name, color in
                    Button(action: {
                        onSelect(tier)
                    }) {
                        HStack {
                            Circle()
                                .fill(color)
                                .frame(width: 20, height: 20)
                            Text(name)
                                .foregroundColor(.primary)
                            Spacer()
                            if currentTier == tier {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择等级")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Item View
struct AddItemView: View {
    let categoryId: Int
    @ObservedObject var viewModel: CategoryDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var price = ""
    @State private var notes = ""
    @State private var colorTier = "gray"
    
    var body: some View {
        NavigationView {
            Form {
                Section("商品信息") {
                    TextField("商品名称", text: $name)
                    TextField("价格（可选）", text: $price)
                        .keyboardType(.decimalPad)
                    TextField("备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("等级") {
                    Picker("等级", selection: $colorTier) {
                        Text("完美").tag("gold")
                        Text("优秀").tag("purple")
                        Text("普通").tag("blue")
                        Text("劣质").tag("gray")
                    }
                }
            }
            .navigationTitle("添加商品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        Task {
                            await viewModel.addItem(
                                name: name,
                                price: price.isEmpty ? nil : price,
                                notes: notes.isEmpty ? nil : notes,
                                colorTier: colorTier
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - ViewModel
@MainActor
class CategoryDetailViewModel: ObservableObject {
    @Published var category: Category?
    @Published var items: [Item] = []
    @Published var properties: [CategoryProperty] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadData(categoryId: Int) async {
        isLoading = true
        errorMessage = nil
        
        async let categoryTask = apiClient.getCategory(id: categoryId)
        async let itemsTask = apiClient.getItems(categoryId: categoryId)
        async let propertiesTask = apiClient.getProperties(categoryId: categoryId)
        
        do {
            category = try await categoryTask
            items = try await itemsTask
            properties = try await propertiesTask
            sortItems()
        } catch {
            errorMessage = (error as? APIError)?.message ?? "加载失败"
            print("Error loading data: \(error)")
        }
        
        isLoading = false
    }
    
    func addItem(name: String, price: String?, notes: String?, colorTier: String) async {
        let request = CreateItemRequest(
            name: name,
            brand: nil,
            categoryId: category?.id ?? 0,
            price: price,
            colorTier: colorTier,
            notes: notes,
            properties: nil
        )
        
        do {
            let newItem = try await apiClient.createItem(request)
            items.append(newItem)
            sortItems()
        } catch {
            errorMessage = (error as? APIError)?.message ?? "添加失败"
            print("Error adding item: \(error)")
        }
    }
    
    func deleteItem(_ itemId: Int) async {
        do {
            try await apiClient.deleteItem(id: itemId)
            items.removeAll { $0.id == itemId }
        } catch {
            errorMessage = (error as? APIError)?.message ?? "删除失败"
            print("Error deleting item: \(error)")
        }
    }
    
    func updateColorTier(itemId: Int, tier: String) async {
        do {
            let updatedItem = try await apiClient.updateItemColorTier(id: itemId, colorTier: tier)
            if let index = items.firstIndex(where: { $0.id == itemId }) {
                items[index] = updatedItem
            }
            sortItems()
        } catch {
            errorMessage = (error as? APIError)?.message ?? "更新失败"
            print("Error updating color tier: \(error)")
        }
    }
    
    func moveItemUp(at index: Int) async {
        guard index > 0 else { return }
        await swapRanks(at: index, with: index - 1)
    }
    
    func moveItemDown(at index: Int) async {
        guard index < items.count - 1 else { return }
        await swapRanks(at: index, with: index + 1)
    }
    
    private func swapRanks(at index1: Int, with index2: Int) async {
        let item1 = items[index1]
        let item2 = items[index2]
        
        let rank1 = item1.rank
        let rank2 = item2.rank
        
        do {
            _ = try await apiClient.updateItemRank(id: item1.id, rank: rank2)
            _ = try await apiClient.updateItemRank(id: item2.id, rank: rank1)
            
            // Reload items to get updated order
            if let categoryId = category?.id {
                items = try await apiClient.getItems(categoryId: categoryId)
                sortItems()
            }
        } catch {
            errorMessage = (error as? APIError)?.message ?? "移动失败"
            print("Error swapping ranks: \(error)")
        }
    }
    
    private func sortItems() {
        items.sort { item1, item2 in
            let rank1 = item1.rank
            let rank2 = item2.rank
            if rank1 != rank2 {
                return rank1 < rank2
            }
            // If ranks are equal, sort by color tier
            let tierOrder: [String: Int] = ["gold": 1, "purple": 2, "blue": 3, "gray": 4]
            let order1 = tierOrder[item1.colorTier] ?? 4
            let order2 = tierOrder[item2.colorTier] ?? 4
            if order1 != order2 {
                return order1 < order2
            }
            return item1.id < item2.id
        }
    }
}

#Preview {
    NavigationView {
        CategoryDetailView(categoryId: 1)
    }
}

