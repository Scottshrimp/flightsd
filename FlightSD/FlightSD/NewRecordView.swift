import SwiftUI
import SwiftData

struct NewRecordView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // ① 当前展开的条目索引，nil 表示全部收起
    @State private var activeField: Int? = 0

    // ② 所有字段的临时存储
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

    // ③ 所有条目是否已填写
    private var allFilled: Bool {
        typeAge != nil &&
        typePosition != nil &&
        typeExistence != nil &&
        time != nil &&
        sound != nil &&
        atm != nil &&
        postnut != nil &&
        horny != nil &&
        !mass.isEmpty
    }

    // ④ mediaType 根据 dimension 过滤可用选项
    private var availableMediaTypes: [MediaType] {
        switch dimension {
        case .twoDimension:
            return [.img, .vid, .txt, .aud]
        case .threeDimension:
            return [.img, .vid]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ⑤ 条目 0：Dimension
                    FieldRow(
                        index: 0,
                        title: "次元",
                        activeField: $activeField,
                        filledValue: activeField != 0 ? dimension.rawValue : nil
                    ) {
                        HStack(spacing: 12) {
                            ForEach([Dimension.twoDimension, Dimension.threeDimension], id: \.self) { d in
                                Button(d == .twoDimension ? "二次元" : "三次元") {
                                    dimension = d
                                    // 如果切换到三次元，mediaType 不合法时重置
                                    if d == .threeDimension && (mediaType == .txt || mediaType == .aud) {
                                        mediaType = .img
                                    }
                                    advance(from: 0)
                                }
                                .buttonStyle(SelectionButtonStyle(isSelected: dimension == d))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }

                    // 条目 1：MediaType
                    FieldRow(
                        index: 1,
                        title: "媒体类型",
                        activeField: $activeField,
                        filledValue: activeField != 1 ? mediaTypeLabel(mediaType) : nil
                    ) {
                        HStack(spacing: 12) {
                            ForEach(availableMediaTypes, id: \.self) { m in
                                Button(mediaTypeLabel(m)) {
                                    mediaType = m
                                    advance(from: 1)
                                }
                                .buttonStyle(SelectionButtonStyle(isSelected: mediaType == m))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }

                    // 条目 2：typeAge
                    FieldRow(
                        index: 2,
                        title: "年龄感",
                        activeField: $activeField,
                        filledValue: typeAge.map { sliderLabel(value: $0, labels: ["区间1", "区间2", "区间3", "区间4", "区间5"]) }
                    ) {
                        SliderField(
                            value: Binding(
                                get: { typeAge ?? 0.5 },
                                set: { typeAge = $0 }
                            ),
                            labels: ["区间1", "区间2", "区间3", "区间4", "区间5"]
                        ) { advance(from: 2) }
                    }

                    // 条目 3：typePosition
                    FieldRow(
                        index: 3,
                        title: "体位",
                        activeField: $activeField,
                        filledValue: typePosition.map { sliderLabel(value: $0, labels: ["区间1", "区间2", "区间3", "区间4", "区间5"]) }
                    ) {
                        SliderField(
                            value: Binding(
                                get: { typePosition ?? 0.5 },
                                set: { typePosition = $0 }
                            ),
                            labels: ["区间1", "区间2", "区间3", "区间4", "区间5"]
                        ) { advance(from: 3) }
                    }

                    // 条目 4：typeExistence
                    FieldRow(
                        index: 4,
                        title: "存在感",
                        activeField: $activeField,
                        filledValue: typeExistence.map { sliderLabel(value: $0, labels: ["区间1", "区间2"]) }
                    ) {
                        SliderField(
                            value: Binding(
                                get: { typeExistence ?? 0.5 },
                                set: { typeExistence = $0 }
                            ),
                            labels: ["区间1", "区间2"]
                        ) { advance(from: 4) }
                    }

                    // 条目 5：time
                    FieldRow(
                        index: 5,
                        title: "时长",
                        activeField: $activeField,
                        filledValue: time.map { sliderLabel(value: $0, labels: ["很短", "短", "中", "长", "很长"]) }
                    ) {
                        SliderField(
                            value: Binding(
                                get: { time ?? 0.5 },
                                set: { time = $0 }
                            ),
                            labels: ["很短", "短", "中", "长", "很长"]
                        ) { advance(from: 5) }
                    }

                    // 条目 6：sound
                    FieldRow(
                        index: 6,
                        title: "声音",
                        activeField: $activeField,
                        filledValue: sound.map { sliderLabel(value: ($0 + 1) / 2, labels: ["不喜欢", "纯图", "喜欢", "纯音"]) }
                    ) {
                        SliderField(
                            value: Binding(
                                get: { (sound ?? 0.0 + 1) / 2 },
                                set: { sound = $0 * 2 - 1 }
                            ),
                            labels: ["不喜欢", "纯图", "喜欢", "纯音"]
                        ) { advance(from: 6) }
                    }

                    // 条目 7：atm
                    FieldRow(
                        index: 7,
                        title: "氛围",
                        activeField: $activeField,
                        filledValue: atm.map { sliderLabel(value: $0, labels: ["纯视觉", "偏视觉", "偏情境", "纯情境"]) }
                    ) {
                        SliderField(
                            value: Binding(
                                get: { atm ?? 0.5 },
                                set: { atm = $0 }
                            ),
                            labels: ["纯视觉", "偏视觉", "偏情境", "纯情境"]
                        ) { advance(from: 7) }
                    }

                    // 条目 8：postnut
                    FieldRow(
                        index: 8,
                        title: "事后状态",
                        activeField: $activeField,
                        filledValue: postnut.map { sliderLabel(value: $0, labels: ["很开心", "没感觉", "有点累", "眼皮打架"]) }
                    ) {
                        SliderField(
                            value: Binding(
                                get: { postnut ?? 0.5 },
                                set: { postnut = $0 }
                            ),
                            labels: ["很开心", "没感觉", "有点累", "眼皮打架"]
                        ) { advance(from: 8) }
                    }

                    // 条目 9：horny
                    FieldRow(
                        index: 9,
                        title: "欲望程度",
                        activeField: $activeField,
                        filledValue: horny.map { sliderLabel(value: $0, labels: ["低", "中低", "中高", "高"]) }
                    ) {
                        SliderField(
                            value: Binding(
                                get: { horny ?? 0.5 },
                                set: { horny = $0 }
                            ),
                            labels: ["低", "中低", "中高", "高"]
                        ) { advance(from: 9) }
                    }

                    // 条目 10：mass + 密度 toggle
                    FieldRow(
                        index: 10,
                        title: "质量",
                        activeField: $activeField,
                        filledValue: mass.isEmpty ? nil : "\(mass)g"
                    ) {
                        VStack(spacing: 8) {
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }

                }
                .padding(.bottom, 100)
            }

            // ⑥ 底部按钮
            .overlay(alignment: .bottom) {
                HStack(spacing: 8) {
                    // 大按钮：提交并关闭
                    Button {
                        saveRecord()
                        dismiss()
                    } label: {
                        Text("完成")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)

                    // 小按钮：提交并设置提醒，allFilled 时隐藏
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
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
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

    // ⑦ 工具函数

    // 松手后自动跳到下一个未填条目
    func advance(from index: Int) {
        let filled: [Bool] = [
            true, true,                          // dimension, mediaType 按钮选完即填
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
        // 从 index+1 开始找第一个未填的条目
        if let next = (index + 1 ..< filled.count).first(where: { !filled[$0] }) {
            withAnimation { activeField = next }
        } else {
            withAnimation { activeField = nil }
        }
    }

    // 把 0-1 的值映射到对应的区间 label
    func sliderLabel(value: Double, labels: [String]) -> String {
        let i = min(Int(value * Double(labels.count)), labels.count - 1)
        return labels[i]
    }

    // mediaType 显示名称
    func mediaTypeLabel(_ m: MediaType) -> String {
        switch m {
        case .img: return "图片"
        case .vid: return "视频"
        case .txt: return "文本"
        case .aud: return "声音"
        }
    }

    // 保存记录到 SwiftData
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

    // 设置提醒（占位，之后接入 UserNotifications）
    func scheduleReminder(minutes: Int) {
        // TODO: UserNotifications 实现
        print("将在 \(minutes) 分钟后提醒")
    }
}

// ⑧ 可复用的条目行组件
struct FieldRow<Content: View>: View {
    let index: Int
    let title: String
    @Binding var activeField: Int?
    let filledValue: String?
    @ViewBuilder let content: () -> Content

    var isExpanded: Bool { activeField == index }

    var body: some View {
        VStack(spacing: 0) {
            // 条目标题行，点击可展开/收起
            Button {
                withAnimation { activeField = isExpanded ? nil : index }
            } label: {
                HStack {
                    Text(title)
                        .foregroundStyle(.primary)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            // 展开内容
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
        }
    }
}

// ⑨ 可复用的滑块组件，带区间标注和震动反馈
struct SliderField: View {
    @Binding var value: Double
    let labels: [String]
    let onRelease: () -> Void

    @State private var lastZone: Int = -1

    var body: some View {
        VStack(spacing: 4) {
            // 区间标注
            HStack {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 滑块
            Slider(value: $value, in: 0...1)
                .onChange(of: value) { _, newVal in
                    let zone = min(Int(newVal * Double(labels.count)), labels.count - 1)
                    if zone != lastZone {
                        // 跨区间时稍强震动
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        lastZone = zone
                    } else {
                        // 滑动时轻微震动
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        // 松手时触发 advance
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in onRelease() }
        )
    }
}

// ⑩ 按钮选择样式
struct SelectionButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
