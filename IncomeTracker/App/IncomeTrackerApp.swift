import SwiftUI

@main
struct IncomeTrackerApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @Environment(\.scenePhase) private var scenePhase

    init() {
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(currentColorScheme)
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .active:
                        PollingService.shared.start()
                    case .inactive, .background:
                        PollingService.shared.stop()
                    @unknown default:
                        break
                    }
                }
        }
    }

    private var currentColorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var dashboardPath = NavigationPath()

    var body: some View {
        TabView(selection: Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == selectedTab && newTab == 0 {
                    dashboardPath = NavigationPath()
                }
                selectedTab = newTab
            }
        )) {
            NavigationStack(path: $dashboardPath) {
                DashboardView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            .tag(0)

            TransactionsListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)

            WorkersListView()
                .tabItem {
                    Label("Workers", systemImage: "person.2.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(AppTheme.Colors.primaryFallback)
        .onChange(of: selectedTab) { _ in
            dashboardPath = NavigationPath()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
