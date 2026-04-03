//
//  AppState.swift
//  FlightSD
//
//  Created by Scott Nishiki on 2026-03-12.
//

import SwiftUI

@Observable
class AppState {
    // Shared transient UI state for presenting the capture sheet from multiple tabs.
    var showNewRecord: Bool = false
}
