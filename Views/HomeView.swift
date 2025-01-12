import SwiftUI
import MapKit

struct HomeView: View {
    @State private var pickupLocation: String = ""
    @State private var dropLocation: String = ""
    @ObservedObject var rideManager: RideManager
    @StateObject private var locationManager = LocationManager()
    var riderEmail = UserDefaults.standard.string(forKey: "loggedInEmail") ?? "Rider"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var currentTab: Int
    @State private var requestSuccess = false

    @StateObject private var pickupSearchCompleter = AddressSearchCompleter()
    @StateObject private var dropSearchCompleter = AddressSearchCompleter()

    var body: some View {
        VStack {
            // Map Section
            UberMapViewRepresentable(rides: $rideManager.rides)
                .ignoresSafeArea()
                .frame(height: 250)

            // Input Section
            VStack(spacing: 50) {
                InputCard(
                    placeholder: "Pickup Location",
                    text: $pickupLocation,
                    searchCompleter: pickupSearchCompleter
                )

                InputCard(
                    placeholder: "Drop Location",
                    text: $dropLocation,
                    searchCompleter: dropSearchCompleter
                )
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(20)
            .shadow(radius: 5)
            .padding(.horizontal)

            // Request Button
            Button(action: {
                requestRide()
            }) {
                Text("Request Carpool")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                    .shadow(radius: 5)
            }
            .padding(.horizontal)
            .padding(.top)

            Spacer()
        }
        .navigationTitle("Request a Carpool")
        .alert(isPresented: $requestSuccess) {
            Alert(
                title: Text("Success"),
                message: Text("Your ride request has been submitted!"),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Please Enter a Valid Address"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(rideManager.$acceptedRide) { acceptedRide in
            if let ride = acceptedRide {
                if ride.userEmail == riderEmail {
                    alertMessage = "Your ride from \(ride.pickupLocation) to \(ride.dropLocation) has been accepted."
                    showAlert = true
                }
            }
        }
    }

    func requestRide() {
        guard !pickupLocation.isEmpty, !dropLocation.isEmpty else {
            alertMessage = "Pickup and drop locations cannot be empty."
            showAlert = true
            return
        }

        guard let userLocation = locationManager.location else { return }

        rideManager.requestRide(
            pickupLocation: pickupLocation,
            dropLocation: dropLocation,
            coordinate: userLocation.coordinate
        )

        requestSuccess = true
        pickupLocation = ""
        dropLocation = ""
    }
}

// Input Card for Pickup/Drop Location
struct InputCard: View {
    var placeholder: String
    @Binding var text: String
    @ObservedObject var searchCompleter: AddressSearchCompleter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(placeholder)
                .font(.headline)
                .foregroundColor(.blue) // Blue text for the label

            TextField(placeholder, text: $text)
                .onChange(of: text) { _, newValue in
                    searchCompleter.startSearching(for: newValue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1)) // Light blue background
                        .shadow(color: Color.blue.opacity(0.3), radius: 5) // Blue shadow
                )
                .foregroundColor(Color.primary) // Adapts to light/dark mode
                .autocapitalization(.none)
                .disableAutocorrection(true)

            // Search Results
            if !searchCompleter.searchResults.isEmpty {
                List(searchCompleter.searchResults, id: \.self) { result in
                    Text(result.title)
                        .onTapGesture {
                            text = result.title
                            searchCompleter.clearResults()
                        }
                        .padding(.vertical, 8)
                }
                .frame(height: 150)
                .listStyle(PlainListStyle())
            }
        }
        .padding(.horizontal)
    }
}
