import SwiftUI

struct CustomerTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BookingView()
                .tabItem {
                    Image(systemName: "calendar.badge.plus")
                    Text("Book")
                }
                .tag(0)

            MyAppointmentsView()
                .tabItem {
                    Image(systemName: "list.clipboard")
                    Text("My Appointments")
                }
                .tag(1)

            MessagesView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Messages")
                }
                .tag(2)

            CustomerProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .tint(.green)
    }
}

#Preview {
    CustomerTabView()
        .environmentObject(AuthenticationManager())
}
