import SwiftUI

struct Step0PersonalInfoView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    // Formatter for age input
    private var ageFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none // No separators, etc.
        formatter.allowsFloats = false
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About You")
                .font(.title2).bold()
                .padding(.bottom, 10)

            // Name Input
            VStack(alignment: .leading) {
                Text("Your Name").font(.headline)
                TextField("Enter your name", text: $viewModel.userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled(true)
            }

            // Sex Selection
            VStack(alignment: .leading) {
                Text("Sex").font(.headline)
                Picker("Select Sex", selection: $viewModel.sex) {
                    Text("Select...").tag("") // Add a default empty tag
                    ForEach(viewModel.sexOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu) // Or .wheel, .segmented etc.
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 5)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1)) // Add border for clarity
            }

            // Age Input
            VStack(alignment: .leading) {
                Text("Age").font(.headline)
                TextField("Enter your age", value: $viewModel.age, formatter: ageFormatter)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
            }

            // Location Input (Optional)
            // You might want more sophisticated pickers here later
            VStack(alignment: .leading) {
                Text("Location (Optional)").font(.headline)
                HStack {
                    TextField("Country", text: $viewModel.locationCountry)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Postal Code", text: $viewModel.locationPostalCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numbersAndPunctuation) // Adjust keyboard if needed
                }
            }

            Spacer() // Push content to top
        }
        .padding()
    }
}

#Preview {
    Step0PersonalInfoView()
        .environmentObject(OnboardingViewModel())
} 