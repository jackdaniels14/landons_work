import Foundation

struct ServicePackage: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var basePrice: Double
    var duration: Int // in minutes
    var features: [String]
    var isActive: Bool
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        basePrice: Double,
        duration: Int,
        features: [String] = [],
        isActive: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.basePrice = basePrice
        self.duration = duration
        self.features = features
        self.isActive = isActive
        self.sortOrder = sortOrder
    }

    func priceForVehicle(_ vehicle: Vehicle) -> Double {
        basePrice * vehicle.size.priceMultiplier
    }

    var formattedPrice: String {
        String(format: "$%.0f+", basePrice)
    }

    var formattedDuration: String {
        if duration >= 60 {
            let hours = duration / 60
            let mins = duration % 60
            if mins > 0 {
                return "\(hours)h \(mins)m"
            }
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        }
        return "\(duration) min"
    }
}

// Default services for Emerald Details
extension ServicePackage {
    static let defaultServices: [ServicePackage] = [
        ServicePackage(
            name: "Express Wash",
            description: "Quick exterior hand wash and dry",
            basePrice: 35,
            duration: 30,
            features: ["Hand wash", "Wheel cleaning", "Tire shine", "Window cleaning"],
            sortOrder: 1
        ),
        ServicePackage(
            name: "Interior Detail",
            description: "Complete interior cleaning and conditioning",
            basePrice: 75,
            duration: 60,
            features: ["Vacuum & steam clean", "Dashboard & console detail", "Leather conditioning", "Window cleaning", "Air freshener"],
            sortOrder: 2
        ),
        ServicePackage(
            name: "Exterior Detail",
            description: "Full exterior wash, clay bar, and wax",
            basePrice: 100,
            duration: 90,
            features: ["Hand wash", "Clay bar treatment", "Polish", "Wax application", "Tire & trim dressing"],
            sortOrder: 3
        ),
        ServicePackage(
            name: "Full Detail",
            description: "Complete interior and exterior detailing",
            basePrice: 150,
            duration: 150,
            features: ["Everything in Interior Detail", "Everything in Exterior Detail", "Engine bay cleaning", "Headlight restoration"],
            sortOrder: 4
        ),
        ServicePackage(
            name: "Ceramic Coating",
            description: "Professional ceramic coating application",
            basePrice: 300,
            duration: 240,
            features: ["Full detail included", "Paint correction", "Ceramic coating application", "2-year protection"],
            sortOrder: 5
        )
    ]
}
