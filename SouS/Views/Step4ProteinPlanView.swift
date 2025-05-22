import SwiftUI

struct Step4ProteinPlanView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    // Date formatter for the target date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }

    var body: some View {
        ScrollView { // Make content scrollable if it overflows
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Your Protein Plan")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)
                
                // Daily Target Summary Box
                VStack(alignment: .leading, spacing: 10) {
                    Text("DAILY TARGET")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(viewModel.adjustedProteinTarget, specifier: "%.0f")")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.primaryBlue)
                        Text("g")
                            .font(.title)
                            .foregroundColor(.primaryBlue)
                    }
                    // TODO: Replace 1.6g/kg with dynamic value if needed
                    Text("~1.6g/kg optimized")
                        .font(.footnote)
                    HStack {
                        Image(systemName: "calendar")
                        Text("Target: \(viewModel.targetDate, formatter: dateFormatter)")
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.bottom)

                // Adjust Target Section
                VStack(alignment: .leading) {
                    HStack {
                        Text("Adjust Target")
                            .font(.headline)
                        Spacer()
                        // Use the rounded adjustment value for display
                        Text("\(viewModel.proteinTargetAdjustmentRounded > 0 ? "+" : "")\(viewModel.proteinTargetAdjustmentRounded)g")
                            .font(.headline)
                    }
                    // Bind slider to the raw value
                    Slider(value: $viewModel.proteinTargetAdjustmentRaw, 
                           in: viewModel.proteinAdjustmentRange
                           // Step removed - rounding handles discrete steps
                           ) {
                        Text("Adjust Target") // Accessibility label
                    }
                    HStack {
                        Text("Less")
                        Spacer()
                        Text("More")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .padding(.bottom)
                
                Divider()
                
                // Daily Meal Plan Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "fork.knife.circle") // Placeholder icon
                            .foregroundColor(.blue)
                        Text("Daily Meal Plan")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.adjustedProteinTarget, specifier: "%.0f")g total")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 5)
                    
                    // Display Calculated Protein Split
                    let split = viewModel.calculatedProteinSplit
                    MacroRow(label: "Breakfast", value: split.breakfast)
                    MacroRow(label: "Lunch", value: split.lunch)
                    MacroRow(label: "Dinner", value: split.dinner)
                    
                }

                Spacer() // Push content to the top
            }
            .padding()
        }
    }
}

// --- New Subview for Macro Row ---
struct MacroRow: View {
    let label: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
            Spacer()
            Text("\(value)g")
                .font(.title2) // Make value slightly larger
                .foregroundColor(.primaryBlue)
        }
        .padding(.vertical, 5)
    }
}

// --- Preview ---
#Preview {
    Step4ProteinPlanView()
        .environmentObject(OnboardingViewModel())
} 