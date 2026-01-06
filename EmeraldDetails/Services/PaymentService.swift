import Foundation
import FirebaseFirestore

@MainActor
class PaymentService: ObservableObject {
    private let db = Firestore.firestore()
    private let collection = "payments"

    @Published var paymentMethods: [PaymentMethod] = []
    @Published var transactions: [Transaction] = []
    @Published var isProcessing = false

    // MARK: - Stripe Configuration
    // TODO: Replace with your Stripe publishable key
    static let stripePublishableKey = "pk_test_YOUR_KEY_HERE"

    // MARK: - Fetch Payment Methods
    func fetchPaymentMethods(for customerId: UUID) async throws {
        let snapshot = try await db.collection("users")
            .document(customerId.uuidString)
            .collection("paymentMethods")
            .getDocuments()

        let fetched = try snapshot.documents.compactMap { doc in
            try doc.data(as: PaymentMethod.self)
        }

        paymentMethods = fetched
    }

    // MARK: - Add Payment Method
    func addPaymentMethod(_ method: PaymentMethod, customerId: UUID) async throws {
        let data = try Firestore.Encoder().encode(method)

        // If this is the first method or marked as default, update others
        if method.isDefault || paymentMethods.isEmpty {
            for existingMethod in paymentMethods {
                if existingMethod.isDefault {
                    try await db.collection("users")
                        .document(customerId.uuidString)
                        .collection("paymentMethods")
                        .document(existingMethod.id.uuidString)
                        .updateData(["isDefault": false])
                }
            }
        }

        try await db.collection("users")
            .document(customerId.uuidString)
            .collection("paymentMethods")
            .document(method.id.uuidString)
            .setData(data)

        var newMethod = method
        if paymentMethods.isEmpty {
            newMethod.isDefault = true
        }
        paymentMethods.append(newMethod)
    }

    // MARK: - Remove Payment Method
    func removePaymentMethod(_ methodId: UUID, customerId: UUID) async throws {
        try await db.collection("users")
            .document(customerId.uuidString)
            .collection("paymentMethods")
            .document(methodId.uuidString)
            .delete()

        paymentMethods.removeAll { $0.id == methodId }
    }

    // MARK: - Set Default Payment Method
    func setDefaultPaymentMethod(_ methodId: UUID, customerId: UUID) async throws {
        // Remove default from all others
        for method in paymentMethods {
            try await db.collection("users")
                .document(customerId.uuidString)
                .collection("paymentMethods")
                .document(method.id.uuidString)
                .updateData(["isDefault": method.id == methodId])
        }

        // Update local state
        for i in paymentMethods.indices {
            paymentMethods[i].isDefault = paymentMethods[i].id == methodId
        }
    }

    // MARK: - Process Payment
    func processPayment(
        amount: Double,
        appointmentId: UUID,
        customerId: UUID,
        paymentMethodId: UUID
    ) async throws -> Transaction {
        isProcessing = true

        // TODO: Integrate with Stripe
        // 1. Create PaymentIntent on your backend
        // 2. Confirm payment with Stripe SDK
        // 3. Store transaction

        // Mock implementation for now
        let transaction = Transaction(
            appointmentId: appointmentId,
            customerId: customerId,
            amount: amount,
            status: .paid,
            paymentMethodId: paymentMethodId,
            stripePaymentIntentId: "pi_mock_\(UUID().uuidString.prefix(8))"
        )

        let data = try Firestore.Encoder().encode(transaction)
        try await db.collection(collection).document(transaction.id.uuidString).setData(data)

        transactions.append(transaction)
        isProcessing = false

        return transaction
    }

    // MARK: - Fetch Transactions
    func fetchTransactions(for customerId: UUID) async throws {
        let snapshot = try await db.collection(collection)
            .whereField("customerId", isEqualTo: customerId.uuidString)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        let fetched = try snapshot.documents.compactMap { doc in
            try doc.data(as: Transaction.self)
        }

        transactions = fetched
    }

    // MARK: - Refund (Admin)
    func refundTransaction(_ transactionId: UUID) async throws {
        // TODO: Process refund through Stripe

        try await db.collection(collection).document(transactionId.uuidString).updateData([
            "status": PaymentStatus.refunded.rawValue
        ])

        if let index = transactions.firstIndex(where: { $0.id == transactionId }) {
            transactions[index].status = .refunded
        }
    }
}
