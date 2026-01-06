import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let userService = UserService()

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.loadUserProfile(firebaseUid: user.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }
        }
    }

    // MARK: - Sign Up
    func signUp(name: String, email: String, password: String, phone: String, role: UserRole = .customer) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let firebaseUid = result.user.uid

            let newUser = User(
                firebaseUid: firebaseUid,
                name: name,
                email: email.lowercased(),
                phone: phone,
                role: role,
                isEmailVerified: false,
                vehicles: role == .customer ? [] : nil,
                isAvailable: role == .employee ? true : nil
            )

            try await userService.createUserProfile(newUser, firebaseUid: firebaseUid)
            try await result.user.sendEmailVerification()

            currentUser = newUser
            isAuthenticated = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await loadUserProfile(firebaseUid: result.user.uid)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load User Profile
    private func loadUserProfile(firebaseUid: String) async {
        do {
            if let user = try await userService.getUserByFirebaseUid(firebaseUid) {
                currentUser = user
                isAuthenticated = true
            } else {
                errorMessage = "User profile not found"
                try? Auth.auth().signOut()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Email Verification
    func sendEmailVerification() async {
        guard let user = Auth.auth().currentUser else { return }

        do {
            try await user.sendEmailVerification()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkEmailVerification() async -> Bool {
        guard let user = Auth.auth().currentUser else { return false }

        do {
            try await user.reload()
            if user.isEmailVerified {
                currentUser?.isEmailVerified = true
                if let uid = currentUser?.firebaseUid {
                    try await userService.updateEmailVerification(firebaseUid: uid, isVerified: true)
                }
                return true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        return false
    }

    // MARK: - Update Profile
    func updateProfile(name: String, phone: String) async {
        guard var user = currentUser else { return }

        user.name = name
        user.phone = phone

        do {
            try await userService.updateUserProfile(user)
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Vehicle Management (Customers)
    func addVehicle(_ vehicle: Vehicle) async {
        guard var user = currentUser, user.role == .customer else { return }

        var vehicles = user.vehicles ?? []
        vehicles.append(vehicle)
        user.vehicles = vehicles

        do {
            try await userService.updateUserProfile(user)
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeVehicle(_ vehicle: Vehicle) async {
        guard var user = currentUser, user.role == .customer else { return }

        user.vehicles?.removeAll { $0.id == vehicle.id }

        do {
            try await userService.updateUserProfile(user)
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Password Reset
    func sendPasswordReset(email: String) async {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
