import SwiftUI
import SwiftData
#if canImport(CoreHaptics)
import CoreHaptics
#endif
#if canImport(UIKit)
import UIKit
#endif

struct RecordsView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Record.timestamp, order: .reverse) private var records: [Record]

    @State private var expandedRecordID: PersistentIdentifier?
    @State private var appliedFilter = RecordsFilter()
    @State private var draftFilter = RecordsFilter()
    @State private var isShowingFilterSheet = false
    private let scrollAnchor = UnitPoint(x: 0.5, y: -0.03)
    private let recordListSpacing: CGFloat = 14
    private let sectionSpacing: CGFloat = 32
    private let sectionHeaderSpacing: CGFloat = 24
    private let monthGroupSpacing: CGFloat = 24
    private let contentHorizontalPadding: CGFloat = 10
    private let bigTitleLeadingPadding: CGFloat = 8
    private let recordCardHorizontalInset: CGFloat = 8
    private let bigTitleFontSize: CGFloat = 34
    private let monthTitleFontSize: CGFloat = 25
    private let filterButtonSize: CGFloat = 39
    private let filterButtonIconSize: CGFloat = 26
    private let filterButtonTrailingPadding: CGFloat = 14

    private var filteredRecords: [Record] {
        records.filter { appliedFilter.matches($0) }
    }

    private var groupedRecords: RecordGroups {
        RecordGroups(records: filteredRecords, calendar: .current)
    }

    init() {}

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: sectionSpacing) {
                    groupedSection(
                        title: "今天",
                        records: groupedRecords.today,
                        emptyText: "今天还没有记录",
                        proxy: proxy,
                        showsFilterButton: true
                    )

                    groupedSection(
                        title: "过去一周",
                        records: groupedRecords.pastWeek,
                        emptyText: "过去一周还没有记录",
                        proxy: proxy
                    )

                    earlierSection(proxy: proxy)
                }
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AddRecordBar {
                    appState.showNewRecord = true
                }
            }
            .sheet(isPresented: $isShowingFilterSheet) {
                RecordsFilterSheet(
                    draftFilter: $draftFilter,
                    onApply: applyFilter,
                    onClear: clearFilter
                )
            }
        }
    }

    @ViewBuilder
    private func groupedSection(
        title: String,
        records: [Record],
        emptyText: String,
        proxy: ScrollViewProxy,
        showsFilterButton: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: sectionHeaderSpacing) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .font(.system(size: bigTitleFontSize, weight: .bold, design: .rounded))
                    .padding(.leading, bigTitleLeadingPadding)

                Spacer(minLength: 12)

                if showsFilterButton {
                    Button {
                        draftFilter = appliedFilter
                        isShowingFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: filterButtonIconSize, weight: .semibold))
                            .foregroundStyle(appliedFilter.isActive ? Color.accentColor : Color.secondary)
                        .frame(width: filterButtonSize, height: filterButtonSize)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, filterButtonTrailingPadding)
                }
            }

            if records.isEmpty {
                EmptySectionCard(message: emptyText)
                    .padding(.horizontal, recordCardHorizontalInset)
            } else {
                VStack(spacing: recordListSpacing) {
                    ForEach(records) { record in
                        RecordEntryCard(
                            record: record,
                            isExpanded: expandedRecordID == record.persistentModelID,
                            onToggle: { toggle(record, using: proxy) },
                            onTopDone: { finishEditing(record) },
                            onBottomDone: {
                                finishEditingScrollingBelow(record, using: proxy)
                            },
                            onDeleteConfirmed: { performDelete in
                                prepareDeleteScrollingBelow(record, using: proxy, performDelete: performDelete)
                            }
                        )
                        .id(record.persistentModelID)
                    }
                }
                .padding(.horizontal, recordCardHorizontalInset)
            }
        }
    }

    @ViewBuilder
    private func earlierSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: sectionHeaderSpacing) {
            Text("更久之前")
                .font(.system(size: bigTitleFontSize, weight: .bold, design: .rounded))
                .padding(.leading, bigTitleLeadingPadding)

            if groupedRecords.earlierMonths.isEmpty {
                EmptySectionCard(message: "还没有更久之前的记录")
                    .padding(.horizontal, recordCardHorizontalInset)
            } else {
                VStack(alignment: .leading, spacing: monthGroupSpacing) {
                    ForEach(groupedRecords.earlierMonths) { monthGroup in
                        VStack(alignment: .leading, spacing: 14) {
                            Text(RecordPresentation.monthTitle(monthGroup.monthStart))
                                .font(.system(size: monthTitleFontSize, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.leading, bigTitleLeadingPadding)

                            VStack(spacing: recordListSpacing) {
                                ForEach(monthGroup.records) { record in
                                    RecordEntryCard(
                                        record: record,
                                        isExpanded: expandedRecordID == record.persistentModelID,
                                        onToggle: { toggle(record, using: proxy) },
                                        onTopDone: { finishEditing(record) },
                                        onBottomDone: {
                                            finishEditingScrollingBelow(record, using: proxy)
                                        },
                                        onDeleteConfirmed: { performDelete in
                                            prepareDeleteScrollingBelow(record, using: proxy, performDelete: performDelete)
                                        }
                                    )
                                    .id(record.persistentModelID)
                                }
                            }
                            .padding(.horizontal, recordCardHorizontalInset)
                        }
                    }
                }
            }
        }
    }

    private func toggle(_ record: Record, using proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            if expandedRecordID == record.persistentModelID {
                expandedRecordID = nil
            } else {
                expandedRecordID = record.persistentModelID
            }
        }

        if expandedRecordID != nil {
            scrollToRecord(record.persistentModelID, using: proxy, delay: 0.08)
        }
    }

    private func finishEditing(_ record: Record) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            expandedRecordID = nil
        }
    }

    private func finishEditingScrollingBelow(_ record: Record, using proxy: ScrollViewProxy) {
        let nextID = nextRecordID(after: record)

        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            expandedRecordID = nil
        }

        if let nextID {
            scrollToRecord(nextID, using: proxy, delay: 0.08)
        }
    }

    private func prepareDeleteScrollingBelow(
        _ record: Record,
        using proxy: ScrollViewProxy,
        performDelete: @escaping () -> Void
    ) {
        let nextID = nextRecordID(after: record)

        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            expandedRecordID = nil
        }

        if let nextID {
            scrollToRecord(nextID, using: proxy, delay: 0.08)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            performDelete()
        }
    }

    private func nextRecordID(after record: Record) -> PersistentIdentifier? {
        guard let currentIndex = filteredRecords.firstIndex(where: { $0.persistentModelID == record.persistentModelID }) else {
            return nil
        }

        let nextIndex = filteredRecords.index(after: currentIndex)
        guard filteredRecords.indices.contains(nextIndex) else { return nil }
        return filteredRecords[nextIndex].persistentModelID
    }

    private func scrollToRecord(_ id: PersistentIdentifier, using proxy: ScrollViewProxy, delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.28)) {
                proxy.scrollTo(id, anchor: scrollAnchor)
            }
        }
    }

    private func applyFilter() {
        appliedFilter = draftFilter
        collapseExpandedRecordIfHidden()
        isShowingFilterSheet = false
    }

    private func clearFilter() {
        appliedFilter = RecordsFilter()
        draftFilter = RecordsFilter()
        collapseExpandedRecordIfHidden()
        isShowingFilterSheet = false
    }

    private func collapseExpandedRecordIfHidden() {
        guard let expandedRecordID else { return }
        let isStillVisible = filteredRecords.contains { $0.persistentModelID == expandedRecordID }
        if !isStillVisible {
            self.expandedRecordID = nil
        }
    }
}

