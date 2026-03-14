import SwiftUI
import SwiftData

struct TrendView: View {
    @Query(sort: \Record.timestamp, order: .reverse) private var records: [Record]
    @State private var selectedTab: TrendTab = .week

    private let horizontalPadding: CGFloat = 18

    var body: some View {
        VStack(spacing: 3) {
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

    private var weekSummary: WeekTrendSummary {
        WeekTrendSummary(records: records)
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
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 120)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("This Week")
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: true)

                        Text(metric.label)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: true)
                    }
                    .fixedSize(horizontal: true, vertical: true)
                }
                .overlay(alignment: .bottomTrailing) {
                    Text(metric.valueText(estVolume: weekSummary.totalEstimatedVolume, mass: weekSummary.totalMass))
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: true)
                        .contentTransition(.numericText())
                }
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

private struct WeekTrendSummary {
    let weekRecords: [Record]
    let validMassValues: [Double]
    let invalidMassRecordCount: Int
    let averageMass: Double?

    init(records: [Record], calendar: Calendar = .current, referenceDate: Date = .now) {
        let today = calendar.startOfDay(for: referenceDate)
        let start = calendar.date(byAdding: .day, value: -6, to: today)
        let end = calendar.date(byAdding: .day, value: 1, to: today)

        weekRecords = records.filter { record in
            guard let start, let end else { return false }
            let recordDate = normalizedRecordDate(record.timestamp, calendar: calendar)
            return recordDate >= start && recordDate < end
        }

        validMassValues = weekRecords.compactMap { record in
            guard let mass = record.mass, mass > 0 else { return nil }
            return mass
        }

        invalidMassRecordCount = weekRecords.count - validMassValues.count
        averageMass = invalidMassRecordCount > 0 ? storedAverageMass(from: records) : nil
    }

    var totalValidMass: Double {
        validMassValues.reduce(0, +)
    }

    var totalMass: Double {
        totalValidMass + Double(invalidMassRecordCount) * (averageMass ?? 0)
    }

    var totalEstimatedVolume: Double {
        totalMass / defaultDensity
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
