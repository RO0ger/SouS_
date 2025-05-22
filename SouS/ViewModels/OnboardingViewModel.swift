import Foundation
import SwiftUI // Import SwiftUI for @Published
import Supabase // Import Supabase

// Define UserProfile struct matching Supabase table (assuming it doesn't exist elsewhere)
// This should match the columns in your 'user_profiles' table
// struct UserProfile: Codable { // REMOVE THIS DEFINITION
//     let id: UUID
//     var onboardingCompleted: Bool? // Needs to be var if updated separately
//     var userName: String?
//     var sex: String? // Consider enum mapping if DB uses specific values like 'male', 'female'
//     var age: Int?
//     var locationCountry: String?
//     var locationPostalCode: String?
//     // Store weights consistently, e.g., always in kg
//     var currentWeightKg: Double?
//     var targetWeightKg: Double?
//     var timelineMonths: Int? // Store timeline as Int
//     var activityLevel: OnboardingViewModel.ActivityLevel? // Assumes ActivityLevel is Codable
//     var dietPreference: OnboardingViewModel.DietPreference? // Assumes DietPreference is Codable
//     var proteinTargetAdjustment: Int? // Store the rounded adjustment
//     var goal: String? // Add goal (e.g., "gain_weight", "lose_weight")
//     // Add other fields as needed, matching your Supabase table
    
//     // Match database column names if different (e.g., using CodingKeys)
//     enum CodingKeys: String, CodingKey {
//         case id
//         case onboardingCompleted = "onboarding_completed" // Example if DB uses snake_case
//         case userName = "user_name"
//         case sex
//         case age
//         case locationCountry = "location_country"
//         case locationPostalCode = "location_postal_code"
//         case currentWeightKg = "current_weight_kg"
//         case targetWeightKg = "target_weight_kg"
//         case timelineMonths = "timeline_months"
//         case activityLevel = "activity_level"
//         case dietPreference = "diet_preference"
//         case proteinTargetAdjustment = "protein_target_adjustment"
//         case goal
//     }
// }

// ViewModel to manage the state during the multi-step onboarding process
@MainActor // Apply MainActor at the class level
class OnboardingViewModel: ObservableObject {
    
    // Step tracking
    @Published var currentStep: Int = 1
    let totalSteps = 5 // Updated total steps
    
    // --- Step 0: Personal Info ---
    @Published var userName: String = ""
    @Published var sex: String = "" // Consider using an Enum for better type safety
    @Published var age: Int? = nil { // Use optional Int
        didSet {
            // Clamp age between 1 and 100
            if let currentAge = age {
                if currentAge < 1 {
                    // Setting back to nil allows the TextField to become empty if user deletes input or types 0
                    // If you prefer to force it to 1, uncomment the next line
                     age = nil 
                    // age = 1 
                } else if currentAge > 100 {
                    age = 100
                }
            }
        }
    }
    @Published var locationCountry: String = ""
    @Published var locationPostalCode: String = ""
    // Add potential options for Sex if using Picker
    let sexOptions = ["Male", "Female", "Other", "Prefer Not To Say"]
    
    // Step 1: Weight Goals
    // Add a boolean state for the toggle
    @Published var unitIsKg: Bool = true
    
    // Make selectedUnit a computed property based on the toggle state
    var selectedUnit: WeightUnit {
        unitIsKg ? .kg : .lbs
    }
    
    enum WeightUnit: String, CaseIterable, Identifiable {
        case kg, lbs
        var id: String { self.rawValue }
    }
    @Published var currentWeight: Double = 70
    @Published var targetWeight: Double = 77
    // Define reasonable min/max for sliders based on units
    var minWeightKg: Double = 40
    var maxWeightKg: Double = 150
    var minWeightLbs: Double { minWeightKg * 2.20462 }
    var maxWeightLbs: Double { maxWeightKg * 2.20462 }
    
    // Step 2: Journey / Activity
    enum ActivityLevel: String, CaseIterable, Identifiable, Codable {
        case startingOut = "Just Starting Out"
        case regular = "Regular Gym-Goer"
        case enthusiast = "Fitness Enthusiast"
        var id: String { self.rawValue }
        
