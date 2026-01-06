import Foundation
import CoreLocation

struct Location: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let address: String
    let city: String?
    let state: String?
    let zipCode: String?

    init(
        latitude: Double,
        longitude: Double,
        address: String,
        city: String? = nil,
        state: String? = nil,
        zipCode: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var fullAddress: String {
        var parts = [address]
        if let city = city {
            parts.append(city)
        }
        if let state = state {
            parts.append(state)
        }
        if let zipCode = zipCode {
            parts.append(zipCode)
        }
        return parts.joined(separator: ", ")
    }

    var shortAddress: String {
        if let city = city {
            return "\(address), \(city)"
        }
        return address
    }
}
