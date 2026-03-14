import SwiftUI
import SwiftData

struct NewRecordView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenNewRecordIntroCard") private var hasSeenNewRecordIntroCard: Bool = false
    @Query(sort: \Record.timestamp, order: .reverse) private var records: [Record]

    @State private var activeField: Int? = 0
    @State private var showIntroCard: Bool = false
    @State private var recordDate: Date = normalizedRecordDate(.now)
    @State private var exactTime: Date? = .now
    @State private var isExactTimePickerPresented = false

    @State private var dimension: Dimension? = nil
    @State private var mediaType: MediaType? = nil
    @State private var typeAge: Double? = nil
    @State private var typePosition: Double? = nil
    @State private var typeExistence: Double? = nil
    @State private var time: Double? = nil
    @State private var sound: Double? = nil
    @State private var atm: Double? = nil
    @State private var postnut: Double? = nil
    @State private var horny: Double? = nil
    @State private var mass: String = ""
    @State private var usePreciseDensity: Bool = false
    @State private var preciseDensityInput: String = ""

    private let typeAgeLabels = ["萝莉", "妹妹系", "少女", "姐姐系", "妈妈系"]
    private let typePositionLabels = ["完全被动", "被动", "中等", "主动", "完全主动"]
    private let typeExistenceLabels = ["弱", "偏弱", "中等", "偏强", "强"]
    private let timeLabels = ["很短", "短", "中", "长", "很长"]
    private let soundLabels = ["无声", "有声", "喜欢", "纯音"]
    private let atmLabels = ["纯视觉", "偏视觉", "偏情境", "纯情境"]
    private let postnutLabels = ["很放松", "没感觉", "有点累", "眼皮打架"]
    private let hornyLabels = ["低", "中低", "中高", "高"]
    private let scrollAnchor = UnitPoint(x: 0.5, y: 0.5)

    private var filledStatus: [Bool] {
        [
            dimension != nil,
            mediaType != nil,
            typeAge != nil,
            typePosition != nil,
            typeExistence != nil,
            time != nil,
            sound != nil,
            atm != nil,
            horny != nil,
            postnut != nil,
            !mass.isEmpty
        ]
    }

    private var allFilled: Bool {
        filledStatus.allSatisfy { $0 }
    }

    private var availableMediaTypes: [MediaType] {
        switch dimension {
        case .twoDimension:
            return [.img, .vid, .txt, .aud]
        case .threeDimension:
            return [.img, .vid]
        case nil:
            return [.img, .vid, .txt, .aud]
        }
    }

    private var estimatedVolumeText: String {
        guard let massValue = parsedOptionalNumber(from: mass) else { return "--" }
        let fallbackDensity = effectiveGlobalDensity(from: records)
        let density = usePreciseDensity ? (parsedOptionalNumber(from: preciseDensityInput) ?? fallbackDensity) : fallbackDensity
        let estimatedVolume = massValue / density
        return "\(newRecordFixedNumberText(estimatedVolume, fractionDigits: 2)) mL"
    }

    private var preciseDensityToggleBinding: Binding<Bool> {
        Binding(
            get: { usePreciseDensity },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.13)) {
                    usePreciseDensity = newValue
                }
            }
        )
    }

    private var recordDateBinding: Binding<Date> {
        Binding(
            get: { recordDate },
            set: { newValue in
                let normalizedDate = normalizedRecordDate(newValue)
                recordDate = normalizedDate
                if let exactTime {
                    self.exactTime = combinedRecordDate(normalizedDate, time: exactTime)
                }
            }
        )
    }

    private var timePickerSeed: Date {
        exactTime ?? combinedRecordDate(recordDate, time: .now)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        recordTimeCard

                        if showIntroCard {
                            headerCard
                        }

                        VStack(spacing: 12) {
                            FieldRow(
                                index: 0,
                                title: "Dimension",
                                activeField: $activeField,
                                filledValue: activeField != 0 ? dimension.map(dimensionLabel) : nil
                            ) {
                                selectionGrid(
                                    options: [Dimension.twoDimension, .threeDimension],
                                    label: dimensionLabel,
                                    selection: dimension
                                ) { selected in
                                    dimension = selected
                                    if selected == .threeDimension && (mediaType == .txt || mediaType == .aud) {
                                        mediaType = nil
                                    }
                                    advance(from: 0)
                                }
                            }
                            .id(fieldScrollID(0))

                            FieldRow(
                                index: 1,
                                title: "Media Type",
                                activeField: $activeField,
                                filledValue: activeField != 1 ? mediaType.map(mediaTypeLabel) : nil
                            ) {
                                selectionGrid(
                                    options: availableMediaTypes,
                                    label: mediaTypeLabel,
                                    selection: mediaType
                                ) { selected in
                                    mediaType = selected
                                    advance(from: 1)
                                }
                            }
                            .id(fieldScrollID(1))

                            sliderRow(
                                index: 2,
                                title: "Age",
                                value: Binding(get: { typeAge ?? 0.5 }, set: { typeAge = $0 }),
                                filled: typeAge,
                                labels: typeAgeLabels
                            )
                            .id(fieldScrollID(2))

                            sliderRow(
                                index: 3,
                                title: "Position",
                                value: Binding(get: { typePosition ?? 0.5 }, set: { typePosition = $0 }),
                                filled: typePosition,
                                labels: typePositionLabels
                            )
                            .id(fieldScrollID(3))

                            sliderRow(
                                index: 4,
                                title: "Existence",
                                value: Binding(get: { typeExistence ?? 0.5 }, set: { typeExistence = $0 }),
                                filled: typeExistence,
                                labels: typeExistenceLabels
                            )
                            .id(fieldScrollID(4))

                            sliderRow(
                                index: 5,
                                title: "Time",
                                value: Binding(get: { time ?? 0.5 }, set: { time = $0 }),
                                filled: time,
                                labels: timeLabels
                            )
                            .id(fieldScrollID(5))

                            sliderRow(
                                index: 6,
                                title: "Audio",
                                value: Binding(get: { ((sound ?? 0.0) + 1) / 2 }, set: { sound = $0 * 2 - 1 }),
                                filled: sound.map { ($0 + 1) / 2 },
                                labels: soundLabels
                            )
                            .id(fieldScrollID(6))

                            sliderRow(
                                index: 7,
                                title: "Atm",
                                value: Binding(get: { atm ?? 0.5 }, set: { atm = $0 }),
                                filled: atm,
                                labels: atmLabels
                            )
                            .id(fieldScrollID(7))

                            sliderRow(
                                index: 8,
                                title: "Horny Level",
                                value: Binding(get: { horny ?? 0.5 }, set: { horny = $0 }),
                                filled: horny,
                                labels: hornyLabels
                            )
                            .id(fieldScrollID(8))

                            sliderRow(
                                index: 9,
                                title: "Postnut",
                                value: Binding(get: { postnut ?? 0.5 }, set: { postnut = $0 }),
                                filled: postnut,
                                labels: postnutLabels
                            )
                            .id(fieldScrollID(9))

                            FieldRow(
                                index: 10,
                                title: "Mass",
                                activeField: $activeField,
                                filledValue: activeField != 10 ? massSummary : nil
                            ) {
                                VStack(alignment: .leading, spacing: 16) {
                                    GeometryReader { geometry in
                                        let compactFieldWidth = max(118, geometry.size.width * 0.26)

                                        HStack(alignment: .top, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Mass")
                                                    .font(.subheadline.weight(.semibold))

                                                TextField("gram", text: $mass)
                                                    .keyboardType(.decimalPad)
                                                    .textFieldStyle(.roundedBorder)
                                                    .frame(width: compactFieldWidth)
                                            }

                                            if usePreciseDensity {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("Density")
                                                        .font(.subheadline.weight(.semibold))

                                                    TextField("g/cm^3", text: $preciseDensityInput)
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

                                    Toggle("Exact Density", isOn: preciseDensityToggleBinding)
                                        .font(.subheadline)

                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("est.Vol")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            Text(estimatedVolumeText)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                        }

                                        Spacer()
                                    }
                                }
                            }
                            .id(fieldScrollID(10))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                }
                .onAppear {
                    markIntroCardSeenIfNeeded()
                    scrollToField(activeField, using: proxy, animated: false)
                }
                .onChange(of: activeField) { _, newValue in
                    scrollToField(newValue, using: proxy, animated: true)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actionBar
            }
            .navigationTitle("New Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("记录这一次")
                .font(.system(.title2, design: .rounded).weight(.bold))

            Text(allFilled ? "所有字段都已填完，可以直接保存。" : "按顺序快速填写，也可以直接点开任意卡片补充。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !mass.isEmpty {
                HStack {
                    Text("est.Vol")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(estimatedVolumeText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
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

    private var recordTimeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                DatePicker(
                    "Date",
                    selection: recordDateBinding,
                    displayedComponents: [.date]
                )
                .labelsHidden()

                OptionalTimeFieldButton(
                    time: exactTime,
                    placeholder: "",
                    width: 96
                ) {
                    isExactTimePickerPresented = true
                }

                Spacer(minLength: 0)

                Button("Clear Time") {
                    exactTime = nil
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(exactTime == nil ? Color.secondary : Color.accentColor)
            }
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
        .sheet(isPresented: $isExactTimePickerPresented) {
            TimeSelectionSheet(title: "Time", initialTime: timePickerSeed) { selectedTime in
                exactTime = combinedRecordDate(recordDate, time: selectedTime)
            }
        }
    }

    private var actionBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    saveAndDismiss()
                } label: {
                    Text("Done")
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

                if !allFilled {
                    Button {
                        saveAndDismiss(reminderMinutes: 30)
                    } label: {
                        Image(systemName: "clock.badge")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("2 小时后提醒") { saveAndDismiss(reminderMinutes: 120) }
                        Button("1 小时后提醒") { saveAndDismiss(reminderMinutes: 60) }
                        Button("30 分钟后提醒") { saveAndDismiss(reminderMinutes: 30) }
                        Button("15 分钟后提醒") { saveAndDismiss(reminderMinutes: 15) }
                        Button("5 分钟后提醒") { saveAndDismiss(reminderMinutes: 5) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .padding(.top, 12)
        }
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
        .padding(.top, 8)
        .shadow(color: .black.opacity(0.04), radius: 12, y: -2)
    }

    @ViewBuilder
    private func selectionGrid<T: Hashable>(
        options: [T],
        label: @escaping (T) -> String,
        selection: T?,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(options, id: \.self) { option in
                Button(label(option)) {
                    onSelect(option)
                }
                .buttonStyle(SelectionButtonStyle(isSelected: selection == option))
            }
        }
    }

    @ViewBuilder
    private func sliderRow(
        index: Int,
        title: String,
        value: Binding<Double>,
        filled: Double?,
        labels: [String]
    ) -> some View {
        FieldRow(
            index: index,
            title: title,
            activeField: $activeField,
            filledValue: activeField != index ? filled.map { sliderLabel(value: $0, labels: labels) } : nil
        ) {
            CustomSliderField(value: value, labels: labels) {
                advance(from: index)
            }
        }
    }

    private var massSummary: String? {
        guard !mass.isEmpty else { return nil }
        return "\(mass) g · \(estimatedVolumeText)"
    }

    private func advance(from index: Int) {
        if let next = (index + 1 ..< filledStatus.count).first(where: { !filledStatus[$0] }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                activeField = next
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                activeField = nil
            }
        }
    }

    private func sliderLabel(value: Double, labels: [String]) -> String {
        let index = min(Int(value * Double(labels.count)), labels.count - 1)
        return labels[index]
    }

    private func dimensionLabel(_ dimension: Dimension) -> String {
        switch dimension {
        case .twoDimension:
            return "二次元"
        case .threeDimension:
            return "三次元"
        }
    }

    private func mediaTypeLabel(_ mediaType: MediaType) -> String {
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

    private func saveAndDismiss(reminderMinutes: Int? = nil) {
        saveRecord()
        if let reminderMinutes {
            scheduleReminder(minutes: reminderMinutes)
        }
        dismiss()
    }

    private func saveRecord() {
        let record = Record(
            timestamp: recordDate,
            exactTime: exactTime,
            dimension: dimension,
            mediaType: mediaType,
            typeAge: typeAge,
            typePosition: typePosition,
            typeExistence: typeExistence,
            time: time,
            sound: sound,
            atm: atm,
            postnut: postnut,
            horny: horny,
            mass: parsedOptionalNumber(from: mass),
            preciseDensity: usePreciseDensity ? parsedOptionalNumber(from: preciseDensityInput) : nil
        )

        modelContext.insert(record)
        try? modelContext.save()
        refreshStoredAverages(in: modelContext)
    }

    private func scheduleReminder(minutes: Int) {
        print("将在 \(minutes) 分钟后提醒")
    }

    private func markIntroCardSeenIfNeeded() {
        guard !hasSeenNewRecordIntroCard else { return }
        showIntroCard = true
        hasSeenNewRecordIntroCard = true
    }

    private func parsedOptionalNumber(from text: String) -> Double? {
        parsedRecordNumber(from: text)
    }

    private func fieldScrollID(_ index: Int) -> String {
        "new-record-field-\(index)"
    }

    private func scrollToField(_ index: Int?, using proxy: ScrollViewProxy, animated: Bool) {
        guard let index else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            if animated {
                withAnimation(.easeInOut(duration: 0.34)) {
                    proxy.scrollTo(fieldScrollID(index), anchor: scrollAnchor)
                }
            } else {
                proxy.scrollTo(fieldScrollID(index), anchor: scrollAnchor)
            }
        }
    }
}

struct CustomSliderField: View {
    @Binding var value: Double
    let labels: [String]
    let onRelease: () -> Void

    @State private var lastZone: Int = -1
    @State private var isDragging: Bool = false

    private var currentZone: Int {
        newRecordZoneIndex(for: value, zoneCount: labels.count)
    }

    private var accentColor: Color {
        newRecordZoneColor(for: currentZone, zoneCount: labels.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(labels[currentZone])
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.14))
                    )

                Spacer()
            }

            HStack(spacing: 0) {
                ForEach(labels.indices, id: \.self) { index in
                    Text(labels[index])
                        .font(.caption2)
                        .foregroundStyle(index == currentZone ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let filledWidth = max(0, min(trackWidth, value * trackWidth))
                let boundaryCount = max(labels.count - 1, 0)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color.secondary.opacity(0.14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                        }
                        .frame(height: 14)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(isDragging ? 0.92 : 0.82),
                                    accentColor
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: filledWidth, height: 14)
                        .animation(.easeInOut(duration: 0.12), value: isDragging)

                    if boundaryCount > 0 {
                        ForEach(1 ... boundaryCount, id: \.self) { boundary in
                            Rectangle()
                                .fill(Color.primary.opacity(0.18))
                                .frame(width: 1, height: 14)
                                .offset(x: trackWidth * CGFloat(boundary) / CGFloat(labels.count) - 0.5)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .frame(height: 36)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { drag in
                            isDragging = true
                            let newValue = max(0, min(1, drag.location.x / trackWidth))
                            value = newValue

                            let zone = newRecordZoneIndex(for: newValue, zoneCount: labels.count)
                            if zone != lastZone {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                lastZone = zone
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onRelease()
                        }
                )
            }
            .frame(height: 36)
        }
    }
}

struct FieldRow<Content: View>: View {
    let index: Int
    let title: String
    @Binding var activeField: Int?
    let filledValue: String?
    @ViewBuilder let content: () -> Content

    private let cardCornerRadius: CGFloat = 14

    private var isExpanded: Bool {
        activeField == index
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    activeField = isExpanded ? nil : index
                }
            } label: {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if let filledValue, !isExpanded {
                            Text(filledValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            SlidingFieldExpansion(isExpanded: isExpanded) {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 18)

                    content()
                        .padding(.horizontal, 18)
                        .padding(.vertical, 18)
                }
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
    }
}

private struct SlidingFieldExpansion<Content: View>: View {
    let isExpanded: Bool
    @ViewBuilder let content: () -> Content

    @State private var measuredHeight: CGFloat = 0

    private var progress: CGFloat {
        isExpanded ? 1 : 0
    }

    var body: some View {
        content()
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SlidingFieldExpansionHeightKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(SlidingFieldExpansionHeightKey.self) { height in
                measuredHeight = height
            }
            .offset(y: (1 - progress) * -28)
            .frame(height: measuredHeight * progress, alignment: .top)
            .clipped()
            .opacity(progress)
            .allowsHitTesting(isExpanded)
            .accessibilityHidden(!isExpanded)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isExpanded)
    }
}

private struct SlidingFieldExpansionHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct SelectionButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.05))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                        lineWidth: 1
                    )
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

private func newRecordZoneIndex(for value: Double, zoneCount: Int) -> Int {
    guard zoneCount > 1 else { return 0 }
    let clampedValue = min(max(value, 0), 1)
    return min(Int(clampedValue * Double(zoneCount)), zoneCount - 1)
}

private func newRecordZoneColor(for zone: Int, zoneCount: Int) -> Color {
    let palette: [Color] = [.teal, .blue, .green, .orange, .pink]
    guard zoneCount > 1 else { return palette[2] }

    let scaledIndex = Int(
        round(
            Double(zone) * Double(palette.count - 1) / Double(zoneCount - 1)
        )
    )

    return palette[min(max(scaledIndex, 0), palette.count - 1)]
}

private func newRecordNumberText(_ value: Double, maxFractionDigits: Int) -> String {
    value.formatted(
        .number
            .precision(.fractionLength(0 ... maxFractionDigits))
    )
}

private func newRecordFixedNumberText(_ value: Double, fractionDigits: Int) -> String {
    value.formatted(
        .number
            .precision(.fractionLength(fractionDigits))
    )
}
