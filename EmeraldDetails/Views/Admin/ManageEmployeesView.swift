import SwiftUI

struct ManageEmployeesView: View {
    @StateObject private var userService = UserService()
    @State private var showAddEmployee = false

    var body: some View {
        NavigationStack {
            List {
                if userService.employees.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No employees yet")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(userService.employees) { employee in
                        EmployeeRow(employee: employee)
                    }
                }
            }
            .navigationTitle("Team")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddEmployee = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .task {
                try? await userService.fetchEmployees()
            }
            .refreshable {
                try? await userService.fetchEmployees()
            }
            .sheet(isPresented: $showAddEmployee) {
                AddEmployeeView()
            }
        }
    }
}

struct EmployeeRow: View {
    let employee: User

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.headline)

                Text(employee.email)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Circle()
                        .fill(employee.isAvailable == true ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(employee.isAvailable == true ? "Available" : "Unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddEmployeeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var isValid: Bool {
        !name.isEmpty && !email.isEmpty && !phone.isEmpty && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Employee Information") {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Account") {
                    SecureField("Temporary Password", text: $password)
                    Text("Employee can change this after first login")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addEmployee()
                    }
                    .disabled(!isValid || isLoading)
                }
            }
        }
    }

    func addEmployee() {
        isLoading = true
        errorMessage = nil

        // In a real app, you'd create this via a Cloud Function
        // to properly create the user with employee role
        Task {
            await authManager.signUp(
                name: name,
                email: email,
                password: password,
                phone: phone,
                role: .employee
            )

            if authManager.errorMessage != nil {
                errorMessage = authManager.errorMessage
            } else {
                dismiss()
            }
            isLoading = false
        }
    }
}

#Preview {
    ManageEmployeesView()
        .environmentObject(AuthenticationManager())
}
