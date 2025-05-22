import SwiftUI
import Combine // For handling potential future debouncing etc.
import GoogleGenerativeAI // Import the SDK
import Foundation // <-- Add this import

// --- REMOVE Placeholder API Key Struct --- 
// struct APIKey { ... }
// -----------------------------------------

// Model for Detected Ingredient
struct DetectedIngredient: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: String? // Optional quantity/count (e.g., "300g", "(6)")
}

// Model for Recipe Suggestion
struct RecipeSuggestion: Identifiable {
    let id = UUID()
    var name: String
    var description: String? // Will store only the description now
    var durationString: String? // Added for specific duration
    var matchPercentage: Int? // e.g., 83
    var protein: Int?
    var carbs: Int?
    var fats: Int?
    var imageUrl: String? // URL string for the recipe image
}

@MainActor
final class RecipeFinderViewModel: ObservableObject {
    
    // Image to process
    let inputImage: UIImage
    
    // State for Ingredient Detection
    @Published var detectedIngredients: [DetectedIngredient] = []
    @Published var isLoadingIngredients = false
    @Published var ingredientError: Error? = nil
    
    // State for Recipe Suggestions
    @Published var recipeSuggestions: [RecipeSuggestion] = []
    @Published var isLoadingRecipes = false
    @Published var recipeError: Error? = nil
    
    // Search Query
    @Published var searchQuery: String = ""
    
    // Initializer now only takes the image
    init(inputImage: UIImage) {
        self.inputImage = inputImage
        print("RecipeFinderViewModel initialized with image.")
        
        // Immediately start ingredient detection
        // We still need a way to detect ingredients. For now, keep the
        // client-side Gemini vision call, but the recipe suggestion part will change.
        // TODO: Decide if ingredient detection should also move to backend.
        configureVisionModelAndDetect() // Renamed initialization logic
    }
    
