import SwiftUI
import SwiftData
import Charts

struct TrendView: View {
    @Query(sort: \Record.timestamp, order: .reverse) private var records: [Record]
    @Query(sort: \DateTrend.date, order: .forward) private var dateTrends: [DateTrend]
    @State private var selectedTab: TrendTab = .week

    private let horizontalPadding: CGFloat = 18

    var body: some View {
        VStack(spacing: 3) {
            trendTabSelector
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, 14)

            TabView(selection: $selectedTab) {
                WeekTrendPage(records: records, dateTrends: dateTrends)
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
    let dateTrends: [DateTrend]

    @AppStorage("trendTargetFlightsPerWeek") private var storedTargFlPerW: Double = 7
    @State private var metric: WeekTrendMetric = .estVolume
    @State private var chartMetric: WeekTrendChartMetric = .weekAvg
    @State private var displayedChartScale: Double = WeekTrendChartMetric.weekAvg.scaleMultiplier
    @State private var displayedSuppressFractionalAxisMarks = false
    @State private var axisMarkTransitionTask: Task<Void, Never>?

    private let horizontalPadding: CGFloat = 18
    private let cardCornerRadius: CGFloat = 14

    private var weekSummary: WeekTrendSummary {
        WeekTrendSummary(records: records)
    }

    private var chartSummary: RecentWeekChartSummary {
        RecentWeekChartSummary(dateTrends: dateTrends)
    }

    private var targFlPerW: Double {
        get { min(max(storedTargFlPerW, 0), 70) }
        nonmutating set { storedTargFlPerW = min(max(newValue, 0), 70) }
    }

    private var targFlPerD: Double {
        get { targFlPerW / 7 }
        nonmutating set { targFlPerW = newValue * 7 }
    }

    private var chartCardHeight: CGFloat {
        286 * 0.75
    }

    private var displayedYAxisMarks: [Double] {
        chartSummary.displayedYAxisMarks(
            scaleMultiplier: displayedChartScale,
            suppressFractionalMarks: displayedSuppressFractionalAxisMarks,
            referenceValues: [displayedTargetValue]
        )
    }

    private var displayedYAxisFractionDigits: Int {
        chartSummary.displayedYAxisFractionDigits(
            scaleMultiplier: displayedChartScale,
            suppressFractionalMarks: displayedSuppressFractionalAxisMarks,
            referenceValues: [displayedTargetValue]
        )
    }

    private var displayedYDomain: ClosedRange<Double> {
        chartSummary.displayedYDomain(
            scaleMultiplier: displayedChartScale,
            referenceValues: [displayedTargetValue]
        )
    }

    private var displayedTargetValue: Double {
        targFlPerD * displayedChartScale
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                weekSummaryCard
                recentWeekChartCard
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

    private var recentWeekChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Recent Week Trend", selection: $chartMetric) {
                ForEach(WeekTrendChartMetric.allCases) { metric in
                    Text(metric.title)
                        .tag(metric)
                }
            }
            .pickerStyle(.segmented)

            Chart(chartSummary.points) { point in
                RuleMark(y: .value("Target", displayedTargetValue))
                    .foregroundStyle(AddRecordBar.primaryBlue.opacity(0.9))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))

                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Value", point.avgTimesW * displayedChartScale)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor)

                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Lower Bound", displayedYDomain.lowerBound),
                    yEnd: .value("Value", point.avgTimesW * displayedChartScale)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.accentColor.opacity(0.24), Color.accentColor.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                PointMark(
                    x: .value("Time", point.date),
                    y: .value("Value", point.avgTimesW * displayedChartScale)
                )
                .foregroundStyle(Color.accentColor)
            }
            .chartXScale(domain: chartSummary.dateDomain)
            .chartYScale(domain: displayedYDomain)
            .chartXAxis {
                AxisMarks(values: chartSummary.points.map(\.date)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: displayedYAxisMarks) { _ in
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    if let plotFrame = proxy.plotFrame.map({ geometry[$0] }) {
                        Rectangle()
                            .fill(.clear)
                            .frame(width: plotFrame.width, height: plotFrame.height)
                            .contentShape(Rectangle())
                            .position(x: plotFrame.midX, y: plotFrame.midY)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        updateTargetValue(
                                            from: value.location,
                                            plotFrame: plotFrame
                                        )
                                    }
                            )

                        if let plotTargetY = proxy.position(forY: displayedTargetValue) {
                            let targetY = plotFrame.minY + plotTargetY

                            Rectangle()
                                .fill(AddRecordBar.primaryBlue.opacity(0.9))
                                .frame(width: plotFrame.width, height: 1.5)
                                .position(x: plotFrame.midX, y: targetY)

                            Text("Targ")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AddRecordBar.primaryBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.thinMaterial, in: Capsule())
                                .position(
                                    x: plotFrame.maxX - 20,
                                    y: targetY - 12
                                )
                        }

