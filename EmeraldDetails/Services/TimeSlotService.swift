import Foundation
import FirebaseFirestore

@MainActor
class TimeSlotService: ObservableObject {
    private let db = Firestore.firestore()
    private let collection = "timeSlots"

    @Published var availableSlots: [TimeSlot] = []
    @Published var isLoading = false

    // MARK: - Fetch Available Slots for Date
    func fetchAvailableSlots(for date: Date) async throws {
        isLoading = true

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        let snapshot = try await db.collection(collection)
            .whereField("date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("date", isLessThan: endOfDay)
            .whereField("isAvailable", isEqualTo: true)
            .getDocuments()

        let fetched = try snapshot.documents.compactMap { doc in
            try doc.data(as: TimeSlot.self)
        }

        availableSlots = fetched.sorted { $0.startTime < $1.startTime }
        isLoading = false
    }

    // MARK: - Create Time Slot (Admin)
    func createTimeSlot(_ slot: TimeSlot) async throws {
        let data = try Firestore.Encoder().encode(slot)
        try await db.collection(collection).document(slot.id.uuidString).setData(data)
    }

    // MARK: - Generate Slots for Date Range (Admin)
    func generateSlotsForDateRange(from startDate: Date, to endDate: Date, employeeId: UUID? = nil, employeeName: String? = nil) async throws {
        var currentDate = startDate
        let calendar = Calendar.current

        while currentDate <= endDate {
            // Skip weekends (optional)
            let weekday = calendar.component(.weekday, from: currentDate)
            if weekday != 1 && weekday != 7 { // Not Sunday or Saturday
                let slots = TimeSlot.generateDailySlots(
                    for: currentDate,
                    employeeId: employeeId,
                    employeeName: employeeName
                )

                for slot in slots {
                    try await createTimeSlot(slot)
                }
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
    }

    // MARK: - Book Slot (mark as unavailable)
    func bookSlot(_ slotId: UUID) async throws {
        try await db.collection(collection).document(slotId.uuidString).updateData([
            "isAvailable": false
        ])

        if let index = availableSlots.firstIndex(where: { $0.id == slotId }) {
            availableSlots.remove(at: index)
        }
    }

    // MARK: - Release Slot (make available again)
    func releaseSlot(_ slotId: UUID) async throws {
        try await db.collection(collection).document(slotId.uuidString).updateData([
            "isAvailable": true
        ])
    }

    // MARK: - Delete Slot (Admin)
    func deleteSlot(_ slotId: UUID) async throws {
        try await db.collection(collection).document(slotId.uuidString).delete()
        availableSlots.removeAll { $0.id == slotId }
    }

    // MARK: - Assign Employee to Slot (Admin)
    func assignEmployee(_ slotId: UUID, employeeId: UUID, employeeName: String) async throws {
        try await db.collection(collection).document(slotId.uuidString).updateData([
            "assignedEmployeeId": employeeId.uuidString,
            "assignedEmployeeName": employeeName
        ])
    }
}
