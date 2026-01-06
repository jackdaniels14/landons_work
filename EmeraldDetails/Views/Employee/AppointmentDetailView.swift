import SwiftUI
import MapKit

struct AppointmentDetailView: View {
    @StateObject private var appointmentService = AppointmentService()
    @State var appointment: Appointment
    @State private var showStartAlert = false
    @State private var showCompleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Card
                VStack(spacing: 12) {
                    StatusBadge(status: appointment.status)

                    Text(appointment.timeSlot.formattedTimeRange)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(appointment.timeSlot.formattedDate)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Customer Info
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Customer")

                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.green)
                        Text(appointment.customerName)
                            .fontWeight(.medium)
                    }

                    Link(destination: URL(string: "tel:\(appointment.customerPhone)")!) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                            Text(appointment.customerPhone)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Service Info
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Service")

                    Text(appointment.service.name)
                        .font(.headline)

                    Text(appointment.vehicle.fullDescription)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Duration:")
                            .foregroundColor(.secondary)
                        Text(appointment.service.formattedDuration)
                    }

                    HStack {
                        Text("Price:")
                            .foregroundColor(.secondary)
                        Text(appointment.formattedPrice)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Location
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Location")

                    Text(appointment.location.fullAddress)

                    // Mini Map
                    Map(position: .constant(.region(MKCoordinateRegion(
                        center: appointment.location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )))) {
                        Marker(appointment.customerName, coordinate: appointment.location.coordinate)
                    }
                    .frame(height: 150)
                    .cornerRadius(10)

                    // Directions Button
                    Button {
                        openMaps()
                    } label: {
                        Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Notes
                if let notes = appointment.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Notes")
                        Text(notes)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Appointment")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    var actionButtons: some View {
        switch appointment.status {
        case .confirmed:
            Button {
                showStartAlert = true
            } label: {
                Label("Start Service", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .alert("Start Service?", isPresented: $showStartAlert) {
                Button("Start") {
                    updateStatus(.inProgress)
                }
                Button("Cancel", role: .cancel) {}
            }

        case .inProgress:
            Button {
                showCompleteAlert = true
            } label: {
                Label("Mark Complete", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .alert("Complete Service?", isPresented: $showCompleteAlert) {
                Button("Complete") {
                    updateStatus(.completed)
                }
                Button("Cancel", role: .cancel) {}
            }

        case .completed:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Service Completed")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)

        default:
            EmptyView()
        }
    }

    func updateStatus(_ status: AppointmentStatus) {
        Task {
            try? await appointmentService.updateStatus(appointment.id, status: status)
            appointment.status = status
        }
    }

    func openMaps() {
        let coordinate = appointment.location.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = appointment.customerName
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}

#Preview {
    NavigationStack {
        AppointmentDetailView(appointment: Appointment(
            customerId: UUID(),
            customerName: "John Doe",
            customerPhone: "555-123-4567",
            vehicle: Vehicle(make: "Toyota", model: "Camry", year: 2022, color: "Silver", size: .sedan),
            service: ServicePackage.defaultServices[0],
            timeSlot: TimeSlot(date: Date(), startTime: Date(), endTime: Date()),
            location: Location(latitude: 47.6062, longitude: -122.3321, address: "123 Main St", city: "Seattle", state: "WA"),
            status: .confirmed,
            totalPrice: 150
        ))
    }
}
