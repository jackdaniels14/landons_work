import Foundation
import FirebaseFirestore

class UserService: ObservableObject {
    private let db = Firestore.firestore()
    private let collection = "users"

    @Published var employees: [User] = []
    @Published var customers: [User] = []

    // MARK: - Create
    func createUserProfile(_ user: User, firebaseUid: String) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await db.collection(collection).document(firebaseUid).setData(data)
    }

    // MARK: - Read
    func getUserByFirebaseUid(_ firebaseUid: String) async throws -> User? {
        let document = try await db.collection(collection).document(firebaseUid).getDocument()
        guard document.exists else { return nil }
        return try document.data(as: User.self)
    }

    func getUserById(_ id: UUID) async throws -> User? {
        let snapshot = try await db.collection(collection)
            .whereField("id", isEqualTo: id.uuidString)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first?.data(as: User.self)
    }

    // MARK: - Update
    func updateUserProfile(_ user: User) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await db.collection(collection).document(user.firebaseUid).setData(data, merge: true)
    }

    func updateEmailVerification(firebaseUid: String, isVerified: Bool) async throws {
        try await db.collection(collection).document(firebaseUid).updateData([
            "isEmailVerified": isVerified
        ])
    }

    // MARK: - Fetch Employees
    func fetchEmployees() async throws {
        let snapshot = try await db.collection(collection)
            .whereField("role", isEqualTo: UserRole.employee.rawValue)
            .getDocuments()

        let fetchedEmployees = try snapshot.documents.compactMap { doc in
            try doc.data(as: User.self)
        }

        await MainActor.run {
            self.employees = fetchedEmployees
        }
    }

    // MARK: - Fetch Customers
    func fetchCustomers() async throws {
        let snapshot = try await db.collection(collection)
            .whereField("role", isEqualTo: UserRole.customer.rawValue)
            .getDocuments()

        let fetchedCustomers = try snapshot.documents.compactMap { doc in
            try doc.data(as: User.self)
        }

        await MainActor.run {
            self.customers = fetchedCustomers
        }
    }

    // MARK: - Employee Availability
    func updateEmployeeAvailability(firebaseUid: String, isAvailable: Bool) async throws {
        try await db.collection(collection).document(firebaseUid).updateData([
            "isAvailable": isAvailable
        ])
    }

    // MARK: - Delete (Admin only)
    func deleteUser(firebaseUid: String) async throws {
        try await db.collection(collection).document(firebaseUid).delete()
    }
}
