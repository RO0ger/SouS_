import SwiftUI

// Helper View for Macro Boxes
struct RecipeMacroView: View {
    let label: String
    let value: Int?

    var body: some View {
        // Only display the VStack if value is not nil
        if let actualValue = value {
            VStack(spacing: 4) { // Add spacing
                // Use the unwrapped value
                Text("\(actualValue)g") 
                    .font(.title3) // Slightly smaller title
                    .fontWeight(.semibold) // Adjust weight
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary) // Use secondary color for label
            }
            .frame(width: 75, height: 65) // Adjust size slightly
            .background(Color(.systemGray5)) // Lighter gray background
            .cornerRadius(10) // Match card corner radius
        }
        // If value is nil, nothing is rendered for this view instance
    }
}

struct RecipeFinderView: View {
    @StateObject var viewModel: RecipeFinderViewModel
    // State for sheet presentation is now managed within IngredientsSectionView if button stays there
    // We might need it here if the sheet content needs to interact back with this parent level.
    // For now, let's keep it local to where the button is.
    // @State private var showingAddIngredientInput = false 
    
    // --- Add State for presenting ImageSelectionView ---
    @State private var showingImageSelection = false
    // -------------------------------------------------
    
    // Initialize with just the selected image
    init(selectedImage: UIImage) {
        _viewModel = StateObject(wrappedValue: RecipeFinderViewModel(inputImage: selectedImage))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) { 
                
                // --- Initialization Error Display ---
                if let error = viewModel.ingredientError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Initialization Error")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    // Only show sections if no initialization error
                    IngredientsSectionView(viewModel: viewModel)
                    RecipesSectionView(viewModel: viewModel)
                }
                // ---------------------------------------------
                
            }
            .padding(.vertical) 
        } 
        .navigationTitle("Recipe Finder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { 
             ToolbarItem(placement: .navigationBarTrailing) {
                 Button {
                     // --- Set state to show ImageSelectionView ---
                     showingImageSelection = true
                     // -----------------------------------------
                 } label: {
                     Image(systemName: "camera.fill")
                         .font(.title2)
                 }
             }
         }
        // --- Add sheet modifier to present ImageSelectionView ---
        .sheet(isPresented: $showingImageSelection) {
            // Present ImageSelectionView modally
            ImageSelectionView()
        }
        // -----------------------------------------------------
    }
    
    // --- REMOVE OLD COMPUTED PROPERTIES --- 
}

// MARK: - Private Subviews (Refactored Sections)

private struct IngredientsSectionView: View {
    @ObservedObject var viewModel: RecipeFinderViewModel
    // Manage sheet presentation locally within this section
    @State private var showingAddIngredientInput = false 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Title and Add Button
            HStack { 
                Text("Detected Ingredients")
                    .font(.title2).bold()
                Spacer()
                Button {
                    showingAddIngredientInput = true 
                    print("Add ingredient button tapped")
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2) 
                        .foregroundColor(.secondary) 
                }
            }
            .padding(.horizontal)
            
            // Display Ingredients or Loading/Error States
            Group {
                if viewModel.isLoadingIngredients {
                    ProgressView("Detecting...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = viewModel.ingredientError {
                    Text("Error detecting ingredients: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                } else if viewModel.detectedIngredients.isEmpty {
                   Text("No ingredients detected yet.")
                        .foregroundColor(.secondary) 
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                } else {
                    // --- Ingredient Display using Columns (Green Tags Style) --- 
                    let allIngredients = viewModel.detectedIngredients
                    let unwantedIngredients = ["some type of sauce or dressing", "unspecified additional items"]
                    let ingredients = allIngredients.filter { ingredient in
                        !unwantedIngredients.contains { unwanted in
                            ingredient.name.lowercased() == unwanted // Case-insensitive check
                        }
                    }
                    
                    let itemsPerColumn = 4
                    let columnsData = stride(from: 0, to: ingredients.count, by: itemsPerColumn).map {
                        Array(ingredients[$0..<min($0 + itemsPerColumn, ingredients.count)])
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 15) { // Spacing between columns
                            ForEach(columnsData.indices, id: \.self) { columnIndex in
                                VStack(alignment: .leading, spacing: 8) { // Spacing within columns
                                    ForEach(columnsData[columnIndex]) { item in
                                        // HStack to hold potential quantity later, if needed
                                        HStack { 
                                            Text(item.name.capitalized)
                                                .fontWeight(.medium) // Make ingredient name slightly bolder
                                            // Quantity display (optional)
                                            if let quantity = item.quantity, !quantity.isEmpty {
                                                 Text("(\(quantity))")
                                                     .font(.caption) // Keep quantity smaller
                                                     .foregroundColor(.black.opacity(0.6))
                                             }
                                            Spacer() // Push content left
                                        }
                                        .font(.footnote)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.green.opacity(0.1))
                                        .foregroundColor(.black.opacity(0.8))
                                        .cornerRadius(8)
                                        .frame(maxWidth: .infinity, alignment: .leading) // Align text left
                                        .fixedSize(horizontal: false, vertical: true) // Allow text wrapping vertically
                                    }
                                    // Add spacers if a column has less than `itemsPerColumn` items
                                    if columnsData[columnIndex].count < itemsPerColumn {
                                         Spacer()
                                             .frame(height: CGFloat(itemsPerColumn - columnsData[columnIndex].count) * (15 + 8)) // Adjust spacer height
                                     }
                                }
                            }
                        }
                        .padding(.horizontal) // Padding inside the scroll view
                    }
                }
            }
        } // End Ingredients VStack
        .sheet(isPresented: $showingAddIngredientInput) {
            // Pass viewModel if sheet content needs it
            AddIngredientSheetView(viewModel: viewModel) 
        }
    }
}