        var description: String {
            switch self {
            case .startingOut: return "Little to no regular exercise"
            case .regular: return "Exercise 3-5 times per week"
            case .enthusiast: return "Daily exercise or intense training"
            }
        }
    }
    @Published var timeline: Double = 6 // In months
    @Published var activityLevel: ActivityLevel = .startingOut
    
    // Step 3: Diet Plan
    enum DietPreference: String, CaseIterable, Identifiable, Codable {
        case omnivore = "Omnivore"
        case vegetarian = "Vegetarian"
        case vegan = "Vegan"
        case pescatarian = "Pescatarian"
        case ketogenic = "Ketogenic"
        case paleo = "Paleo"
        var id: String { self.rawValue }
        
        // Add descriptions if needed, similar to ActivityLevel
    }
    @Published var dietPreference: DietPreference = .omnivore
    
    // --- Step 4: Protein Plan ---
    // Placeholder for target adjustment slider (Raw value)
    @Published var proteinTargetAdjustmentRaw: Double = 0
    let proteinAdjustmentRange: ClosedRange<Double> = -20...20
    
    // Computed property to get the adjustment rounded to nearest 5
    var proteinTargetAdjustmentRounded: Int {
        Int((proteinTargetAdjustmentRaw / 5.0).rounded() * 5.0)
    }
    
    // Placeholder calculation for base protein target (grams)
    // In a real app, this would use weight, activity, goals etc.
    var calculatedBaseProteinTarget: Double {
        let baseMultiplier = 1.6 // Example g/kg
        let weightInKg = unitIsKg ? currentWeight : currentWeight / 2.20462
        // Add simple multipliers for activity - VERY basic example
        let activityMultiplier: Double
        switch activityLevel {
        case .startingOut: activityMultiplier = 1.0
        case .regular: activityMultiplier = 1.1
        case .enthusiast: activityMultiplier = 1.2
        }
        return (weightInKg * baseMultiplier * activityMultiplier).rounded()
    }
    
    // Final target including user adjustment (using rounded adjustment)
    var adjustedProteinTarget: Double {
        (calculatedBaseProteinTarget + Double(proteinTargetAdjustmentRounded)).rounded()
    }
    
    // Calculate target date based on selected timeline
    var targetDate: Date {
        Calendar.current.date(byAdding: .month, value: Int(timeline), to: Date()) ?? Date()
    }
    
    // Simple struct to hold the calculated split
    struct CalculatedMealProtein {
        let breakfast: Int
        let lunch: Int
        let dinner: Int
    }
    
    // Computed property for basic protein split calculation
    var calculatedProteinSplit: CalculatedMealProtein {
        let target = adjustedProteinTarget
        // Basic split example: 30% Breakfast, 40% Lunch, 30% Dinner
        let breakfastProtein = Int((target * 0.30).rounded())
        let lunchProtein = Int((target * 0.40).rounded())
        // Calculate dinner as the remainder to ensure sum matches target closely
        let dinnerProtein = Int(target) - breakfastProtein - lunchProtein 
        
        // Ensure dinner isn't negative if rounding causes issues
        let finalDinnerProtein = max(0, dinnerProtein)
        
        return CalculatedMealProtein(breakfast: breakfastProtein, lunch: lunchProtein, dinner: finalDinnerProtein)
    }
    
    // --- Summary Screen Data ---
    
    // Calculate weight difference for the summary
    var targetWeightDifference: Double {
        targetWeight - currentWeight
    }
    
    // Placeholder for Daily Calories calculation
    var estimatedDailyCalories: Int {
        // Very rough estimate - often based on BMR * Activity Level + Goal
        // Using protein target as a proxy for now
        Int(adjustedProteinTarget * 25) // Example: 25 kcal per gram of protein target
    }
    
    // Placeholder for Daily Carbs calculation
    var estimatedDailyCarbs: Int {
        // Example: Assume 40-50% of calories from carbs (1g carb = 4 kcal)
        Int((Double(estimatedDailyCalories) * 0.45) / 4.0)
    }
    
    // Placeholder for Daily Fats calculation
    var estimatedDailyFats: Int {
        // Example: Remainder from protein (4 kcal/g) and carbs (4 kcal/g), assuming 1g fat = 9 kcal
        let proteinCalories = adjustedProteinTarget * 4.0
        let carbCalories = Double(estimatedDailyCarbs) * 4.0
        let fatCalories = Double(estimatedDailyCalories) - proteinCalories - carbCalories
        return max(0, Int(fatCalories / 9.0)) // Ensure non-negative
    }
    
