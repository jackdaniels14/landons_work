import SwiftUI

struct BookingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var servicePackageService = ServicePackageService()
    @StateObject private var timeSlotService = TimeSlotService()
    @StateObject private var appointmentService = AppointmentService()
    @StateObject private var locationManager = LocationManager()

    @State private var currentStep = 0
    @State private var selectedService: ServicePackage?
    @State private var selectedVehicle: Vehicle?
    @State private var selectedDate = Date()
    @State private var selectedTimeSlot: TimeSlot?
    @State private var address = ""
    @State private var selectedLocation: Location?
    @State private var notes = ""
    @State private var showAddVehicle = false
    @State private var showConfirmation = false
    @State private var bookingComplete = false

    var totalPrice: Double {
        guard let service = selectedService, let vehicle = selectedVehicle else { return 0 }
        return service.priceForVehicle(vehicle)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Indicator
                ProgressSteps(currentStep: currentStep, totalSteps: 5)
                    .padding()

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 0:
                            serviceSelectionStep
                        case 1:
                            vehicleSelectionStep
                        case 2:
                            dateTimeSelectionStep
                        case 3:
                            locationStep
                        case 4:
                            reviewStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }

                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    Button(currentStep == 4 ? "Confirm Booking" : "Next") {
                        if currentStep == 4 {
                            confirmBooking()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(!canProceed)
                }
                .padding()
            }
            .navigationTitle("Book Appointment")
            .task {
                try? await servicePackageService.fetchServices()
            }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView()
            }
            .alert("Booking Confirmed!", isPresented: $bookingComplete) {
                Button("OK") {
                    resetBooking()
                }
            } message: {
                Text("Your appointment has been scheduled. You'll receive a confirmation shortly.")
            }
        }
    }

    // MARK: - Step Views

    var serviceSelectionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select a Service")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(servicePackageService.activeServices) { service in
                ServiceCard(
                    service: service,
                    isSelected: selectedService?.id == service.id
                ) {
                    selectedService = service
                }
            }
        }
    }

    var vehicleSelectionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Your Vehicle")
                .font(.title2)
                .fontWeight(.bold)

            if let vehicles = authManager.currentUser?.vehicles, !vehicles.isEmpty {
                ForEach(vehicles) { vehicle in
                    VehicleCard(
                        vehicle: vehicle,
                        isSelected: selectedVehicle?.id == vehicle.id
                    ) {
                        selectedVehicle = vehicle
                    }
                }
            }

            Button {
                showAddVehicle = true
            } label: {
                Label("Add New Vehicle", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }

            if let service = selectedService, let vehicle = selectedVehicle {
                PriceBreakdown(service: service, vehicle: vehicle)
            }
        }
    }

    var dateTimeSelectionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Date & Time")
                .font(.title2)
                .fontWeight(.bold)

            DatePicker(
                "Select Date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(.green)
            .onChange(of: selectedDate) { _, newDate in
                Task {
                    try? await timeSlotService.fetchAvailableSlots(for: newDate)
                }
            }

            Text("Available Times")
                .font(.headline)

            if timeSlotService.isLoading {
                ProgressView()
            } else if timeSlotService.availableSlots.isEmpty {
                Text("No available slots for this date")
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(timeSlotService.availableSlots) { slot in
                        TimeSlotButton(
                            slot: slot,
                            isSelected: selectedTimeSlot?.id == slot.id
                        ) {
                            selectedTimeSlot = slot
                        }
                    }
                }
            }
        }
        .task {
            try? await timeSlotService.fetchAvailableSlots(for: selectedDate)
        }
    }

    var locationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Service Location")
                .font(.title2)
                .fontWeight(.bold)

            Text("Where should we come to detail your vehicle?")
                .foregroundColor(.secondary)

            TextField("Enter your address", text: $address)
                .textContentType(.fullStreetAddress)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .onChange(of: address) { _, newValue in
                    Task {
                        await locationManager.searchAddress(newValue)
                    }
                }

            if !locationManager.searchResults.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(locationManager.searchResults, id: \.self) { item in
                        Button {
                            selectedLocation = locationManager.mapItemToLocation(item)
                            address = selectedLocation?.fullAddress ?? ""
                            locationManager.searchResults = []
                        } label: {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "")
                                    .fontWeight(.medium)
                                Text(item.placemark.title ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        }
                        .foregroundColor(.primary)
                        Divider()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }

            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(3...5)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    var reviewStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Review Your Booking")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                ReviewRow(title: "Service", value: selectedService?.name ?? "")
                ReviewRow(title: "Vehicle", value: selectedVehicle?.displayName ?? "")
                ReviewRow(title: "Date", value: selectedTimeSlot?.formattedDate ?? "")
                ReviewRow(title: "Time", value: selectedTimeSlot?.formattedTimeRange ?? "")
                ReviewRow(title: "Location", value: selectedLocation?.shortAddress ?? "")

                Divider()

                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "$%.2f", totalPrice))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Text("Payment will be collected after service completion.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    var canProceed: Bool {
        switch currentStep {
        case 0: return selectedService != nil
        case 1: return selectedVehicle != nil
        case 2: return selectedTimeSlot != nil
        case 3: return selectedLocation != nil
        case 4: return true
        default: return false
        }
    }

    func confirmBooking() {
        guard let user = authManager.currentUser,
              let service = selectedService,
              let vehicle = selectedVehicle,
              let timeSlot = selectedTimeSlot,
              let location = selectedLocation else { return }

        let appointment = Appointment(
            customerId: user.id,
            customerName: user.name,
            customerPhone: user.phone,
            vehicle: vehicle,
            service: service,
            timeSlot: timeSlot,
            location: location,
            totalPrice: totalPrice,
            notes: notes.isEmpty ? nil : notes
        )

        Task {
            try? await appointmentService.createAppointment(appointment)
            try? await timeSlotService.bookSlot(timeSlot.id)
            bookingComplete = true
        }
    }

    func resetBooking() {
        currentStep = 0
        selectedService = nil
        selectedVehicle = nil
        selectedDate = Date()
        selectedTimeSlot = nil
        address = ""
        selectedLocation = nil
        notes = ""
    }
}

// MARK: - Supporting Views

struct ProgressSteps: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color.green : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
            }
        }
    }
}

struct ServiceCard: View {
    let service: ServicePackage
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(service.name)
                        .font(.headline)
                    Spacer()
                    Text(service.formattedPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                Text(service.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(service.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)

                FlowLayout(spacing: 6) {
                    ForEach(service.features.prefix(4), id: \.self) { feature in
                        Text(feature)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct VehicleCard: View {
    let vehicle: Vehicle
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(alignment: .leading) {
                    Text(vehicle.displayName)
                        .font(.headline)
                    Text("\(vehicle.color) - \(vehicle.size.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct TimeSlotButton: View {
    let slot: TimeSlot
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(slot.formattedStartTime)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.green : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
        }
    }
}

struct PriceBreakdown: View {
    let service: ServicePackage
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price Estimate")
                .font(.headline)

            HStack {
                Text("Base price")
                Spacer()
                Text(String(format: "$%.0f", service.basePrice))
            }
            .font(.subheadline)

            HStack {
                Text("Vehicle size (\(vehicle.size.rawValue))")
                Spacer()
                Text("x\(String(format: "%.1f", vehicle.size.priceMultiplier))")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Divider()

            HStack {
                Text("Total")
                    .fontWeight(.bold)
                Spacer()
                Text(String(format: "$%.2f", service.priceForVehicle(vehicle)))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ReviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + lineHeight)
        }
    }
}

#Preview {
    BookingView()
        .environmentObject(AuthenticationManager())
}
