import SwiftUI

struct WelcomeView: View {
    @State private var showSignIn = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.green.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)

                        Text("Emerald Details")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text("Mobile Car Detailing")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Spacer()

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "calendar", text: "Easy Online Booking")
                        FeatureRow(icon: "mappin.and.ellipse", text: "We Come to You")
                        FeatureRow(icon: "creditcard", text: "Secure Payments")
                        FeatureRow(icon: "star.fill", text: "Professional Service")
                    }
                    .padding(.horizontal, 40)

                    Spacer()

                    // Buttons
                    VStack(spacing: 16) {
                        Button {
                            showSignUp = true
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }

                        Button {
                            showSignIn = true
                        } label: {
                            Text("I Already Have an Account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .sheet(isPresented: $showSignIn) {
                SignInView()
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)

            Text(text)
                .font(.body)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    WelcomeView()
}
