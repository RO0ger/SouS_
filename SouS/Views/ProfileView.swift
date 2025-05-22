import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView { // Embed in NavigationView for title and potential future navigation
            Form { // Use Form for standard settings/profile layout
                Section("Account Info") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authManager.session?.user.email ?? "N/A")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Name")
                        Spacer()
                        // Display fetched name or placeholder
                        Text(authManager.userName ?? "-") 
                            .foregroundColor(.gray)
                    }
                    // TODO: Add other profile fields if needed (e.g., edit profile button)
                }
                
                Section {
                    Button("Log Out", role: .destructive) { // Destructive role for logout
                        Task {
                            await authManager.signOut()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear { 
                // Optionally re-fetch name if it might change elsewhere 
                // or wasn't fetched initially
                if authManager.userName == nil, let userId = authManager.session?.user.id {
                    Task {
                        await authManager.fetchUserName(for: userId)
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager()) // Provide dummy manager
} 