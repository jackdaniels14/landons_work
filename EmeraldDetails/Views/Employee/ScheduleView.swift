import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var appointmentService = AppointmentService()
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date Picker
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .padding()
                .onChange(of: selectedDate) { _, _ in
                    loadAppointments()
                }

                Divider()

                // Appointments List
                if appointmentService.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if appointmentService.todaysAppointments.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No appointments scheduled")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(appointmentService.todaysAppointments) { appointment in
                            NavigationLink {
                                AppointmentDetailView(appointment: appointment)
                            } label: {
                                EmployeeAppointmentRow(appointment: appointment)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Schedule")
            .task {
                loadAppointments()
            }
            .refreshable {
                loadAppointments()
            }
        }
    }

    func loadAppointments() {
        Task {
            if let userId = authManager.currentUser?.id {
                try? await appointmentService.fetchTodaysAppointments(for: userId)
            }
        }
    }
}

struct EmployeeAppointmentRow: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(appointment.timeSlot.formattedStartTime)
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()

                StatusBadge(status: appointment.status)
            }

            Text(appointment.service.name)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(appointment.customerName)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "car.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(appointment.vehicle.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ScheduleView()
        .environmentObject(AuthenticationManager())
}
