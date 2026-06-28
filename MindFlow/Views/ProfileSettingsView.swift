import SwiftUI

struct ProfileSettingsView: View {
    @State private var showingResetConfirm = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color(hex: "#d8f3dc")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("个人设置")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Color(hex: "#2B5748"))
                        Text("管理你的 Mindflow 账户与偏好")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    settingsGroup(title: "账户") {
                        settingsRow(icon: "person.crop.circle", title: "个人资料")
                        settingsRow(icon: "bell", title: "通知")
                        settingsRow(icon: "lock", title: "隐私与安全")
                    }

                    settingsGroup(title: "应用") {
                        settingsRow(icon: "paintbrush", title: "外观")
                        settingsRow(icon: "icloud", title: "数据与同步")
                        Button {
                            showingResetConfirm = true
                        } label: {
                            settingsRow(icon: "trash", title: "清除所有数据", showsChevron: false)
                        }
                        .buttonStyle(.plain)
                        settingsRow(icon: "questionmark.circle", title: "帮助与反馈")
                    }

                    settingsGroup(title: "关于") {
                        settingsRow(icon: "info.circle", title: "关于 Mindflow", detail: "1.0")
                    }
                }
                .padding(.horizontal, 20)
            }
            .mindFlowScrollContentBottomInset()
        }
        .navigationBarHidden(true)
        .alert("清除所有数据？", isPresented: $showingResetConfirm) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                MindFlowRepository.shared.resetAllData()
            }
        } message: {
            Text("将删除所有分类、待办、衣物等本地数据，并恢复为初始示例数据。此操作不可撤销。")
        }
    }

    @ViewBuilder
    private func settingsGroup(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
        }
    }

    private func settingsRow(
        icon: String,
        title: String,
        detail: String? = nil,
        showsChevron: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(title == "清除所有数据" ? .red : Color(hex: "#2B5748"))
                .frame(width: 28)
            Text(title)
                .font(.body)
                .foregroundStyle(title == "清除所有数据" ? .red : Color(hex: "#2B5748"))
            Spacer()
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationView {
        ProfileSettingsView()
    }
}
