import SwiftUI
import SwiftData

@main
struct FlightSDApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Record.self,
            DateTrend.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        refreshDerivedData(in: sharedModelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.platformProfile, PlatformProfile.current)
        }
        .modelContainer(sharedModelContainer)
    }
}
