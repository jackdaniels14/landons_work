import Foundation

struct TimeSlot: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var isAvailable: Bool
    var assignedEmployeeId: UUID?
    var assignedEmployeeName: String?

    init(
        id: UUID = UUID(),
        date: Date,
        startTime: Date,
        endTime: Date,
        isAvailable: Bool = true,
        assignedEmployeeId: UUID? = nil,
        assignedEmployeeName: String? = nil
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.isAvailable = isAvailable
        self.assignedEmployeeId = assignedEmployeeId
        self.assignedEmployeeName = assignedEmployeeName
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}

// Helper to generate default time slots
extension TimeSlot {
    static func generateDailySlots(for date: Date, employeeId: UUID? = nil, employeeName: String? = nil) -> [TimeSlot] {
        let calendar = Calendar.current
        var slots: [TimeSlot] = []

        // Time slots: 8am, 10am, 12pm, 2pm, 4pm
        let hours = [8, 10, 12, 14, 16]

        for hour in hours {
            guard let startTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date),
                  let endTime = calendar.date(byAdding: .hour, value: 2, to: startTime) else {
                continue
            }

            let slot = TimeSlot(
                date: date,
                startTime: startTime,
                endTime: endTime,
                isAvailable: true,
                assignedEmployeeId: employeeId,
                assignedEmployeeName: employeeName
            )
            slots.append(slot)
        }

        return slots
    }
}
