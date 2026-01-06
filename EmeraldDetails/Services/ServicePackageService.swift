import Foundation
import FirebaseFirestore

@MainActor
class ServicePackageService: ObservableObject {
    private let db = Firestore.firestore()
    private let collection = "services"

    @Published var services: [ServicePackage] = []
    @Published var activeServices: [ServicePackage] = []
    @Published var isLoading = false

    // MARK: - Fetch Services
    func fetchServices() async throws {
        isLoading = true

        let snapshot = try await db.collection(collection)
            .order(by: "sortOrder")
            .getDocuments()

        let fetched = try snapshot.documents.compactMap { doc in
            try doc.data(as: ServicePackage.self)
        }

        services = fetched
        activeServices = fetched.filter { $0.isActive }
        isLoading = false
    }

    // MARK: - Create Service (Admin)
    func createService(_ service: ServicePackage) async throws {
        let data = try Firestore.Encoder().encode(service)
        try await db.collection(collection).document(service.id.uuidString).setData(data)

        services.append(service)
        services.sort { $0.sortOrder < $1.sortOrder }
        activeServices = services.filter { $0.isActive }
    }

    // MARK: - Update Service (Admin)
    func updateService(_ service: ServicePackage) async throws {
        let data = try Firestore.Encoder().encode(service)
        try await db.collection(collection).document(service.id.uuidString).setData(data, merge: true)

        if let index = services.firstIndex(where: { $0.id == service.id }) {
            services[index] = service
        }
        activeServices = services.filter { $0.isActive }
    }

    // MARK: - Toggle Active Status (Admin)
    func toggleServiceActive(_ serviceId: UUID) async throws {
        guard let index = services.firstIndex(where: { $0.id == serviceId }) else { return }

        let newStatus = !services[index].isActive

        try await db.collection(collection).document(serviceId.uuidString).updateData([
            "isActive": newStatus
        ])

        services[index].isActive = newStatus
        activeServices = services.filter { $0.isActive }
    }

    // MARK: - Delete Service (Admin)
    func deleteService(_ serviceId: UUID) async throws {
        try await db.collection(collection).document(serviceId.uuidString).delete()

        services.removeAll { $0.id == serviceId }
        activeServices = services.filter { $0.isActive }
    }

    // MARK: - Seed Default Services (Admin - one time)
    func seedDefaultServices() async throws {
        for service in ServicePackage.defaultServices {
            let data = try Firestore.Encoder().encode(service)
            try await db.collection(collection).document(service.id.uuidString).setData(data)
        }

        services = ServicePackage.defaultServices
        activeServices = services
    }
}
