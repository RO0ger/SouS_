import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = "" // Re-added password state
    
    // Binding to control showing Login vs SignUp in parent AuthenticationView
    @Binding var showLogin: Bool
    
    // State for local validation errors
    @State private var emailError: Bool = false
    @State private var passwordError: Bool = false // Re-added password error state
    @State private var validationMessage: String?
    
    // Computed property for button disabled state - depends on email and password now
    private var isSignInDisabled: Bool {
        authManager.isLoading || email.isEmpty || password.isEmpty
    }
    
    var body: some View {
        // Use a ScrollView to prevent content being hidden by keyboard
        ScrollView {
            VStack(spacing: 0) { // Use spacing modifiers for more control
                // --- Header ---
                Text("Sign into SouS")
                    .font(.largeTitle).bold()
                    .padding(.top, 60) // Add top padding
                    .padding(.bottom, 8) // Reduced bottom padding
                
                Text("Welcome back! Please sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 30) // Increased space below subtitle
                
                // --- Google Button Placeholder ---
                Button {
                    // Call the AuthManager function
                    Task {
                        await authManager.signInWithGoogle()
                    }
                } label: {
                    HStack {
                        // TODO: Use official Google SVG icon
                        Image(systemName: "g.circle.fill") // Placeholder icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Continue with Google")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12) // Increased rounding
                }
                .padding(.bottom, 25) // Increased space below Google button
                
                // --- Divider ---
                HStack {
                    VStack { Divider() }
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.gray)
                    VStack { Divider() }
                }
                .padding(.bottom, 25) // Increased space below divider
                
                // --- Email Input ---
                TextField("Email address", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12) // Increased rounding
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(emailError ? Color.red : Color.clear, lineWidth: 1) // Red border if error
                    )
                    .padding(.bottom, 15) // Space below email
                
                // --- Password Input ---
                SecureField("Password", text: $password) // Added SecureField for password
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12) // Increased rounding
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(passwordError ? Color.red : Color.clear, lineWidth: 1) // Red border if error
                    )
                    .padding(.bottom, 15) // Space below password
                
                // --- Validation Message Display (Local) ---
                if let validationMessage = validationMessage {
                     Text(validationMessage)
                         .foregroundColor(.red)
                         .font(.caption)
                         .frame(maxWidth: .infinity, alignment: .leading) // Align left
                         .padding(.bottom, 10) // Space below validation message
                } else if let apiMessage = authManager.errorMessage { // Display API messages (including success messages)
                    // Ensure API message isn't the old OTP message
                    if !apiMessage.starts(with: "Please check your email") {
                        Text(apiMessage)
                            // TODO: Potentially differentiate API error color if needed
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.leading) // Align left
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 10)
                    } else {
                        // Provide space if it's the old OTP message or no message
                        Spacer().frame(height: 18 + 10) // Approx height of Text + padding
                            .padding(.bottom, 10)
                    }
                } else {
                     // Add placeholder space to prevent layout jumps when error appears/disappears
                     // Adjusted height to account for potential single line error message
                     Spacer().frame(height: 18 + 10) // Approx height of Text + padding
                         .padding(.bottom, 10)
                }
                
                // --- Sign In Button ---
                Button {
                    validateAndSignIn() // Changed action to sign in with password
                } label: {
                    HStack {
                        // Updated button text
                        Text("Sign In")
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    // Use primaryBlue or default blue, adjust opacity when disabled
                    .background(isSignInDisabled ? Color.blue.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12) // Increased rounding
                }
                .disabled(isSignInDisabled) // Use updated computed property
                
                Spacer() // Push switch link and privacy text down
                
                // --- Privacy Text ---
                Text("We respect your privacy. Your data is safe with us.")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
                
                // --- Switch to Sign Up ---
                HStack {
                    Text("Need an account?") // Adjusted text slightly
                    Button("Create Account") { // Changed button text and action
                        showLogin = false // Set binding to false to show SignUpView
                    }
                    // Removed .disabled(true)
                }
                .font(.footnote)
                .padding(.bottom, 30) // More padding at the bottom
                
            } // End Main VStack
            .padding(.horizontal, 30)
        } // End ScrollView
        .onAppear {
           clearErrors()
        }
    }
    
    // --- Helper Methods ---\
    
    // Updated validation and action method for standard sign-in
    private func validateAndSignIn() {
        // Reset errors
        clearErrors() // Clear errors first
        
        var isValid = true
        
        if email.isEmpty {
            emailError = true
            isValid = false
        } else if !email.contains("@") || !email.contains(".") { // Basic email format check
            emailError = true
            validationMessage = "Please enter a valid email address."
            isValid = false
        }
        
        if password.isEmpty {
            passwordError = true
            isValid = false
        }
        
        if !isValid {
            // Update general validation message if specific one wasn't set
            if validationMessage == nil {
                 validationMessage = "Please fill in all fields."
            }
            return
        }
        
        // If validation passes, attempt to sign in
        Task {
           await authManager.signInWithEmailPassword(email: email, password: password)
           // AuthManager will update its errorMessage property, which is displayed above the button
           // Set local validation message only if API error occurs (handled by authManager)
           if authManager.errorMessage != nil {
               validationMessage = nil // Clear local message if API error takes precedence
           }
        }
    }
    
    private func clearErrors() {
        emailError = false
        passwordError = false // Clear password error
        validationMessage = nil
        authManager.errorMessage = nil // Also clear API error message from AuthManager
    }
}

// --- Preview ---
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(showLogin: .constant(true))
            .environmentObject(AuthManager())
    }
} 