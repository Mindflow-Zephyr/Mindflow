import SwiftUI

/// 生活页列表行卡片（详情条目、今日穿搭等）统一外观。
enum MindFlowListRowCardStyle {
    static let cornerRadius: CGFloat = 12
    static let background = Color(.systemBackground)
    static let shadowColor = Color(hex: "#1b4332").opacity(0.22)
    static let shadowRadius: CGFloat = 4
    static let shadowY: CGFloat = 2
    static let leadingPadding: CGFloat = 16
    static let trailingPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 16
}

extension View {
    func mindFlowListRowCardChrome() -> some View {
        background(MindFlowListRowCardStyle.background)
            .cornerRadius(MindFlowListRowCardStyle.cornerRadius)
            .shadow(
                color: MindFlowListRowCardStyle.shadowColor,
                radius: MindFlowListRowCardStyle.shadowRadius,
                x: 0,
                y: MindFlowListRowCardStyle.shadowY
            )
    }

    func mindFlowListRowCardPadding() -> some View {
        padding(.vertical, MindFlowListRowCardStyle.verticalPadding)
            .padding(.leading, MindFlowListRowCardStyle.leadingPadding)
            .padding(.trailing, MindFlowListRowCardStyle.trailingPadding)
    }
}