private struct RecordsFilter: Equatable {
    var dimension: Dimension? = nil
    var mediaType: MediaType? = nil

    var isActive: Bool {
        dimension != nil || mediaType != nil
    }

    func matches(_ record: Record) -> Bool {
        if let dimension, record.dimension != dimension {
            return false
        }

        if let mediaType, record.mediaType != mediaType {
            return false
        }

        return true
    }
}

private struct RecordsFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var draftFilter: RecordsFilter
    let onApply: () -> Void
    let onClear: () -> Void

    private var availableMediaTypes: [MediaType] {
        switch draftFilter.dimension {
        case .threeDimension:
            return [.img, .vid]
        case .twoDimension, nil:
            return [.img, .vid, .txt, .aud]
        }
    }

    private let filterGridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    FilterSectionCard(title: "次元") {
                        LazyVGrid(columns: filterGridColumns, spacing: 12) {
                            filterButton(title: "全部", isSelected: draftFilter.dimension == nil) {
                                draftFilter.dimension = nil
                            }

                            ForEach([Dimension.twoDimension, .threeDimension], id: \.self) { dimension in
                                filterButton(
                                    title: RecordPresentation.dimensionLabel(dimension),
                                    isSelected: draftFilter.dimension == dimension
                                ) {
                                    draftFilter.dimension = dimension
                                    if dimension == .threeDimension,
                                       let mediaType = draftFilter.mediaType,
                                       !availableMediaTypes.contains(mediaType) {
                                        draftFilter.mediaType = nil
                                    }
                                }
                            }
                        }
                    }

                    FilterSectionCard(title: "媒体类型") {
                        LazyVGrid(columns: filterGridColumns, spacing: 12) {
                            filterButton(title: "全部", isSelected: draftFilter.mediaType == nil) {
                                draftFilter.mediaType = nil
                            }

                            ForEach(availableMediaTypes, id: \.self) { mediaType in
                                filterButton(
                                    title: RecordPresentation.mediaTypeLabel(mediaType),
                                    isSelected: draftFilter.mediaType == mediaType
                                ) {
                                    draftFilter.mediaType = mediaType
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .navigationTitle("筛选记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 10) {
                    Button {
                        onApply()
                    } label: {
                        Text("Apply Filter")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.accentColor)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onClear()
                    } label: {
                        Text("Clear Filter")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .background {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: [.horizontal, .bottom])
                }
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 1)
                }
            }
        }
    }

    @ViewBuilder
    private func filterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(SelectionButtonStyle(isSelected: isSelected))
    }
}

