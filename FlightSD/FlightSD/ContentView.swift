import SwiftUI
import SwiftData

struct ContentView: View {

    @AppStorage("lastOpenedDate") private var lastOpenedDate: String = ""
    @State private var selectedTab: Int = 0

    // 创建 AppState 实例，注入给所有子页面
    @State private var appState = AppState()

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date.now)
    }

    var body: some View {

        TabView(selection: $selectedTab) {

            RecordsView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    AddRecordBar {
                        appState.showNewRecord = true
                    }
                }
                .tabItem {
                    Label("记录", systemImage: "pencil")
                }
                .tag(0)

            TrendView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    AddRecordBar {
                        appState.showNewRecord = true
                    }
                }
                .tabItem {
                    Label("趋势", systemImage: "arrow.up.arrow.down")
                }
                .tag(1)

            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.dots.scatter")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(3)

        }
        // 把 appState 注入到整个 app 的环境里
        // 之后任何子页面都可以直接取用，不需要一层层传
        .environment(appState)
        .sheet(isPresented: $appState.showNewRecord) {
            NewRecordView()
        }
        .onAppear {
            if lastOpenedDate != todayString {
                //lastOpenedDate != todayString {
                lastOpenedDate = todayString
                selectedTab = 0
                appState.showNewRecord = true
            } else {
                selectedTab = 1
            }
        }
    }
}
