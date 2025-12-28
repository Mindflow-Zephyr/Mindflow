import SwiftUI
import Combine

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingCreateCategory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.white, Color(hex: "#d8f3dc")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .center, spacing: 8) {
                            Text("Mindflow")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                            Text("登峰造极于每一个领域")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Categories Grid
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.orange)
                                Text("无法连接到服务器")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                Text("请确保后端服务器正在运行在 http://localhost:5000")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else if viewModel.categories.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("还没有领域")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("创建一个开始吧")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(viewModel.categories) { category in
                                    NavigationLink(destination: CategoryDetailView(categoryId: category.id)) {
                                        CategoryCard(category: category)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100) // 为底部导航栏留出空间
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadCategories()
            }
            .sheet(isPresented: $showingCreateCategory) {
                CreateCategoryView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadCategories()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateCategory = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
            }
        }
    }
}

struct CategoryCard: View {
    let category: Category
    
    // 根据领域ID生成不同的背景颜色
    var cardBackground: LinearGradient {
        let colors: [(Color, Color)] = [
            (Color(hex: "#FF6B6B"), Color(hex: "#FF8E8E")),  // 红色渐变
            (Color(hex: "#4ECDC4"), Color(hex: "#6EDDD6")),  // 青色渐变
            (Color(hex: "#95E1D3"), Color(hex: "#B8F0E3")),  // 薄荷绿渐变
            (Color(hex: "#F38181"), Color(hex: "#F9A8A8")),  // 粉红渐变
            (Color(hex: "#AA96DA"), Color(hex: "#C4B5E8")),  // 紫色渐变
            (Color(hex: "#FCBAD3"), Color(hex: "#FDD4E3")),  // 淡粉渐变
            (Color(hex: "#A8E6CF"), Color(hex: "#C4F0DC")),  // 绿色渐变
            (Color(hex: "#FFD3A5"), Color(hex: "#FFE0B8"))   // 橙色渐变
        ]
        
        let index = category.id % colors.count
        let (color1, color2) = colors[index]
        
        return LinearGradient(
            colors: [color1, color2],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
                Text(category.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - ViewModel
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadCategories() async {
        await MainActor.run {
        isLoading = true
        errorMessage = nil
        }
        
        do {
            let loadedCategories = try await apiClient.getCategories()
            await MainActor.run {
                categories = loadedCategories
                print("✅ Loaded \(loadedCategories.count) categories")
                print("Categories: \(loadedCategories.map { $0.name })")
            }
        } catch {
            await MainActor.run {
            errorMessage = (error as? APIError)?.message ?? "加载失败"
                print("❌ Error loading categories: \(error)")
            }
        }
        
        await MainActor.run {
        isLoading = false
        }
    }
    
    func createCategory(name: String, description: String?, icon: String?) async -> Bool {
        let request = CreateCategoryRequest(
            name: name,
            description: description,
            parentId: nil,
            icon: icon ?? "📁"
        )
        
        do {
            print("Creating category: \(name)")
            let newCategory = try await apiClient.createCategory(request)
            print("Category created successfully: \(newCategory)")
            // 创建成功后重新加载领域列表，确保数据同步
            await loadCategories()
            print("Categories reloaded. Count: \(categories.count)")
            return true
        } catch {
            errorMessage = (error as? APIError)?.message ?? "创建失败"
            print("Error creating category: \(error)")
            return false
        }
    }
}

// MARK: - Create Category View
struct CreateCategoryView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var icon = "📁"
    @State private var isCreating = false
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("领域信息") {
                    TextField("领域名称", text: $name)
                    TextField("描述（可选）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("图标", text: $icon)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("新建领域")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isCreating {
                        ProgressView()
                    } else {
                    Button("创建") {
                            Task { @MainActor in
                                isCreating = true
                                viewModel.errorMessage = nil
                                let success = await viewModel.createCategory(
                                name: name,
                                description: description.isEmpty ? nil : description,
                                icon: icon
                            )
                                isCreating = false
                                if success {
                                    // 稍微延迟一下，确保 UI 更新完成
                                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                            dismiss()
                                }
                            }
                        }
                        .disabled(name.isEmpty)
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}