private struct FilterSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            content()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
    }
}

private struct RecordEntryCard: View {
    let record: Record
    let isExpanded: Bool
    let onToggle: () -> Void
    let onTopDone: () -> Void
    let onBottomDone: () -> Void
    let onDeleteConfirmed: (@escaping () -> Void) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var draft: RecordDraft
    @State private var showDeleteConfirmation = false

    private let cardCornerRadius: CGFloat = 14

    init(
        record: Record,
        isExpanded: Bool,
        onToggle: @escaping () -> Void,
        onTopDone: @escaping () -> Void,
        onBottomDone: @escaping () -> Void,
        onDeleteConfirmed: @escaping (@escaping () -> Void) -> Void
    ) {
        self.record = record
        self.isExpanded = isExpanded
        self.onToggle = onToggle
        self.onTopDone = onTopDone
        self.onBottomDone = onBottomDone
        self.onDeleteConfirmed = onDeleteConfirmed
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
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 18)

                    RecordInlineEditor(draft: $draft) {
                        saveChanges(scrollsToNextRecord: false)
                    } onBottomDone: {
                        saveChanges(scrollsToNextRecord: true)
                    } onDelete: {
                        showDeleteConfirmation = true
                    }
                }
                .clipped()
                .transition(.recordsVerticalReveal)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(.thinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                draft = RecordDraft(record: record)
            }
        }
        .alert("是否要删除记录", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text(RecordPresentation.deletePromptTimestamp(record.timestamp))
        }
    }

    private func saveChanges(scrollsToNextRecord: Bool) {
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
        record.mass = draft.massValue
        record.preciseDensity = draft.preciseDensityValue

        try? modelContext.save()

        if scrollsToNextRecord {
            onBottomDone()
        } else {
            onTopDone()
        }
    }

    private func deleteRecord() {
        onDeleteConfirmed {
            modelContext.delete(record)
            try? modelContext.save()
        }
    }
}

