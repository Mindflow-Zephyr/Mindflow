import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 领域页面
        NavigationView {
            DashboardView()
        }
            .tag(0)
            
            // 待办事项页面
            NavigationView {
                TodoView(showingAddTodo: .constant(false))
            }
            .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

#Preview {
    ContentView()
}
