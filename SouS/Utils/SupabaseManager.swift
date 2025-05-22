import Foundation
import Supabase

/// Manager class for Supabase operations
class SupabaseManager {
    static let shared = SupabaseManager()
    
    // Create a custom date formatter for "YYYY-MM-DD"
    private static let yyyyMMddFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // Create a custom JSON decoder
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // Use combined strategy: try ISO8601 first, then YYYY-MM-DD
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 format first (for timestamptz like updated_at)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Try YYYY-MM-DD format (for date like target_date)
            if let date = SupabaseManager.yyyyMMddFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, 
                                               debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }()
    
    private init() {}
    
    /// Fetch the current logged-in user's profile data from Supabase
    /// - Returns: The user profile if found, nil otherwise
    func fetchCurrentUserData() async throws -> UserProfile? {
        // Get the current user's ID from the auth session
        guard let session = supabase.auth.currentSession else {
            print("No active session found")
            return nil
        }
        
        let userId = session.user.id
        
        print("Fetching profile for user ID: \(userId) from table: user_profiles")
        
        // Fetch the raw response
        let response = try await supabase
            .from("user_profiles")
            .select() // Selects all columns by default if UserProfile matches
            .eq("id", value: userId)
            .execute()

        // Manually decode the raw data using the custom decoder
        do {
            let profiles = try self.decoder.decode([UserProfile].self, from: response.data)
            print("Found \(profiles.count) profile(s) for user ID: \(userId)")
            // Return the first profile found (should be only one)
            return profiles.first
        } catch let decodingError as DecodingError {
            // Print detailed decoding error information
            print("\n--- DETAILED DECODING ERROR ---")
            print("Error: \(decodingError.localizedDescription)")
            
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("Type Mismatch: \(type)")
                print("Context: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value Not Found: \(type)")
                print("Context: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("Key Not Found: \(key.stringValue)")
                print("Context: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("Data Corrupted")
                print("Context: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error: \(decodingError)")
            }
            print("-----------------------------\n")
            // Re-throw the original error to maintain the function's contract
            throw decodingError 
        } catch {
            // Catch any other non-decoding errors
            print("Non-decoding error during profile fetch: \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetch all homepage inspiration recipes from Supabase
    /// - Returns: An array of `HomepageInspiration` items.
    func fetchHomepageInspirations() async throws -> [HomepageInspiration] {
        print("Fetching homepage inspirations from table: homepage_inspirations")

        let response = try await supabase
            .from("homepage_inspirations")
            .select() // Selects all columns
            .order("created_at", ascending: true) // Optional: order by creation date
            .execute()

        do {
            let inspirations = try self.decoder.decode([HomepageInspiration].self, from: response.data)
            print("Fetched \(inspirations.count) homepage inspiration(s)")
            return inspirations
        } catch let decodingError as DecodingError {
            print("\n--- DETAILED DECODING ERROR (HomepageInspirations) ---")
            print("Error: \(decodingError.localizedDescription)")
            
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("Type Mismatch: \(type)")
                print("Context: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value Not Found: \(type)")
                print("Context: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("Key Not Found: \(key.stringValue)")
                print("Context: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("Data Corrupted")
                print("Context: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error: \(decodingError)")
            }
            print("----------------------------------------------------\n")
            throw decodingError
        } catch {
            print("Non-decoding error during homepage inspirations fetch: \(error.localizedDescription)")
            throw error
        }
    }
} 