    // --- Refactored Model Configuration & Initial Detection ---
    private func configureVisionModelAndDetect() {
        // Keep vision model configuration for ingredient detection for now
        do {
            let apiKey = try APIKeyLoader.loadAPIKey()
            let visionModel = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: apiKey)
            print("Gemini Vision model configured for ingredient detection.")
            Task {
                 await detectIngredients(using: visionModel)
             }
        } catch {
            print("Error configuring Gemini vision model: \(error.localizedDescription)")
            self.ingredientError = error // Use ingredientError for this phase
            self.isLoadingIngredients = false
        }
    }
    
    // --- Ingredient Detection (Kept client-side for now) ---
    func detectIngredients(using visionModel: GenerativeModel) async {
        guard !isLoadingIngredients else { return }
        isLoadingIngredients = true
        ingredientError = nil
        detectedIngredients = []
        
        print("Starting ingredient detection (client-side)...")
        let prompt = "Identify all food ingredients visible in this image. For each ingredient, list its name followed by an estimated quantity in parentheses (e.g., weight like '300g' or count like '(6)'). If quantity cannot be reasonably estimated, just list the name. Separate each ingredient entry with a comma. Example: tomatoes (500g), onions (3), garlic, chicken breast (400g)"
        
        do {
            let response = try await visionModel.generateContent(prompt, inputImage)
            
            if let text = response.text {
                print("Gemini Vision Response (Raw): \(text)")
                
                var parsedIngredients: [DetectedIngredient] = []
                let components = text.split(separator: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                
                // --- Use try? to handle potential regex creation error --- 
                guard let regex = try? NSRegularExpression(pattern: "^(.+?)(?:\\s*\\((.+?)\\))?$", options: []) else {
                    print("Error: Invalid Regex pattern for ingredient parsing.")
                    self.ingredientError = NSError(domain: "ParsingError", code: 99, userInfo: [NSLocalizedDescriptionKey: "Internal error: Invalid regex pattern."])
                    self.isLoadingIngredients = false
                    return // Exit if regex fails
                }
                // ---------------------------------------------------------
                
                for component in components {
                    if component.isEmpty { continue } // Skip empty parts
                    
                    let nsRange = NSRange(component.startIndex..<component.endIndex, in: component)
                    if let match = regex.firstMatch(in: component, options: [], range: nsRange) {
                        var ingredientName: String? = nil
                        var ingredientQuantity: String? = nil
                        
                        // Extract Name (Group 1)
                        if let nameRange = Range(match.range(at: 1), in: component) {
                            ingredientName = String(component[nameRange]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        // Extract Optional Quantity (Group 2)
                        if match.numberOfRanges > 2, let quantityRange = Range(match.range(at: 2), in: component) {
                            ingredientQuantity = String(component[quantityRange]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        // Add if name is valid
                        if let name = ingredientName, !name.isEmpty {
                            parsedIngredients.append(DetectedIngredient(name: name, quantity: ingredientQuantity))
                        } else {
                            print("Parsing Warning: Could not extract valid name from component: '\(component)'")
                        }
                    } else {
                        // If regex doesn't match, assume the whole component is the name
                        print("Parsing Warning: Regex did not match component: '\(component)'. Treating as name only.")
                        parsedIngredients.append(DetectedIngredient(name: component, quantity: nil))
                    }
                }
                
                self.detectedIngredients = parsedIngredients
                print("Detected Ingredients (Parsed): \(self.detectedIngredients)")
                
                // Trigger backend fetch for recipe suggestions
                await fetchPersonalizedRecipes()
                
            } else {
                print("Gemini Vision Error: No text response received.")
                ingredientError = NSError(domain: "GeminiAPIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No text response received from Vision API."])
                isLoadingIngredients = false // Stop loading on error
            }
        } catch {
            print("Ingredient Detection Error: \(error.localizedDescription)")
            self.ingredientError = error
            isLoadingIngredients = false
        }
        // Loading state managed within fetchPersonalizedRecipes or error paths
        // isLoadingIngredients = false // Removed
    }
    
    // --- Personalized Recipe Fetch (NEW - Calls Backend) ---
    func fetchPersonalizedRecipes() async {
        isLoadingIngredients = false // Mark ingredient detection as done
        isLoadingRecipes = true
        recipeError = nil
        recipeSuggestions = [] // Clear previous suggestions
        
        guard !detectedIngredients.isEmpty else {
            print("Skipping personalized recipe fetch: No ingredients detected.")
            isLoadingRecipes = false
            return
        }
        
        print("Fetching personalized recipes with user data and detected ingredients...")
        
        do {
            // 1. Get current user's data from Supabase
            guard let userData = try await SupabaseManager.shared.fetchCurrentUserData() else {
                throw NSError(domain: "UserDataError", code: 1, 
                              userInfo: [NSLocalizedDescriptionKey: "Could not fetch user data from Supabase"])
            }
            
            // FIX: Use the new 'dietaryPreferences' array and get the first element
            let dietPreferenceString = userData.dietaryPreferences?.first ?? "None"
            print("Retrieved user data: Goal=\(userData.goal ?? "No goal"), Diet=\(dietPreferenceString)")
            
            // Format dietary preferences array as comma-separated string
            let dietaryPrefs = dietPreferenceString
            
            // 2. Prepare ingredients list
            let ingredientNames = detectedIngredients.map { ingredient in
                if let quantity = ingredient.quantity {
                    return "\(ingredient.name) (\(quantity))"
                } else {
                    return ingredient.name
                }
            }.joined(separator: ", ")
            
            // 3. Construct enhanced prompt with user data
            // --- Updated Prompt for Simpler Macro Parsing ---
            let prompt = """
            Generate 3 personalized recipe suggestions based on these ingredients and user profile:
            
            INGREDIENTS: \(ingredientNames)
            
            USER PROFILE:
            - Goal: \(userData.goal ?? "N/A")
            - Current Weight: \(userData.currentWeightKg != nil ? "\(userData.currentWeightKg!)kg" : "N/A")
            - Target Weight: \(userData.targetWeightKg != nil ? "\(userData.targetWeightKg!)kg" : "N/A")
            - Dietary Preferences: \(dietaryPrefs)
            - Activity Level: \(userData.activityLevel?.rawValue ?? "N/A")
            - Target Date: \(userData.targetDate != nil ? "\(formatDate(userData.targetDate!))" : "N/A")
            - Sex: \(userData.sex ?? "N/A")
            - Age: \(userData.age != nil ? "\(userData.age!)" : "N/A")
            - Country: \(userData.locationCountry ?? "N/A")
            
            For each recipe, provide:
            1. Recipe name on its own line, starting with "**".
            2. Approximate cooking time on its own line, starting with "Time:".
            3. A very brief, single-sentence description on its own line, starting with "Desc:".
            4. Macronutrient breakdown, each on its own line: 
               - Start line with "Protein:"
               - Start line with "Carbs:"
               - Start line with "Fats:"
            
            Separate each recipe suggestion with a blank line.
            Example Recipe Format:
            **Example Recipe Name
            Time: 25 minutes
            Desc: A very short description fitting one line.
            Protein: 30g
            Carbs: 45g
            
            [Blank Line Here]
            
            **Another Recipe Name
            ...
            """
            // --- End Updated Prompt ---
            
            // 4. Call Gemini API for personalized recipes
            let apiKey = try APIKeyLoader.loadAPIKey()
            let recipeModel = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: apiKey)
            let response = try await recipeModel.generateContent(prompt)
            
            guard let recipeText = response.text else {
                throw NSError(domain: "GeminiAPIError", code: 2, 
                             userInfo: [NSLocalizedDescriptionKey: "No text response received from Gemini API."])
            }
            
            print("Received personalized recipes from Gemini API.")
            
            // 5. Parse the response into RecipeSuggestion objects
            // Split into potential recipe blocks based on blank lines
            let recipeBlocks = recipeText.split(separator: "\n\n", omittingEmptySubsequences: true)
            
            var suggestions: [RecipeSuggestion] = []

            for block in recipeBlocks {
                let lines = block.split(separator: "\n", omittingEmptySubsequences: true).map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
                
                // Reset for each block
                var currentName: String?
                var currentTime: String?
                var currentDescription: String?
                var currentProtein: Int?
                var currentCarbs: Int?
                var currentFats: Int?
                
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespaces)
                    
                    if trimmedLine.starts(with: "**") {
                        // Remove all * characters from recipe name
                        currentName = String(trimmedLine.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: CharacterSet.whitespaces))
                    } else if trimmedLine.starts(with: "Time:") {
                        currentTime = String(trimmedLine.dropFirst(5).trimmingCharacters(in: CharacterSet.whitespaces)) // Extract time
                    } else if trimmedLine.starts(with: "Desc:") {
                        currentDescription = String(trimmedLine.dropFirst(5).trimmingCharacters(in: CharacterSet.whitespaces)) // Extract description
                    } else if trimmedLine.starts(with: "Protein:") {
                        currentProtein = parseMacro(from: trimmedLine)
                    } else if trimmedLine.starts(with: "Carbs:") {
                        currentCarbs = parseMacro(from: trimmedLine)
                    } else if trimmedLine.starts(with: "Fats:") {
                        currentFats = parseMacro(from: trimmedLine)
                    }
                }
                
                // Validate and create suggestion
                if let finalName = currentName, !finalName.isEmpty {
                    // Debug Print (Optional)
                    print("Parsed Block: Name='\(finalName)', Time='\(currentTime ?? "N/A")', Desc='\(currentDescription ?? "N/A")', P=\(currentProtein ?? -1), C=\(currentCarbs ?? -1), F=\(currentFats ?? -1)")
                    
                    let suggestion = RecipeSuggestion(
                        name: finalName,
                        description: currentDescription, // Use extracted description
                        durationString: currentTime, // Use extracted time
                        matchPercentage: nil,
                        protein: currentProtein,
                        carbs: currentCarbs,
                        fats: currentFats,
                        imageUrl: nil
                    )
                    suggestions.append(suggestion)
                } else {
                    print("Parsing Warning: Recipe block did not contain a valid name starting with '**':\n\(block)")
                }
            }
            
            // If parsing failed or no valid recipes returned, provide a more helpful error
            if suggestions.isEmpty {
                throw NSError(domain: "ParseError", code: 3, 
                             userInfo: [NSLocalizedDescriptionKey: "Could not parse recipe suggestions from API response."])
            }
            
            // Update the UI with the personalized recipes
            self.recipeSuggestions = suggestions
            print("Successfully parsed \(suggestions.count) personalized recipes.")
        } catch {
            print("Error fetching personalized recipes: \(error.localizedDescription)")
            self.recipeError = error
        }
        
        isLoadingRecipes = false
    }
    
    // Helper to format date for prompt
    private func formatDate(_ date: Date) -> String {
        // Use consistent date formatting with our SupabaseManager
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Helper function to parse macro values from strings like "Protein: 25g"
    private func parseMacro(from line: String) -> Int? {
        // Extract only the digits from the string
        let valueText = line.components(separatedBy: ":").last?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
        let valueString = valueText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if !valueString.isEmpty {
            return Int(valueString)
        }
        print("Parsing Warning: Could not extract macro value from line: \(line)")
        return nil
    }
    
    // --- Recipe Detail Fetch (Can potentially remain client-side or move to backend) ---
    // If this stays client-side, it needs its own textModel configuration.
    // For consistency, moving detail fetching to backend might be better later.
    func fetchRecipeDetails(recipeName: String) async throws -> Recipe {
         print("Fetching recipe details for: \(recipeName)")
        
         // 1. Find the corresponding suggestion (to potentially use macros, duration etc. if needed)
         guard let suggestion = recipeSuggestions.first(where: { 
             $0.name.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: CharacterSet.whitespaces) == 
             recipeName.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: CharacterSet.whitespaces)
         }) else {
             print("Error: Suggestion not found for \(recipeName). Returning preview data.")
             return Recipe.previewData // Return default preview if name not found
         }
        
         // 2. Prepare Base Recipe Details (using suggestion data)
         var details = Recipe.previewData // Start with preview data template
         details.name = suggestion.name.replacingOccurrences(of: "*", with: "") // Clean the name
         details.duration = suggestion.durationString ?? Recipe.previewData.duration // Use suggestion time or fallback
         // TODO: Add other fields from suggestion if available (servings, etc.)
         details.ingredients = self.detectedIngredients.map { Ingredient(name: $0.name, quantity: $0.quantity ?? "", isMissing: false) } // Use currently detected ingredients
         
         // 3. Fetch Instructions via Gemini API
         print("Fetching instructions for \(details.name) via Gemini...")
         do {
             let apiKey = try APIKeyLoader.loadAPIKey()
             let instructionModel = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: apiKey)
             
             // Construct the prompt for instructions
             let ingredientList = detectedIngredients.map { $0.name }.joined(separator: ", ")
             let instructionPrompt = """
             For the recipe "\(details.name)", provide the required ingredients and cooking instructions.

             FIRST, list the ingredients under an "INGREDIENTS:" heading.
             Each ingredient should be on a new line with its name and quantity (e.g., "Spinach: 1 cup", "Eggs: 2").

             SECOND, provide clear, numbered cooking instructions under an "INSTRUCTIONS:" heading.
             Aim for 5-7 easy-to-follow steps (not more).
             Make the tone fun and lighthearted for about 80% of the instruction steps, but keep jokes short and concise.
             Each instruction should be wrapped in _italic text_ using underscores (e.g., "_Preheat your oven to 350°F._").
             Each instruction step should provide enough detail (heat, technique, cues) but remain concise.

             Assume the user initially had these ingredients available (for context, but list only the ones NEEDED for THIS recipe): \(ingredientList)

             Output Format Example:
             INGREDIENTS:
             Ingredient A: Quantity A
             Ingredient B: Quantity B

             INSTRUCTIONS:
             1. _Funny, concise instruction step 1._
             2. _Clear, direct instruction step 2._
             3. _Another fun, brief step 3._
             ... (5-7 steps total)
             """
             
             let response = try await instructionModel.generateContent(instructionPrompt)
             
             if let responseText = response.text {
                 print("Received details response from Gemini: \(responseText)")
                 
                 // --- Parse BOTH Ingredients and Instructions --- 
                 var fetchedIngredients: [Ingredient] = []
                 var fetchedInstructions: [String] = []
                 var currentlyParsing: String? = nil // Tracks if we are parsing "INGREDIENTS" or "INSTRUCTIONS"
                 
                 let lines = responseText.split(separator: "\n").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                 
                 for line in lines {
                     if line.uppercased().hasPrefix("INGREDIENTS:") {
                         currentlyParsing = "INGREDIENTS"
                         continue // Skip the heading line
                     } else if line.uppercased().hasPrefix("INSTRUCTIONS:") {
                         currentlyParsing = "INSTRUCTIONS"
                         continue // Skip the heading line
                     }
                     
                     guard let section = currentlyParsing else { continue } // Skip lines before the first heading
                     
                     if section == "INGREDIENTS" {
                         if !line.isEmpty {
                             // Simple split logic (can be refined if format is complex)
                             let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
                             let name = parts.first ?? ""
                             let quantity = parts.count > 1 ? String(parts[1]) : "" // Handle missing quantity
                             if !name.isEmpty {
                                 // Note: isMissing logic might need adjustment based on how we handle inventory later
                                 fetchedIngredients.append(Ingredient(name: String(name), quantity: quantity, isMissing: false)) 
                             }
                         }
                     } else if section == "INSTRUCTIONS" {
                         if !line.isEmpty {
                             // Remove leading numbers/periods if present
                             let instructionText: String // Declare type explicitly
                             if let range = line.range(of: "^\\d+[.\\)]\\s*", options: .regularExpression) {
                                 instructionText = String(line[range.upperBound...])
                             } else {
                                 instructionText = String(line)
                             }
                             if !instructionText.isEmpty { // Add check if removing number resulted in empty string
                                 // Preserve the instruction text with the underscore formatting
                                 fetchedInstructions.append(instructionText)
                             }
                         }
                     }
                 }
                 
                 // --- Update Recipe Details --- 
                 if !fetchedIngredients.isEmpty {
                     details.ingredients = fetchedIngredients
                     print("Successfully parsed \(fetchedIngredients.count) specific ingredients.")
                 } else {
                     print("Warning: Could not parse specific ingredients. Keeping detected ingredients.")
                     // Keep default/detected ingredients as fallback? Or show error?
                     // details.ingredients = [Ingredient(name: "Failed to load ingredients", quantity: "", isMissing: true)] 
                 }
                 
                 if !fetchedInstructions.isEmpty {
                     details.instructions = fetchedInstructions
                     print("Successfully parsed \(fetchedInstructions.count) instructions.")
                 } else {
                     print("Warning: Could not parse instructions. Using placeholders.")
                     details.instructions = ["Failed to load instructions. Please try again later."]
                 }
                 
             } else {
                 print("Error: No text response received from Gemini for recipe details.")
                 details.ingredients = [Ingredient(name: "Could not fetch ingredients", quantity: "", isMissing: true)] 
                 details.instructions = ["Could not fetch instructions."]
             }
             
         } catch {
             print("Error fetching instructions from Gemini: \(error.localizedDescription)")
             details.ingredients = [Ingredient(name: "Error loading ingredients", quantity: "", isMissing: true)]
             details.instructions = ["Error loading instructions: \(error.localizedDescription)"]
         }
         
         // 4. Return the populated details
         // No need for simulated delay anymore unless debugging
         // try? await Task.sleep(nanoseconds: 500_000_000) 
         return details
     }
}

// APIKeyLoader is now defined in Utils/APIKeyLoader.swift

// --- API Key Loader (Keep for vision model config for now) ---
// Placeholder struct for loading API keys (Replace with your secure method)
// struct APIKeyLoader {
//     static func loadAPIKey() throws -> String {
//         // IMPORTANT: Replace this with secure key loading (e.g., from plist, obfuscation)
//         // DO NOT HARDCODE YOUR KEY HERE IN PRODUCTION
//         guard let path = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist"),
//               let data = FileManager.default.contents(atPath: path),
//               let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
//               let key = dict["API_KEY"] else {
//             throw NSError(domain: "APIKeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key not found in GenerativeAI-Info.plist"])
//         }
//         return key
//     }
// } 