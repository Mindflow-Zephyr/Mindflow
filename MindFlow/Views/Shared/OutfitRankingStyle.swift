import SwiftUI

// MARK: - 排行榜样式说明
//
// 本文件集中维护两种排行榜视觉样式，修改一处即可同步所有对应入口：
//
// 1. 简略排行榜（Preview）— `OutfitRankingPreview*`
//    仅展示前三名，用于穿搭页喜爱度卡片、排行榜 Hub 各榜预览等。
//
// 2. 完整排行榜（Full）— `OutfitRankingFull*`
//    展示全部排名，用于 Hub 详情页、喜爱度完整页、衣物同类排名页等。
//    衣物榜：Top3 特色大卡 + 第 4 名起独立列表行；品牌榜：放大版简略行。

// MARK: - Preview Metrics

enum OutfitRankingPreviewMetrics {
    /// 简略排行榜标题距卡片顶部的统一内边距（穿搭页与 Hub 页共用）
    static let titleTopInset: CGFloat = 16
    static let headerBottomSpacing: CGFloat = 12
    static let rowVerticalPadding: CGFloat = 14
    static let rowHeight: CGFloat = 56
    static let contentBottomInset: CGFloat = 8
}

enum OutfitRankingPreviewRankColor {
    static func color(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(hex: "#C4A035")
        case 2: return Color(hex: "#3A9491")
        case 3: return Color(hex: "#E8954A")
        default: return Color(hex: "#9CA3AF")
        }
    }
}

enum OutfitRankingPreviewTypography {
    static func rankDigit(rank: Int) -> Font {
        let size: CGFloat = rank == 1 ? 36 : 32
        return .custom("Didot-Bold", size: size)
    }
}

enum OutfitRankingRankPalette {
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
}

// MARK: - Preview Row Data

struct OutfitRankingPreviewRowData: Identifiable {
    let id: String
    let rank: Int
    let title: String
    let metricText: String

    static func wardrobeItem(
        rank: Int,
        item: WardrobeItem,
        kind: OutfitHubRankingKind,
        metricValue: Int
    ) -> Self {
        Self(
            id: item.id.uuidString,
            rank: rank,
            title: "\(item.brand.isEmpty ? "未命名品牌" : item.brand) · \(item.name)",
            metricText: metricDisplayText(for: kind, value: metricValue)
        )
    }

    static func favoriteItem(rank: Int, item: WardrobeItem) -> Self {
        let metricText: String
        if let score = item.favoriteScores.overallScore {
            metricText = "\(score)分"
        } else {
            metricText = "未评分"
        }
        return Self(
            id: item.id.uuidString,
            rank: rank,
            title: "\(item.brand.isEmpty ? "未命名品牌" : item.brand) · \(item.name)",
            metricText: metricText
        )
    }

    static func brand(rank: Int, brand: String, count: Int) -> Self {
        Self(
            id: brand,
            rank: rank,
            title: brand.isEmpty ? "未命名品牌" : brand,
            metricText: "\(count)件"
        )
    }

    private static func metricDisplayText(for kind: OutfitHubRankingKind, value: Int) -> String {
        switch kind {
        case .price, .costPerWear:
            return "¥\(value)"
        case .favorite:
            return "\(value)分"
        case .wearCount:
            return "\(value)次"
        case .consecutiveWearDays:
            return "\(value)天"
        case .brandCount:
            return "\(value)件"
        }
    }
}

// MARK: - Preview Header

enum OutfitRankingPreviewHeaderTrailing {
    case none
    case chevron
    case chevronButton(action: () -> Void)
}

// MARK: - Preview Row

struct OutfitRankingPreviewRow: View {
    let rank: Int
    let title: String
    let metricText: String
    var showBottomDivider: Bool = true

