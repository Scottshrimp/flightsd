import SwiftUI
import SwiftData

struct NewRecordView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var activeField: Int? = 0

    @State private var dimension: Dimension = .twoDimension
    @State private var mediaType: MediaType = .img
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

    private var allFilled: Bool {
        typeAge != nil && typePosition != nil && typeExistence != nil &&
        time != nil && sound != nil && atm != nil &&
        postnut != nil && horny != nil && !mass.isEmpty
    }

    private var availableMediaTypes: [MediaType] {
        dimension == .twoDimension ? [.img, .vid, .txt, .aud] : [.img, .vid]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    FieldRow(index: 0, title: "次元", activeField: $activeField,
                             filledValue: activeField != 0 ? dimension.rawValue : nil) {
                        HStack(spacing: 12) {
                            ForEach([Dimension.twoDimension, Dimension.threeDimension], id: \.self) { d in
                                Button(d == .twoDimension ? "二次元" : "三次元") {
                                    dimension = d
                                    if d == .threeDimension && (mediaType == .txt || mediaType == .aud) {
                                        mediaType = .img
                                    }
                                    advance(from: 0)
                                }
                                .buttonStyle(SelectionButtonStyle(isSelected: dimension == d))
                            }
                        }
                        .padding(.vertical, 12).padding(.horizontal, 16)
                    }

                    FieldRow(index: 1, title: "媒体类型", activeField: $activeField,
                             filledValue: activeField != 1 ? mediaTypeLabel(mediaType) : nil) {
                        HStack(spacing: 12) {
                            ForEach(availableMediaTypes, id: \.self) { m in
                                Button(mediaTypeLabel(m)) {
                                    mediaType = m
                                    advance(from: 1)
                                }
                                .buttonStyle(SelectionButtonStyle(isSelected: mediaType == m))
                            }
                        }
                        .padding(.vertical, 12).padding(.horizontal, 16)
                    }

                    sliderRow(index: 2, title: "年龄感",
                              value: Binding(get: { typeAge ?? 0.5 }, set: { typeAge = $0 }),
                              filled: typeAge,
                              labels: ["区间1", "区间2", "区间3", "区间4", "区间5"])

                    sliderRow(index: 3, title: "体位",
                              value: Binding(get: { typePosition ?? 0.5 }, set: { typePosition = $0 }),
                              filled: typePosition,
                              labels: ["区间1", "区间2", "区间3", "区间4", "区间5"])

                    sliderRow(index: 4, title: "存在感",
                              value: Binding(get: { typeExistence ?? 0.5 }, set: { typeExistence = $0 }),
                              filled: typeExistence,
                              labels: ["区间1", "区间2"])

                    sliderRow(index: 5, title: "时长",
                              value: Binding(get: { time ?? 0.5 }, set: { time = $0 }),
                              filled: time,
                              labels: ["很短", "短", "中", "长", "很长"])

                    sliderRow(index: 6, title: "声音",
                              value: Binding(get: { ((sound ?? 0.0) + 1) / 2 }, set: { sound = $0 * 2 - 1 }),
                              filled: sound,
                              labels: ["不喜欢", "纯图", "喜欢", "纯音"])

                    sliderRow(index: 7, title: "氛围",
                              value: Binding(get: { atm ?? 0.5 }, set: { atm = $0 }),
                              filled: atm,
                              labels: ["纯视觉", "偏视觉", "偏情境", "纯情境"])

                    sliderRow(index: 8, title: "事后状态",
                              value: Binding(get: { postnut ?? 0.5 }, set: { postnut = $0 }),
                              filled: postnut,
                              labels: ["很开心", "没感觉", "有点累", "眼皮打架"])

                    sliderRow(index: 9, title: "欲望程度",
                              value: Binding(get: { horny ?? 0.5 }, set: { horny = $0 }),
                              filled: horny,
                              labels: ["低", "中低", "中高", "高"])

                    FieldRow(index: 10, title: "质量", activeField: $activeField,
                             filledValue: mass.isEmpty ? nil : "\(mass)g") {
                        HStack {
                            TextField("克数", text: $mass)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            if usePreciseDensity {
                                TextField("密度", text: $preciseDensityInput)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }
                            Toggle("", isOn: $usePreciseDensity)
                                .labelsHidden()
                                .frame(width: 50)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                    }

                }
                .padding(.bottom, 100)
            }
            .overlay(alignment: .bottom) {
                HStack(spacing: 8) {
                    Button {
                        saveRecord()
                        dismiss()
                    } label: {
                        Text("完成")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)

                    if !allFilled {
                        Button {
                            saveRecord()
                            scheduleReminder(minutes: 30)
                            dismiss()
                        } label: {
                            Image(systemName: "clock.badge")
                                .frame(width: 50, height: 50)
                        }
                        .buttonStyle(.bordered)
                        .clipShape(Circle())
                        .contextMenu {
                            Button("5 分钟后提醒")  { scheduleReminder(minutes: 5) }
                            Button("15 分钟后提醒") { scheduleReminder(minutes: 15) }
                            Button("30 分钟后提醒") { scheduleReminder(minutes: 30) }
                            Button("1 小时后提醒")  { scheduleReminder(minutes: 60) }
                            Button("2 小时后提醒")  { scheduleReminder(minutes: 120) }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("新记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    // 把 sliderRow 抽成一个函数，避免重复代码
    @ViewBuilder
    func sliderRow(index: Int, title: String, value: Binding<Double>, filled: Double?, labels: [String]) -> some View {
        FieldRow(index: index, title: title, activeField: $activeField,
                 filledValue: filled.map { sliderLabel(value: $0, labels: labels) }) {
            CustomSliderField(value: value, labels: labels) { advance(from: index) }
        }
    }

    func advance(from index: Int) {
        let filled: [Bool] = [
            true, true,
            typeAge != nil, typePosition != nil, typeExistence != nil,
            time != nil, sound != nil, atm != nil, postnut != nil, horny != nil,
            !mass.isEmpty
        ]
        if let next = (index + 1 ..< filled.count).first(where: { !filled[$0] }) {
            withAnimation { activeField = next }
        } else {
            withAnimation { activeField = nil }
        }
    }

    func sliderLabel(value: Double, labels: [String]) -> String {
        let i = min(Int(value * Double(labels.count)), labels.count - 1)
        return labels[i]
    }

    func mediaTypeLabel(_ m: MediaType) -> String {
        switch m {
        case .img: return "图片"
        case .vid: return "视频"
        case .txt: return "文本"
        case .aud: return "声音"
        }
    }

    func saveRecord() {
        let record = Record(
            dimension: dimension,
            mediaType: mediaType,
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
    }

    func scheduleReminder(minutes: Int) {
        print("将在 \(minutes) 分钟后提醒")
    }
}

// 自定义滑块：用 GeometryReader + DragGesture 实现，彻底绕开 ScrollView 手势冲突
struct CustomSliderField: View {
    @Binding var value: Double
    let labels: [String]
    let onRelease: () -> Void

    @State private var lastZone: Int = -1
    @State private var isDragging: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            // 区间标注
            HStack(spacing: 0) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 自定义滑块轨道
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let thumbX = value * trackWidth

                ZStack(alignment: .leading) {
                    // 轨道背景
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.25))
                        .frame(height: 4)

                    // 已填充部分
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: thumbX, height: 4)

                    // 拇指圆点
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: isDragging ? 26 : 22, height: isDragging ? 26 : 22)
                        .shadow(radius: isDragging ? 4 : 2)
                        .offset(x: thumbX - (isDragging ? 13 : 11))
                        .animation(.spring(response: 0.2), value: isDragging)
                }
                .frame(height: 30)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { drag in
                            isDragging = true
                            let newVal = max(0, min(1, drag.location.x / trackWidth))
                            value = newVal

                            // 震动反馈
                            let zone = min(Int(newVal * Double(labels.count)), labels.count - 1)
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
            .frame(height: 30)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct FieldRow<Content: View>: View {
    let index: Int
    let title: String
    @Binding var activeField: Int?
    let filledValue: String?
    @ViewBuilder let content: () -> Content

    var isExpanded: Bool { activeField == index }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation { activeField = isExpanded ? nil : index }
            } label: {
                HStack {
                    Text(title).foregroundStyle(.primary)
                    Spacer()
                    if let val = filledValue, !isExpanded {
                        Text(val)
                            .foregroundStyle(Color.accentColor)
                            .font(.subheadline)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            }

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
        }
    }
}

struct SelectionButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
