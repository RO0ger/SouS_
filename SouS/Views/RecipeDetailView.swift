import SwiftUI

// String extension removed - now in String+Extensions.swift

struct RecipeDetailView: View {
    // ViewModel for fetching details
    @ObservedObject var viewModel: RecipeFinderViewModel
    
    // Initial placeholder/suggestion data
    let initialRecipe: Recipe // Renamed from recipe

    // State for holding the fully fetched recipe details
    @State private var detailedRecipe: Recipe? = nil
    @State private var isLoadingDetails: Bool = false
    @State private var fetchError: Error? = nil

    // Timer State Variables
    @State private var timeRemaining: Double = 0 // Store time in seconds
    @State private var isTimerRunning: Bool = false
    // Timer publisher
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Get the recipe to display (either fetched details or initial placeholder)
    private var recipeToDisplay: Recipe {
        detailedRecipe ?? initialRecipe
    }

    // Helper to parse duration string (e.g., "25 mins" or "15 minutes") into seconds
    private func parseDuration(durationString: String) -> Double {
        // Handle different formats like "25 mins", "15 minutes", "1 hour", etc.
        let components = durationString.lowercased().split(separator: " ")
        guard components.count >= 1, let value = Double(components[0]) else {
            return 0 // Default to 0 if parsing fails
        }
        
        // Check unit (mins, minutes, hour, hours, etc.)
        if components.count >= 2 {
            let unit = String(components[1])
            if unit.starts(with: "hour") {
                return value * 60 * 60 // Convert hours to seconds
            }
        }
        
        // Default to minutes for all other cases
        return value * 60 // Convert minutes to seconds
    }

