import SwiftUI

struct MainTabView: View {
    @ObservedObject var rideManager: RideManager // Shared ride manager
    @State private var currentTab: Int = 0 // Track the current tab index
    @State private var showingProfile: Bool = false // Track whether the profile view is presented

    var body: some View {
        NavigationView { // Wrap in NavigationView
            TabView(selection: $currentTab) {
                HomeView(rideManager: rideManager, currentTab: $currentTab)
                    .tabItem {
                        Label("Request a Carpool", systemImage: "car")
                    }
                    .tag(0) // Tag 0 for Request a Ride tab
                
                DriverView(rideManager: rideManager)
                    .tabItem {
                        Label("Carpools", systemImage: "list.bullet")
                    }
                    .tag(1) // Tag 1 for View Ride Requests tab
            }
            .navigationTitle("Your App Title") // Set a title for the navigation bar
            .navigationBarItems(trailing: Button(action: {
                showingProfile = true // Show ProfileView when button is tapped
            }) {
                Image(systemName: "person.circle") // Icon for the Profile button
                    .font(.title) // Make the icon larger
            })
            .sheet(isPresented: $showingProfile) { // Present ProfileView as a sheet
                ProfileView()
            }
        }
    }
}