    private var rankColor: Color {
        OutfitRankingPreviewRankColor.color(for: rank)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                Text(String(format: "%02d", rank))
                    .font(OutfitRankingPreviewTypography.rankDigit(rank: rank))
                    .foregroundStyle(rankColor)
                    .frame(width: 46, alignment: .leading)

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(hex: "#1A1A1A"))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(metricText)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(rankColor)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, OutfitRankingPreviewMetrics.rowVerticalPadding)

            if showBottomDivider {
                Rectangle()
                    .fill(Color(hex: "#E8E8E8"))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Preview Card

struct OutfitRankingPreviewCard: View {
    let title: String
    var headerTrailing: OutfitRankingPreviewHeaderTrailing = .none
    let emptyMessage: String
    let rows: [OutfitRankingPreviewRowData]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if rows.isEmpty {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        OutfitRankingPreviewRow(
                            rank: row.rank,
                            title: row.title,
                            metricText: row.metricText,
                            showBottomDivider: index < rows.count - 1
                        )
                    }
                }
                .padding(.bottom, OutfitRankingPreviewMetrics.contentBottomInset)
            }
        }
        .todoPanelCardChrome()
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color(hex: "#2B5748"))

            Spacer(minLength: 8)

            switch headerTrailing {
            case .none:
                EmptyView()
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            case .chevronButton(let action):
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, OutfitRankingPreviewMetrics.titleTopInset)
        .padding(.bottom, OutfitRankingPreviewMetrics.headerBottomSpacing)
    }
}

// MARK: - Full Page Header

