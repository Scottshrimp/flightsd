# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FlightSD is a personal data tracking iOS/iPadOS app built with Swift, SwiftUI, and SwiftData. No external dependencies — pure Apple frameworks. Targets iOS/iPadOS 18+.

## Build & Test Commands

```bash
# Build
xcodebuild -project FlightSD/FlightSD.xcodeproj -scheme FlightSD -configuration Debug build

# Run unit tests
xcodebuild test -project FlightSD/FlightSD.xcodeproj -scheme FlightSD -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -project FlightSD/FlightSD.xcodeproj -scheme FlightSD -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FlightSDUITests

# Open in Xcode
open FlightSD/FlightSD.xcodeproj
```

## Architecture

**Entry point:** `FlightSDApp.swift` — sets up `ModelContainer` with `Record` and `DateTrend` schemas, runs `refreshDerivedData()` on launch.

**Navigation:** Tab-based (`ContentView.swift`) with 4 tabs:
- Records (browse/filter/edit) → `RecordsView.swift`
- Trend (weekly charts) → `TrendView.swift`
- Stats → placeholder
- Profile → placeholder

**Modal:** `NewRecordView.swift` — floating action button opens record entry sheet. Auto-opens on first launch each day. Controlled by `AppState` (`@Observable`).

**Data layer (`Record.swift`):**
- `Record` (@Model) — core entity with timestamp, classification (dimension/mediaType), 8 sliding-scale metrics (0.0–1.0), mass, density, computed volume
- `DateTrend` (@Model) — derived model storing 7-day rolling averages/sums per date
- `refreshDerivedData()` orchestrates recomputation of averages and trends
- Dual density system: precise per-record density vs running average, with `defaultDensity = 1.035`
- Locale-aware number parsing with POSIX fallback

**Platform adaptation:** `PlatformProfile` environment value detects iOS/iPad/Mac for responsive layouts. Uses `#if canImport(UIKit)` for platform-specific code.

## Key Patterns

- State: `@Observable` AppState for cross-view state, `@Query` for SwiftData lists, `@Environment` for dependency injection
- Large monolithic view files with many `private` nested structs (RecordsView ~1800 lines, NewRecordView ~850 lines)
- `RecordsFilter` struct handles multi-criteria filtering with match logic
- `RecordGroups` groups records by today/this week/earlier months
- UI labels use Chinese text for the target audience
- Custom components: `FieldRow`, `CustomSliderField`, `AddRecordBar`, `RecordEntryCard`
- Uses Swift Testing framework (not XCTest) for unit tests
