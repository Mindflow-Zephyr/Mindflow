import SwiftUI

enum MindFlowOOTDStyleCalendarDayInteraction {
    /// 仅已标记日期可点击（穿搭 OOTD 历史）
    case ootdHistory
    /// 任意日期可点击切换标记（年重复等）
    case toggleSelect
}

enum MindFlowOOTDStyleCalendarMetrics {
    static let titleTopInset: CGFloat = 4
    static let titleBottomInset: CGFloat = 6
    static let contentBottomInset: CGFloat = 16
    static let gridSpacing: CGFloat = 4
    static let weekdayHeaderBottomPadding: CGFloat = 8
    static let monthControlRowHeight: CGFloat = 36
}

/// 与穿搭页 OOTD 日历一致的月历卡片，可配置标题与日期交互。
struct MindFlowOOTDStyleCalendarCard: View {
    let title: String
    @Binding var displayedMonth: Date
    let isDayMarked: (Date) -> Bool
    let onDayTap: (Date) -> Void
    var dayInteraction: MindFlowOOTDStyleCalendarDayInteraction = .ootdHistory
    var appliesPanelChrome: Bool = true
    var contentWidth: CGFloat?

    private var weekdaySymbols: [String] {
        ["一", "二", "三", "四", "五", "六", "日"]
    }

    private var monthNavigationTitle: String {
        displayedMonth.formatted(.dateTime.year().month(.wide))
    }

    var body: some View {
        Group {
            if let contentWidth {
                calendarBody(cellSize: cellSize(for: contentWidth))
                    .frame(width: contentWidth)
            } else {
                GeometryReader { geometry in
                    calendarBody(cellSize: cellSize(for: geometry.size.width))
                        .frame(width: geometry.size.width)
                }
                .frame(height: intrinsicHeight(forWidth: UIScreen.main.bounds.width - 72))
            }
        }
        .modifier(MindFlowOOTDStyleCalendarChrome(enabled: appliesPanelChrome))
    }

    @ViewBuilder
    private func calendarBody(cellSize: CGFloat) -> some View {
        let gridDays = Self.gridDays(for: displayedMonth)
        let rowCount = max(1, gridDays.count / 7)
        let gridHeight = CGFloat(rowCount) * cellSize
            + CGFloat(max(0, rowCount - 1)) * MindFlowOOTDStyleCalendarMetrics.gridSpacing

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(MindFlowFormSheetStyle.accent)

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    monthControlButton(systemName: "chevron.left") {
                        displayedMonth = Calendar.current.date(
                            byAdding: .month,
                            value: -1,
                            to: displayedMonth
                        ) ?? displayedMonth
                    }

                    Text(monthNavigationTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MindFlowFormSheetStyle.accent)
                        .frame(minWidth: 88)

                    monthControlButton(systemName: "chevron.right") {
                        displayedMonth = Calendar.current.date(
                            byAdding: .month,
                            value: 1,
                            to: displayedMonth
                        ) ?? displayedMonth
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, MindFlowOOTDStyleCalendarMetrics.titleTopInset)
            .padding(.bottom, MindFlowOOTDStyleCalendarMetrics.titleBottomInset)

            HStack(spacing: MindFlowOOTDStyleCalendarMetrics.gridSpacing) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: cellSize)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, MindFlowOOTDStyleCalendarMetrics.weekdayHeaderBottomPadding)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.fixed(cellSize), spacing: MindFlowOOTDStyleCalendarMetrics.gridSpacing),
                    count: 7
                ),
                spacing: MindFlowOOTDStyleCalendarMetrics.gridSpacing
            ) {
                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day, cellSize: cellSize)
                    } else {
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, MindFlowOOTDStyleCalendarMetrics.contentBottomInset)
            .frame(height: gridHeight)
        }
    }

    private func cellSize(for width: CGFloat) -> CGFloat {
        (width - 32 - 6 * MindFlowOOTDStyleCalendarMetrics.gridSpacing) / 7
    }

    private func intrinsicHeight(forWidth width: CGFloat) -> CGFloat {
        let cellSize = cellSize(for: width)
        let gridDays = Self.gridDays(for: displayedMonth)
        let rowCount = max(1, gridDays.count / 7)
        let gridHeight = CGFloat(rowCount) * cellSize
            + CGFloat(max(0, rowCount - 1)) * MindFlowOOTDStyleCalendarMetrics.gridSpacing
        return MindFlowOOTDStyleCalendarMetrics.titleTopInset
            + MindFlowOOTDStyleCalendarMetrics.monthControlRowHeight
            + MindFlowOOTDStyleCalendarMetrics.titleBottomInset
            + 20
            + MindFlowOOTDStyleCalendarMetrics.weekdayHeaderBottomPadding
            + gridHeight
            + MindFlowOOTDStyleCalendarMetrics.contentBottomInset
    }

    private func monthControlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MindFlowFormSheetStyle.accent)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dayCell(_ day: Date, cellSize: CGFloat) -> some View {
        let dayStart = Calendar.current.startOfDay(for: day)
        let isMarked = isDayMarked(dayStart)
        let dayNumber = Calendar.current.component(.day, from: day)

        switch dayInteraction {
        case .ootdHistory:
            if isMarked {
                Button {
                    onDayTap(dayStart)
                } label: {
                    markedDayLabel(dayNumber: dayNumber, cellSize: cellSize)
                }
                .buttonStyle(.plain)
            } else {
                Text("\(dayNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary.opacity(0.55))
                    .frame(width: cellSize, height: cellSize)
            }
        case .toggleSelect:
            Button {
                onDayTap(dayStart)
            } label: {
                if isMarked {
                    markedDayLabel(dayNumber: dayNumber, cellSize: cellSize)
                } else {
                    Text("\(dayNumber)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary.opacity(0.55))
                        .frame(width: cellSize, height: cellSize)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func markedDayLabel(dayNumber: Int, cellSize: CGFloat) -> some View {
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

    static func gridDays(for month: Date) -> [Date?] {
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
}

private struct MindFlowOOTDStyleCalendarChrome: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.todoPanelCardChrome()
        } else {
            content
        }
    }
}
