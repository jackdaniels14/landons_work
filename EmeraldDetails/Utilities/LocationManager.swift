import Foundation
import CoreLocation
import MapKit

@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Address Search
    func searchAddress(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if let location = userLocation {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 50000,
                longitudinalMeters: 50000
            )
        }

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            searchResults = response.mapItems
        } catch {
            searchResults = []
        }

        isSearching = false
    }

    // MARK: - Geocoding
    func geocodeAddress(_ address: String) async -> Location? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            guard let placemark = placemarks.first,
                  let coordinate = placemark.location?.coordinate else {
                return nil
            }

            return Location(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                address: address,
                city: placemark.locality,
                state: placemark.administrativeArea,
                zipCode: placemark.postalCode
            )
        } catch {
            return nil
        }
    }

    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> Location? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            let address = [
                placemark.subThoroughfare,
                placemark.thoroughfare
            ].compactMap { $0 }.joined(separator: " ")

            return Location(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                address: address.isEmpty ? "Unknown Address" : address,
                city: placemark.locality,
                state: placemark.administrativeArea,
                zipCode: placemark.postalCode
            )
        } catch {
            return nil
        }
    }

    // MARK: - Map Item to Location
    func mapItemToLocation(_ mapItem: MKMapItem) -> Location {
        let placemark = mapItem.placemark

        let address = [
            placemark.subThoroughfare,
            placemark.thoroughfare
        ].compactMap { $0 }.joined(separator: " ")

        return Location(
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude,
            address: address.isEmpty ? mapItem.name ?? "Unknown" : address,
            city: placemark.locality,
            state: placemark.administrativeArea,
            zipCode: placemark.postalCode
        )
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
