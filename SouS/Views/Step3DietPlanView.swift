import SwiftUI

struct Step3DietPlanView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 15) { // Reduced spacing slightly
            // Title
            Text("Build Your Protein Plan")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)
            
            // List of Diet Preferences
            // Wrap in ScrollView in case the list gets long or for smaller screens
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(OnboardingViewModel.DietPreference.allCases) { diet in
                        DietPlanRow(diet: diet, selectedDiet: $viewModel.dietPreference)
                    }
                }
            }

            Spacer() // Push content to the top
        }
        .padding()
    }
}

// --- Subview for Diet Plan Row ---
struct DietPlanRow: View {
    let diet: OnboardingViewModel.DietPreference
    @Binding var selectedDiet: OnboardingViewModel.DietPreference

    // TODO: Add detailed descriptions for each diet later if needed
    var description: String {
        switch diet {
        case .omnivore: return "A balanced diet including all food groups"
        case .vegetarian: return "Plant-based diet with eggs and dairy"
        case .vegan: return "Exclusively plant-based diet"
        case .pescatarian: return "Vegetarian diet that includes fish"
        case .ketogenic: return "High-fat, low-carb diet"
        case .paleo: return "Based on foods available to our ancestors"
        }
    }
    
    var proteinSources: String {
         switch diet {
         case .omnivore: return "Protein sources: Meat, Fish, Eggs, Dairy, Legumes"
         case .vegetarian: return "Protein sources: Eggs, Dairy, Legumes, Tofu, Tempeh"
         case .vegan: return "Protein sources: Legumes, Tofu, Tempeh, Seitan, Quinoa"
         case .pescatarian: return "Protein sources: Fish, Seafood, Eggs, Dairy, Legumes"
         case .ketogenic: return "Protein sources: Meat, Fish, Eggs, Cheese"
         case .paleo: return "Protein sources: Meat, Fish, Eggs, Nuts"
         }
     }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(diet.rawValue).font(.headline)
                // Display description and protein sources from web screenshot
                Text(description).font(.caption).foregroundColor(.gray)
                Text(proteinSources).font(.caption).foregroundColor(.blue) // Using blue like screenshot
            }
            Spacer()
            Image(systemName: selectedDiet == diet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(selectedDiet == diet ? .blue : .gray)
                .font(.title2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onTapGesture {
            selectedDiet = diet // Update selection on tap
        }
    }
}


// --- Preview ---
#Preview {
    Step3DietPlanView()
        .environmentObject(OnboardingViewModel())
} 