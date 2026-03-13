import SwiftUI
import SwiftData

struct RecordsView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Record.timestamp, order: .reverse) private var records: [Record]

    @State private var expandedRecordID: PersistentIdentifier?

    private var groupedRecords: RecordGroups {
        RecordGroups(records: records, calendar: .current)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                groupedSection(
                    title: "今天",
                    records: groupedRecords.today,
                    emptyText: "今天还没有记录"
                )

                groupedSection(
                    title: "过去一周",
                    records: groupedRecords.pastWeek,
                    emptyText: "过去一周还没有记录"
                )

                earlierSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AddRecordBar {
                appState.showNewRecord = true
            }
        }
    }

    @ViewBuilder
    private func groupedSection(title: String, records: [Record], emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(.title, design: .rounded).weight(.bold))

            if records.isEmpty {
                EmptySectionCard(message: emptyText)
            } else {
                VStack(spacing: 12) {
                    ForEach(records) { record in
                        RecordEntryCard(
                            record: record,
                            isExpanded: expandedRecordID == record.persistentModelID,
                            onToggle: { toggle(record) },
                            onDone: { expandedRecordID = nil }
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var earlierSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("更久之前")
                .font(.system(.title, design: .rounded).weight(.bold))

            if groupedRecords.earlierMonths.isEmpty {
                EmptySectionCard(message: "还没有更久之前的记录")
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(groupedRecords.earlierMonths) { monthGroup in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(RecordPresentation.monthTitle(monthGroup.monthStart))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.secondary)

                            VStack(spacing: 12) {
                                ForEach(monthGroup.records) { record in
                                    RecordEntryCard(
                                        record: record,
                                        isExpanded: expandedRecordID == record.persistentModelID,
                                        onToggle: { toggle(record) },
                                        onDone: { expandedRecordID = nil }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func toggle(_ record: Record) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            if expandedRecordID == record.persistentModelID {
                expandedRecordID = nil
            } else {
                expandedRecordID = record.persistentModelID
            }
        }
    }
}

private struct RecordEntryCard: View {
    let record: Record
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var draft: RecordDraft

    init(record: Record, isExpanded: Bool, onToggle: @escaping () -> Void, onDone: @escaping () -> Void) {
        self.record = record
        self.isExpanded = isExpanded
        self.onToggle = onToggle
        self.onDone = onDone
        _draft = State(initialValue: RecordDraft(record: record))
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                if !isExpanded {
                    draft = RecordDraft(record: record)
                }
                onToggle()
            } label: {
                RecordSummaryRow(record: record)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.horizontal, 18)

                RecordInlineEditor(draft: $draft) {
                    saveChanges()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.thinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                draft = RecordDraft(record: record)
            }
        }
    }

    private func saveChanges() {
        guard draft.canSave else { return }

        record.timestamp = draft.timestamp
        record.dimension = draft.dimension
        record.mediaType = draft.mediaType
        record.typeAge = draft.typeAge
        record.typePosition = draft.typePosition
        record.typeExistence = draft.typeExistence
        record.time = draft.time
        record.sound = draft.sound
        record.atm = draft.atm
        record.postnut = draft.postnut
        record.horny = draft.horny
        record.mass = draft.massValue ?? record.mass
        record.preciseDensity = draft.preciseDensityValue

        try? modelContext.save()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            onDone()
        }
    }
}

private struct RecordSummaryRow: View {
    let record: Record

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(RecordPresentation.recordTitle(for: record.timestamp))
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(RecordPresentation.recordSubtitle(for: record))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 12) {
                MetricDotStrip(metrics: RecordPresentation.metricDots(for: record))

                Text(RecordPresentation.mediaCategory(for: record))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

private struct RecordInlineEditor: View {
    @Binding var draft: RecordDraft
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            EditorBlock(title: "记录时间") {
                DatePicker(
                    "记录时间",
                    selection: $draft.timestamp,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }

            EditorBlock(title: "次元") {
                HStack(spacing: 12) {
                    ForEach([Dimension.twoDimension, Dimension.threeDimension], id: \.self) { dimension in
                        Button(RecordPresentation.dimensionLabel(dimension)) {
                            draft.dimension = dimension
                            if dimension == .threeDimension && !draft.availableMediaTypes.contains(draft.mediaType) {
                                draft.mediaType = .img
                            }
                        }
                        .buttonStyle(SelectionButtonStyle(isSelected: draft.dimension == dimension))
                    }
                }
            }

            EditorBlock(title: "媒体类型") {
                HStack(spacing: 12) {
                    ForEach(draft.availableMediaTypes, id: \.self) { mediaType in
                        Button(RecordPresentation.mediaTypeLabel(mediaType)) {
                            draft.mediaType = mediaType
                        }
                        .buttonStyle(SelectionButtonStyle(isSelected: draft.mediaType == mediaType))
                    }
                }
            }

            MetricEditorRow(
                title: "年龄感",
                value: $draft.typeAge,
                labels: RecordPresentation.typeAgeLabels
            )

            MetricEditorRow(
                title: "体位",
                value: $draft.typePosition,
                labels: RecordPresentation.typePositionLabels
            )

            MetricEditorRow(
                title: "存在感",
                value: $draft.typeExistence,
                labels: RecordPresentation.typeExistenceLabels
            )

            MetricEditorRow(
                title: "时长",
                value: $draft.time,
                labels: RecordPresentation.timeLabels
            )

            MetricEditorRow(
                title: "声音",
                value: $draft.sound,
                labels: RecordPresentation.soundLabels,
                range: -1 ... 1,
                normalize: { ($0 + 1) / 2 }
            )

            MetricEditorRow(
                title: "氛围",
                value: $draft.atm,
                labels: RecordPresentation.atmLabels
            )

            MetricEditorRow(
                title: "事后状态",
                value: $draft.postnut,
                labels: RecordPresentation.postnutLabels
            )

            MetricEditorRow(
                title: "欲望程度",
                value: $draft.horny,
                labels: RecordPresentation.hornyLabels
            )

            EditorBlock(title: "质量") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("克数", text: $draft.massText)
                        .textFieldStyle(.roundedBorder)

                    Toggle("精确密度", isOn: $draft.usePreciseDensity)

                    if draft.usePreciseDensity {
                        TextField("密度", text: $draft.preciseDensityText)
                            .textFieldStyle(.roundedBorder)
                    }

                    Text("估算体积 \(draft.estimatedVolumeText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !draft.canSave {
                        Text("质量或密度格式无效，暂时无法保存。")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            HStack {
                Spacer()

                Button("Done") {
                    onDone()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!draft.canSave)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
    }
}

private struct MetricEditorRow: View {
    let title: String
    @Binding var value: Double
    let labels: [String]
    var range: ClosedRange<Double> = 0 ... 1
    var normalize: (Double) -> Double = { $0 }

    private var currentZone: Int {
        zoneIndex(for: normalize(value), zoneCount: labels.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(labels[currentZone])
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(zoneColor(for: currentZone, zoneCount: labels.count))
            }

            Slider(value: $value, in: range)
                .tint(zoneColor(for: currentZone, zoneCount: labels.count))

            HStack(spacing: 0) {
                ForEach(labels.indices, id: \.self) { index in
                    Text(labels[index])
                        .font(.caption2)
                        .foregroundStyle(index == currentZone ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct MetricDotStrip: View {
    let metrics: [MetricDot]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                Circle()
                    .fill(zoneColor(for: metric.zone, zoneCount: metric.zoneCount))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

private struct AddRecordBar: View {
    @Environment(\.colorScheme) private var colorScheme

    let action: () -> Void

    private var gradientColors: [Color] {
        let darkerBlue = Color(red: 0, green: 111.0 / 255.0, blue: 248.0 / 255.0)
        let lighterBlue = Color(red: 32.0 / 255.0, green: 138.0 / 255.0, blue: 1)

        if colorScheme == .dark {
            return [lighterBlue, darkerBlue]
        }

        return [darkerBlue, lighterBlue]
    }

    private func diagonalGradient(in size: CGSize) -> LinearGradient {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        let halfHorizontalOffset = min(height / width, 0.22) / 2

        return LinearGradient(
            colors: gradientColors,
            startPoint: UnitPoint(x: 0.5 - halfHorizontalOffset, y: 1),
            endPoint: UnitPoint(x: 0.5 + halfHorizontalOffset, y: 0)
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            Button {
                action()
            } label: {
                HStack {
                    Text("Add Record")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "arrow.up.left")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(width: UIScreen.main.bounds.width * 0.85)
            .background {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)

                    GeometryReader { proxy in
                        Rectangle()
                            .fill(diagonalGradient(in: proxy.size))
                            .saturation(1.3)
                            .brightness(-0.05)
                            .opacity(0.60)
                    }
                }
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.18))
                    .frame(height: 1)
            }
            Spacer(minLength: 0)
        }
        .ignoresSafeArea(edges: .horizontal)
    }
}

private struct EmptySectionCard: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.thinMaterial)
            }
    }
}

private struct EditorBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            content()
        }
    }
}

private struct RecordGroups {
    let today: [Record]
    let pastWeek: [Record]
    let earlierMonths: [MonthGroup]

    init(records: [Record], calendar: Calendar) {
        let startOfToday = calendar.startOfDay(for: Date.now)
        let startOfPastWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday) ?? startOfToday

        var todayRecords: [Record] = []
        var pastWeekRecords: [Record] = []
        var monthBuckets: [Date: [Record]] = [:]

        for record in records {
            if calendar.isDate(record.timestamp, inSameDayAs: startOfToday) {
                todayRecords.append(record)
            } else if record.timestamp >= startOfPastWeek && record.timestamp < startOfToday {
                pastWeekRecords.append(record)
            } else if let monthStart = calendar.dateInterval(of: .month, for: record.timestamp)?.start {
                monthBuckets[monthStart, default: []].append(record)
            }
        }

        today = todayRecords
        pastWeek = pastWeekRecords
        earlierMonths = monthBuckets
            .keys
            .sorted(by: >)
            .map { monthStart in
                MonthGroup(
                    monthStart: monthStart,
                    records: monthBuckets[monthStart]?.sorted(by: { $0.timestamp > $1.timestamp }) ?? []
                )
            }
    }
}

