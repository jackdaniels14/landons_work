import Foundation

enum PaymentMethodType: String, Codable {
    case card
    case applePay
    case bankAccount
}

struct PaymentMethod: Identifiable, Codable {
    let id: UUID
    var type: PaymentMethodType
    var isDefault: Bool
    var cardLast4: String?
    var cardBrand: String?
    var cardExpMonth: Int?
    var cardExpYear: Int?
    var stripePaymentMethodId: String?

    init(
        id: UUID = UUID(),
        type: PaymentMethodType,
        isDefault: Bool = false,
        cardLast4: String? = nil,
        cardBrand: String? = nil,
        cardExpMonth: Int? = nil,
        cardExpYear: Int? = nil,
        stripePaymentMethodId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.isDefault = isDefault
        self.cardLast4 = cardLast4
        self.cardBrand = cardBrand
        self.cardExpMonth = cardExpMonth
        self.cardExpYear = cardExpYear
        self.stripePaymentMethodId = stripePaymentMethodId
    }

    var displayName: String {
        switch type {
        case .card:
            if let brand = cardBrand, let last4 = cardLast4 {
                return "\(brand.capitalized) ****\(last4)"
            }
            return "Card"
        case .applePay:
            return "Apple Pay"
        case .bankAccount:
            return "Bank Account"
        }
    }

    var expirationString: String? {
        guard let month = cardExpMonth, let year = cardExpYear else { return nil }
        return String(format: "%02d/%02d", month, year % 100)
    }
}

struct Transaction: Identifiable, Codable {
    let id: UUID
    var appointmentId: UUID
    var customerId: UUID
    var amount: Double
    var status: PaymentStatus
    var paymentMethodId: UUID?
    var stripePaymentIntentId: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        appointmentId: UUID,
        customerId: UUID,
        amount: Double,
        status: PaymentStatus = .pending,
        paymentMethodId: UUID? = nil,
        stripePaymentIntentId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.appointmentId = appointmentId
        self.customerId = customerId
        self.amount = amount
        self.status = status
        self.paymentMethodId = paymentMethodId
        self.stripePaymentIntentId = stripePaymentIntentId
        self.createdAt = createdAt
    }

    var formattedAmount: String {
        String(format: "$%.2f", amount)
    }
}
