import UIKit
import SwiftUI
import Supabase

// No @UIApplicationMain needed when using @main in SwiftUI App lifecycle
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("AppDelegate: didFinishLaunchingWithOptions")
        return true
    }

    // Handle incoming URLs (like Supabase auth callbacks)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // --- AGGRESSIVE LOGGING: Check if this method is EVER called --- 
        print("!!! AppDelegate application(_:open:options:) ENTERED !!! URL: \(url.absoluteString)")
        // -------------------------------------------------------------
        
        print("\n--- AppDelegate handling URL: \(url) ---")
        
        // Check if the URL is the Supabase callback
        // Using hasPrefix for flexibility with potential fragments (#)
        if url.absoluteString.hasPrefix("sous://callback") {
            print("URL is Supabase callback, attempting to process...")
            // Process the URL asynchronously using the Supabase client
            Task {
                print("AppDelegate: Entered Task to process URL.") // Log Task entry
                do {
                    try await supabase.auth.session(from: url)
                    print("AppDelegate: Successfully processed Supabase auth URL.")
                } catch {
                    print("AppDelegate: Error processing Supabase auth URL: \(error.localizedDescription)")
                    print("Error details: \(error)")
                }
                print("AppDelegate: Exiting Task for URL processing.") // Log Task exit
            }
            return true // Indicate we handled the URL
        } else {
            print("URL scheme [\(url.scheme ?? "nil")] or host [\(url.host ?? "nil")] not handled by AppDelegate.")
            return false // Let other handlers (like .onOpenURL) try if needed
        }
    }
    
    // MARK: UISceneSession Lifecycle (Optional but good practice)

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }
} 