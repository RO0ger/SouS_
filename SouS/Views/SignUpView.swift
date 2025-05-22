import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    // Binding to control showing Login vs SignUp in parent AuthenticationView
    @Binding var showLogin: Bool
    
    // State for local validation errors
    @State private var emailError: Bool = false
    @State private var passwordError: Bool = false
    @State private var confirmPasswordError: Bool = false
    @State private var validationMessage: String?
    
    // Computed property for button disabled state
    private var isSignUpDisabled: Bool {
        authManager.isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // --- Header ---
                Text("Create Account")
                    .font(.largeTitle).bold()
                    .padding(.top, 60)
                    .padding(.bottom, 8)
                
                Text("Enter your details to get started")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
                
                // --- Email Input ---
                TextField("Email address", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(emailError ? Color.red : Color.clear, lineWidth: 1)
                    )
                    .padding(.bottom, 15)
                
                // --- Password Input ---
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(passwordError ? Color.red : Color.clear, lineWidth: 1)
                    )
                    .padding(.bottom, 15)
                
                // --- Confirm Password Input ---
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(confirmPasswordError ? Color.red : Color.clear, lineWidth: 1)
                    )
                    .padding(.bottom, 15)
                
                // --- Validation/API Message Display ---
                if let message = validationMessage ?? authManager.errorMessage {
                     Text(message)
                         .foregroundColor(.red)
                         .font(.caption)
                         .frame(maxWidth: .infinity, alignment: .leading)
                         .padding(.bottom, 10)
                } else {
                     // Placeholder space
                     Spacer().frame(height: 18 + 10) // Approx height of Text + padding
                         .padding(.bottom, 10)
                }
                
                // --- Sign Up Button ---
                Button {
                    validateAndSignUp()
                } label: {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isSignUpDisabled ? Color.blue.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSignUpDisabled)
                
                Spacer() // Push switch link down
                
                // --- Switch back to Login ---
                HStack {
                    Text("Already have an account?")
                    Button("Sign In") {
                        showLogin = true // Set binding to true to show LoginView
                    }
                }
                .font(.footnote)
                .padding(.bottom, 30)
                
            } // End Main VStack
            .padding(.horizontal, 30)
        } // End ScrollView
        .onAppear {
           clearErrors()
        }
    }
    
    // --- Helper Methods ---
    
    private func validateAndSignUp() {
        // Reset errors
        clearErrors()
        
        var isValid = true
        
        // Basic Email Validation
        if email.isEmpty {
            emailError = true
            isValid = false
        } else if !email.contains("@") || !email.contains(".") {
            emailError = true
            validationMessage = "Please enter a valid email address."
            isValid = false
        }
        
        // Basic Password Validation (e.g., minimum length)
        if password.isEmpty {
            passwordError = true
            isValid = false
        } else if password.count < 6 { // Example: Enforce minimum length
            passwordError = true
            validationMessage = "Password must be at least 6 characters."
            isValid = false
        }
        
        // Confirm Password Validation
        if confirmPassword.isEmpty {
            confirmPasswordError = true
            isValid = false
        } else if password != confirmPassword {
            passwordError = true
            confirmPasswordError = true
            validationMessage = "Passwords do not match."
            isValid = false
        }
        
        if !isValid {
            // Update general validation message if specific one wasn\'t set
            if validationMessage == nil {
                 validationMessage = "Please fill in all fields correctly."
            }
            return
        }
        
        // If validation passes, attempt to sign up
        Task {
           await authManager.signUp(email: email, password: password)
           // AuthManager handles the state transition on success.
           // AuthManager.errorMessage will be updated on failure and displayed.
           if authManager.errorMessage != nil {
               validationMessage = nil // Clear local message if API error takes precedence
           }
        }
    }
    
    private func clearErrors() {
        emailError = false
        passwordError = false
        confirmPasswordError = false
        validationMessage = nil
        authManager.errorMessage = nil // Also clear API error
    }
}

// --- Preview ---
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(showLogin: .constant(false))
            .environmentObject(AuthManager()) // Provide dummy manager
    }
} 