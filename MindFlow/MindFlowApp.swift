import SwiftUI

@main
struct MindFlowApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

// MARK: - Main Tab View (自定义底部导航栏)
struct MainTabView: View {
    @State private var selectedTab = 1 // 默认显示待办事项页面
    
    var body: some View {
        ZStack {
            // 全局背景渐变 - 确保覆盖整个屏幕
            LinearGradient(
                colors: [Color.white, Color(hex: "#d8f3dc")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 内容区域 - 根据底部导航栏切换页面
            Group {
                switch selectedTab {
                case 0:
                    NavigationView {
                        DashboardView()
                    }
                    .background(Color.clear)
                case 1:
                    NavigationView {
                        TodoView()
                    }
                    .background(Color.clear)
                case 2:
                    NavigationView {
                        TaskView()
                    }
                    .background(Color.clear)
                default:
                    NavigationView {
                        TodoView()
                    }
                    .background(Color.clear)
                }
            }
            .onAppear {
                // 设置导航栏背景为透明
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // 底部导航栏
            VStack {
                Spacer()
                CustomBottomNavBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Custom Bottom Navigation Bar
struct CustomBottomNavBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let buttonWidth = totalWidth / 3
            let sliderPadding: CGFloat = 8
            let sliderWidth = buttonWidth - (sliderPadding * 2)
            
            // 中间 Tab 时：滑块与中间按钮居中对齐
            let middleButtonCenter = buttonWidth + buttonWidth / 2

            // 计算滑块位置：确保在第一个和最后一个时对齐边界
            let sliderOffset: CGFloat = {
                switch selectedTab {
                case 0:
                    // 第一个：左边界对齐（滑块左边界距离背景左边界8px）
                    return sliderPadding
                case 2:
                    // 最后一个：右边界对齐（滑块右边界距离背景右边界8px）
                    return totalWidth - sliderWidth - sliderPadding
                default:
                    // 中间：按钮中心对齐
                    return middleButtonCenter - sliderWidth / 2
                }
            }()
            
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: -5)
                
                // 滑动滑块
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#2d6a4f"))
                    .frame(width: sliderWidth, height: 54)
                    .offset(x: sliderOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
                
                // 按钮层
                HStack(spacing: 0) {
                    // 领域按钮
                    BottomNavButton(
                        icon: "square.grid.2x2",
                        title: "领域",
                        isSelected: selectedTab == 0,
                        action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTab = 0
                            }
                        }
                    )
                    .frame(width: buttonWidth)
                    
                    // 待办事项按钮
                    BottomNavButton(
                        icon: "checkmark.circle",
                        title: "待办",
                        isSelected: selectedTab == 1,
                        action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTab = 1
                            }
                        }
                    )
                    .frame(width: buttonWidth)
                    
                    // 任务按钮
                    BottomNavButton(
                        icon: "list.bullet",
                        title: "任务",
                        isSelected: selectedTab == 2,
                        action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTab = 2
                            }
                        }
                    )
                    .frame(width: buttonWidth)
                }
            }
        }
        .frame(height: 70)
        .padding(.horizontal, 16)
        .padding(.bottom, 35) // 底部 padding 产生悬空感
        .background(Color.clear) // 确保GeometryReader正确计算宽度
    }
}

// MARK: - Bottom Navigation Button
struct BottomNavButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // 图标（滑块背景在ZStack中，这里只显示图标）
                Image(systemName: icon)
                    .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.white : Color.black)
                
                // 文字标签
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.white : Color.gray)
            }
            .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
    }
}
