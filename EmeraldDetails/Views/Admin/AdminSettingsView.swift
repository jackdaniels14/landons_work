import SwiftUI

struct AdminSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var servicePackageService = ServicePackageService()
    @StateObject private var timeSlotService = TimeSlotService()

    @State private var showSignOutAlert = false
    @State private var showSeedAlert = false
    @State private var showGenerateSlotsSheet = false

    var body: some View {
        NavigationStack {
            List {
                // Profile
                Section {
                    if let user = authManager.currentUser {
                        HStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)

                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                Text("Administrator")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Business Settings
                Section("Business Settings") {
                    NavigationLink {
                        BusinessInfoView()
                    } label: {
                        Label("Business Information", systemImage: "building.2")
                    }

                    NavigationLink {
                        ManageTimeSlotsView()
                    } label: {
                        Label("Time Slots", systemImage: "clock")
                    }

                    Button {
                        showGenerateSlotsSheet = true
                    } label: {
                        Label("Generate Time Slots", systemImage: "calendar.badge.plus")
                    }
                }

                // Data Management
                Section("Data Management") {
                    Button {
                        showSeedAlert = true
                    } label: {
                        Label("Seed Default Services", systemImage: "square.and.arrow.down")
                    }

                    NavigationLink {
                        ExportDataView()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }

                // Support
                Section("Support") {
                    Link(destination: URL(string: "https://firebase.google.com/console")!) {
                        Label("Firebase Console", systemImage: "server.rack")
                    }

                    Link(destination: URL(string: "https://dashboard.stripe.com")!) {
                        Label("Stripe Dashboard", systemImage: "creditcard")
                    }
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Seed Default Services?", isPresented: $showSeedAlert) {
                Button("Seed") {
                    Task {
                        try? await servicePackageService.seedDefaultServices()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will add the default service packages to your database.")
            }
            .sheet(isPresented: $showGenerateSlotsSheet) {
                GenerateTimeSlotsView()
            }
        }
    }
}

struct BusinessInfoView: View {
    @State private var businessName = "Emerald Details"
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""

    var body: some View {
        Form {
            Section("Business Details") {
                TextField("Business Name", text: $businessName)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                TextField("Address", text: $address)
            }

            Section("Hours of Operation") {
                Text("Monday - Friday: 8am - 6pm")
                Text("Saturday: 9am - 4pm")
                Text("Sunday: Closed")
            }
        }
        .navigationTitle("Business Info")
    }
}

struct ManageTimeSlotsView: View {
    @StateObject private var timeSlotService = TimeSlotService()
    @State private var selectedDate = Date()

    var body: some View {
        VStack {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()

            List {
                ForEach(timeSlotService.availableSlots) { slot in
                    HStack {
                        Text(slot.formattedTimeRange)
                        Spacer()
                        if slot.isAvailable {
                            Text("Available")
                                .foregroundColor(.green)
                        } else {
                            Text("Booked")
                                .foregroundColor(.red)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let slot = timeSlotService.availableSlots[index]
                        Task {
                            try? await timeSlotService.deleteSlot(slot.id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Time Slots")
        .task {
            try? await timeSlotService.fetchAvailableSlots(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, newDate in
            Task {
                try? await timeSlotService.fetchAvailableSlots(for: newDate)
            }
        }
    }
}

struct GenerateTimeSlotsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var timeSlotService = TimeSlotService()

    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section {
                    Text("This will generate time slots (8am, 10am, 12pm, 2pm, 4pm) for each weekday in the selected range.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Generate Slots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate") {
                        generateSlots()
                    }
                    .disabled(isGenerating)
                }
            }
        }
    }

    func generateSlots() {
        isGenerating = true
        Task {
            try? await timeSlotService.generateSlotsForDateRange(from: startDate, to: endDate)
            dismiss()
        }
    }
}

struct ExportDataView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("Export Data")
                .font(.title2)
                .fontWeight(.bold)

            Text("Data export functionality coming soon!")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Export Data")
    }
}

#Preview {
    AdminSettingsView()
        .environmentObject(AuthenticationManager())
}
