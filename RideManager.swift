import SwiftUI
import CoreLocation
import Firebase
import FirebaseDatabase
import FirebaseAuth

struct Ride: Identifiable {
    var id: String
    var pickupLocation: String
    var dropLocation: String
    var status: String = "requested"
    var coordinate: CLLocationCoordinate2D
    var requestedBy: String
    var userName: String
    var schoolName: String
    var userEmail: String
    var phoneNumber: String
    var carpoolMessage: String

    init(id: String = UUID().uuidString, pickupLocation: String, dropLocation: String, status: String = "requested", coordinate: CLLocationCoordinate2D, requestedBy: String, userName: String, schoolName: String, phoneNumber: String, userEmail: String) {
        self.id = id
        self.pickupLocation = pickupLocation
        self.dropLocation = dropLocation
        self.status = status
        self.coordinate = coordinate
        self.requestedBy = requestedBy
        self.userName = userName
        self.schoolName = schoolName
        self.phoneNumber = phoneNumber
        self.userEmail = userEmail
        self.carpoolMessage = ""
    }
}

class RideManager: ObservableObject {
    @Published var rides: [Ride] = []
    @Published var acceptedRide: Ride?
    @Published var alertMessage: String = ""
    
    private let dbRef = Database.database().reference()
    
    init() {
        fetchRidesFromRealtimeDatabase()
        listenForRideUpdates()
    }
    
    func didUserRequestRide(userEmail: String, ride: Ride) -> Bool {
        return ride.requestedBy == userEmail
    }
    
    func sendAlertToRider(riderEmail: String) {
        DispatchQueue.main.async {
            self.alertMessage = "Your ride has been accepted!"
        }
    }
    
    private func listenForRideUpdates() {
        dbRef.child("rideRequests").observe(.childChanged) { snapshot in
            guard let rideData = snapshot.value as? [String: Any],
                  let status = rideData["status"] as? String,
                  let _ = rideData["requestedBy"] as? String else {
                return
            }
            
            if status == "accepted" {
                let riderEmail = rideData["requestedBy"] as? String ?? "Unknown"
                self.sendAlertToRider(riderEmail: riderEmail)
            }
        }
    }
    
    func fetchRidesFromRealtimeDatabase() {
        dbRef.child("rideRequests").observe(.value) { snapshot in
            var fetchedRides: [Ride] = []
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let rideData = child.value as? [String: Any],
                   let ride = self.parseRideData(rideData, id: child.key) {
                    fetchedRides.append(ride)
                }
            }
            self.rides = fetchedRides
        }
    }
    
    private func parseRideData(_ data: [String: Any], id: String) -> Ride? {
        guard
            let pickupLocation = data["pickupLocation"] as? String,
            let dropLocation = data["dropLocation"] as? String,
            let status = data["status"] as? String,
            let latitude = data["latitude"] as? Double,
            let longitude = data["longitude"] as? Double,
            let requestedBy = data["requestedBy"] as? String,
            let userName = data["userName"] as? String,
            let schoolName = data["schoolName"] as? String,
            let phoneNumber = data["phoneNumber"] as? String,
            let userEmail = data["userEmail"] as? String
        else {
            return nil
        }
        
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userEmail)
        docRef.getDocument { _, _ in }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return Ride(id: id, pickupLocation: pickupLocation, dropLocation: dropLocation, status: status, coordinate: coordinate, requestedBy: requestedBy, userName: userName, schoolName: schoolName, phoneNumber: phoneNumber, userEmail: userEmail)
    }
    
    func requestRide(pickupLocation: String, dropLocation: String, coordinate: CLLocationCoordinate2D) {
        guard let user = Auth.auth().currentUser else { return }
        
        let userEmail = user.email ?? "Unknown"
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userEmail)
        docRef.getDocument { document, _ in
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                let userName = data["userName"] as? String ?? "Unknown"
                let schoolName = data["schoolName"] as? String ?? "Unknown"
                let phoneNumber = data["phoneNumber"] as? String ?? "Unknown"
                
                let newRideID = UUID().uuidString
                let newRide = Ride(
                    id: newRideID,
                    pickupLocation: pickupLocation,
                    dropLocation: dropLocation,
                    coordinate: coordinate,
                    requestedBy: userEmail,
                    userName: userName,
                    schoolName: schoolName,
                    phoneNumber: phoneNumber,
                    userEmail: userEmail
                )
                
                let rideData: [String: Any] = [
                    "pickupLocation": newRide.pickupLocation,
                    "dropLocation": newRide.dropLocation,
                    "status": newRide.status,
                    "requestedBy": newRide.requestedBy,
                    "userName": newRide.userName,
                    "schoolName": newRide.schoolName,
                    "phoneNumber": newRide.phoneNumber,
                    "userEmail": newRide.userEmail,
                    "latitude": newRide.coordinate.latitude,
                    "longitude": newRide.coordinate.longitude
                ]
                
                self.dbRef.child("rideRequests").child(newRideID).setValue(rideData) { _, _ in
                    self.rides.append(newRide)
                }
            }
        }
    }
    
    func acceptRide(_ ride: Ride) {
        if let index = rides.firstIndex(where: { $0.id == ride.id }) {
            rides[index].status = "accepted"
            acceptedRide = rides[index]
            dbRef.child("rideRequests").child(ride.id).updateChildValues(["status": "accepted"]) { _, _ in }
        }
    }
    
    func startRide(_ ride: Ride) {
        if let index = rides.firstIndex(where: { $0.id == ride.id }) {
            rides[index].status = "inProgress"
            acceptedRide = rides[index]
            dbRef.child("rideRequests").child(ride.id).updateChildValues(["status": "inProgress"]) { _, _ in }
        }
    }
    
    func completeRide(_ ride: Ride) {
        if let index = rides.firstIndex(where: { $0.id == ride.id }) {
            rides[index].status = "completed"
            acceptedRide = nil
            dbRef.child("rideRequests").child(ride.id).updateChildValues(["status": "completed"]) { _, _ in }
        }
    }
    
    func cancelRide(_ ride: Ride) {
        if let index = rides.firstIndex(where: { $0.id == ride.id }) {
            rides[index].status = "requested"
            acceptedRide = nil
            dbRef.child("rideRequests").child(ride.id).updateChildValues(["status": "requested"]) { _, _ in }
        }
    }
}
