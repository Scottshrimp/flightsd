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
        Picker("Trend Range", selection: $selectedTab) {
            ForEach(TrendTab.allCases) { tab in
                Text(tab.title)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
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

    @AppStorage("trendTargetFlightsPerWeek") private var storedTargFlPerW: Double = 7
    @State private var metric: WeekTrendMetric = .estVolume

    private let horizontalPadding: CGFloat = 18
    private let cardCornerRadius: CGFloat = 14

    private var weekSummary: WeekTrendSummary {
        WeekTrendSummary(records: records)
    }

    private var targFlPerW: Double {
        get { min(max(storedTargFlPerW, 0), 70) }
        nonmutating set { storedTargFlPerW = min(max(newValue, 0), 70) }
    }

    private var targFlPerD: Double {
        get { targFlPerW / 7 }
        nonmutating set { targFlPerW = newValue * 7 }
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
                .frame(maxWidth: .infinity, minHeight: 110)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .center, spacing: 13) {
                            Text("This Week")
                                .font(.system(.title, design: .default).weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: true)

                            Circle()
                                .fill(
                                    weekTrendFrequencyColor(
                                        flPerWRecentW: weekSummary.flPerWRecentW,
                                        targFlPerW: targFlPerW
                                    )
                                )
                                .frame(width: 12, height: 12)
                        }

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
                        .font(.system(size: 50, weight: .bold, design: .default))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: true)
                        .contentTransition(.numericText())
                        .padding(.trailing, 9)
                        .padding(.bottom, -10)
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
    let averageDensity: Double?

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
        averageDensity = storedAverageDensity(from: records)
    }

    var totalValidMass: Double {
        validMassValues.reduce(0, +)
    }

    var totalMass: Double {
        totalValidMass + Double(invalidMassRecordCount) * (averageMass ?? 0)
    }

    var totalEstimatedVolume: Double {
        estimatedVolume(for: totalMass, averageDensity: averageDensity)
    }

    var flPerWRecentW: Double {
        Double(weekRecords.count)
    }

    var flPerDRecentW: Double {
        flPerWRecentW / 7
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
            return "\(fixedDisplayNumberText(estVolume, fractionDigits: 2))ml"
        case .mass:
            return "\(fixedDisplayNumberText(mass, fractionDigits: 2))g"
        }
    }
}

private func weekTrendFrequencyColor(flPerWRecentW: Double, targFlPerW: Double) -> Color {
    switch flPerWRecentW {
    case ..<max(targFlPerW - 2, 0):
        return .teal
    case ..<max(targFlPerW - 1, 0):
        return .blue
    case ..<targFlPerW:
        return .green
    case ..<(targFlPerW + 1):
        return .orange
    default:
        return .pink
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