                        ForEach(Array(displayedYAxisMarks.enumerated()), id: \.offset) { _, mark in
                            if let plotY = proxy.position(forY: mark) {
                                Text(fixedDisplayNumberText(mark, fractionDigits: displayedYAxisFractionDigits))
                                    .font(.caption2)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .contentTransition(.numericText())
                                    .frame(width: 28, alignment: .trailing)
                                    .position(
                                        x: plotFrame.minX - 24,
                                        y: plotFrame.minY + plotY
                                    )
                            }
                        }
                    }
                }
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.leading, 12)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, minHeight: chartCardHeight, maxHeight: chartCardHeight, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(.thinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
        .clipped()
        .onChange(of: chartMetric) { _, newMetric in
            axisMarkTransitionTask?.cancel()
            displayedSuppressFractionalAxisMarks = false

            withAnimation(.easeInOut(duration: 0.24)) {
                displayedChartScale = newMetric.scaleMultiplier
            }

            guard newMetric.suppressesFractionalAxisMarks else { return }

            axisMarkTransitionTask = Task {
                try? await Task.sleep(for: .milliseconds(240))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    displayedSuppressFractionalAxisMarks = true
                }
            }
        }
        .onDisappear {
            axisMarkTransitionTask?.cancel()
        }
    }

    private func updateTargetValue(from location: CGPoint, plotFrame: CGRect) {
        guard plotFrame.height > 0 else { return }

        let clampedY = min(max(location.y, plotFrame.minY), plotFrame.maxY)
        let relativeY = clampedY - plotFrame.minY
        let progress = 1 - (relativeY / plotFrame.height)
        let domain = displayedYDomain
        let displayedValue = domain.lowerBound + Double(progress) * (domain.upperBound - domain.lowerBound)
        let scale = max(displayedChartScale, 0.000_001)
        targFlPerD = max(0, displayedValue / scale)
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

private enum WeekTrendChartMetric: String, CaseIterable, Identifiable {
    case weekAvg
    case weekSum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekAvg:
            return "WeekAvg"
        case .weekSum:
            return "WeekSum"
        }
    }

    var scaleMultiplier: Double {
        switch self {
        case .weekAvg:
            return 1
        case .weekSum:
            return 7
        }
    }

    var suppressesFractionalAxisMarks: Bool {
        switch self {
        case .weekAvg:
            return false
        case .weekSum:
            return true
        }
    }

}

private struct RecentWeekChartPoint: Identifiable {
    let date: Date
    let sumTimesW: Double
    let avgTimesW: Double

    var id: Date { date }
}

private struct RecentWeekChartSummary {
    let points: [RecentWeekChartPoint]

    init(dateTrends: [DateTrend], calendar: Calendar = .current, referenceDate: Date = .now) {
        let today = normalizedRecordDate(referenceDate, calendar: calendar)
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let trendsByDate = dateTrends.reduce(into: [String: DateTrend]()) { partialResult, trend in
            partialResult[trend.date] = trend
        }

        var generatedPoints: [RecentWeekChartPoint] = []
        var currentDate = start

        while currentDate <= today {
            let key = dateTrendKey(from: currentDate, calendar: calendar)
            let trend = trendsByDate[key]
            generatedPoints.append(
                RecentWeekChartPoint(
                    date: currentDate,
                    sumTimesW: trend?.sumTimesW ?? 0,
                    avgTimesW: trend?.avgTimesW ?? 0
                )
            )

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate), nextDate > currentDate else {
                break
            }
            currentDate = nextDate
        }

