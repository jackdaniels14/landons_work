import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if let user = authManager.currentUser {
                    switch user.role {
                    case .customer:
                        CustomerTabView()
                    case .employee:
                        EmployeeTabView()
                    case .admin:
                        AdminTabView()
                    }
                }
            } else {
                WelcomeView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}
