import Foundation

enum AppointmentStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "blue"
        case .inProgress: return "purple"
        case .completed: return "green"
        case .cancelled: return "red"
        }
    }
}

enum PaymentStatus: String, Codable {
    case pending = "Pending"
    case paid = "Paid"
    case failed = "Failed"
    case refunded = "Refunded"
}

struct Appointment: Identifiable, Codable {
    let id: UUID
    var customerId: UUID
    var customerName: String
    var customerPhone: String
    var employeeId: UUID?
    var employeeName: String?
    var vehicle: Vehicle
    var service: ServicePackage
    var timeSlot: TimeSlot
    var location: Location
    var status: AppointmentStatus
    var totalPrice: Double
    var paymentStatus: PaymentStatus
    var paymentIntentId: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        customerId: UUID,
        customerName: String,
        customerPhone: String,
        employeeId: UUID? = nil,
        employeeName: String? = nil,
        vehicle: Vehicle,
        service: ServicePackage,
        timeSlot: TimeSlot,
        location: Location,
        status: AppointmentStatus = .pending,
        totalPrice: Double,
        paymentStatus: PaymentStatus = .pending,
        paymentIntentId: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.customerId = customerId
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.employeeId = employeeId
        self.employeeName = employeeName
        self.vehicle = vehicle
        self.service = service
        self.timeSlot = timeSlot
        self.location = location
        self.status = status
        self.totalPrice = totalPrice
        self.paymentStatus = paymentStatus
        self.paymentIntentId = paymentIntentId
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var formattedPrice: String {
        String(format: "$%.2f", totalPrice)
    }

    var isUpcoming: Bool {
        status == .pending || status == .confirmed
    }

    var canBeCancelled: Bool {
        status == .pending || status == .confirmed
    }
}
