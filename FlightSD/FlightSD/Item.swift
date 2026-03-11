//
//  Item.swift
//  FlightSD
//
//  Created by Scott Nishiki on 2026-03-11.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
