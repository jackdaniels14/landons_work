import SwiftUI

struct AllAppointmentsView: View {
    @StateObject private var appointmentService = AppointmentService()
    @StateObject private var userService = UserService()
    @State private var selectedStatus: AppointmentStatus?
    @State private var searchText = ""
    @State private var selectedAppointment: Appointment?

    var filteredAppointments: [Appointment] {
        var results = appointmentService.appointments

        if let status = selectedStatus {
            results = results.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            results = results.filter {
                $0.customerName.localizedCaseInsensitiveContains(searchText) ||
                $0.service.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return results
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(title: "All", isSelected: selectedStatus == nil) {
                            selectedStatus = nil
                        }

                        ForEach(AppointmentStatus.allCases, id: \.self) { status in
                            FilterPill(
                                title: status.rawValue,
                                isSelected: selectedStatus == status
                            ) {
                                selectedStatus = status
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                Divider()

                // List
                if appointmentService.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredAppointments.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No appointments found")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredAppointments) { appointment in
                            AdminAppointmentRow(
                                appointment: appointment,
                                employees: userService.employees
                            ) { employeeId, employeeName in
                                Task {
                                    try? await appointmentService.assignEmployee(
                                        appointment.id,
                                        employeeId: employeeId,
                                        employeeName: employeeName
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("All Appointments")
            .searchable(text: $searchText, prompt: "Search by name or service")
            .task {
                try? await appointmentService.fetchAllAppointments()
                try? await userService.fetchEmployees()
            }
            .refreshable {
                try? await appointmentService.fetchAllAppointments()
            }
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct AdminAppointmentRow: View {
    let appointment: Appointment
    let employees: [User]
    let onAssign: (UUID, String) -> Void

    @State private var showAssignSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(appointment.customerName)
                        .font(.headline)
                    Text(appointment.service.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: appointment.status)
            }

            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.green)
                Text(appointment.timeSlot.formattedDate)
                    .font(.caption)

                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.leading, 8)
                Text(appointment.timeSlot.formattedTimeRange)
                    .font(.caption)
            }

            HStack {
                if let employeeName = appointment.employeeName {
                    Label(employeeName, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Button {
                        showAssignSheet = true
                    } label: {
                        Label("Assign Employee", systemImage: "person.badge.plus")
                            .font(.caption)
                    }
                }

                Spacer()

                Text(appointment.formattedPrice)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showAssignSheet) {
            AssignEmployeeSheet(employees: employees) { employeeId, employeeName in
                onAssign(employeeId, employeeName)
            }
        }
    }
}

struct AssignEmployeeSheet: View {
    let employees: [User]
    let onAssign: (UUID, String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(employees) { employee in
                    Button {
                        onAssign(employee.id, employee.name)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(employee.name)
                                    .fontWeight(.medium)
                                if let isAvailable = employee.isAvailable, isAvailable {
                                    Text("Available")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            Spacer()
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Assign Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AllAppointmentsView()
}