private struct MonthGroup: Identifiable {
    let monthStart: Date
    let records: [Record]

    var id: Date { monthStart }
}

private struct MetricDot {
    let zone: Int
    let zoneCount: Int
}

private struct RecordDraft {
    var timestamp: Date
    var dimension: Dimension
    var mediaType: MediaType
    var typeAge: Double
    var typePosition: Double
    var typeExistence: Double
    var time: Double
    var sound: Double
    var atm: Double
    var postnut: Double
    var horny: Double
    var massText: String
    var usePreciseDensity: Bool
    var preciseDensityText: String

    init(record: Record) {
        timestamp = record.timestamp
        dimension = record.dimension
        mediaType = record.mediaType
        typeAge = record.typeAge
        typePosition = record.typePosition
        typeExistence = record.typeExistence
        time = record.time
        sound = record.sound
        atm = record.atm
        postnut = record.postnut
        horny = record.horny
        massText = RecordPresentation.numberText(record.mass, maxFractionDigits: 2)
        usePreciseDensity = record.preciseDensity != nil
        preciseDensityText = record.preciseDensity.map {
            RecordPresentation.numberText($0, maxFractionDigits: 3)
        } ?? ""
    }

    var availableMediaTypes: [MediaType] {
        dimension == .twoDimension ? [.img, .vid, .txt, .aud] : [.img, .vid]
    }