private struct RecordsVerticalRevealModifier: AnimatableModifier {
    var progress: CGFloat
    private let travel: CGFloat = 28

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .offset(y: (1 - progress) * -travel)
            .mask(alignment: .top) {
                Rectangle()
                    .scaleEffect(x: 1, y: max(progress, 0.001), anchor: .top)
            }
            .opacity(progress)
    }
}

private extension AnyTransition {
    static var recordsVerticalReveal: AnyTransition {
        .modifier(
            active: RecordsVerticalRevealModifier(progress: 0),
            identity: RecordsVerticalRevealModifier(progress: 1)
        )
    }
}

private struct RecordSummaryRow: View {
    let record: Record

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TimestampLine(timestamp: record.timestamp)

            Spacer(minLength: 8)

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .trailing, spacing: 4) {
                    MetricDotStrip(metrics: RecordPresentation.metricDots(for: record))

                    Text(RecordPresentation.metricSummary(for: record))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Text(RecordPresentation.mediaCategory(for: record))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

private struct TimestampLine: View {
    let timestamp: Date

    var body: some View {
        HStack(spacing: 6) {
            if let dateText = RecordPresentation.dateText(for: timestamp) {
                Text(dateText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(RecordPresentation.timeText(for: timestamp))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .lineLimit(1)
        .layoutPriority(0)
    }
}

private struct RecordInlineEditor: View {
    @Binding var draft: RecordDraft
    let onTopDone: () -> Void
    let onBottomDone: () -> Void
    let onDelete: () -> Void

    private var preciseDensityToggleBinding: Binding<Bool> {
        Binding(
            get: { draft.usePreciseDensity },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.13)) {
                    draft.usePreciseDensity = newValue
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            EditorBlock(title: "记录时间") {
                HStack(alignment: .center, spacing: 12) {
                    DatePicker(
                        "记录时间",
                        selection: $draft.timestamp,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()

                    Spacer(minLength: 12)

                    EditorActionButton(title: "Done", variant: .prominent, isDisabled: !draft.canSave) {
                        onTopDone()
                    }
                }
            }

            EditorBlock(title: "次元") {
                HStack(spacing: 12) {
                    ForEach([Dimension.twoDimension, Dimension.threeDimension], id: \.self) { dimension in
                        Button(RecordPresentation.dimensionLabel(dimension)) {
                            draft.dimension = dimension
                            if dimension == .threeDimension,
                               let mediaType = draft.mediaType,
                               !draft.availableMediaTypes.contains(mediaType) {
                                draft.mediaType = nil
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
                    GeometryReader { geometry in
                        let compactFieldWidth = geometry.size.width / 5

                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("质量")
                                    .font(.subheadline.weight(.semibold))

                                TextField("克数", text: $draft.massText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: compactFieldWidth)
                            }

                            if draft.usePreciseDensity {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("密度")
                                        .font(.subheadline.weight(.semibold))

                                    TextField("密度", text: $draft.preciseDensityText)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: compactFieldWidth)
                                }
                                .transition(.opacity)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                    .frame(height: 62)

                    Toggle("精确密度", isOn: preciseDensityToggleBinding)
                        .font(.subheadline)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("估算体积")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(draft.estimatedVolumeText)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }

                        Spacer()
                    }

                    if !draft.canSave {
                        Text("质量或密度格式无效，暂时无法保存。")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            HStack {
                EditorActionButton(title: "Delete", variant: .destructive) {
                    onDelete()
                }

                Spacer()

                EditorActionButton(title: "Done", variant: .prominent, isDisabled: !draft.canSave) {
                    onBottomDone()
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
    }
}

private struct MetricEditorRow: View {
    let title: String
    @Binding var value: Double?
    let labels: [String]
    var range: ClosedRange<Double> = 0 ... 1
    var normalize: (Double) -> Double = { $0 }

    private var midpointValue: Double {
        (range.lowerBound + range.upperBound) / 2
    }

    private var currentZone: Int? {
        value.map { zoneIndex(for: normalize($0), zoneCount: labels.count) }
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { value ?? midpointValue },
            set: { value = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(currentZone.map { labels[$0] } ?? "未填写")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(currentZone.map { zoneColor(for: $0, zoneCount: labels.count) } ?? Color.secondary)
            }

            Slider(value: sliderBinding, in: range)
                .tint(currentZone.map { zoneColor(for: $0, zoneCount: labels.count) } ?? Color.secondary.opacity(0.55))

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
        HStack(spacing: 4) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                Circle()
                    .fill(dotColor(for: metric))
                    .frame(width: 6.5, height: 6.5)
            }
        }
    }

    private func dotColor(for metric: MetricDot) -> Color {
        guard let zone = metric.zone else {
            return Color.secondary.opacity(0.4)
        }
        return zoneColor(for: zone, zoneCount: metric.zoneCount)
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
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

private struct EditorActionButton: View {
    let title: String
    let variant: EditorActionButtonStyle.Variant
    var isDisabled: Bool = false
    let action: () -> Void

    @GestureState private var isPressed = false
    @State private var didTriggerImpact = false

    var body: some View {
        Button(title) {
            action()
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(EditorActionButtonStyle(variant: variant).backgroundColor(isPressed: effectivePressed, isDisabled: isDisabled))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    EditorActionButtonStyle(variant: variant).borderColor(isPressed: effectivePressed, isDisabled: isDisabled),
                    lineWidth: variant == .destructive ? 1 : 0
                )
        }
        .foregroundStyle(EditorActionButtonStyle(variant: variant).foregroundColor(isDisabled: isDisabled))
        .scaleEffect(effectivePressed ? 0.96 : 1)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .animation(.easeOut(duration: 0.12), value: effectivePressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    if !isDisabled {
                        state = true
                    }
                }
                .onChanged { _ in
                    guard !isDisabled, !didTriggerImpact else { return }
                    didTriggerImpact = true
                    triggerImpact()
                }
                .onEnded { _ in
                    didTriggerImpact = false
                }
        )
        .onChange(of: effectivePressed) { _, pressed in
            if !pressed {
                didTriggerImpact = false
            }
        }
    }

    private var effectivePressed: Bool {
        !isDisabled && isPressed
    }

    private func triggerImpact() {
        EditorActionHaptics.shared.play(for: variant)
    }
}

private struct EditorActionButtonStyle {
    enum Variant {
        case prominent
        case destructive
    }

    let variant: Variant

    func backgroundColor(isPressed: Bool, isDisabled: Bool) -> Color {
        switch variant {
        case .prominent:
            let baseOpacity = isDisabled ? 0.4 : 1.0
            return Color.accentColor.opacity((isPressed ? 0.78 : 1) * baseOpacity)
        case .destructive:
            let baseOpacity = isDisabled ? 0.45 : 1.0
            return Color.red.opacity((isPressed ? 0.18 : 0.10) * baseOpacity)
        }
    }

    func borderColor(isPressed: Bool, isDisabled: Bool) -> Color {
        switch variant {
        case .prominent:
            return .clear
        case .destructive:
            let baseOpacity = isDisabled ? 0.35 : 1.0
            return Color.red.opacity((isPressed ? 0.72 : 0.82) * baseOpacity)
        }
    }

    func foregroundColor(isDisabled: Bool) -> Color {
        switch variant {
        case .prominent:
            return Color.white.opacity(isDisabled ? 0.75 : 1)
        case .destructive:
            return Color.red.opacity(isDisabled ? 0.55 : 1)
        }
    }
}

private struct EditorActionHapticEvent {
    enum Kind {
        case transient
        case continuous
    }

    let kind: Kind
    let intensity: Float
    let sharpness: Float
    let relativeTime: TimeInterval
    var duration: TimeInterval? = nil
}

private struct EditorActionHapticConfiguration {
    let events: [EditorActionHapticEvent]
}

private final class EditorActionHaptics {
    static let shared = EditorActionHaptics()

    // Tune these event lists directly to change the Done/Delete button feel.
    private let doneConfiguration = EditorActionHapticConfiguration(
        events: [
            EditorActionHapticEvent(
                kind: .transient,
                intensity: 0.2,
                sharpness: 0.45,
                relativeTime: 0
            ),
            EditorActionHapticEvent(
                kind: .continuous,
                intensity: 0.1,
                sharpness: 0.1,
                relativeTime: 0,
                duration:0.3
            ),
            EditorActionHapticEvent(
                kind: .transient,
                intensity: 1.0,
                sharpness: 0.8,
                relativeTime: 0.3
            )
        ]
    )
    private let deleteConfiguration = EditorActionHapticConfiguration(
        events: [
            EditorActionHapticEvent(
                kind: .transient,
                intensity: 0.5,
                sharpness: 0.1,
                relativeTime: 0
            ),
            EditorActionHapticEvent(
                kind: .transient,
                intensity: 0.0,
                sharpness: 0.0,
                relativeTime: 0.06
            )
        ]
    )

#if canImport(CoreHaptics)
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private var engine: CHHapticEngine?
#endif

    private init() {
#if canImport(CoreHaptics)
        configureEngineIfNeeded()
#endif
    }

    func play(for variant: EditorActionButtonStyle.Variant) {
        let configuration = configuration(for: variant)

#if canImport(CoreHaptics)
        guard supportsHaptics else {
            fallbackImpact(for: variant)
            return
        }

        startEngineIfNeeded()
        guard let engine else {
            fallbackImpact(for: variant)
            return
        }

        let events = configuration.events.compactMap { hapticEvent(for: $0) }
        guard !events.isEmpty else {
            fallbackImpact(for: variant)
            return
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            fallbackImpact(for: variant)
        }
#else
        fallbackImpact(for: variant)
#endif
    }

    private func configuration(for variant: EditorActionButtonStyle.Variant) -> EditorActionHapticConfiguration {
        switch variant {
        case .prominent:
            return doneConfiguration
        case .destructive:
            return deleteConfiguration
        }
    }

    private func hapticEvent(for event: EditorActionHapticEvent) -> CHHapticEvent? {
        let parameters = [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: event.intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: event.sharpness)
        ]

        switch event.kind {
        case .transient:
            return CHHapticEvent(
                eventType: .hapticTransient,
                parameters: parameters,
                relativeTime: event.relativeTime
            )
        case .continuous:
            return CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: parameters,
                relativeTime: event.relativeTime,
                duration: event.duration ?? 0.1
            )
        }
    }

#if canImport(CoreHaptics)
    private func configureEngineIfNeeded() {
        guard supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true
            engine?.stoppedHandler = { [weak self] _ in
                self?.engine = nil
            }
            engine?.resetHandler = { [weak self] in
                self?.configureEngineIfNeeded()
                self?.startEngineIfNeeded()
            }
        } catch {
            engine = nil
        }
    }

    private func startEngineIfNeeded() {
        guard supportsHaptics else { return }
        if engine == nil {
            configureEngineIfNeeded()
        }
        try? engine?.start()
    }
#endif // canImport(CoreHaptics)

    private func fallbackImpact(for variant: EditorActionButtonStyle.Variant) {
#if canImport(UIKit)
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch variant {
        case .prominent:
            style = .soft
        case .destructive:
            style = .rigid
        }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
#endif // canImport(UIKit)
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
    let zone: Int?
    let zoneCount: Int
}

private struct RecordDraft {
    var timestamp: Date
    var dimension: Dimension?
    var mediaType: MediaType?
    var typeAge: Double?
    var typePosition: Double?
    var typeExistence: Double?
    var time: Double?
    var sound: Double?
    var atm: Double?
    var postnut: Double?
    var horny: Double?
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
        massText = record.mass.map {
            RecordPresentation.numberText($0, maxFractionDigits: 2)
        } ?? ""
        usePreciseDensity = record.preciseDensity != nil
        preciseDensityText = record.preciseDensity.map {
            RecordPresentation.numberText($0, maxFractionDigits: 3)
        } ?? ""
    }

    var availableMediaTypes: [MediaType] {
        switch dimension {
        case .twoDimension:
            return [.img, .vid, .txt, .aud]
        case .threeDimension:
            return [.img, .vid]
        case nil:
            return [.img, .vid, .txt, .aud]
        }
    }

    var massValue: Double? {
        parsedOptionalNumber(from: massText)
    }

    var preciseDensityValue: Double? {
        guard usePreciseDensity else { return nil }
        return parsedOptionalNumber(from: preciseDensityText)
    }

    var canSave: Bool {
        hasValidNumber(massText) && (!usePreciseDensity || hasValidNumber(preciseDensityText))
    }

    var estimatedVolumeText: String {
        guard let massValue else { return "--" }
        let density = preciseDensityValue ?? 1.035
        let estVol = massValue / density
        return "\(RecordPresentation.fixedNumberText(estVol, fractionDigits: 2)) mL"
    }

    private func parsedOptionalNumber(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private func hasValidNumber(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || Double(trimmed) != nil
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

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private static let deletePromptFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
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
        switch (record.dimension, record.mediaType) {
        case let (.some(dimension), .some(mediaType)):
            return dimensionLabel(dimension) + mediaTypeLabel(mediaType)
        case let (.some(dimension), nil):
            return dimensionLabel(dimension)
        case let (nil, .some(mediaType)):
            return mediaTypeLabel(mediaType)
        case (nil, nil):
            return "未分类"
        }
    }

    static func dateText(for date: Date) -> String? {
        let calendar = Calendar.current
        guard !calendar.isDateInToday(date) else {
            return nil
        }
        return dateFormatter.string(from: date)
    }

    static func timeText(for date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func deletePromptTimestamp(_ date: Date) -> String {
        deletePromptFormatter.string(from: date)
    }

    static func metricSummary(for record: Record) -> String {
        let mass = record.mass.map { numberText($0, maxFractionDigits: 1) } ?? "--"
        let estVol = record.estVol.map { fixedNumberText($0, fractionDigits: 2) } ?? "--"
        return "\(mass) g · \(estVol) mL"
    }

    static func metricDots(for record: Record) -> [MetricDot] {
        [
            MetricDot(zone: record.typeAge.map { zoneIndex(for: $0, zoneCount: typeAgeLabels.count) }, zoneCount: typeAgeLabels.count),
            MetricDot(zone: record.typePosition.map { zoneIndex(for: $0, zoneCount: typePositionLabels.count) }, zoneCount: typePositionLabels.count),
            MetricDot(zone: record.typeExistence.map { zoneIndex(for: $0, zoneCount: typeExistenceLabels.count) }, zoneCount: typeExistenceLabels.count),
            MetricDot(zone: record.time.map { zoneIndex(for: $0, zoneCount: timeLabels.count) }, zoneCount: timeLabels.count),
            MetricDot(zone: record.sound.map { zoneIndex(for: ($0 + 1) / 2, zoneCount: soundLabels.count) }, zoneCount: soundLabels.count),
            MetricDot(zone: record.atm.map { zoneIndex(for: $0, zoneCount: atmLabels.count) }, zoneCount: atmLabels.count),
            MetricDot(zone: record.postnut.map { zoneIndex(for: $0, zoneCount: postnutLabels.count) }, zoneCount: postnutLabels.count),
            MetricDot(zone: record.horny.map { zoneIndex(for: $0, zoneCount: hornyLabels.count) }, zoneCount: hornyLabels.count)
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
