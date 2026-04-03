# FlightSD

FlightSD is a private SwiftUI + SwiftData tracker for recording session details, measurements, and long-term patterns across iPhone, iPad, and Mac.

Suggested GitHub repo description:
`A SwiftUI + SwiftData app for private session logging and pattern tracking across iPhone, iPad, and Mac.`

## Overview

This repository contains an Apple-platform app focused on quick, repeatable personal logging. The current implementation is centered on a guided record-entry flow and a local history view, with future expansion planned for trends, statistics, and profile settings.

The product is designed for:

- fast one-handed record entry
- structured tracking instead of free-form notes
- local-first storage with SwiftData
- a shared codebase for iOS, iPadOS, and macOS

## Current Features

Implemented today:

- SwiftUI app with a shared SwiftData model container
- guided "New Record" workflow with progressive field expansion
- record date selection and optional exact time
- categorical inputs for dimension and media type
- slider-based inputs for age, position, existence, duration, audio, atmosphere, arousal level, and post-session state
- optional mass input and precise density override with estimated volume calculation
- record list grouped into Today, This Week, and Earlier
- filtering support inside the records list
- local persistence through SwiftData

Partially implemented or planned:

- trend view
- stats dashboard
- profile/settings area
- actual reminder scheduling behind the reminder UI
- sync, export, and backup workflows

## Tech Stack

- Swift
- SwiftUI
- SwiftData
- Xcode project targets for iPhone Simulator, iPhone, and macOS

## Platform Requirements

Based on the current Xcode project settings:

- Xcode 16 or newer recommended
- iOS / iPadOS 18.6+
- macOS 15.0+

## Run Locally

1. Open [FlightSD.xcodeproj](/Users/scottnishiki/Desktop/flightsd/FlightSD/FlightSD.xcodeproj) in Xcode.
2. Select the `FlightSD` scheme.
3. Choose an iOS Simulator or a macOS run destination.
4. Build and run the app.

## Project Structure

- [README.md](/Users/scottnishiki/Desktop/flightsd/README.md): repository overview
- [LICENSE](/Users/scottnishiki/Desktop/flightsd/LICENSE): MIT license
- [FlightSD/FlightSD](/Users/scottnishiki/Desktop/flightsd/FlightSD/FlightSD): main app source
- [FlightSD/FlightSD/FlightSDApp.swift](/Users/scottnishiki/Desktop/flightsd/FlightSD/FlightSD/FlightSDApp.swift): app entry point and SwiftData container
- [FlightSD/FlightSD/Record.swift](/Users/scottnishiki/Desktop/flightsd/FlightSD/FlightSD/Record.swift): data model
- [FlightSD/FlightSD/NewRecordView.swift](/Users/scottnishiki/Desktop/flightsd/FlightSD/FlightSD/NewRecordView.swift): guided record creation flow
- [FlightSD/FlightSD/RecordsView.swift](/Users/scottnishiki/Desktop/flightsd/FlightSD/FlightSD/RecordsView.swift): record history and filtering UI

## Roadmap

- finish the Trend, Stats, and Profile tabs
- replace placeholder reminder behavior with real local notifications
- add richer analytics and derived summaries
- add export and sync options when the data model stabilizes
- improve test coverage beyond the default template tests

## License

This project is licensed under the MIT License. See [LICENSE](/Users/scottnishiki/Desktop/flightsd/LICENSE) for details.
