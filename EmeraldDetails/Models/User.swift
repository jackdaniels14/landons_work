import Foundation

enum UserRole: String, Codable, CaseIterable {
    case customer
    case employee
    case admin
}

struct User: Identifiable, Codable {
    let id: UUID
    var firebaseUid: String
    var name: String
    var email: String
    var phone: String
    var role: UserRole
    var isEmailVerified: Bool
    var profileImageUrl: String?
    var stripeCustomerId: String?
    var createdAt: Date

    // Customer-specific
    var vehicles: [Vehicle]?

    // Employee-specific
    var isAvailable: Bool?
    var assignedAppointmentIds: [UUID]?

    init(
        id: UUID = UUID(),
        firebaseUid: String = "",
        name: String,
        email: String,
        phone: String,
        role: UserRole = .customer,
        isEmailVerified: Bool = false,
        profileImageUrl: String? = nil,
        stripeCustomerId: String? = nil,
        createdAt: Date = Date(),
        vehicles: [Vehicle]? = nil,
        isAvailable: Bool? = nil,
        assignedAppointmentIds: [UUID]? = nil
    ) {
        self.id = id
        self.firebaseUid = firebaseUid
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.isEmailVerified = isEmailVerified
        self.profileImageUrl = profileImageUrl
        self.stripeCustomerId = stripeCustomerId
        self.createdAt = createdAt
        self.vehicles = vehicles
        self.isAvailable = isAvailable
        self.assignedAppointmentIds = assignedAppointmentIds
    }
}
