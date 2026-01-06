import Foundation
import FirebaseFirestore

@MainActor
class AppointmentService: ObservableObject {
    private let db = Firestore.firestore()
    private let collection = "appointments"

    @Published var appointments: [Appointment] = []
    @Published var todaysAppointments: [Appointment] = []
    @Published var upcomingAppointments: [Appointment] = []
    @Published var isLoading = false

    // MARK: - Create Appointment
    func createAppointment(_ appointment: Appointment) async throws {
        let data = try Firestore.Encoder().encode(appointment)
        try await db.collection(collection).document(appointment.id.uuidString).setData(data)

        appointments.append(appointment)
        sortAppointments()
    }

    // MARK: - Fetch Appointments
    func fetchAllAppointments() async throws {
        isLoading = true

        let snapshot = try await db.collection(collection)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        let fetched = try snapshot.documents.compactMap { doc in
            try doc.data(as: Appointment.self)
        }

        appointments = fetched
        sortAppointments()
        isLoading = false
    }

    func fetchAppointmentsForCustomer(_ customerId: UUID) async throws {
        isLoading = true

        let snapshot = try await db.collection(collection)
            .whereField("customerId", isEqualTo: customerId.uuidString)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        let fetched = try snapshot.documents.compactMap { doc in
            try doc.data(as: Appointment.self)
        }

        appointments = fetched
        sortAppointments()
        isLoading = false
    }

    func fetchAppointmentsForEmployee(_ employeeId: UUID) async throws {
        isLoading = true

        let snapshot = try await db.collection(collection)
            .whereField("employeeId", isEqualTo: employeeId.uuidString)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        let fetched = try snapshot.documents.compactMap { doc in
            try doc.data(as: Appointment.self)
        }

        appointments = fetched
        filterTodaysAppointments()
        sortAppointments()
        isLoading = false
    }

    func fetchTodaysAppointments(for employeeId: UUID? = nil) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        var query: Query = db.collection(collection)
            .whereField("timeSlot.date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("timeSlot.date", isLessThan: endOfDay)

        if let employeeId = employeeId {
            query = query.whereField("employeeId", isEqualTo: employeeId.uuidString)
        }

        let snapshot = try await query.getDocuments()

        let fetched = try snapshot.documents.compactMap { doc in
            try doc.data(as: Appointment.self)
        }

        todaysAppointments = fetched.sorted { $0.timeSlot.startTime < $1.timeSlot.startTime }
    }

    // MARK: - Update Status
    func updateStatus(_ appointmentId: UUID, status: AppointmentStatus) async throws {
        try await db.collection(collection).document(appointmentId.uuidString).updateData([
            "status": status.rawValue,
            "updatedAt": Date()
        ])

        if let index = appointments.firstIndex(where: { $0.id == appointmentId }) {
            appointments[index].status = status
            appointments[index].updatedAt = Date()
        }
    }

    func updatePaymentStatus(_ appointmentId: UUID, status: PaymentStatus, paymentIntentId: String? = nil) async throws {
        var updates: [String: Any] = [
            "paymentStatus": status.rawValue,
            "updatedAt": Date()
        ]

        if let paymentIntentId = paymentIntentId {
            updates["paymentIntentId"] = paymentIntentId
        }

        try await db.collection(collection).document(appointmentId.uuidString).updateData(updates)

        if let index = appointments.firstIndex(where: { $0.id == appointmentId }) {
            appointments[index].paymentStatus = status
            appointments[index].paymentIntentId = paymentIntentId
        }
    }

    // MARK: - Assign Employee
    func assignEmployee(_ appointmentId: UUID, employeeId: UUID, employeeName: String) async throws {
        try await db.collection(collection).document(appointmentId.uuidString).updateData([
            "employeeId": employeeId.uuidString,
            "employeeName": employeeName,
            "status": AppointmentStatus.confirmed.rawValue,
            "updatedAt": Date()
        ])

        if let index = appointments.firstIndex(where: { $0.id == appointmentId }) {
            appointments[index].employeeId = employeeId
            appointments[index].employeeName = employeeName
            appointments[index].status = .confirmed
        }
    }

    // MARK: - Cancel
    func cancelAppointment(_ appointmentId: UUID) async throws {
        try await updateStatus(appointmentId, status: .cancelled)
    }

    // MARK: - Delete
    func deleteAppointment(_ appointmentId: UUID) async throws {
        try await db.collection(collection).document(appointmentId.uuidString).delete()
        appointments.removeAll { $0.id == appointmentId }
    }

    // MARK: - Helpers
    private func sortAppointments() {
        appointments.sort { $0.timeSlot.startTime > $1.timeSlot.startTime }
        upcomingAppointments = appointments.filter { $0.isUpcoming }
    }

    private func filterTodaysAppointments() {
        let calendar = Calendar.current
        todaysAppointments = appointments.filter {
            calendar.isDateInToday($0.timeSlot.date)
        }.sorted { $0.timeSlot.startTime < $1.timeSlot.startTime }
    }

    // MARK: - Statistics (Admin)
    func getRevenueStats() async throws -> (total: Double, thisMonth: Double, thisWeek: Double) {
        let snapshot = try await db.collection(collection)
            .whereField("paymentStatus", isEqualTo: PaymentStatus.paid.rawValue)
            .getDocuments()

        let paidAppointments = try snapshot.documents.compactMap { doc in
            try doc.data(as: Appointment.self)
        }

        let total = paidAppointments.reduce(0) { $0 + $1.totalPrice }

        let calendar = Calendar.current
        let now = Date()

        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let thisMonth = paidAppointments
            .filter { $0.createdAt >= thisMonthStart }
            .reduce(0) { $0 + $1.totalPrice }

        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let thisWeek = paidAppointments
            .filter { $0.createdAt >= thisWeekStart }
            .reduce(0) { $0 + $1.totalPrice }

        return (total, thisMonth, thisWeek)
    }
}
