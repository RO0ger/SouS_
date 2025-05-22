import SwiftUI

// Simple struct to hold parsed ingredient data for display
private struct IngredientDisplayItem: Identifiable {
    let id = UUID()
    let name: String
    let quantity: String
}

struct InspirationRecipeDetailView: View {
    let inspirationItem: HomepageInspiration

    // Timer State Variables
    @State private var timeRemaining: Double = 0
    @State private var isTimerRunning: Bool = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Parsed ingredients
    @State private var parsedIngredients: [IngredientDisplayItem] = []
    // Parsed instructions
    @State private var parsedInstructions: [String] = []

    // Helper to parse duration string (e.g., "25 mins" or "15 minutes") into seconds
    private func parseDuration(durationString: String) -> Double {
        let components = durationString.lowercased().split(separator: " ")
        guard components.count >= 1, let value = Double(components[0]) else {
            return 0
        }
        if components.count >= 2 {
            let unit = String(components[1])
            if unit.starts(with: "hour") {
                return value * 60 * 60
            }
        }
        return value * 60
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
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }

    // Function to pause the timer
    private func pauseTimer() {
        isTimerRunning = false
        timer.upstream.connect().cancel()
    }

    // Function to reset the timer
    private func resetTimer() {
        pauseTimer()
        timeRemaining = parseDuration(durationString: inspirationItem.duration)
        isTimerRunning = false
    }

    // Function to parse ingredients string
    // Example format: "Eggs: 2 large; Spinach: 1 cup; Milk: 100ml"
    private func parseIngredients(ingredientsString: String) -> [IngredientDisplayItem] {
        var items: [IngredientDisplayItem] = []
        let individualIngredients = ingredientsString.split(separator: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for ingredientEntry in individualIngredients {
            let parts = ingredientEntry.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2 {
                items.append(IngredientDisplayItem(name: String(parts[0]), quantity: String(parts[1])))
            } else if parts.count == 1 && !parts[0].isEmpty { // Handle case where there might be no quantity
                items.append(IngredientDisplayItem(name: String(parts[0]), quantity: ""))
            }
        }
        return items
    }
    
    // Function to parse instructions string (separated by newlines)
    private func parseInstructions(instructionsString: String) -> [String] {
        return instructionsString.split(separator: "\n").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }.filter { !$0.isEmpty }
    }


    // MARK: - View Sections

    @ViewBuilder
    private var recipeImageSection: some View {
        // Using SF Symbol for image based on imageName from HomepageInspiration
        // Adapted from RecipeDetailView's placeholder style
        Image(systemName: inspirationItem.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 150)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
    }

    @ViewBuilder
    private var recipeTitleSection: some View {
        Text(inspirationItem.title)
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .padding(.horizontal)
    }

    @ViewBuilder
    private var recipeInfoBarSection: some View {
        HStack(spacing: 15) {
            Label(inspirationItem.duration, systemImage: "timer")
            // Servings and Meal Prep info are not in HomepageInspiration model, so omitted.
            Spacer()
        }
        .font(.subheadline)
        .padding(.horizontal)
        .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var timerControlSection: some View {
        // --- Enhanced Timer Section (Adapted from RecipeDetailView) ---
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
                    .frame(minWidth: 150, alignment: .leading)

                Button {
                    if isTimerRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                } label: {
                    Image(systemName: isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                        .resizable().aspectRatio(contentMode: .fit).frame(width: 40, height: 40)
                        .foregroundStyle(Color.accentColor)
                }

                Button {
                    resetTimer()
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .resizable().aspectRatio(contentMode: .fit).frame(width: 35, height: 35)
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
            }
        }
        .padding().background(Color(.systemGray6)).cornerRadius(15).padding(.horizontal)
    }

    @ViewBuilder
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Ingredients")
                .font(.title2).fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 4)

            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(parsedIngredients) { ingredient in
                    HStack {
                        Text(ingredient.name).font(.body)
                        Spacer()
                        Text(ingredient.quantity).font(.callout).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .padding(.horizontal).padding(.vertical, 12)
        .background(Color(.systemGray6)).cornerRadius(15).padding(.horizontal)
    }

    @ViewBuilder
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.title2).fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 4)

            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(Array(parsedInstructions.enumerated()), id: \.offset) { index, instruction in
                    InstructionRowView(index: index, instruction: instruction)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical).background(Color(.systemGray6)).cornerRadius(15)
        .padding(.horizontal).padding(.bottom)
    }
    
    // Copied from RecipeDetailView
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

    // Private helper view for a single instruction row
    // Copied from RecipeDetailView and adapted to use the static formattedInstructionText
    private struct InstructionRowView: View {
        let index: Int
        let instruction: String

        var body: some View {
            HStack(alignment: .top, spacing: 10) {
                Text("\(index + 1)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Circle())
                    .frame(width: 25)
                    .padding(.top, 2)
                    
                // Use the static helper method from the parent view context
                InspirationRecipeDetailView.formattedInstructionText(for: instruction)
                    .font(.body)
            }
        }
    }


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                recipeImageSection
                recipeTitleSection
                recipeInfoBarSection
                Divider().padding(.horizontal).padding(.vertical, 10)
                timerControlSection
                ingredientsSection
                instructionsSection
            }
        }
        .navigationTitle(inspirationItem.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Parse ingredients and instructions from the inspirationItem
            self.parsedIngredients = parseIngredients(ingredientsString: inspirationItem.ingredients)
            self.parsedInstructions = parseInstructions(instructionsString: inspirationItem.instructions)
            resetTimer()
        }
        .onDisappear {
            pauseTimer()
        }
    }
}

// --- Preview Provider ---
struct InspirationRecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy HomepageInspiration for preview
        let previewInspirationItem = HomepageInspiration(
            id: 1,
            createdAt: Date(),
            title: "Preview Inspiration Dish",
            imageName: "fork.knife.circle", // SF Symbol
            duration: "30 min",
            ingredients: "Pasta: 200g; Tomato Sauce: 1 can; Garlic: 2 cloves; Olive Oil: 1 tbsp; Basil: handful",
            instructions: "Cook pasta according to package.\nSauté garlic in olive oil.\nAdd tomato sauce and simmer.\nCombine with pasta and basil.\n_Enjoy your meal!_"
        )
        
        NavigationView {
            InspirationRecipeDetailView(inspirationItem: previewInspirationItem)
        }
    }
} 