    var massValue: Double? {
        Double(massText)
    }

    var preciseDensityValue: Double? {
        guard usePreciseDensity else { return nil }
        return Double(preciseDensityText)
    }

    var canSave: Bool {
        massValue != nil && (!usePreciseDensity || preciseDensityValue != nil)
    }

    var estimatedVolumeText: String {
        guard let massValue else { return "--" }
        let density = preciseDensityValue ?? 1.035
        let estVol = massValue / density
        return "\(RecordPresentation.fixedNumberText(estVol, fractionDigits: 2)) mL"
    }
}

private enum RecordPresentation {
    static let typeAgeLabels = ["区间1", "区间2", "区间3", "区间4", "区间5"]
    static let typePositionLabels = ["区间1", "区间2", "区间3", "区间4", "区间5"]
    static let typeExistenceLabels = ["区间1", "区间2"]
    static let timeLabels = ["很短", "短", "中", "长", "很长"]
    static let soundLabels = ["不喜欢", "纯图", "喜欢", "纯音"]
    static let atmLabels = ["纯视觉", "偏视觉", "偏情境", "纯情境"]
    static let postnutLabels = ["很开心", "没感觉", "有点累", "眼皮打架"]
    static let hornyLabels = ["低", "中低", "中高", "高"]

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "LLL. yyyy"
        return formatter
    }()

    private static let todayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let pastFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static func monthTitle(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }

    static func dimensionLabel(_ dimension: Dimension) -> String {
        switch dimension {
        case .twoDimension:
            return "二次元"
        case .threeDimension:
            return "三次元"
        }
    }

    static func mediaTypeLabel(_ mediaType: MediaType) -> String {
        switch mediaType {
        case .img:
            return "图片"
        case .vid:
            return "视频"
        case .txt:
            return "文本"
        case .aud:
            return "声音"
        }
    }

    static func mediaCategory(for record: Record) -> String {
        dimensionLabel(record.dimension) + mediaTypeLabel(record.mediaType)
    }

    static func recordTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return todayFormatter.string(from: date)
        }
        return pastFormatter.string(from: date)
    }

    static func recordSubtitle(for record: Record) -> String {
        let mass = numberText(record.mass, maxFractionDigits: 1)
        let estVol = fixedNumberText(record.estVol, fractionDigits: 2)
        return "\(mass) g · \(estVol) mL"
    }

    static func metricDots(for record: Record) -> [MetricDot] {
        [
            MetricDot(zone: zoneIndex(for: record.typeAge, zoneCount: typeAgeLabels.count), zoneCount: typeAgeLabels.count),
            MetricDot(zone: zoneIndex(for: record.typePosition, zoneCount: typePositionLabels.count), zoneCount: typePositionLabels.count),
            MetricDot(zone: zoneIndex(for: record.typeExistence, zoneCount: typeExistenceLabels.count), zoneCount: typeExistenceLabels.count),
            MetricDot(zone: zoneIndex(for: record.time, zoneCount: timeLabels.count), zoneCount: timeLabels.count),
            MetricDot(zone: zoneIndex(for: (record.sound + 1) / 2, zoneCount: soundLabels.count), zoneCount: soundLabels.count),
            MetricDot(zone: zoneIndex(for: record.atm, zoneCount: atmLabels.count), zoneCount: atmLabels.count),
            MetricDot(zone: zoneIndex(for: record.postnut, zoneCount: postnutLabels.count), zoneCount: postnutLabels.count),
            MetricDot(zone: zoneIndex(for: record.horny, zoneCount: hornyLabels.count), zoneCount: hornyLabels.count)
        ]
    }

    static func numberText(_ value: Double, maxFractionDigits: Int) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(0 ... maxFractionDigits))
        )
    }

    static func fixedNumberText(_ value: Double, fractionDigits: Int) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(fractionDigits))
        )
    }
}

private func zoneIndex(for value: Double, zoneCount: Int) -> Int {
    guard zoneCount > 1 else { return 0 }
    let clampedValue = min(max(value, 0), 1)
    return min(Int(clampedValue * Double(zoneCount)), zoneCount - 1)
}

private func zoneColor(for zone: Int, zoneCount: Int) -> Color {
    let palette: [Color] = [.teal, .blue, .green, .orange, .pink]
    guard zoneCount > 1 else { return palette[2] }

    let scaledIndex = Int(
        round(
            Double(zone) * Double(palette.count - 1) / Double(zoneCount - 1)
        )
    )
    return palette[min(max(scaledIndex, 0), palette.count - 1)]
}
