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
    /// OOTD 日历卡片：标题行与下方星期/日期网格的间距（可调试）
    static let ootdCalendarCardTitleBottomSpacing: CGFloat = 20
    /// OOTD 日历卡片：右上角年月标题字号（可调试）
    static let ootdCalendarMonthTitleFont: Font = .body.weight(.semibold)
    static let contentBottomInset: CGFloat = 16
    static let gridSpacing: CGFloat = 4
    static let weekdayHeaderBottomPadding: CGFloat = 4
    static let monthControlRowHeight: CGFloat = 36
    /// 月历网格最多 6 行，切换月份动画时统一高度避免抖动
    static let maxGridRowCount: Int = 6
    /// 月份切换滑动动画时长（可调试）
    static let monthChangeDuration: TimeInterval = 0.32
}

private enum CalendarMonthSlideDirection {
    case forward
    case backward
}

private struct CalendarMonthIdentity: Hashable {
    let year: Int
    let month: Int

    static func from(_ date: Date, calendar: Calendar = .current) -> CalendarMonthIdentity {
        CalendarMonthIdentity(
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date)
        )
    }
}

/// 与穿搭页 OOTD 日历一致的月历卡片，可配置标题与日期交互。
struct MindFlowOOTDStyleCalendarCard: View {
    var title: String? = nil
    @Binding var displayedMonth: Date
    let isDayMarked: (Date) -> Bool
    let onDayTap: (Date) -> Void
    var dayInteraction: MindFlowOOTDStyleCalendarDayInteraction = .ootdHistory
    /// 为 true 时，点左右箭头切换月份会播放横向滑动动画（不可手势切月）
    var animatesMonthChanges: Bool = false
    /// 标题行与下方日历表间距；nil 时使用 `titleBottomInset`
    var headerBottomSpacing: CGFloat? = nil
    var appliesPanelChrome: Bool = true
    var contentWidth: CGFloat?

    @State private var monthSlideDirection: CalendarMonthSlideDirection = .forward

    private var weekdaySymbols: [String] {
        ["一", "二", "三", "四", "五", "六", "日"]
    }

    private var monthNavigationTitle: String {
        displayedMonth.formatted(
            .dateTime
                .year()
                .month(.wide)
                .locale(Locale(identifier: "zh_CN"))
        )
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
        let animatedGridHeight = gridHeight(
            rowCount: MindFlowOOTDStyleCalendarMetrics.maxGridRowCount,
            cellSize: cellSize
        )
        let naturalGridHeight = gridHeight(for: displayedMonth, cellSize: cellSize)

        VStack(alignment: .leading, spacing: 0) {
            monthHeaderRow

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

            if animatesMonthChanges {
                ZStack {
                    monthGrid(for: displayedMonth, cellSize: cellSize)
                        .id(CalendarMonthIdentity.from(displayedMonth))
                        .transition(monthGridTransition)
                }
                .frame(height: animatedGridHeight)
                .clipped()
            } else {
                monthGrid(for: displayedMonth, cellSize: cellSize)
                    .frame(height: naturalGridHeight)
            }
        }
    }

    private var monthGridTransition: AnyTransition {
        switch monthSlideDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }

    @ViewBuilder
    private var monthHeaderRow: some View {
        HStack(alignment: .center) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(MindFlowFormSheetStyle.accent)

                Spacer(minLength: 8)
            } else {
                Spacer(minLength: 0)
            }

            HStack(spacing: 4) {
                monthControlButton(systemName: "chevron.left") {
                    shiftMonth(by: -1)
                }

                Text(monthNavigationTitle)
                    .font(MindFlowOOTDStyleCalendarMetrics.ootdCalendarMonthTitleFont)
                    .foregroundStyle(MindFlowFormSheetStyle.accent)
                    .frame(minWidth: 96)

                monthControlButton(systemName: "chevron.right") {
                    shiftMonth(by: 1)
                }
            }

            if title == nil || title?.isEmpty == true {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, MindFlowOOTDStyleCalendarMetrics.titleTopInset)
        .padding(.bottom, headerBottomSpacing ?? MindFlowOOTDStyleCalendarMetrics.titleBottomInset)
    }

    private func shiftMonth(by offset: Int) {
        guard offset != 0 else { return }
        let applyChange = {
            displayedMonth = Calendar.current.date(
                byAdding: .month,
                value: offset,
                to: displayedMonth
            ) ?? displayedMonth
        }

        guard animatesMonthChanges else {
            applyChange()
            return
        }

        monthSlideDirection = offset > 0 ? .forward : .backward
        withAnimation(.easeInOut(duration: MindFlowOOTDStyleCalendarMetrics.monthChangeDuration)) {
            applyChange()
        }
    }

    @ViewBuilder
    private func monthGrid(for month: Date, cellSize: CGFloat) -> some View {
        let gridDays = Self.gridDays(for: month)
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
    }

    private func cellSize(for width: CGFloat) -> CGFloat {
        (width - 32 - 6 * MindFlowOOTDStyleCalendarMetrics.gridSpacing) / 7
    }

    private func gridHeight(for month: Date, cellSize: CGFloat) -> CGFloat {
        let rowCount = max(1, Self.gridDays(for: month).count / 7)
        return gridHeight(rowCount: rowCount, cellSize: cellSize)
    }

    private func gridHeight(rowCount: Int, cellSize: CGFloat) -> CGFloat {
        CGFloat(rowCount) * cellSize
            + CGFloat(max(0, rowCount - 1)) * MindFlowOOTDStyleCalendarMetrics.gridSpacing
            + MindFlowOOTDStyleCalendarMetrics.contentBottomInset
    }

    private func intrinsicHeight(forWidth width: CGFloat) -> CGFloat {
        let cellSize = cellSize(for: width)
        let gridHeight = animatesMonthChanges
            ? gridHeight(rowCount: MindFlowOOTDStyleCalendarMetrics.maxGridRowCount, cellSize: cellSize)
            : gridHeight(for: displayedMonth, cellSize: cellSize)
        return MindFlowOOTDStyleCalendarMetrics.titleTopInset
            + MindFlowOOTDStyleCalendarMetrics.monthControlRowHeight
            + MindFlowOOTDStyleCalendarMetrics.titleBottomInset
            + 20
            + MindFlowOOTDStyleCalendarMetrics.weekdayHeaderBottomPadding
            + gridHeight
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
