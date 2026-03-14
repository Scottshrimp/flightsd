import Foundation
import SwiftData

let defaultDensity: Double = 1.035

enum Dimension: String, Codable {
    case twoDimension = "2D"
    case threeDimension = "3D"
}

enum MediaType: String, Codable {
    case img   = "image"
    case vid   = "video"
    case txt    = "text"
    case aud   = "audio"
}

@Model
class Record {
    var timestamp: Date
    var exactTime: Date?

    var dimension: Dimension?
    var mediaType: MediaType?

    // ⑤ 连续型字段（滑块）：全部用 Double
    var typeAge: Double?      // 妹妹系 → 妈妈系
    var typePosition: Double?      // Active 相关
    var typeExistence: Double?      // Existence 相关
    var time: Double?       // 施法时长，短 → 长
    var sound: Double?      // 声音偏好，-1.0 ~ 1.0
    var atm: Double?        // 唤起来源，纯视觉 → 纯情境
    var postnut: Double?    // 事后状态，开心 → 眼皮打架
    var horny: Double?      // 唤起程度，低 → 高

    // ⑥ 实测质量
    var mass: Double?       // 单位：克
    var avgMass: Double?

    // ⑦ 精确密度（可选）：没有开启精确测量时为 nil
    var preciseDensity: Double?
    var avgDensity: Double?

    // ⑧ 计算属性：est.vol 不存储，实时根据 mass 和密度计算
    var estVol: Double? {
        guard let mass else { return nil }
        let density = preciseDensity ?? avgDensity ?? defaultDensity
        return mass / density
    }

    // ⑨ 初始化函数：新建一条记录时，给所有字段赋初始值
    init(
        timestamp: Date = .now,
        exactTime: Date? = nil,
        dimension: Dimension? = nil,
        mediaType: MediaType? = nil,
        typeAge: Double? = nil,
        typePosition: Double? = nil,
        typeExistence: Double? = nil,
        time: Double? = nil,
        sound: Double? = nil,
        atm: Double? = nil,
        postnut: Double? = nil,
        horny: Double? = nil,
        mass: Double? = nil,
        avgMass: Double? = nil,
        preciseDensity: Double? = nil,
        avgDensity: Double? = nil
    ) {
        self.timestamp = timestamp
        self.exactTime = exactTime
        self.dimension = dimension
        self.mediaType = mediaType
        self.typeAge = typeAge
        self.typePosition = typePosition
        self.typeExistence = typeExistence
        self.time = time
        self.sound = sound
        self.atm = atm
        self.postnut = postnut
        self.horny = horny
        self.mass = mass
        self.avgMass = avgMass
        self.preciseDensity = preciseDensity
        self.avgDensity = avgDensity
    }
}

func computeAverageMass(from records: [Record]) -> Double? {
    let validMasses = records.compactMap(\.mass).filter { $0 > 0 }
    guard !validMasses.isEmpty else { return nil }
    let totalMass = validMasses.reduce(0, +)
    return totalMass / Double(validMasses.count)
}

func computeAverageDensity(from records: [Record]) -> Double? {
    let validDensities = records.compactMap(\.preciseDensity).filter { $0 > 0 }
    guard !validDensities.isEmpty else { return nil }
    let totalDensity = validDensities.reduce(0, +)
    return totalDensity / Double(validDensities.count)
}

@discardableResult
func refreshStoredAverages(in modelContext: ModelContext) -> (avgMass: Double?, avgDensity: Double?) {
    let descriptor = FetchDescriptor<Record>(sortBy: [SortDescriptor(\Record.timestamp, order: .forward)])
    guard let records = try? modelContext.fetch(descriptor) else {
        return (nil, nil)
    }

    let averageMass = computeAverageMass(from: records)
    let averageDensity = computeAverageDensity(from: records)
    for record in records {
        record.avgMass = averageMass
        record.avgDensity = averageDensity
    }

    try? modelContext.save()
    return (averageMass, averageDensity)
}

@discardableResult
func refreshAverageMass(in modelContext: ModelContext) -> Double? {
    refreshStoredAverages(in: modelContext).avgMass
}

func storedAverageMass(from records: [Record]) -> Double? {
    computeAverageMass(from: records) ?? records.compactMap(\.avgMass).last
}

func storedAverageDensity(from records: [Record]) -> Double? {
    computeAverageDensity(from: records) ?? records.compactMap(\.avgDensity).last
}

func effectiveGlobalDensity(from records: [Record]) -> Double {
    storedAverageDensity(from: records) ?? defaultDensity
}

func parsedRecordNumber(from text: String) -> Double? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    for formatter in [currentLocaleRecordNumberFormatter, posixRecordNumberFormatter] {
        if let number = formatter.number(from: trimmed) {
            return number.doubleValue
        }
    }

    let fallback = trimmed
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: " ", with: "")
    return Double(fallback)
}

func isValidRecordNumber(_ text: String) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty || parsedRecordNumber(from: trimmed) != nil
}

func editableRecordNumberText(_ value: Double, maxFractionDigits: Int) -> String {
    plainRecordNumberFormatter.maximumFractionDigits = maxFractionDigits
    return plainRecordNumberFormatter.string(from: NSNumber(value: value)) ?? String(value)
}

func normalizedRecordDate(_ date: Date, calendar: Calendar = .current) -> Date {
    calendar.startOfDay(for: date)
}

func combinedRecordDate(_ date: Date, time: Date, calendar: Calendar = .current) -> Date {
    let day = normalizedRecordDate(date, calendar: calendar)
    let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
    return calendar.date(byAdding: timeComponents, to: day) ?? day
}

func recordHasClockTime(_ date: Date, calendar: Calendar = .current) -> Bool {
    let components = calendar.dateComponents([.hour, .minute, .second], from: date)
    return (components.hour ?? 0) != 0 || (components.minute ?? 0) != 0 || (components.second ?? 0) != 0
}

private let currentLocaleRecordNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = .current
    formatter.isLenient = true
    return formatter
}()

private let posixRecordNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.isLenient = true
    return formatter
}()

private let plainRecordNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.usesGroupingSeparator = false
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3
    return formatter
}()
//
//  Record.swift
//  FlightSD
//
//  Created by Scott Nishiki on 2026-03-12.
//
