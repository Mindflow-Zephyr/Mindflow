import SwiftUI

@main
struct MindFlowApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

// MARK: - 底部导航 Tab（中间为新建，不切换页面）
enum MainTab: Int, CaseIterable {
    case dashboard = 0
    case todo = 1
    case add = 2
    case task = 3
    case profile = 4

    var icon: String {
        switch self {
        case .dashboard: return "house"
        case .todo: return "checklist"
        case .add: return "plus"
        case .task: return "list.bullet"
        case .profile: return "person"
        }
    }

    var title: String {
        switch self {
        case .dashboard: return "领域"
        case .todo: return "待办"
        case .add: return ""
        case .task: return "任务"
        case .profile: return "我的"
        }
    }

    var isNavigable: Bool {
        self != .add
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: MainTab = .todo
    @State private var showingAddTodo = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color(hex: "#d8f3dc")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Group {
                switch selectedTab {
                case .dashboard:
                    NavigationView { DashboardView() }
                case .todo, .add:
                    NavigationView { TodoView(showingAddTodo: $showingAddTodo) }
                case .task:
                    NavigationView { TaskView() }
                case .profile:
                    NavigationView { ProfileSettingsView() }
                }
            }
            .background(Color.clear)
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }

            VStack {
                Spacer()
                CustomBottomNavBar(
                    selectedTab: $selectedTab,
                    onAddTapped: openAddTodo
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func openAddTodo() {
        withAnimation(tabSpring) {
            selectedTab = .todo
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                showingAddTodo = true
            }
        }
    }

    private var tabSpring: Animation {
        .spring(response: 0.46, dampingFraction: 0.76, blendDuration: 0.12)
    }
}

// MARK: - 参考 EverSync 样式的底部导航（配色为 Mindflow 绿）
private enum BottomNavStyle {
    static let barBackground = Color.white
    static let inactiveCircle = Color(hex: "#F0F0F0")
    static let iconMuted = Color(hex: "#6B7280")
    static let accent = Color(hex: "#2d6a4f")
    static let accentDark = Color(hex: "#1b4332")
    static let accentLight = Color(hex: "#d8f3dc")
}

struct CustomBottomNavBar: View {
    @Binding var selectedTab: MainTab
    var onAddTapped: () -> Void
    @Namespace private var selectionCapsule

    private let barHeight: CGFloat = 72
    private let barInset: CGFloat = 3
    private let itemSpacing: CGFloat = 3

    private var itemHeight: CGFloat { barHeight - barInset * 2 }

    private var tabSpring: Animation {
        .spring(response: 0.46, dampingFraction: 0.76, blendDuration: 0.12)
    }

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            HStack(spacing: itemSpacing) {
                sideTabButton(.todo)
                sideTabButton(.dashboard)
                centerAddButton()
                sideTabButton(.task)
                sideTabButton(.profile)
            }
            .padding(.horizontal, barInset)
            .padding(.vertical, barInset)
            .frame(height: barHeight)
            .background(
                Capsule(style: .continuous)
                    .fill(BottomNavStyle.barBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 5)
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 46)
    }

    private func expandedWidth(for tab: MainTab) -> CGFloat {
        switch tab.title.count {
        case 0: return itemHeight
        case 1: return itemHeight + 54
        case 2: return itemHeight + 66
        default: return itemHeight + 74
        }
    }

    @ViewBuilder
    private func sideTabButton(_ tab: MainTab) -> some View {
        let isSelected = selectedTab == tab
        Button {
            withAnimation(tabSpring) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: isSelected ? 19 : 0) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .frame(
                        width: isSelected ? 22 : itemHeight,
                        height: itemHeight
                    )

                Text(tab.title)
                    .font(.system(size: 20, weight: .semibold))
                    .tracking(1.6)
                    .lineLimit(1)
                    .opacity(isSelected ? 1 : 0)
                    .frame(width: isSelected ? nil : 0, alignment: .leading)
                    .clipped()
            }
            .foregroundStyle(isSelected ? BottomNavStyle.accentDark : BottomNavStyle.iconMuted)
            .padding(.leading, isSelected ? 10 : 0)
            .padding(.trailing, isSelected ? 20 : 0)
            .frame(width: isSelected ? expandedWidth(for: tab) : itemHeight, height: itemHeight)
            .background {
                ZStack {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(BottomNavStyle.accentLight)
                            .matchedGeometryEffect(id: "tabSelection", in: selectionCapsule)
                    } else {
                        Circle()
                            .fill(BottomNavStyle.inactiveCircle)
                    }
                }
            }
            .clipShape(Capsule(style: .continuous))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(tabSpring, value: isSelected)
    }

    private func centerAddButton() -> some View {
        Button(action: onAddTapped) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: itemHeight, height: itemHeight)
                .background(
                    Circle()
                        .fill(BottomNavStyle.accent)
                )
        }
        .buttonStyle(.plain)
    }
}
