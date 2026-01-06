import SwiftUI

struct EmployeeProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isAvailable = true
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
                                Text("Employee")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Availability
                Section("Availability") {
                    Toggle("Available for Jobs", isOn: $isAvailable)
                        .tint(.green)

                    if !isAvailable {
                        Text("You won't be assigned new appointments while unavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Stats
                Section("Today's Stats") {
                    HStack {
                        Label("Completed", systemImage: "checkmark.circle")
                        Spacer()
                        Text("3")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    HStack {
                        Label("Remaining", systemImage: "clock")
                        Spacer()
                        Text("2")
                            .fontWeight(.bold)
                    }

                    HStack {
                        Label("Earnings", systemImage: "dollarsign.circle")
                        Spacer()
                        Text("$425")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }

                // Support
                Section("Support") {
                    Link(destination: URL(string: "tel:+15551234567")!) {
                        Label("Contact Manager", systemImage: "phone")
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
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    EmployeeProfileView()
        .environmentObject(AuthenticationManager())
}