struct OutfitRankingFullPageHeader: View {
    let kind: OutfitHubRankingKind
    @Binding var selectedWardrobeGroup: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(kind.title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#2B5748"))
                    .fixedSize(horizontal: false, vertical: true)
                Text(kind.detailSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button("全部分类") {
                    selectedWardrobeGroup = nil
                }
                ForEach(WardrobeCategoryCatalog.allGroups, id: \.self) { group in
                    Button(group) {
                        selectedWardrobeGroup = group
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedWardrobeGroup ?? "全部分类")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .foregroundColor(Color(hex: "#2B5748"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Full Item Ranking Body

struct OutfitRankingFullItemRankingBody: View {
    let kind: OutfitHubRankingKind
    let items: [WardrobeItem]
    let metricValue: (WardrobeItem) -> Int
    let onSelect: (UUID) -> Void
    var highlightItemId: UUID?
    var listLimit: Int = 7

    var body: some View {
        if items.isEmpty {
            Text("暂无数据")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        } else {
            VStack(spacing: 12) {
                OutfitRankingFullTopThreeSection(
                    items: Array(items.prefix(3)),
                    kind: kind,
                    metricValue: metricValue,
                    onSelect: onSelect,
                    highlightItemId: highlightItemId
                )

                if items.count > 3 {
                    OutfitRankingFullListSection(
                        items: Array(items.dropFirst(3).prefix(listLimit)),
                        startRank: 4,
                        kind: kind,
                        metricValue: metricValue,
                        onSelect: onSelect,
                        highlightItemId: highlightItemId
                    )
                }
            }
        }
    }
}

// MARK: - Full Brand Ranking Body

struct OutfitRankingFullBrandRankingBody: View {
    let entries: [OutfitBrandRankEntry]

    var body: some View {
        if entries.isEmpty {
            Text("暂无数据")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    OutfitRankingPreviewRow(
                        rank: index + 1,
                        title: entry.brand.isEmpty ? "未命名品牌" : entry.brand,
                        metricText: "\(entry.count)件",
                        showBottomDivider: index < entries.count - 1
                    )
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Full Top Three

struct OutfitRankingFullTopThreeSection: View {
    let items: [WardrobeItem]
    let kind: OutfitHubRankingKind
    let metricValue: (WardrobeItem) -> Int
    let onSelect: (UUID) -> Void
    var highlightItemId: UUID?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(items.prefix(3).enumerated()), id: \.element.id) { index, item in
                let rank = index + 1
                Button {
                    onSelect(item.id)
                } label: {
                    OutfitRankingFeaturedPlaceCard(
                        rank: rank,
                        item: item,
                        kind: kind,
                        metricValue: metricValue(item),
                        isHighlighted: item.id == highlightItemId
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Full List Section

struct OutfitRankingFullListSection: View {
    let items: [WardrobeItem]
    let startRank: Int
    let kind: OutfitHubRankingKind
    let metricValue: (WardrobeItem) -> Int
    let onSelect: (UUID) -> Void
    var highlightItemId: UUID?

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.element.id) { offset, item in
                let rank = startRank + offset
                Button {
                    onSelect(item.id)
                } label: {
                    OutfitRankingFullListRow(
                        rank: rank,
                        item: item,
                        kind: kind,
                        metricValue: metricValue(item),
                        isHighlighted: item.id == highlightItemId
                    )
                }
                .buttonStyle(.plain)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Full List Row

struct OutfitRankingFullListRow: View {
    let rank: Int
    let item: WardrobeItem
    let kind: OutfitHubRankingKind
    let metricValue: Int
    var isHighlighted: Bool = false

    private var theme: OutfitRankingListRankTheme { .forRank(rank) }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.accentColor)
                .frame(width: 32, alignment: .center)

            Text("\(item.brand.isEmpty ? "未命名品牌" : item.brand) · \(item.name)")
                .font(.system(size: 15, weight: isHighlighted ? .semibold : .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            OutfitRankingMetricBadge(
                kind: kind,
                value: metricValue,
                background: theme.pillBackground,
                textColor: theme.pillTextColor,
                size: .compact
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.accentColor, lineWidth: 1.5)
            }
        }
    }
}

// MARK: - Featured Place Card

struct OutfitRankingFeaturedPlaceCard: View {
    let rank: Int
    let item: WardrobeItem
    let kind: OutfitHubRankingKind
    let metricValue: Int
    var isHighlighted: Bool = false

    private var tier: OutfitRankingFeaturedTier { OutfitRankingFeaturedTier(rank: rank) }
    private var layout: OutfitRankingFeaturedLayoutMetrics { .forRank(rank) }

    var body: some View {
        HStack(spacing: 0) {
            tier.rankColor
                .frame(width: layout.accentBarWidth)
                .frame(maxHeight: .infinity)

            HStack(alignment: .center, spacing: layout.sectionSpacing) {
                rankLabelBlock

                OutfitRankingCenterThickVerticalDivider(
                    color: tier.dividerColor,
                    height: layout.dividerHeight
                )

                VStack(alignment: .leading, spacing: layout.contentVerticalSpacing) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(brandDisplayName)
                            .font(.system(size: layout.nameFontSize, weight: .semibold))
                        Text(" · ")
                            .font(.system(size: layout.nameFontSize, weight: .semibold))
                        Text(item.name)
                            .font(.system(size: layout.productNameFontSize, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                    HStack(alignment: .center, spacing: 8) {
                        Text(OutfitRankingMetricPillParts(kind: kind, value: metricValue).prefix)
                            .font(layout.subtitleFont)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        OutfitRankingMetricBadge(
                            kind: kind,
                            value: metricValue,
                            background: tier.pillBackground,
                            textColor: tier.pillTextColor,
                            size: layout.metricBadgeSize
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.vertical, layout.verticalPadding)
        }
        .frame(maxWidth: .infinity)
        .frame(height: layout.cardHeight)
        .background(tier.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(layout.shadowOpacity), radius: layout.shadowRadius, x: 0, y: layout.shadowY)
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tier.rankColor, lineWidth: 1.5)
            }
        }
    }

    private var rankLabelBlock: some View {
        let rankString = String(format: "%02d", rank)
        let firstDigit = String(rankString.prefix(1))
        let secondDigit = String(rankString.suffix(1))
        let digitFont = OutfitRankingTypography.didot(size: layout.rankDigitSize, bold: true)
        let noOffset = layout.rankNoFontSize + layout.rankNoDigitSpacing + 1

        return HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text(firstDigit)
                .font(digitFont)
                .background(alignment: .bottom) {
                    Rectangle()
                        .fill(tier.rankColor)
                        .frame(height: layout.underlineHeight)
                }
                .overlay(alignment: .top) {
                    Text("NO.")
                        .font(OutfitRankingTypography.didot(size: layout.rankNoFontSize + 1, bold: true))
                        .foregroundColor(tier.rankColor)
                        .fixedSize()
                        .frame(maxWidth: .infinity)
                        .offset(y: -noOffset)
                }

            Text(secondDigit)
                .font(digitFont)
        }
        .foregroundColor(tier.rankColor)
        .padding(.top, layout.rankNoFontSize + layout.rankNoDigitSpacing)
        .frame(minWidth: layout.rankBlockMinWidth, alignment: .leading)
    }

    private var brandDisplayName: String {
        item.brand.isEmpty ? "未命名品牌" : item.brand
    }
}

// MARK: - Full Style Helpers

private enum OutfitRankingTypography {
    static func didot(size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Didot-Bold" : "Didot", size: size)
    }
}

private struct OutfitRankingCenterThickVerticalDivider: View {
    let color: Color
    let height: CGFloat
    var minLineWidth: CGFloat = 0.5
    var maxLineWidth: CGFloat = 1.5

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let centerX = size.width / 2
            var path = Path()
            path.move(to: CGPoint(x: centerX - minLineWidth / 2, y: 0))
            path.addLine(to: CGPoint(x: centerX + minLineWidth / 2, y: 0))
            path.addLine(to: CGPoint(x: centerX + maxLineWidth / 2, y: midY))
            path.addLine(to: CGPoint(x: centerX + maxLineWidth / 2, y: size.height))
            path.addLine(to: CGPoint(x: centerX - minLineWidth / 2, y: size.height))
            path.addLine(to: CGPoint(x: centerX - maxLineWidth / 2, y: midY))
            path.closeSubpath()
            context.fill(path, with: .color(color))
        }
        .frame(width: maxLineWidth, height: height)
    }
}

private enum OutfitRankingFeaturedTier {
    case first
    case second
    case third

    init(rank: Int) {
        switch rank {
        case 1: self = .first
        case 2: self = .second
        default: self = .third
        }
    }

    var cardBackground: Color {
        switch self {
        case .first: return Color(hex: "#FFF9EE")
        case .second: return Color(hex: "#F2FAFA")
        case .third: return Color(hex: "#FFF4EB")
        }
    }

    var rankColor: Color {
        switch self {
        case .first: return Color(hex: "#D4AF37")
        case .second: return Color(hex: "#3A9491")
        case .third: return Color(hex: "#E8954A")
        }
    }

    var dividerColor: Color {
        switch self {
        case .first: return Color(hex: "#B8960C")
        case .second: return Color(hex: "#248581")
        case .third: return Color(hex: "#C2410C")
        }
    }

    var pillBackground: Color {
        switch self {
        case .first: return Color(hex: "#FFF3CD")
        case .second: return Color(hex: "#C8EBEB")
        case .third: return Color(hex: "#FFEDD5")
        }
    }

    var pillTextColor: Color {
        switch self {
        case .first: return Color(hex: "#E8954A")
        case .second: return Color(hex: "#28706E")
        case .third: return Color(hex: "#E8954A")
        }
    }
}

private struct OutfitRankingFeaturedLayoutMetrics {
    let rank: Int

    static func forRank(_ rank: Int) -> Self {
        Self(rank: rank)
    }

    var cardHeight: CGFloat {
        switch rank {
        case 1: return 104
        case 2: return 98
        default: return 92
        }
    }

    var accentBarWidth: CGFloat { 5 }
    var horizontalPadding: CGFloat { 18 }
    var verticalPadding: CGFloat { 20 }
    var sectionSpacing: CGFloat { 22 }
    var nameFontSize: CGFloat {
        switch rank {
        case 1: return 20
        case 2: return 18
        default: return 17
        }
    }
    var productNameFontSize: CGFloat {
        switch rank {
        case 1: return 18
        case 2: return 16
        default: return 15
        }
    }
    var rankDigitSize: CGFloat { rank == 1 ? 44 : 40 }
    var rankNoFontSize: CGFloat { rank == 1 ? 12 : 11 }
    var rankNoDigitSpacing: CGFloat { 0 }
    var rankBlockMinWidth: CGFloat { 58 }
    var dividerHeight: CGFloat { 58 }
    var contentVerticalSpacing: CGFloat { 8 }
    var underlineHeight: CGFloat { 1.5 }
    var shadowRadius: CGFloat { 8 }
    var shadowY: CGFloat { 3 }
    var shadowOpacity: Double { 0.06 }
    var subtitleFont: Font { rank == 1 ? .subheadline : .footnote }
    var metricBadgeSize: OutfitRankingMetricBadgeSize {
        switch rank {
        case 1: return .regular
        case 2, 3: return .medium
        default: return .medium
        }
    }
}

private struct OutfitRankingListRankTheme {
    let accentColor: Color
    let pillBackground: Color
    let pillTextColor: Color

    static func forRank(_ rank: Int) -> Self {
        switch rank {
        case 4...6:
            return Self(
                accentColor: Color(hex: "#7C3AED"),
                pillBackground: Color(hex: "#EDE9FE"),
                pillTextColor: Color(hex: "#6D28D9")
            )
        case 7...8:
            return Self(
                accentColor: Color(hex: "#2563EB"),
                pillBackground: Color(hex: "#DBEAFE"),
                pillTextColor: Color(hex: "#1D4ED8")
            )
        case 9...10:
            return Self(
                accentColor: Color(hex: "#16A34A"),
                pillBackground: Color(hex: "#DCFCE7"),
                pillTextColor: Color(hex: "#15803D")
            )
        default:
            return Self(
                accentColor: Color(hex: "#9CA3AF"),
                pillBackground: Color(hex: "#F3F4F6"),
                pillTextColor: Color(hex: "#6B7280")
            )
        }
    }
}

private enum OutfitRankingMetricBadgeSize {
    case regular
    case medium
    case compact
}

private struct OutfitRankingMetricBadge: View {
    let kind: OutfitHubRankingKind
    let value: Int
    var background: Color = Color(hex: "#E8F5E9")
    var textColor: Color = Color(hex: "#2B5748")
    var size: OutfitRankingMetricBadgeSize = .regular

    var body: some View {
        Text(compactText)
            .font(badgeFont)
            .foregroundColor(textColor)
            .monospacedDigit()
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background {
                Capsule(style: .continuous)
                    .fill(background)
            }
    }

    private var badgeFont: Font {
        switch size {
        case .regular: return .subheadline.weight(.semibold)
        case .medium: return .footnote.weight(.semibold)
        case .compact: return .caption.weight(.semibold)
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .regular: return 12
        case .medium: return 10
        case .compact: return 9
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .regular: return 6
        case .medium: return 5
        case .compact: return 4
        }
    }

    private var compactText: String {
        switch kind {
        case .price, .costPerWear:
            return "¥\(value)"
        case .favorite:
            return "\(value)分"
        default:
            let parts = OutfitRankingMetricPillParts(kind: kind, value: value)
            return "\(parts.value)\(parts.suffix)"
        }
    }
}

private struct OutfitRankingMetricPillParts {
    let prefix: String
    let value: String
    let suffix: String

    init(kind: OutfitHubRankingKind, value: Int) {
        switch kind {
        case .consecutiveWearDays:
            prefix = "连续穿戴"
            self.value = "\(value)"
            suffix = "天"
        case .wearCount:
            prefix = "累计穿着"
            self.value = "\(value)"
            suffix = "次"
        case .favorite:
            prefix = "喜爱度"
            self.value = "\(value)"
            suffix = "分"
        case .price:
            prefix = "购入价"
            self.value = "\(value)"
            suffix = "元"
        case .costPerWear:
            prefix = "每次"
            self.value = "\(value)"
            suffix = "元"
        case .brandCount:
            prefix = ""
            self.value = "\(value)"
            suffix = ""
        }
    }
}

extension WardrobeRankingKind {
    var hubRankingKind: OutfitHubRankingKind {
        switch self {
        case .price: return .price
        case .wearCount: return .wearCount
        }
    }
}
