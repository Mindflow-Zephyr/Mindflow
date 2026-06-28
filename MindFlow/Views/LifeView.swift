import SwiftUI
import Combine

// MARK: - Life Page

struct LifeView: View {
    @StateObject private var waterStore = DailyWaterStore()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color(hex: "#d8f3dc")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LifePageTitle()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.top, 20)

                    VStack(spacing: 12) {
                        DailyWaterCard(store: waterStore)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .mindFlowScrollContentBottomInset()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            waterStore.refreshIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .mindFlowDataDidReset)) { _ in
            waterStore.refreshIfNeeded()
        }
    }
}

private struct LifePageTitle: View {
    var body: some View {
        Text("Mindflow")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

// MARK: - Daily Water

@MainActor
final class DailyWaterStore: ObservableObject {
    @Published private(set) var milliliters: Int = 0

    private let defaults = UserDefaults.standard
    private let dateKey = "mindflow.dailyWater.date"
    private let amountKey = "mindflow.dailyWater.ml"
    static let dailyGoalML = 2000

    init() {
        refreshIfNeeded()
    }

    func refreshIfNeeded() {
        let today = Self.dayKey(for: Date())
        let savedDate = defaults.string(forKey: dateKey) ?? ""
        if savedDate == today {
            milliliters = defaults.integer(forKey: amountKey)
        } else {
            milliliters = 0
            persist(date: today, milliliters: 0)
        }
    }

    func add(_ amount: Int) {
        guard amount > 0 else { return }
        refreshIfNeeded()
        milliliters += amount
        persist(date: Self.dayKey(for: Date()), milliliters: milliliters)
    }

    var progress: Double {
        guard Self.dailyGoalML > 0 else { return 0 }
        return min(1, Double(milliliters) / Double(Self.dailyGoalML))
    }

    private func persist(date: String, milliliters: Int) {
        defaults.set(date, forKey: dateKey)
        defaults.set(milliliters, forKey: amountKey)
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct DailyWaterCard: View {
    @ObservedObject var store: DailyWaterStore

    private var formattedAmount: String {
        if store.milliliters >= 1000 {
            let liters = Double(store.milliliters) / 1000
            return String(format: "%.1f L", liters)
        }
        return "\(store.milliliters) ml"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "#3A9491"))

                VStack(alignment: .leading, spacing: 4) {
                    Text("每日喝水")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("记录今日饮水量")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formattedAmount)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color(hex: "#2B5748"))
            }

            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color(hex: "#d8f3dc").opacity(0.7))
                        Capsule(style: .continuous)
                            .fill(Color(hex: "#3A9491"))
                            .frame(width: max(0, geometry.size.width * store.progress))
                    }
                }
                .frame(height: 8)

                Text("目标 \(DailyWaterStore.dailyGoalML) ml · 已完成 \(Int(store.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ForEach([200, 250, 500], id: \.self) { amount in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            store.add(amount)
                        }
                    } label: {
                        Text("+\(amount) ml")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: "#2B5748"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(hex: "#d8f3dc").opacity(0.85))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mindFlowListRowCardPadding()
        .mindFlowListRowCardChrome()
    }
}
