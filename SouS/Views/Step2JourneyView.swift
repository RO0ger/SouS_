import SwiftUI

struct Step2JourneyView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    // Define the discrete timeline options
    let timelineOptions: [Double] = [3, 6, 12]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text("Your Journey")
                .font(.title2)
                // .fontWeight(.bold) // Removed for consistency
                .frame(maxWidth: .infinity, alignment: .center) // Center align title
                .padding(.bottom)

            // --- Timeline Section ---
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "calendar")
                    Text("Timeline")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(viewModel.timeline)) months") // Display selected months
                        .font(.headline)
                        .foregroundColor(.blue) // Match screenshot color
                }
                
                Text("How quickly do you want to reach your goals?")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Slider for continuous values between 1 and 12
                Slider(value: $viewModel.timeline, in: 1...12) {
                    Text("Timeline") // Accessibility label
                }
                // Display labels below the slider
                HStack {
                    Text("1 month")
                    Spacer()
                    Text("6 months")
                    Spacer()
                    Text("12 months")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding(.bottom, 30)
            
            Divider()

            // --- Current Activity Section ---
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "figure.walk") // Placeholder icon
                    Text("Current Activity")
                        .font(.headline)
                }
                Text("Tell us about your typical week")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)

                // Radio button style selection
                ForEach(OnboardingViewModel.ActivityLevel.allCases) { level in
                    ActivityLevelRow(level: level, selectedLevel: $viewModel.activityLevel)
                }
            }

            Spacer() // Push content to the top
        }
        .padding()
    }
}

// --- Subview for Activity Level Row ---
struct ActivityLevelRow: View {
    let level: OnboardingViewModel.ActivityLevel
    @Binding var selectedLevel: OnboardingViewModel.ActivityLevel

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(level.rawValue).font(.headline)
                Text(level.description).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: selectedLevel == level ? "checkmark.circle.fill" : "circle")
                .foregroundColor(selectedLevel == level ? .blue : .gray)
                .font(.title2)
        }
        .padding()
        .background(Color(.systemGray6)) // Use a light background for the row
        .cornerRadius(10)
        .onTapGesture {
            selectedLevel = level // Update selection on tap
        }
    }
}

// --- Preview ---
#Preview {
    Step2JourneyView()
        .environmentObject(OnboardingViewModel())
} 