    // Helper to format seconds into MM:SS string
    private func formatTime(_ totalSeconds: Double) -> String {
        let seconds = Int(totalSeconds) % 60
        let minutes = Int(totalSeconds) / 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // Function to start the timer
    private func startTimer() {
        isTimerRunning = true
        // Reconnect the timer publisher
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }

    // Function to pause the timer
    private func pauseTimer() {
        isTimerRunning = false
        // Stop the timer publisher by cancelling
        timer.upstream.connect().cancel()
    }

    // Function to reset the timer
    private func resetTimer() {
        pauseTimer() // Stop the timer first
        // Use the duration from the currently displayed recipe
        timeRemaining = parseDuration(durationString: recipeToDisplay.duration)
        isTimerRunning = false // Ensure state is not running
    }

    // Function to fetch details
    private func fetchDetails() async {
        isLoadingDetails = true
        fetchError = nil
        do {
            // Fetch the raw recipe data
            var fetchedRecipe = try await viewModel.fetchRecipeDetails(recipeName: initialRecipe.name)
            
            // --- Merge isMissing status --- 
            // Create a set of missing ingredient names from the initial detection (case-insensitive)
            let missingIngredientNames = Set(initialRecipe.ingredients.filter { $0.isMissing }.map { $0.name.lowercased() })
            
            // Iterate and update the fetched ingredients
            for index in fetchedRecipe.ingredients.indices {
                if missingIngredientNames.contains(fetchedRecipe.ingredients[index].name.lowercased()) {
                    fetchedRecipe.ingredients[index].isMissing = true
                }
            }
            // ----------------------------- 
            
            self.detailedRecipe = fetchedRecipe
            resetTimer() // Reset timer based on new duration
        } catch {
            print("Error fetching recipe details in View: \(error)")
            fetchError = error
        }
        isLoadingDetails = false
    }

    // MARK: - View Sections

    // Static helper function to format instruction text with italics
    private static func formattedInstructionText(for instruction: String) -> Text {
        let parts = instruction.split(separator: "_", omittingEmptySubsequences: false)
        var combinedText = Text("")
        for (index, part) in parts.enumerated() {
            if index % 2 == 1 { // Italic part
                combinedText = combinedText + Text(part).italic()
            } else { // Normal part
                combinedText = combinedText + Text(part)
            }
        }
        return combinedText
    }

    @ViewBuilder
    private var loadingErrorSection: some View {
        // Loading / Error display
        if isLoadingDetails {
            ProgressView("Loading Recipe Details...")
                .padding()
                .frame(maxWidth: .infinity)
        } else if let error = fetchError {
            VStack {
                Image(systemName: "exclamationmark.triangle.fill") // Corrected icon name
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("Load Failed")
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                // Optional: Add a retry button
                Button("Retry") {
                    Task { await fetchDetails() } // Call fetch again
                }
                .padding(.top, 5)
                .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var recipeImageSection: some View {
        // --- Using recipe name as a placeholder for the image section ---
        // Text(recipeToDisplay.name)
        //     .font(.title3)
        //     .padding()
        //     .frame(maxWidth: .infinity)
        //     .background(Color.gray.opacity(0.2))
        //     .cornerRadius(10)
        //     .padding(.horizontal)
        // -----------------------------------------------------------------
        EmptyView() // Return an EmptyView to effectively remove it
    }

    @ViewBuilder
    private var recipeTitleSection: some View {
        // --- Restore Enhanced Title ---
        Text(recipeToDisplay.name)
            .font(.system(size: 34, weight: .bold, design: .rounded)) // Larger, bolder, rounded font
            .padding(.horizontal)
            // .padding(.top) // Remove extra top padding
        // --------------------------
    }

    @ViewBuilder
    private var recipeInfoBarSection: some View {
        // --- Enhanced Info Bar ---
        HStack(spacing: 15) { // Adjust spacing
            Label(recipeToDisplay.duration, systemImage: "timer") // Updated icon
            Label("\(recipeToDisplay.servings) servings", systemImage: "person.2.fill") // Filled icon

            if recipeToDisplay.isMealPrepFriendly {
                Label("Meal Prep", systemImage: "figure.walk.motion") // Icon for tag
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule()) // Use Capsule shape
            }
            Spacer()
        }
        .font(.subheadline) // Apply base font size to info bar
        .padding(.horizontal)
        .foregroundColor(.secondary)
        // -----------------------
    }

    @ViewBuilder
    private var timerControlSection: some View {
        // --- Enhanced Timer Section ---
        VStack {
            Text("Timer")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 2)

            HStack(spacing: 20) {
                Text(formatTime(timeRemaining))
                    .font(.system(size: 60, weight: .regular, design: .monospaced))
                    .foregroundColor(.primary)
                    .onReceive(timer) { _ in
                        guard isTimerRunning else { return }
                        if timeRemaining > 0 {
                            timeRemaining -= 1
                        } else {
                            pauseTimer()
                        }
                    }
                    // Add minimum width to prevent layout shifts
                    .frame(minWidth: 150, alignment: .leading)

                // Controls with slightly larger tap area
                Button {
                    if isTimerRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                } label: {
                    Image(systemName: isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        // Use primaryBlue or accent color
                        .foregroundStyle(Color.accentColor)
                }

                Button {
                    resetTimer()
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35, height: 35) // Slightly smaller reset icon
                        .foregroundStyle(Color.secondary)
                }
                Spacer() // Push timer controls to the right slightly
            }
        }
        .padding()
        .background(Color(.systemGray6)) // Subtle background
        .cornerRadius(15)
        .padding(.horizontal)
        // ---------------------------
    }

    // Placeholder for Ingredients Section - you'll need to move its content here
    @ViewBuilder
    private var ingredientsSection: some View {
        // --- Ingredients Section (Restored Layout) --- 
        VStack(alignment: .leading, spacing: 5) { // Tighter overall spacing
            Text("Ingredients")
                .font(.title2) // Keep updated font
                .fontWeight(.semibold) // Keep updated weight
                .frame(maxWidth: .infinity, alignment: .center) // Keep centered alignment
                .padding(.bottom, 4)

            // Tighter spacing between rows
            LazyVStack(alignment: .leading, spacing: 8) { 
                ForEach(recipeToDisplay.ingredients) { ingredient in // Use recipeToDisplay
                    HStack { 
                        // Optionally add back missing icon logic if needed
                        Text(ingredient.name)
                            .font(.body)
                        Spacer() // Pushes quantity right
                        Text(ingredient.quantity)
                            .font(.callout) // Slightly smaller font for quantity
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 3) // Reduced vertical row padding 
                    // Divider removed for cleaner look
                }
            }
        }
        // Add back background and controlled padding
        .padding(.horizontal) // Inner horizontal padding
        .padding(.vertical, 12) // Inner vertical padding
        .background(Color(.systemGray6)) // Subtle background card
        .cornerRadius(15) 
        .padding(.horizontal) // Outer horizontal padding to inset the card
        // ----------------------------------------
    }

    // Placeholder for Instructions Section - you'll need to move its content here
    @ViewBuilder
    private var instructionsSection: some View {
        // --- Instructions Section (Restored Layout) ---
        VStack(alignment: .leading, spacing: 8) { 
            Text("Instructions")
                .font(.title2) // Keep updated font
                .fontWeight(.semibold) // Keep updated weight
                .frame(maxWidth: .infinity, alignment: .center) // Keep centered alignment
                .padding(.bottom, 4)

            LazyVStack(alignment: .leading, spacing: 12) { // Added spacing
                ForEach(Array(recipeToDisplay.instructions.enumerated()), id: \.offset) { index, instruction in // Use recipeToDisplay
                    InstructionRowView(index: index, instruction: instruction)
                }
            }
            .padding(.horizontal) // Padding inside the LazyVStack
        }
        .padding(.vertical) // Padding top/bottom of the VStack
        .background(Color(.systemGray6)) // Subtle background
        .cornerRadius(15)
        .padding(.horizontal) // Outer horizontal padding
        .padding(.bottom) // Add padding at the very bottom
        // -----------------------------------
    }

    // Private helper view for a single instruction row
    private struct InstructionRowView: View {
        let index: Int
        let instruction: String

        var body: some View {
            HStack(alignment: .top, spacing: 10) { // More spacing
                // Styled Step Number
                Text("\(index + 1)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Circle())
                    .frame(width: 25) // Consistent outer width
                    .padding(.top, 2) // Align circle better
                    
                // Use the static helper method from RecipeDetailView
                RecipeDetailView.formattedInstructionText(for: instruction)
                    .font(.body)
            }
        }
    }

    var body: some View {
        // Use recipeToDisplay throughout the body
        // let currentRecipe = recipeToDisplay // No longer needed here, direct access in helpers

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                loadingErrorSection // Display loading or error message first

                // --- Show Recipe Content only if loaded successfully ---
                if !isLoadingDetails && fetchError == nil {
                    // recipeImageSection // Commented out to remove the placeholder
                    recipeTitleSection
                    recipeInfoBarSection
                    Divider().padding(.horizontal).padding(.vertical, 10)
                    timerControlSection
                    
                    // --- TODO: Add Ingredients Section ---
                    // This is where your original ingredients loop and header would go.
                    // For now, it might be a VStack with Text("Ingredients") and a ForEach.
                    // Example:
                    // VStack(alignment: .leading, spacing: 8) {
                    //     Text("Ingredients")
                    //         .font(.title2.bold())
                    //         .padding(.horizontal)
                    //     ForEach(recipeToDisplay.ingredients) { ingredient in
                    //         HStack {
                    //             Text(ingredient.name)
                    //             // ... other ingredient details ...
                    //         }.padding(.horizontal)
                    //     }
                    // }
                    // Divider().padding(.horizontal).padding(.vertical, 10) // If needed
                    ingredientsSection // Use the extracted section

                    // --- TODO: Add Instructions Section ---
                    // This is where your original instructions text would go.
                    // Example:
                    // VStack(alignment: .leading, spacing: 8) {
                    //     Text("Instructions")
                    //         .font(.title2.bold())
                    //         .padding(.horizontal)
                    //     Text(recipeToDisplay.instructions)
                    //         .padding(.horizontal)
                    // }
                    instructionsSection // Use the extracted section

                }
            }
            // Removed .padding() from VStack, apply to ScrollView content if needed or keep within sections
        }
        .navigationTitle(recipeToDisplay.name) // Keep nav title
        .navigationBarTitleDisplayMode(.inline) // Optional: if you prefer inline
        .onAppear {
            // Fetch details if not already loaded or being loaded
            if detailedRecipe == nil && !isLoadingDetails {
                Task {
                    await fetchDetails()
                }
            } else if detailedRecipe != nil {
                // If details are already loaded, ensure timer is reset for current recipe
                resetTimer()
            }
        }
        // Ensure timer is paused when the view disappears
        .onDisappear {
            pauseTimer()
        }
    }
}

#Preview {
    // Need to provide a ViewModel instance for preview
    let dummyImage = UIImage(systemName: "photo")! 
    // let dummyOnboardingVM = OnboardingViewModel() // No longer needed
    // Use the updated initializer for RecipeFinderViewModel
    let dummyFinderVM = RecipeFinderViewModel(inputImage: dummyImage)
    
    // Create the placeholder recipe using previewData
    let previewRecipe = Recipe.previewData

    NavigationView {
        // Pass the updated viewModel and the previewRecipe as initialRecipe
        RecipeDetailView(viewModel: dummyFinderVM, initialRecipe: previewRecipe)
    }
} 