//
//  SouSApp.swift
//  SouS
//
//  Created by Nasif Jawad
//

import SwiftUI
import Supabase

// Helper to load from Secrets.plist
func loadSecret(key: String) -> String? {
    guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
        // It's crucial to know if Secrets.plist is missing or unreadable.
        print("CRITICAL ERROR: Secrets.plist not found or is invalid. App may not function correctly.")
        return nil
    }
    if dict[key] == nil {
        print("CRITICAL ERROR: Key '\(key)' not found in Secrets.plist. App may not function correctly.")
    }
    return dict[key] as? String
}

// Global Supabase client
let supabase: SupabaseClient = {
    // Hardcoded values for Supabase URL and Anon Key
    let supabaseURLString = "https://qlsmjxydtadtotfururr.supabase.co"
    let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsc21qeHlkdGFkdG90ZnVydXJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQxODkzOTIsImV4cCI6MjA1OTc2NTM5Mn0.t7SR9gZXmCkh0EhEYSpZ_tfZ8nly0OgajcsqeN7ErrM"
    
    guard let supabaseURL = URL(string: supabaseURLString) else {
        fatalError("Invalid Supabase URL. Unable to initialize Supabase client.")
    }
    
    return SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseAnonKey)
}()

@main
struct SouSApp: App {
    // AppDelegate for handling deep links, etc.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Initialize AuthManager as a StateObject
    @StateObject var authManager = AuthManager()
    
    // Initialize other view models that might be needed globally
    @StateObject var onboardingViewModel = OnboardingViewModel()
    // Use a placeholder UIImage for RecipeFinderViewModel until a real image is selected
    @StateObject var recipeFinderViewModel = RecipeFinderViewModel(inputImage: UIImage(systemName: "photo") ?? UIImage())
    @StateObject var ingredientViewModel = IngredientViewModel()
    
    // State variables for navigation and data flow
    @State private var showCameraFlow = false
    @State private var selectedInspiration: HomepageInspiration? = nil
    @State private var selectedImage: UIImage? = nil

    var body: some Scene {
        WindowGroup {
            AppFlowCoordinator()
                .environmentObject(authManager)
                .environmentObject(onboardingViewModel)
                .environmentObject(recipeFinderViewModel)
                .environmentObject(ingredientViewModel)
        }
    }
}

// App Flow Coordinator to handle navigation based on auth state
struct AppFlowCoordinator: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showCameraFlow = false
    @State private var selectedInspiration: HomepageInspiration? = nil
    @State private var selectedImage: UIImage? = UIImage(systemName: "photo")
    
    var body: some View {
        Group {
            if authManager.isLoading {
                // Show loading screen while checking auth state
                LoadingView()
            } else if !authManager.isLoggedIn {
                // User is not logged in, show auth flow
                AuthenticationView()
            } else if authManager.isOnboardingCompleted != true {
                // User is logged in but hasn't completed onboarding
                OnboardingView()
            } else {
                // User is logged in and has completed onboarding
                MainAppTabView(showCameraFlow: $showCameraFlow, 
                              selectedInspiration: $selectedInspiration,
                              selectedImage: $selectedImage)
            }
        }
    }
}

// Simple loading view
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
        }
    }
}

// Main app tab view for camera, recipes, and profile
struct MainAppTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showCameraFlow: Bool
    @Binding var selectedInspiration: HomepageInspiration?
    @Binding var selectedImage: UIImage?
    
    // Add state for selected tab
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Changed to NavigationStack
            NavigationStack {
                HomePageView(showCameraFlow: $showCameraFlow, selectedInspiration: $selectedInspiration)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)
            
            // Camera/Food Detection Tab - Changed to NavigationStack
            NavigationStack {
                ImageSelectionView(onDismiss: {
                    // Go back to home tab when X is pressed
                    selectedTab = 0
                })
            }
            .tabItem {
                Label("Camera", systemImage: "camera")
            }
            .tag(1)
            
            // Profile Tab
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(2)
        }
        // Listen for showCameraFlow changes to switch to camera tab
        .onChange(of: showCameraFlow) { newValue in
            if newValue {
                selectedTab = 1
                showCameraFlow = false
            }
        }
    }
} 
