import SwiftUI

struct MyAppointmentsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var appointmentService = AppointmentService()
    @State private var selectedFilter: AppointmentFilter = .upcoming

    enum AppointmentFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
        case all = "All"
    }

    var filteredAppointments: [Appointment] {
        switch selectedFilter {
        case .upcoming:
            return appointmentService.appointments.filter { $0.isUpcoming }
        case .past:
            return appointmentService.appointments.filter { !$0.isUpcoming }
        case .all:
            return appointmentService.appointments
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(AppointmentFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Appointments List
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
                        Text("No \(selectedFilter.rawValue.lowercased()) appointments")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredAppointments) { appointment in
                            AppointmentCard(appointment: appointment) {
                                // Cancel action
                                Task {
                                    try? await appointmentService.cancelAppointment(appointment.id)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Appointments")
            .task {
                if let userId = authManager.currentUser?.id {
                    try? await appointmentService.fetchAppointmentsForCustomer(userId)
                }
            }
            .refreshable {
                if let userId = authManager.currentUser?.id {
                    try? await appointmentService.fetchAppointmentsForCustomer(userId)
                }
            }
        }
    }
}

struct AppointmentCard: View {
    let appointment: Appointment
    let onCancel: () -> Void

    @State private var showCancelAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(appointment.service.name)
                        .font(.headline)
                    Text(appointment.vehicle.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: appointment.status)
            }

            Divider()

            // Details
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.green)
                Text(appointment.timeSlot.formattedDate)
                    .font(.subheadline)
            }

            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.green)
                Text(appointment.timeSlot.formattedTimeRange)
                    .font(.subheadline)
            }

            HStack {
                Image(systemName: "mappin")
                    .foregroundColor(.green)
                Text(appointment.location.shortAddress)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            // Footer
            HStack {
                Text(appointment.formattedPrice)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Spacer()

                if appointment.canBeCancelled {
                    Button("Cancel") {
                        showCancelAlert = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Cancel Appointment?", isPresented: $showCancelAlert) {
            Button("Yes, Cancel", role: .destructive) {
                onCancel()
            }
            Button("No, Keep It", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this appointment?")
        }
    }
}

struct StatusBadge: View {
    let status: AppointmentStatus

    var color: Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .blue
        case .inProgress: return .purple
        case .completed: return .green
        case .cancelled: return .red
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

#Preview {
    MyAppointmentsView()
        .environmentObject(AuthenticationManager())
}
