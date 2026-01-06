import SwiftUI

struct CustomerProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showEditProfile = false
    @State private var showAddVehicle = false
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    if let user = authManager.currentUser {
                        HStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(user.phone)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Vehicles Section
                Section("My Vehicles") {
                    if let vehicles = authManager.currentUser?.vehicles, !vehicles.isEmpty {
                        ForEach(vehicles) { vehicle in
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundColor(.green)

                                VStack(alignment: .leading) {
                                    Text(vehicle.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("\(vehicle.color) - \(vehicle.size.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                        }
                        .onDelete { indexSet in
                            deleteVehicle(at: indexSet)
                        }
                    }

                    Button {
                        showAddVehicle = true
                    } label: {
                        Label("Add Vehicle", systemImage: "plus.circle")
                    }
                }

                // Account Section
                Section("Account") {
                    Button {
                        showEditProfile = true
                    } label: {
                        Label("Edit Profile", systemImage: "pencil")
                    }

                    NavigationLink {
                        PaymentMethodsView()
                    } label: {
                        Label("Payment Methods", systemImage: "creditcard")
                    }

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                // Support Section
                Section("Support") {
                    Link(destination: URL(string: "tel:+15551234567")!) {
                        Label("Call Support", systemImage: "phone")
                    }

                    Link(destination: URL(string: "mailto:support@emeralddetails.com")!) {
                        Label("Email Support", systemImage: "envelope")
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
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView()
            }
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    func deleteVehicle(at offsets: IndexSet) {
        guard let vehicles = authManager.currentUser?.vehicles else { return }
        for index in offsets {
            let vehicle = vehicles[index]
            Task {
                await authManager.removeVehicle(vehicle)
            }
        }
    }
}

struct AddVehicleView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var color = ""
    @State private var licensePlate = ""
    @State private var size: VehicleSize = .sedan

    var isValid: Bool {
        !make.isEmpty && !model.isEmpty && !color.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Information") {
                    TextField("Make (e.g., Toyota)", text: $make)
                    TextField("Model (e.g., Camry)", text: $model)

                    Picker("Year", selection: $year) {
                        ForEach((1990...Calendar.current.component(.year, from: Date()) + 1).reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    TextField("Color", text: $color)
                    TextField("License Plate (optional)", text: $licensePlate)
                }

                Section("Vehicle Size") {
                    Picker("Size", selection: $size) {
                        ForEach(VehicleSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Size affects pricing. \(size.rawValue) vehicles have a \(String(format: "%.0f%%", (size.priceMultiplier - 1) * 100)) price adjustment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    func saveVehicle() {
        let vehicle = Vehicle(
            make: make,
            model: model,
            year: year,
            color: color,
            licensePlate: licensePlate.isEmpty ? nil : licensePlate,
            size: size
        )

        Task {
            await authManager.addVehicle(vehicle)
            dismiss()
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var phone = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Email") {
                    if let email = authManager.currentUser?.email {
                        Text(email)
                            .foregroundColor(.secondary)
                    }
                    Text("Contact support to change your email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await authManager.updateProfile(name: name, phone: phone)
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                if let user = authManager.currentUser {
                    name = user.name
                    phone = user.phone
                }
            }
        }
    }
}

struct PaymentMethodsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("Payment Methods")
                .font(.title2)
                .fontWeight(.bold)

            Text("Payment integration coming soon!\nPay at time of service for now.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Payment Methods")
    }
}

struct NotificationSettingsView: View {
    @State private var appointmentReminders = true
    @State private var promotions = false
    @State private var messages = true

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Appointment Reminders", isOn: $appointmentReminders)
                Toggle("Promotions & Offers", isOn: $promotions)
                Toggle("Messages", isOn: $messages)
            }
        }
        .navigationTitle("Notifications")
    }
}

#Preview {
    CustomerProfileView()
        .environmentObject(AuthenticationManager())
}
