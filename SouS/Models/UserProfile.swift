import Foundation
import SwiftUI // Needed for OnboardingViewModel enums

// Define UserProfile struct matching Supabase table
// This is the single source of truth.
struct UserProfile: Codable, Identifiable { // Added Identifiable
    let id: UUID
    var onboardingCompleted: Bool? // Needs to be var if updated separately
    var userName: String?
    var sex: String? // Consider enum mapping if DB uses specific values like 'male', 'female'
    var age: Int?
    var locationCountry: String?
    var locationPostalCode: String?
    // Store weights consistently, e.g., always in kg
    var currentWeightKg: Double?
    var targetWeightKg: Double?
    // var timelineMonths: Int? // REMOVE: Column doesn't exist in DB
    // Store enums directly - Codable will use their rawValue (String)
    var activityLevel: OnboardingViewModel.ActivityLevel? 
    // CHANGE: Match DB array type
    var dietaryPreferences: [String]? 
    // var proteinTargetAdjustment: Int? // REMOVE: Column doesn't exist in DB
    var goal: String? // Add goal (e.g., "gain_weight", "lose_weight")
    var targetDate: Date? // ADD: Store the calculated target date
    // Add other fields ONLY IF THEY EXIST in your Supabase table AND are needed
    // var createdAt: Date? // Example
    // var updatedAt: Date? // Example
    
    // Match database column names EXACTLY
    enum CodingKeys: String, CodingKey {
        case id
        case onboardingCompleted = "onboarding_completed"
        case userName = "user_name"
        case sex
        case age
        case locationCountry = "location_country"
        case locationPostalCode = "location_postal_code"
        // CHANGE: Map Swift property to correct DB column name
        case currentWeightKg = "current_weight"
        // CHANGE: Map Swift property to correct DB column name
        case targetWeightKg = "target_weight"
        // case timelineMonths = "timeline_months" // REMOVE: Column doesn't exist
        case activityLevel = "activity_level"
        // CHANGE: Match DB property name and type ([String])
        case dietaryPreferences = "dietary_preferences"
        // case proteinTargetAdjustment = "protein_target_adjustment" // REMOVE: Column doesn't exist
        case goal
        case targetDate = "target_date" // ADD: Coding key for target_date
        // Add keys for other DB columns if you add the properties above
        // case createdAt = "created_at"
        // case updatedAt = "updated_at"
    }
} 