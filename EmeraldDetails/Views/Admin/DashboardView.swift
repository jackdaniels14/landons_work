import SwiftUI

struct DashboardView: View {
    @StateObject private var appointmentService = AppointmentService()
    @State private var totalRevenue: Double = 0
    @State private var monthlyRevenue: Double = 0
    @State private var weeklyRevenue: Double = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Revenue Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "This Week",
                            value: String(format: "$%.0f", weeklyRevenue),
                            icon: "calendar",
                            color: .blue
                        )

                        StatCard(
                            title: "This Month",
                            value: String(format: "$%.0f", monthlyRevenue),
                            icon: "calendar.circle",
                            color: .green
                        )

                        StatCard(
                            title: "Today's Jobs",
                            value: "\(appointmentService.todaysAppointments.count)",
                            icon: "list.clipboard",
                            color: .orange
                        )

                        StatCard(
                            title: "Pending",
                            value: "\(appointmentService.appointments.filter { $0.status == .pending }.count)",
                            icon: "clock",
                            color: .purple
                        )
                    }

                    // Today's Schedule
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today's Schedule")
                                .font(.headline)
                            Spacer()
                            NavigationLink("View All") {
                                AllAppointmentsView()
                            }
                            .font(.subheadline)
                        }

                        if appointmentService.todaysAppointments.isEmpty {
                            Text("No appointments today")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(appointmentService.todaysAppointments.prefix(5)) { appointment in
                                DashboardAppointmentRow(appointment: appointment)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            QuickActionButton(
                                title: "Add Time Slots",
                                icon: "plus.circle",
                                color: .green
                            ) {
                                // Action
                            }

                            QuickActionButton(
                                title: "Send Broadcast",
                                icon: "megaphone",
                                color: .blue
                            ) {
                                // Action
                            }

                            QuickActionButton(
                                title: "View Reports",
                                icon: "chart.pie",
                                color: .purple
                            ) {
                                // Action
                            }

                            QuickActionButton(
                                title: "Add Employee",
                                icon: "person.badge.plus",
                                color: .orange
                            ) {
                                // Action
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .task {
                try? await appointmentService.fetchAllAppointments()
                try? await appointmentService.fetchTodaysAppointments()
                let stats = try? await appointmentService.getRevenueStats()
                totalRevenue = stats?.total ?? 0
                monthlyRevenue = stats?.thisMonth ?? 0
                weeklyRevenue = stats?.thisWeek ?? 0
            }
            .refreshable {
                try? await appointmentService.fetchAllAppointments()
                try? await appointmentService.fetchTodaysAppointments()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DashboardAppointmentRow: View {
    let appointment: Appointment

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(appointment.timeSlot.formattedStartTime)
                    .font(.headline)
                    .foregroundColor(.green)
                Text(appointment.customerName)
                    .font(.subheadline)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(appointment.service.name)
                    .font(.caption)
                StatusBadge(status: appointment.status)
            }
        }
        .padding(.vertical, 8)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
}

#Preview {
    DashboardView()
}
