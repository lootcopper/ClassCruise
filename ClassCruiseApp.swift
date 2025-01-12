import SwiftUI
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct ClassCruiseApp: App {
    @StateObject var rideManager = RideManager() // Shared ride manager
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false // Track login status
    @State private var currentTab: Int = 0 // Track the current tab index
    @State private var showMainApp = false // Control when to show the main app
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            if showMainApp {
                if isLoggedIn {
                    TabView(selection: $currentTab) {
                        NavigationView {
                            HomeView(rideManager: rideManager, currentTab: $currentTab)
                        }
                        .tabItem {
                            Label("Request a Carpool", systemImage: "car.fill")
                        }
                        .tag(0)

                        NavigationView {
                            DriverView(rideManager: rideManager)
                        }
                        .tabItem {
                            Label("Carpools", systemImage: "list.bullet")
                        }
                        .tag(1)

                        NavigationView {
                            ProfileView()
                        }
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                        .tag(3)
                    }
                } else {
                    LoginView()
                }
            } else {
                LaunchView(showMainApp: $showMainApp)
            }
        }
    }
}
