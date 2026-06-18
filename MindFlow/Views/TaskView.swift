import SwiftUI
import Combine

struct TaskView: View {
    @Binding var showingAddTask: Bool
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingAddSubtask = false

    init(showingAddTask: Binding<Bool> = .constant(false)) {
        _showingAddTask = showingAddTask
    }
    
    var body: some View {
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
                        Text("化繁为简于每一个目标")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Task List
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if viewModel.rootTasks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checklist")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("还没有任务")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("创建一个开始吧")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.rootTasks) { task in
                                TaskItemView(
                                    viewModel: viewModel,
                                    task: task,
                                    level: 0
                                )
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
            await viewModel.loadTasks()
        }
        .task {
            await viewModel.loadTasks()
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: viewModel, parentId: nil)
        }
        .sheet(isPresented: $showingAddSubtask) {
            if let parentId = viewModel.addingSubtaskTo {
                AddTaskView(viewModel: viewModel, parentId: parentId)
            }
        }
        .onChange(of: viewModel.addingSubtaskTo, initial: false) { _, newValue in
            showingAddSubtask = newValue != nil
        }
        .onChange(of: showingAddSubtask, initial: false) { _, isShowing in
            if !isShowing {
                viewModel.addingSubtaskTo = nil
            }
        }
    }
}

// MARK: - Task Item View (递归显示任务和子任务)
struct TaskItemView: View {
    @ObservedObject var viewModel: TaskViewModel
    let task: TaskItem
    let level: Int
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主任务项
            HStack(spacing: 12) {
                // 缩进（根据层级）
                if level > 0 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .padding(.leading, CGFloat((level - 1) * 20))
                }
                
                Button(action: {
                    Task {
                        await viewModel.toggleTask(task.id)
                    }
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                    
                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // 如果有子任务，显示展开/收起按钮
                if !task.subtasks.isEmpty {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                task.isCompleted 
                    ? Color.green.opacity(0.15)  // 完成的任务高亮显示
                    : Color(.systemBackground)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    Task {
                        await viewModel.showAddSubtask(parentId: task.id)
                    }
                } label: {
                    Label("添加子任务", systemImage: "plus")
                }
                .tint(.blue)
                
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteTask(task.id)
                    }
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
            
            // 子任务列表（递归显示）
            if isExpanded && !task.subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(task.subtasks) { subtask in
                        TaskItemView(
                            viewModel: viewModel,
                            task: subtask,
                            level: level + 1
                        )
                    }
                }
                .padding(.leading, CGFloat(level * 20))
            }
        }
    }
}

// MARK: - Task Model
struct TaskItem: Identifiable, Codable {
    let id: Int
    var title: String
    var description: String?
    var isCompleted: Bool
    var parentId: Int?
    var subtasks: [TaskItem]
    
    init(id: Int, title: String, description: String? = nil, isCompleted: Bool = false, parentId: Int? = nil, subtasks: [TaskItem] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.parentId = parentId
        self.subtasks = subtasks
    }
}

// MARK: - Task ViewModel
@MainActor
class TaskViewModel: ObservableObject {
    @Published var allTasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var addingSubtaskTo: Int? = nil
    
    var rootTasks: [TaskItem] {
        buildTaskTree()
    }
    
    private var nextTaskId = 1
    
    // 构建任务树（包含子任务）
    private func buildTaskTree() -> [TaskItem] {
        let rootTasks = allTasks.filter { $0.parentId == nil }
        return rootTasks.map { buildSubtree($0) }
    }
    
    private func buildSubtree(_ task: TaskItem) -> TaskItem {
        let subtasks = allTasks.filter { $0.parentId == task.id }
        var taskWithSubtasks = task
        taskWithSubtasks.subtasks = subtasks.map { buildSubtree($0) }
        return taskWithSubtasks
    }
    
    func loadTasks() async {
        isLoading = true
        errorMessage = nil
        
        // 使用模拟数据（扁平结构）
        allTasks = [
            TaskItem(id: 1, title: "完成项目开发", description: "主要项目任务", isCompleted: false, parentId: nil),
            TaskItem(id: 2, title: "设计阶段", description: "完成UI设计", isCompleted: true, parentId: 1),
            TaskItem(id: 3, title: "设计首页", isCompleted: true, parentId: 2),
            TaskItem(id: 4, title: "设计详情页", isCompleted: false, parentId: 2),
            TaskItem(id: 5, title: "开发阶段", description: "实现功能", isCompleted: false, parentId: 1),
            TaskItem(id: 6, title: "准备演示", description: nil, isCompleted: false, parentId: nil)
        ]
        nextTaskId = 7
        
        isLoading = false
    }
    
    func toggleTask(_ id: Int) async {
        if let index = allTasks.firstIndex(where: { $0.id == id }) {
            allTasks[index].isCompleted.toggle()
            // 如果完成父任务，也完成所有子任务
            if allTasks[index].isCompleted {
                markSubtasksCompleted(id: id)
            }
        }
    }
    
    private func markSubtasksCompleted(id: Int) {
        let childTasks = allTasks.filter { $0.parentId == id }
        for childTask in childTasks {
            if let index = allTasks.firstIndex(where: { $0.id == childTask.id }) {
                allTasks[index].isCompleted = true
                markSubtasksCompleted(id: childTask.id)
            }
        }
    }
    
    func deleteTask(_ id: Int) async {
        // 删除任务及其所有子任务
        var idsToDelete = [id]
        var currentId = id
        
        // 收集所有子任务ID
        while !idsToDelete.isEmpty {
            currentId = idsToDelete.removeFirst()
            let childIds = allTasks.filter { $0.parentId == currentId }.map { $0.id }
            idsToDelete.append(contentsOf: childIds)
            allTasks.removeAll { $0.id == currentId }
        }
    }
    
    func showAddSubtask(parentId: Int) async {
        addingSubtaskTo = parentId
    }
    
    func createTask(title: String, description: String?, parentId: Int?) async -> Bool {
        let newTask = TaskItem(
            id: nextTaskId,
            title: title,
            description: description,
            isCompleted: false,
            parentId: parentId,
            subtasks: []
        )
        nextTaskId += 1
        
        if let parentId = parentId {
            addSubtaskRecursive(&allTasks, parentId: parentId, task: newTask)
        } else {
            allTasks.append(newTask)
        }
        
        return true
    }
    
    private func addSubtaskRecursive(_ tasks: inout [TaskItem], parentId: Int, task: TaskItem) {
        for index in tasks.indices {
            if tasks[index].id == parentId {
                tasks[index].subtasks.append(task)
                return
            }
            if !tasks[index].subtasks.isEmpty {
                addSubtaskRecursive(&tasks[index].subtasks, parentId: parentId, task: task)
            }
        }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @ObservedObject var viewModel: TaskViewModel
    let parentId: Int?
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(parentId == nil ? "任务信息" : "子任务信息") {
                    TextField("任务标题", text: $title)
                    TextField("描述（可选）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(parentId == nil ? "新建任务" : "新建子任务")
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
                                let success = await viewModel.createTask(
                                    title: title,
                                    description: description.isEmpty ? nil : description,
                                    parentId: parentId
                                )
                                isCreating = false
                                if success {
                                    try? await Task.sleep(nanoseconds: 100_000_000)
                                    dismiss()
                                    if parentId != nil {
                                        viewModel.addingSubtaskTo = nil
                                    }
                                }
                            }
                        }
                        .disabled(title.isEmpty)
                    }
                }
            }
        }
    }
}

