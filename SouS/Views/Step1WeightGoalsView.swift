import SwiftUI

struct Step1WeightGoalsView: View {
    // Access the shared ViewModel from the environment
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title and Subtitle
            Text("Set Your Weight Goals")
                .font(.title2)
            Text("We\'ll use this to customize your daily protein target")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom)

            // Unit Toggle (lbs/kg) - Changed from Picker to Toggle
            HStack {
                Text("lbs").foregroundColor(viewModel.unitIsKg ? .gray : .primary)
                Toggle("Weight Unit", isOn: $viewModel.unitIsKg)
                    .labelsHidden() // Hide the default Toggle label
                Text("kg").foregroundColor(viewModel.unitIsKg ? .primary : .gray)
            }
            .padding(.horizontal) // Add some horizontal padding to center it slightly
            .frame(maxWidth: .infinity) // Allow centering
            .padding(.bottom)
            
            Divider() // Add divider for separation

            // Current Weight Section
            WeightInputView(label: "Current Weight",
                              iconName: "scalemass",
                              weight: $viewModel.currentWeight,
                              unit: viewModel.selectedUnit,
                              range: viewModel.currentWeightRange)
            
            Divider() // Add divider for separation

            // Target Weight Section
            WeightInputView(label: "Target Weight",
                              iconName: "chart.line.uptrend.xyaxis", // Changed icon
                              weight: $viewModel.targetWeight,
                              unit: viewModel.selectedUnit,
                              range: viewModel.targetWeightRange)

            Spacer() // Push content to the top
        }
        .padding()
    }
}

// --- Subview for Reusable Weight Input ---
struct WeightInputView: View {
    let label: String
    let iconName: String
    @Binding var weight: Double
    let unit: OnboardingViewModel.WeightUnit
    let range: ClosedRange<Double>

    // Formatter for displaying weight
    private var weightFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0 // Show whole numbers for simplicity
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Revised HStack layout
            HStack(spacing: 15) { // Added spacing
                Image(systemName: iconName)
                    .foregroundColor(.accentColor) // Use accent color for consistency
                    .font(.title2) // Slightly larger icon
                    .frame(width: 30) // Give icon some space

                Text(label)
                    .font(.headline)
                
                Spacer()
                
                // Styled Text to look more like the web input
                Text("\(weight, specifier: "%.0f")") // Weight value
                    .font(.title3)
                    .frame(width: 60, alignment: .trailing) // Fixed width for alignment
                
                Text(unit.rawValue) // Unit
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 5) // Add slight vertical padding

            Slider(value: $weight, in: range, step: 1) {
                Text(label) // Accessibility label
            }
            // Optional: Tint the slider
            // .tint(.accentColor)

            HStack {
                Text("\(range.lowerBound, specifier: "%.0f") \(unit.rawValue)")
                Spacer()
                Text("\(range.upperBound, specifier: "%.0f") \(unit.rawValue)")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding(.bottom)
    }
}


// --- Preview ---
#Preview {
    // Provide a dummy ViewModel for the preview
    Step1WeightGoalsView()
        .environmentObject(OnboardingViewModel())
} 