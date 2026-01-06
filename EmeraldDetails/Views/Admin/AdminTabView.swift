import SwiftUI

struct AdminTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Dashboard")
                }
                .tag(0)

            AllAppointmentsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Appointments")
                }
                .tag(1)

            ManageServicesView()
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver")
                    Text("Services")
                }
                .tag(2)

            ManageEmployeesView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Team")
                }
                .tag(3)

            AdminSettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(.green)
    }
}

#Preview {
    AdminTabView()
        .environmentObject(AuthenticationManager())
}