        points = generatedPoints
    }

    var dateDomain: ClosedRange<Date> {
        guard let firstDate = points.first?.date, let lastDate = points.last?.date else {
            let today = normalizedRecordDate(.now)
            return today...today
        }
        return firstDate...lastDate
    }

    func displayedYDomain(scaleMultiplier: Double, referenceValues: [Double] = []) -> ClosedRange<Double> {
        let displayedValues = points.map { $0.avgTimesW * scaleMultiplier } + referenceValues
        guard let minValue = displayedValues.min(), let maxValue = displayedValues.max() else {
            return 0...1
        }

        let rawLowerBound: Double
        let rawUpperBound: Double

        let dataSpan = maxValue - minValue
        if dataSpan > 0 {
            let domainSpan = dataSpan / 0.6
            let padding = domainSpan * 0.2
            rawLowerBound = minValue - padding
            rawUpperBound = maxValue + padding
        } else {
            let fallbackSpan = max(abs(maxValue) * 0.8, 1)
            rawLowerBound = maxValue - fallbackSpan / 2
            rawUpperBound = maxValue + fallbackSpan / 2
        }

        let step = niceAxisStep(for: rawUpperBound - rawLowerBound)
        guard step > 0 else {
            return rawLowerBound...rawUpperBound
        }

        let snappedLowerBound = floor(rawLowerBound / step) * step
        let snappedUpperBound = ceil(rawUpperBound / step) * step
        return normalizedAxisValue(snappedLowerBound)...normalizedAxisValue(snappedUpperBound)
    }

    func displayedYAxisMarks(scaleMultiplier: Double, suppressFractionalMarks: Bool, referenceValues: [Double] = []) -> [Double] {
        let domain = displayedYDomain(
            scaleMultiplier: scaleMultiplier,
            referenceValues: referenceValues
        )
        let step = niceAxisStep(for: domain.upperBound - domain.lowerBound)
        guard step > 0 else { return [domain.lowerBound, domain.upperBound] }

        let marks = stride(
            from: domain.lowerBound,
            through: domain.upperBound + step * 0.25,
            by: step
        ).map {
            normalizedAxisValue($0)
        }
        let normalizedMarks = deduplicatedAxisValues(marks)
        guard suppressFractionalMarks else { return normalizedMarks }

        let integerMarks = normalizedMarks.filter(isEffectivelyInteger)
        return integerMarks.isEmpty ? normalizedMarks : integerMarks
    }

    func displayedYAxisFractionDigits(scaleMultiplier: Double, suppressFractionalMarks: Bool, referenceValues: [Double] = []) -> Int {
        if suppressFractionalMarks {
            return 0
        }

        let domain = displayedYDomain(
            scaleMultiplier: scaleMultiplier,
            referenceValues: referenceValues
        )
        let step = niceAxisStep(for: domain.upperBound - domain.lowerBound)
        switch step {
        case let value where value >= 1:
            return 0
        case let value where value >= 0.1:
            return 1
        default:
            return 2
        }
    }

    private func niceAxisStep(for span: Double) -> Double {
        guard span > 0 else { return 1 }

        let targetMarkCount = 5.0
        let rawStep = span / targetMarkCount
        let exponent = floor(log10(rawStep))
        let scale = pow(10, exponent)
        let normalized = rawStep / scale

        let niceNormalizedStep: Double
        switch normalized {
        case ..<1.5:
            niceNormalizedStep = 1
        case ..<3:
            niceNormalizedStep = 2
        case ..<7:
            niceNormalizedStep = 5
        default:
            niceNormalizedStep = 10
        }

        return niceNormalizedStep * scale
    }

    private func normalizedAxisValue(_ value: Double) -> Double {
        let rounded = (value * 1_000_000).rounded() / 1_000_000
        return rounded == -0 ? 0 : rounded
    }

    private func deduplicatedAxisValues(_ values: [Double]) -> [Double] {
        var result: [Double] = []

        for value in values {
            if let lastValue = result.last, abs(lastValue - value) < 0.000_001 {
                continue
            }
            result.append(value)
        }

        return result
    }

    private func isEffectivelyInteger(_ value: Double) -> Bool {
        abs(value.rounded() - value) < 0.000_001
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
