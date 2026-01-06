import Foundation

enum VehicleSize: String, Codable, CaseIterable {
    case compact = "Compact"
    case sedan = "Sedan"
    case suv = "SUV"
    case truck = "Truck"
    case van = "Van"
    case luxury = "Luxury"

    var priceMultiplier: Double {
        switch self {
        case .compact: return 0.9
        case .sedan: return 1.0
        case .suv: return 1.3
        case .truck: return 1.4
        case .van: return 1.5
        case .luxury: return 1.6
        }
    }
}

struct Vehicle: Identifiable, Codable, Hashable {
    let id: UUID
    var make: String
    var model: String
    var year: Int
    var color: String
    var licensePlate: String?
    var size: VehicleSize
    var notes: String?

    init(
        id: UUID = UUID(),
        make: String,
        model: String,
        year: Int,
        color: String,
        licensePlate: String? = nil,
        size: VehicleSize,
        notes: String? = nil
    ) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.color = color
        self.licensePlate = licensePlate
        self.size = size
        self.notes = notes
    }

    var displayName: String {
        "\(year) \(make) \(model)"
    }

    var fullDescription: String {
        "\(year) \(color) \(make) \(model)"
    }
}