    // --- State for Saving Profile ---
    @Published var isSaving: Bool = false
    @Published var saveError: String? = nil
    
    // --- Methods ---
    
    func nextStep() {
        if currentStep < totalSteps {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    // Helper to get min/max weight based on selected unit
    var currentWeightRange: ClosedRange<Double> {
        selectedUnit == .kg ? (minWeightKg...maxWeightKg) : (minWeightLbs...maxWeightLbs)
    }
    
    var targetWeightRange: ClosedRange<Double> {
        selectedUnit == .kg ? (minWeightKg...maxWeightKg) : (minWeightLbs...maxWeightLbs)
    }
    
    // --- Save User Profile ---
    // @MainActor // No longer needed here if class is MainActor
    func saveUserProfile(authManager: AuthManager) async {
        guard let userId = authManager.session?.user.id else {
            self.saveError = "User session not found. Cannot save profile."
            print(saveError!)
            // Ensure isSaving is false on early return
            self.isSaving = false
            return
        }

        print("Attempting to save profile for user ID: \(userId)")
        self.isSaving = true
        self.saveError = nil

        // Convert weights to KG for storage consistency
        let currentWeightInKg = unitIsKg ? currentWeight : currentWeight / 2.20462
        let targetWeightInKg = unitIsKg ? targetWeight : targetWeight / 2.20462
        
        // Determine the goal based on weight difference
        let goal: String
        if targetWeightInKg > currentWeightInKg + 0.1 { // Add small tolerance for float comparison
             goal = "gain_weight"
         } else if targetWeightInKg < currentWeightInKg - 0.1 {
             goal = "lose_weight"
         } else {
             goal = "maintain_weight"
         }
         
        // --- Map UI Sex value to DB allowed values (adjust based on your DB constraints) ---
        let sexForDatabase: String?
        switch self.sex {
        case "Male":
            sexForDatabase = "male"
        case "Female":
            sexForDatabase = "female"
        case "Prefer Not To Say":
            sexForDatabase = "prefer_not_to_say" // Assuming DB allows this snake_case value
        // Handle "Other" or empty selection - map to nil or a specific DB value if allowed
        default:
            sexForDatabase = nil 
        }

        // Create the UserProfile object to be saved
        let userProfile = UserProfile(
            id: userId,
            onboardingCompleted: true, // Mark onboarding as done
            userName: self.userName.isEmpty ? nil : self.userName,
            sex: sexForDatabase,
            age: self.age, // Use optional age directly
            locationCountry: self.locationCountry.isEmpty ? nil : self.locationCountry,
            locationPostalCode: self.locationPostalCode.isEmpty ? nil : self.locationPostalCode,
            currentWeightKg: currentWeightInKg.rounded(toPlaces: 1), // Round for consistency
            targetWeightKg: targetWeightInKg.rounded(toPlaces: 1),
            activityLevel: self.activityLevel, // Assumes ActivityLevel is Codable
            dietaryPreferences: [self.dietPreference.rawValue], 
            goal: goal,
            targetDate: self.targetDate // Include targetDate in saved profile
        )
        
        print("Profile object created: \(userProfile)")

        do {
            print("Executing upsert operation...")
            // Use upsert to insert or update the profile based on the user ID (primary key)
            try await supabase
                .from("user_profiles") // Ensure this table name is correct
                .upsert(userProfile) // Pass the Codable object directly
                .execute() // Execute the upsert

            print("Upsert successful!")
            // If successful, update the AuthManager state
            authManager.markOnboardingComplete() // Call the method to update AuthManager's state
            print("Called authManager.markOnboardingComplete()")
            self.isSaving = false // Set saving to false on success

        } catch {
            print("Error saving user profile: \(error.localizedDescription)")
            print("Error details: \(error)")
            self.saveError = "Failed to save profile. Please check your connection and try again. Details: \(error.localizedDescription)"
            self.isSaving = false // Ensure saving is false on error
        }
        print("saveUserProfile finished.")
    }
}

// Helper extension for rounding Doubles (optional, but useful)
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - REMOVE Omitted implementations added previously
/*
extension OnboardingViewModel {
    // Remove the duplicated placeholders added before
}

extension OnboardingViewModel.ActivityLevel {
   // Remove the duplicated description property added before
}
*/