private struct RecipesSectionView: View {
    @ObservedObject var viewModel: RecipeFinderViewModel

    var body: some View {
         VStack(alignment: .leading, spacing: 15) { 
            Text("Recipe Suggestions")
                .font(.title2).bold()
                .padding(.horizontal)
            
            Group {
                if viewModel.isLoadingRecipes && !viewModel.isLoadingIngredients { 
                    ProgressView("Finding recipes...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = viewModel.recipeError {
                   Text("Error fetching recipes: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                } else if viewModel.recipeSuggestions.isEmpty && !viewModel.isLoadingIngredients { 
                   Text("No recipe suggestions available.")
                         .foregroundColor(.secondary) 
                         .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                } else {
                    VStack(alignment: .leading, spacing: 15) {
                         ForEach(viewModel.recipeSuggestions) { recipeSuggestion in
                             // Wrap RecipeCardView in a NavigationLink
                             NavigationLink(destination: RecipeDetailView(viewModel: viewModel, initialRecipe: createRecipe(from: recipeSuggestion))) {
                                RecipeCardView(recipe: recipeSuggestion)
                             }
                             // Style the NavigationLink to look like the card (remove default button appearance)
                             .buttonStyle(.plain)
                         }
                     }
                     .padding(.horizontal)
                }
            }
         } // End Recipes VStack
    }
    
    // Helper function to convert RecipeSuggestion to Recipe (Placeholder)
    // TODO: Replace with actual data fetching or proper conversion
    private func createRecipe(from suggestion: RecipeSuggestion) -> Recipe {
        // Use preview data as a placeholder for now
        // Ideally, fetch full recipe details based on suggestion.id or pass needed data
        var recipe = Recipe.previewData // Start with preview data
        recipe.name = suggestion.name // Overwrite name from suggestion
        // Pass the duration string from the suggestion to the initial recipe
        recipe.duration = suggestion.durationString ?? Recipe.previewData.duration // Fallback to preview duration if nil
        // Add other fields if available in suggestion (e.g., duration, imageURL)
        // recipe.imageURL = suggestion.imageURL 
        // recipe.duration = suggestion.durationString ?? "Unknown"
        // ... etc.
        return recipe
    }
}
    
private struct AddIngredientSheetView: View {
    // May need viewModel or other bindings depending on implementation
    @ObservedObject var viewModel: RecipeFinderViewModel 
    @Environment(\.dismiss) var dismiss // To close the sheet
    @State private var newIngredientName: String = ""

    var body: some View {
        NavigationView { // Add NavigationView for title/buttons
            VStack {
                TextField("Enter ingredient name", text: $newIngredientName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Button("Add Ingredient") {
                    if !newIngredientName.isEmpty {
                        // TODO: Add logic to append to viewModel.detectedIngredients
                        // Note: This might require making detectedIngredients mutable
                        // or adding a function in the ViewModel.
                        // For now, just print and dismiss.
                        print("Would add ingredient: \(newIngredientName)")
                         // Example: viewModel.addIngredient(name: newIngredientName)
                        newIngredientName = ""
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newIngredientName.isEmpty)
                
                Spacer()
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// --- Updated Recipe Card View ---
struct RecipeCardView: View {
    let recipe: RecipeSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Adjusted spacing
            // Title
            Text(recipe.name)
                .font(.headline)
                .lineLimit(2)
            
            // Cooking Time (Bold) - Now with Icon - Using durationString
            if let time = recipe.durationString, !time.isEmpty { // Check if durationString exists and is not empty
                HStack(spacing: 4) { // HStack for icon and text
                    Image(systemName: "clock")
                        .font(.caption) // Match text size
                        .foregroundColor(.secondary) // Match text color
                    Text(time)
                        .font(.caption)
                        .fontWeight(.bold) // Keep time bold
                        .foregroundColor(.secondary)
                }
            }
            
            // Description (without time) - Using description
            if let desc = recipe.description, !desc.isEmpty { // Check if description exists and is not empty
                 Text(desc)
                     .font(.caption)
                     .foregroundColor(.secondary)
                     .lineLimit(3) // Allow slightly more lines for description
             }
            
            // Add some space before macros
            Spacer().frame(height: 4)

            // Macro Section
            HStack(spacing: 10) {
                RecipeMacroView(label: "Protein", value: recipe.protein)
                RecipeMacroView(label: "Carbs", value: recipe.carbs)
                RecipeMacroView(label: "Fats", value: recipe.fats)
                Spacer() 
            }
        }
        .padding() // Default padding is fine
        .background(Color(.systemGray6))
        .cornerRadius(12) // Slightly larger radius
    }
}

#Preview { 
    // Update preview to reflect new initializer
    let dummyImage = UIImage(systemName: "photo")! 
    // let dummyOnboardingVM = OnboardingViewModel() // No longer needed for preview

    NavigationView {
        RecipeFinderView(selectedImage: dummyImage)
    }
} 
