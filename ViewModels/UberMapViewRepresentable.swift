import SwiftUI
import MapKit

struct UberMapViewRepresentable: UIViewRepresentable {
    let mapView = MKMapView()
    let locationManager = LocationManager()
    @Binding var rides: [Ride]
    var selectedRide: Ride?

    func makeUIView(context: Context) -> some UIView {
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = true
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let mapView = uiView as? MKMapView else { return }
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        for ride in rides {
            let annotation = MKPointAnnotation()
            annotation.coordinate = ride.coordinate
            annotation.title = "Ride Request"
            annotation.subtitle = "Pickup at \(ride.pickupLocation)"
            mapView.addAnnotation(annotation)
        }

        if let ride = selectedRide, ride.status == "inProgress" || ride.status == "accepted" {
            guard let userLocation = locationManager.location?.coordinate else { return }
            let pickupPlacemark = MKPlacemark(coordinate: ride.coordinate)
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
            request.destination = MKMapItem(placemark: pickupPlacemark)
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { response, _ in
                guard let route = response?.routes.first else { return }
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }

    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(parent: self)
    }
}

extension UberMapViewRepresentable {
    class MapCoordinator: NSObject, MKMapViewDelegate {
        let parent: UberMapViewRepresentable

        init(parent: UberMapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 4.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if mapView.region.center.latitude == 0 && mapView.region.center.longitude == 0 {
                let region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                mapView.setRegion(region, animated: true)
            }
        }
    }
}
