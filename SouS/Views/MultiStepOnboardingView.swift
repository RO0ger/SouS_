import SwiftUI

struct MultiStepOnboardingView: View {
    // Use @StateObject for ViewModel specific to this flow instance
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var navigateToSummary = false
    
    // Remove onComplete, navigation is handled by SouSApp via AuthManager state
    // var onComplete: (OnboardingViewModel) -> Void = { _ in }
    
    var body: some View {
        // No need for NavigationStack here if OnboardingView already has one
        // NavigationStack { 
            VStack {
                // Progress Indicator (using viewModel.totalSteps which is now 5)
                Text("Step \(viewModel.currentStep) of \(viewModel.totalSteps)")
                    .font(.caption)
                    .padding(.top)
                
                // Custom segmented Progress Bar
                HStack(spacing: 4) {
                    ForEach(1...viewModel.totalSteps, id: \.self) { step in
                        Rectangle()
                            .fill(step <= viewModel.currentStep ? Color.blue : Color(.systemGray4)) // Use standard blue
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)

                // Content Area for the current step
                VStack {
                    switch viewModel.currentStep {
                    case 1: // New Step 0 is now Step 1
                        Step0PersonalInfoView()
                            .environmentObject(viewModel)
                            .frame(maxHeight: .infinity)
                    case 2: // Old Step 1 is now Step 2
                        Step1WeightGoalsView()
                            .environmentObject(viewModel)
                            .frame(maxHeight: .infinity)
                    case 3: // Old Step 2 is now Step 3
                        Step2JourneyView()
                            .environmentObject(viewModel)
                            .frame(maxHeight: .infinity)
                    case 4: // Old Step 3 is now Step 4
                        Step3DietPlanView()
                            .environmentObject(viewModel)
                            .frame(maxHeight: .infinity)
                    case 5: // Old Step 4 is now Step 5
                        Step4ProteinPlanView()
                            .environmentObject(viewModel)
                            .frame(maxHeight: .infinity)
                    default:
                        Text("Unknown Step")
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Navigation Buttons
                HStack {
                    if viewModel.currentStep > 1 {
                        Button("Back") {
                            viewModel.previousStep()
                        }
                        .buttonStyle(.bordered) // Simple bordered style
                        .frame(maxWidth: 100)
                    }
                    
                    Spacer()
                    
                    Button(viewModel.currentStep == viewModel.totalSteps ? "Finish" : "Continue") {
                        if viewModel.currentStep == viewModel.totalSteps {
                            navigateToSummary = true 
                        } else {
                            viewModel.nextStep()
                        }
                    }
                     .buttonStyle(.borderedProminent) // Use prominent style
                }
                .padding()
            }
            .navigationDestination(isPresented: $navigateToSummary) {
                // OnboardingSummaryView no longer needs the closure
                OnboardingSummaryView()
                   .environmentObject(viewModel) // Already has AuthManager from parent
            }
            .navigationBarBackButtonHidden(true) // Keep back button hidden for flow
            .navigationTitle("Step \(viewModel.currentStep) of \(viewModel.totalSteps)") // Dynamic title
            .navigationBarTitleDisplayMode(.inline)
        // }
    }
}

#Preview {
    // Remove the dummy action
    MultiStepOnboardingView()
} 
