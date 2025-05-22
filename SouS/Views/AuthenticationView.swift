import SwiftUI

struct AuthenticationView: View {
    // Access the AuthManager from the environment
    @EnvironmentObject var authManager: AuthManager
    
    // State to toggle between Login and Sign Up
    @State private var showLogin = true
    
    var body: some View {
        VStack {
            if showLogin {
                LoginView(showLogin: $showLogin)
            } else {
                SignUpView(showLogin: $showLogin) // Use SignUpView here
            }
        }
        // EnvironmentObject is already passed down from SouSApp
        // TODO: Add nice transition between Login and Sign Up
    }
}

#Preview {
    // Preview needs a dummy AuthManager
    AuthenticationView()
        .environmentObject(AuthManager())
} 