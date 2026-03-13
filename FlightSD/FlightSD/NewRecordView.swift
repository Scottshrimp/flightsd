import SwiftUI
import SwiftData

struct NewRecordView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenNewRecordIntroCard") private var hasSeenNewRecordIntroCard: Bool = false

    @State private var activeField: Int? = 0
    @State private var showIntroCard: Bool = false

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

    private let typeAgeLabels = ["区间1", "区间2", "区间3", "区间4", "区间5"]
    private let typePositionLabels = ["区间1", "区间2", "区间3", "区间4", "区间5"]
    private let typeExistenceLabels = ["区间1", "区间2"]
    private let timeLabels = ["很短", "短", "中", "长", "很长"]
    private let soundLabels = ["不喜欢", "纯图", "喜欢", "纯音"]
    private let atmLabels = ["纯视觉", "偏视觉", "偏情境", "纯情境"]
    private let postnutLabels = ["很开心", "没感觉", "有点累", "眼皮打架"]
    private let hornyLabels = ["低", "中低", "中高", "高"]
    private let scrollAnchor = UnitPoint(x: 0.5, y: 0.68)

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
            postnut != nil,
            horny != nil,
            !mass.isEmpty
        ]
    }

    private var allFilled: Bool {
        filledStatus.allSatisfy { $0 }
    }

    private var availableMediaTypes: [MediaType] {
        dimension == .twoDimension ? [.img, .vid, .txt, .aud] : [.img, .vid]
    }

    private var estimatedVolumeText: String {
        guard let massValue = Double(mass) else { return "--" }
        let density = usePreciseDensity ? (Double(preciseDensityInput) ?? 1.035) : 1.035
        let estimatedVolume = massValue / density
        return "\(newRecordFixedNumberText(estimatedVolume, fractionDigits: 2)) mL"
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        if showIntroCard {
                            headerCard
                        }

                        VStack(spacing: 12) {
                            FieldRow(
                                index: 0,
                                title: "次元",
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
                                title: "媒体类型",
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
                                title: "年龄感",
                                value: Binding(get: { typeAge ?? 0.5 }, set: { typeAge = $0 }),
                                filled: typeAge,
                                labels: typeAgeLabels
                            )
                            .id(fieldScrollID(2))

                            sliderRow(
                                index: 3,
                                title: "体位",
                                value: Binding(get: { typePosition ?? 0.5 }, set: { typePosition = $0 }),
                                filled: typePosition,
                                labels: typePositionLabels
                            )
                            .id(fieldScrollID(3))

                            sliderRow(
                                index: 4,
                                title: "存在感",
                                value: Binding(get: { typeExistence ?? 0.5 }, set: { typeExistence = $0 }),
                                filled: typeExistence,
                                labels: typeExistenceLabels
                            )
                            .id(fieldScrollID(4))

                            sliderRow(
                                index: 5,
                                title: "时长",
                                value: Binding(get: { time ?? 0.5 }, set: { time = $0 }),
                                filled: time,
                                labels: timeLabels
                            )
                            .id(fieldScrollID(5))

                            sliderRow(
                                index: 6,
                                title: "声音",
                                value: Binding(get: { ((sound ?? 0.0) + 1) / 2 }, set: { sound = $0 * 2 - 1 }),
                                filled: sound.map { ($0 + 1) / 2 },
                                labels: soundLabels
                            )
                            .id(fieldScrollID(6))

                            sliderRow(
                                index: 7,
                                title: "氛围",
                                value: Binding(get: { atm ?? 0.5 }, set: { atm = $0 }),
                                filled: atm,
                                labels: atmLabels
                            )
                            .id(fieldScrollID(7))

                            sliderRow(
                                index: 8,
                                title: "事后状态",
                                value: Binding(get: { postnut ?? 0.5 }, set: { postnut = $0 }),
                                filled: postnut,
                                labels: postnutLabels
                            )
                            .id(fieldScrollID(8))

                            sliderRow(
                                index: 9,
                                title: "欲望程度",
                                value: Binding(get: { horny ?? 0.5 }, set: { horny = $0 }),
                                filled: horny,
                                labels: hornyLabels
                            )
                            .id(fieldScrollID(9))

                            FieldRow(
                                index: 10,
                                title: "质量",
                                activeField: $activeField,
                                filledValue: activeField != 10 ? massSummary : nil
                            ) {
                                VStack(alignment: .leading, spacing: 16) {
                                    GeometryReader { geometry in
                                        let compactFieldWidth = geometry.size.width / 5

                                        HStack(alignment: .top, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("质量")
                                                    .font(.subheadline.weight(.semibold))

                                                TextField("克数", text: $mass)
                                                    .keyboardType(.decimalPad)
                                                    .textFieldStyle(.roundedBorder)
                                                    .frame(width: compactFieldWidth)
                                            }

                                            if usePreciseDensity {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("密度")
                                                        .font(.subheadline.weight(.semibold))

                                                    TextField("密度", text: $preciseDensityInput)
                                                        .keyboardType(.decimalPad)
                                                        .textFieldStyle(.roundedBorder)
                                                        .frame(width: compactFieldWidth)
                                                }
                                            }

                                            Spacer(minLength: 0)
                                        }
                                    }
                                    .frame(height: 62)

                                    Toggle("精确密度", isOn: $usePreciseDensity)
                                        .font(.subheadline)

                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("估算体积")
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
            .navigationTitle("新记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
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
                    Text("估算体积")
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
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.thinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
    }

    private var actionBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    saveAndDismiss()
                } label: {
                    Text("完成")
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
                        Button("5 分钟后提醒") { saveAndDismiss(reminderMinutes: 5) }
                        Button("15 分钟后提醒") { saveAndDismiss(reminderMinutes: 15) }
                        Button("30 分钟后提醒") { saveAndDismiss(reminderMinutes: 30) }
                        Button("1 小时后提醒") { saveAndDismiss(reminderMinutes: 60) }
                        Button("2 小时后提醒") { saveAndDismiss(reminderMinutes: 120) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
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
            dimension: dimension ?? .twoDimension,
            mediaType: mediaType ?? .img,
            typeAge: typeAge ?? 0.5,
            typePosition: typePosition ?? 0.5,
            typeExistence: typeExistence ?? 0.5,
            time: time ?? 0.5,
            sound: sound ?? 0.0,
            atm: atm ?? 0.5,
            postnut: postnut ?? 0.5,
            horny: horny ?? 0.5,
            mass: Double(mass) ?? 0.0,
            preciseDensity: usePreciseDensity ? Double(preciseDensityInput) : nil
        )

        modelContext.insert(record)
        try? modelContext.save()
    }

    private func scheduleReminder(minutes: Int) {
        print("将在 \(minutes) 分钟后提醒")
    }

    private func markIntroCardSeenIfNeeded() {
        guard !hasSeenNewRecordIntroCard else { return }
        showIntroCard = true
        hasSeenNewRecordIntroCard = true
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
                let thumbX = value * trackWidth

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.18))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(accentColor)
                        .frame(width: thumbX, height: 6)

                    Circle()
                        .fill(accentColor)
                        .frame(width: isDragging ? 28 : 22, height: isDragging ? 28 : 22)
                        .shadow(color: accentColor.opacity(0.35), radius: isDragging ? 10 : 4, y: 2)
                        .offset(x: thumbX - (isDragging ? 14 : 11))
                        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isDragging)
                }
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

            if isExpanded {
                Divider()
                    .padding(.horizontal, 18)

                content()
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
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
