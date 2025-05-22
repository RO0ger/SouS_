import SwiftUI

struct OnboardingSummaryView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var authManager: AuthManager // Inject AuthManager
    // Remove the proceedToAction closure, navigation is now handled by SouSApp
    // var proceedToAction: (OnboardingViewModel) -> Void 
    
    // Formatter for weight difference
    private var weightDiffFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = "+" // Show + for weight gain
        return formatter
    }
    
    // Date formatter for target date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // e.g., Sep 29
        return formatter
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer() // Push content down slightly
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Ready to Start")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your personalized protein plan")
                .font(.title3)
                .foregroundColor(.gray)
                .padding(.bottom)
            
            // Target Box
            VStack {
                Text("Target")
                    .font(.headline)
                    .foregroundColor(.gray)
                HStack(alignment: .firstTextBaseline) {
                    Text(weightDiffFormatter.string(from: NSNumber(value: viewModel.targetWeightDifference)) ?? "")
                        .font(.system(size: 40, weight: .bold))
                    Text(viewModel.selectedUnit.rawValue)
                        .font(.title2)
                    Image(systemName: viewModel.targetWeightDifference >= 0 ? "arrow.up.right" : "arrow.down.right") // Trend arrow
                }
                Text("by \(dateFormatter.string(from: viewModel.targetDate))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Macro Grid
            HStack(spacing: 15) {
                MacroSummaryBox(label: "Daily Calories", value: "\(viewModel.estimatedDailyCalories)")
                MacroSummaryBox(label: "Protein", value: "\(Int(viewModel.adjustedProteinTarget))g")
            }
            HStack(spacing: 15) {
                MacroSummaryBox(label: "Carbs", value: "\(viewModel.estimatedDailyCarbs)g")
                MacroSummaryBox(label: "Fats", value: "\(viewModel.estimatedDailyFats)g")
            }
            
            // Social Proof Text (Optional)
            Text("Join **847 others** who gained 7kg+ in 3 months")
                 .font(.footnote)
                 .foregroundColor(.gray)
                 .padding(.top)
            Text("Your first recommendation is **60 seconds away**")
                 .font(.footnote)
                 .foregroundColor(.blue)
            
            Spacer()
            Spacer()
            
            // --- Error Display --- 
            if let saveError = viewModel.saveError {
                Text(saveError)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // --- Action Button --- 
            Button {
                print("Confirm & Start Saving Profile...")
                // Call the save function asynchronously
                Task {
                    await viewModel.saveUserProfile(authManager: authManager)
                    // Navigation happens automatically when authManager.isOnboardingCompleted changes via markOnboardingComplete()
                }
            } label: {
                // Show progress indicator when saving
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.7)) // Slightly different background when loading
                        .cornerRadius(12)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle") // Revert back to a valid SF Symbol
                        Text("Confirm & Start Journey") // Updated text maybe?
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue) // Use standard blue
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .disabled(viewModel.isSaving) // Disable button while saving
            .padding(.horizontal)
            .padding(.bottom)
            
        }
        .padding()
        // Hide back button as this is the final onboarding step
        .navigationBarBackButtonHidden(true) 
        .onAppear { 
            // Clear previous save errors when view appears
            viewModel.saveError = nil
        }
    }
}

// --- Subview for Macro Box ---
struct MacroSummaryBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// --- Preview ---
#Preview {
    // Preview now needs AuthManager as well
    OnboardingSummaryView()
        .environmentObject(OnboardingViewModel())
        .environmentObject(AuthManager())
} 