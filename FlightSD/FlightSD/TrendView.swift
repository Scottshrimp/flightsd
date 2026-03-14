import SwiftUI
import SwiftData

struct TrendView: View {
    @Query(sort: \Record.timestamp, order: .reverse) private var records: [Record]
    @State private var selectedTab: TrendTab = .week

    private let horizontalPadding: CGFloat = 18

    var body: some View {
        VStack(spacing: 0) {
            trendTabSelector
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, 14)

            TabView(selection: $selectedTab) {
                WeekTrendPage(records: records)
                    .tag(TrendTab.week)

                TrendPlaceholderPage(title: "Month View")
                    .tag(TrendTab.month)

                TrendPlaceholderPage(title: "Annual View")
                    .tag(TrendTab.year)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var trendTabSelector: some View {
        HStack(spacing: 8) {
            ForEach(TrendTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedTab == tab ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedTab == tab ? Color.accentColor : Color.primary.opacity(0.06))
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private enum TrendTab: String, CaseIterable, Identifiable {
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .year:
            return "Year"
        }
    }
}

private struct WeekTrendPage: View {
    let records: [Record]

    @State private var metric: WeekTrendMetric = .estVolume

    private let horizontalPadding: CGFloat = 18
    private let cardCornerRadius: CGFloat = 14

    private var thisWeekRecords: [Record] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let start = calendar.date(byAdding: .day, value: -6, to: today),
              let end = calendar.date(byAdding: .day, value: 1, to: today) else {
            return []
        }

        return records.filter { record in
            let recordDate = normalizedRecordDate(record.timestamp, calendar: calendar)
            return recordDate >= start && recordDate < end
        }
    }

    private var thisWeekEstVolume: Double {
        thisWeekRecords.compactMap(\.estVol).reduce(0, +)
    }

    private var thisWeekMass: Double {
        thisWeekRecords.compactMap(\.mass).reduce(0, +)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                weekSummaryCard
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }

    private var weekSummaryCard: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.13)) {
                metric = metric == .estVolume ? .mass : .estVolume
            }
        } label: {
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("This Week")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)

                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(metric.label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        Text(metric.valueText(estVolume: thisWeekEstVolume, mass: thisWeekMass))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(.thinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
            .contentShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private enum WeekTrendMetric {
    case estVolume
    case mass

    var label: String {
        switch self {
        case .estVolume:
            return "Total est.Vol"
        case .mass:
            return "Total Mass"
        }
    }

    func valueText(estVolume: Double, mass: Double) -> String {
        switch self {
        case .estVolume:
            return "\(trendMetricNumberText(estVolume))ml"
        case .mass:
            return "\(trendMetricNumberText(mass))g"
        }
    }
}

private struct TrendPlaceholderPage: View {
    let title: String

    var body: some View {
        ScrollView {
            VStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

private func trendMetricNumberText(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
}
