import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {

    @AppStorage("lastOpenedDate") private var lastOpenedDate: String = ""
    @State private var selectedTab: Int = 0
    @State private var tabBarHeight: CGFloat = 0

    // 创建 AppState 实例，注入给所有子页面
    @State private var appState = AppState()

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date.now)
    }

    private var showsAddRecordBar: Bool {
        selectedTab == 0 || selectedTab == 1
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {

                    RecordsView()
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            AddRecordBarReservedSpace()
                        }
                        .tabItem {
                            Label("Record", systemImage: "pencil")
                        }
                        .tag(0)

                    TrendView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            AddRecordBarReservedSpace()
                        }
                        .tabItem {
                            Label("Trend", systemImage: "arrow.up.arrow.down")
                        }
                        .tag(1)

                    StatsView()
                        .tabItem {
                            Label("Stats", systemImage: "chart.dots.scatter")
                        }
                        .tag(2)

                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person")
                        }
                        .tag(3)

                }

#if canImport(UIKit)
                TabBarHeightReader(tabBarHeight: $tabBarHeight)
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
#endif

                if showsAddRecordBar {
                    AddRecordBar {
                        appState.showNewRecord = true
                    }
                    .padding(.bottom, max(tabBarHeight - proxy.safeAreaInsets.bottom, 49))
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                    .zIndex(1)
                }
            }
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

private struct AddRecordBarReservedSpace: View {
    var body: some View {
        AddRecordBar(action: {})
            .hidden()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#if canImport(UIKit)
private struct TabBarHeightReader: UIViewControllerRepresentable {
    @Binding var tabBarHeight: CGFloat

    func makeUIViewController(context: Context) -> TabBarHeightReaderController {
        TabBarHeightReaderController(tabBarHeight: $tabBarHeight)
    }

    func updateUIViewController(_ uiViewController: TabBarHeightReaderController, context: Context) {
        uiViewController.tabBarHeight = $tabBarHeight
        uiViewController.reportIfNeeded()
    }
}

private final class TabBarHeightReaderController: UIViewController {
    var tabBarHeight: Binding<CGFloat>

    init(tabBarHeight: Binding<CGFloat>) {
        self.tabBarHeight = tabBarHeight
        super.init(nibName: nil, bundle: nil)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reportIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        reportIfNeeded()
    }

    func reportIfNeeded() {
        let height = tabBarController?.tabBar.frame.height ?? 0
        guard abs(tabBarHeight.wrappedValue - height) > 0.5 else { return }

        DispatchQueue.main.async { [tabBarHeight] in
            tabBarHeight.wrappedValue = height
        }
    }
}
#endif
