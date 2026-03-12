import Foundation
import SwiftData

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

    var dimension: Dimension
    var mediaType: MediaType

    // ⑤ 连续型字段（滑块）：全部用 Double
    var typeAge: Double      // 妹妹系 → 妈妈系
    var typePosition: Double      // Active 相关
    var typeExistence: Double      // Existence 相关
    var time: Double       // 施法时长，短 → 长
    var sound: Double      // 声音偏好，-1.0 ~ 1.0
    var atm: Double        // 唤起来源，纯视觉 → 纯情境
    var postnut: Double    // 事后状态，开心 → 眼皮打架
    var horny: Double      // 唤起程度，低 → 高

    // ⑥ 实测质量
    var mass: Double       // 单位：克

    // ⑦ 精确密度（可选）：没有开启精确测量时为 nil
    var preciseDensity: Double?

    // ⑧ 计算属性：est.vol 不存储，实时根据 mass 和密度计算
    var estVol: Double {
        let density = preciseDensity ?? 1.035
        return mass / density
    }

    // ⑨ 初始化函数：新建一条记录时，给所有字段赋初始值
    init(
        timestamp: Date = .now,
        dimension: Dimension = .twoDimension,
        mediaType: MediaType = .img,
        typeAge: Double = 0.5,
        typePosition: Double = 0.5,
        typeExistence: Double = 0.5,
        time: Double = 0.5,
        sound: Double = 0.0,
        atm: Double = 0.5,
        postnut: Double = 0.5,
        horny: Double = 0.5,
        mass: Double = 0.0,
        preciseDensity: Double? = nil
    ) {
        self.timestamp = timestamp
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
        self.preciseDensity = preciseDensity
    }
}//
//  Record.swift
//  FlightSD
//
//  Created by Scott Nishiki on 2026-03-12.
//

