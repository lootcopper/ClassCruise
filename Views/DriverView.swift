import SwiftUI
import MapKit
import CoreLocation
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct DriverView: View {
    @ObservedObject var rideManager: RideManager
    @State private var arrivedAtPickup = false
    @State private var showAcceptAlert = false
    @State private var acceptAlertMessage = ""
    @State private var carpoolMessage: String = ""
    @State private var userPhoneNumber: String = ""
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    var driverEmail = UserDefaults.standard.string(forKey: "loggedInEmail") ?? "Driver"
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            if let acceptedRide = rideManager.acceptedRide {
                Text(acceptedRide.status == "accepted" ? "Please text your driver to plan a carpool" : "Address information")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pickup: \(acceptedRide.pickupLocation)")
                    Text("Drop: \(acceptedRide.dropLocation)")
                    
                    if !carpoolMessage.isEmpty {
                        Text("Message: \(carpoolMessage)")
                            .padding(.top)
                            .italic()
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if !userName.isEmpty {
                            Text("User: \(userName)")
                                .font(.subheadline)
                        }
                        if !userPhoneNumber.isEmpty {
                            Text("Phone: \(userPhoneNumber)")
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding(.top)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .shadow(radius: 5)
                
                UberMapViewRepresentable(rides: $rideManager.rides, selectedRide: acceptedRide)
                    .padding(.top)
                
                if acceptedRide.status == "accepted" {
                    Button("Ride Directions") {
                        startRide(acceptedRide)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .gesture(
                        TapGesture()
                            .onEnded {
                                print("Tapped on Ride Directions")
                            }
                    )
                    
                } else if acceptedRide.status == "inProgress" {
                    if !arrivedAtPickup {
                        Button("Arrived at Pickup") {
                            arrivedAtPickup = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .gesture(
                            TapGesture()
                                .onEnded {
                                    print("Tapped on Arrived at Pickup")
                                }
                        )
                    } else {
                        HStack(spacing: 16) {
                            Button("Navigate to Dropoff") {
                                navigateToDropoff(acceptedRide)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .gesture(
                                TapGesture()
                                    .onEnded {
                                        print("Tapped on Navigate to Dropoff")
                                    }
                            )
                            
                            Button("End Ride") {
                                completeRide(acceptedRide)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .gesture(
                                TapGesture()
                                    .onEnded {
                                        print("Tapped on End Ride")
                                    }
                            )
                        }
                        .padding(.top)
                    }
                }
                
                Button("Cancel") {
                    if let acceptedRide = rideManager.acceptedRide {
                        rideManager.cancelRide(acceptedRide)
                    }
                    dismiss()
                }
                .buttonStyle(CancelButtonStyle())
                .gesture(
                    TapGesture()
                        .onEnded {
                            print("Tapped on Cancel")
                        }
                )
                
            } else {
                List(rideManager.rides) { ride in
                    if ride.status == "requested" {
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Rider: \(ride.userName)")
                                        .font(.headline)
                                    Text("Phone: \(ride.phoneNumber)")
                                        .font(.subheadline)
                                }
                                Spacer()
                                Button("View Details") {
                                    acceptRide(ride)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .gesture(
                                    TapGesture()
                                        .onEnded {
                                            print("Tapped on View Details")
                                        }
                                )
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        }
                        .padding(.bottom, 8)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Available Carpools")
        .onAppear {
            loadCarpoolMessage()
        }
        .padding()
    }
    
    private func loadCarpoolMessage() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user.email ?? "")
        docRef.getDocument { document, _ in
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                carpoolMessage = data["carpoolMessage"] as? String ?? ""
                userName = data["userName"] as? String ?? ""
                userPhoneNumber = data["phoneNumber"] as? String ?? ""
                userEmail = data["email"] as? String ?? ""
            }
        }
    }
    
    func acceptRide(_ ride: Ride) {
        rideManager.acceptRide(ride)
        loadCarpoolMessage()
    }
    
    func startRide(_ ride: Ride) {
        rideManager.startRide(ride)
        openAppleMapsToPickup(pickupAddress: ride.pickupLocation)
    }
    
    func navigateToDropoff(_ ride: Ride) {
        openAppleMapsToDropoff(dropoffAddress: ride.dropLocation)
    }
    
    func completeRide(_ ride: Ride) {
        rideManager.completeRide(ride)
    }
    
    func openAppleMapsToPickup(pickupAddress: String) {
        let geocoder = CLGeocoder()
        guard let userLocation = CLLocationManager().location?.coordinate else { return }
        geocoder.geocodeAddressString(pickupAddress) { pickupPlacemarks, _ in
            if let pickupPlacemark = pickupPlacemarks?.first?.location?.coordinate {
                let userMapItem = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
                let pickupMapItem = MKMapItem(placemark: MKPlacemark(coordinate: pickupPlacemark))
                MKMapItem.openMaps(with: [userMapItem, pickupMapItem], launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                ])
            }
        }
    }
    
    func openAppleMapsToDropoff(dropoffAddress: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(dropoffAddress) { dropoffPlacemarks, _ in
            if let dropoffPlacemark = dropoffPlacemarks?.first?.location?.coordinate {
                let dropoffMapItem = MKMapItem(placemark: MKPlacemark(coordinate: dropoffPlacemark))
                MKMapItem.openMaps(with: [dropoffMapItem], launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                ])
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 5)
            .opacity(configuration.isPressed ? 0.7 : 1) // Button opacity change on press
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 5)
            .opacity(configuration.isPressed ? 0.7 : 1) // Button opacity change on press
    }
}

struct CancelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 5)
            .opacity(configuration.isPressed ? 0.7 : 1) // Button opacity change on press
    }
}
