import SwiftUI

struct OptionalTimeFieldButton: View {
    let time: Date?
    let placeholder: String
    var width: CGFloat = 92
    let action: () -> Void

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private var accessibilityText: String {
        time.map { Self.formatter.string(from: $0) } ?? "Time"
    }

    var body: some View {
        Button(action: action) {
            Text(time.map { Self.formatter.string(from: $0) } ?? placeholder)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: width, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
                .opacity(time == nil ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }
}

struct TimeSelectionSheet: View {
    let title: String
    let initialTime: Date
    let onConfirm: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    // Stage edits locally so tapping Cancel leaves the caller untouched.
    @State private var selectedTime: Date

    init(
        title: String = "Time",
        initialTime: Date,
        onConfirm: @escaping (Date) -> Void
    ) {
        self.title = title
        self.initialTime = initialTime
        self.onConfirm = onConfirm
        _selectedTime = State(initialValue: initialTime)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    title,
                    selection: $selectedTime,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onConfirm(selectedTime)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
}
