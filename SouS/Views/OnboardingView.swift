import SwiftUI

struct OnboardingView: View {
    // This view is now shown AFTER authentication if onboarding is not complete.
    
    var body: some View {
        // NavigationStack might still be useful if MultiStepOnboardingView pushes sub-views
        NavigationStack {
            VStack(alignment: .leading, spacing: 30) { // Leading alignment, more spacing
                
                Spacer() // Push content down slightly
                
                Text("Tell us about yourself")
                    .font(.largeTitle).bold()
                    .padding(.bottom, 10)
                
                Text("Let's gather some details to personalize your meal suggestions.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
                
                // Directly navigate to the multi-step onboarding flow
                NavigationLink {
                    MultiStepOnboardingView()
                } label: {
                    Text("Get Started") // Changed button text
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue) // Use standard blue for now
                        .cornerRadius(12) // Consistent rounding
                }
                
                Spacer()
                Spacer() // Add more space at the bottom
            }
            .padding()
            .navigationTitle("Complete Your Profile") // Set an appropriate title
            .navigationBarTitleDisplayMode(.inline)
            // .navigationBarHidden(true) // Can hide if preferred
        }
    }
}

#Preview {
    OnboardingView()
} 