import SwiftUI
import Supabase
// import Combine // Combine is no longer needed directly here

@MainActor // Ensure UI updates happen on the main thread
class AuthManager: ObservableObject {
    // Published properties will trigger UI updates when they change
    @Published var session: Session?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isOnboardingCompleted: Bool? = nil // nil = unknown, true/false when checked
    @Published var userName: String? = nil // Store fetched user name

    // Store the Task handle to manage cancellation
    private var authListenerTask: Task<Void, Never>? = nil

    init() {
        self.session = supabase.auth.currentSession
        // Start listening on initialization
        startAuthStateListener()
        
        // Initial check if session exists
        if let currentSession = session {
            Task {
                await checkOnboardingStatus(for: currentSession.user.id)
            }
        }
    }
    
    // Clean up listener task on deinitialization
    deinit {
        authListenerTask?.cancel()
    }

    // Function to start the listener Task
    private func startAuthStateListener() {
        // Cancel any existing listener first
        authListenerTask?.cancel()
        
        print("\n--- STARTING AUTH STATE LISTENER ---")
        print("Current session exists: \(session != nil)")
        if let currentSession = session {
            print("User ID: \(currentSession.user.id)")
            print("Email: \(currentSession.user.email ?? "unknown")")
            print("Is email confirmed: \(currentSession.user.emailConfirmedAt != nil)")
        }
        print("Onboarding status: \(String(describing: isOnboardingCompleted))")
        
        authListenerTask = Task {
            // Loop indefinitely over the auth state changes stream
            for await (event, session) in supabase.auth.authStateChanges {
                // Ensure task hasn't been cancelled
                guard !Task.isCancelled else { break }
                
                // Print detailed event information
                print("\n=== AUTH STATE CHANGE EVENT: \(event) ===")
                print("Session: \(session == nil ? "nil" : "active")")
                if let session = session {
                    print("User ID: \(session.user.id)")
                    print("Email: \(session.user.email ?? "unknown")")
                    print("Email Confirmed At: \(session.user.emailConfirmedAt?.description ?? "not confirmed")")
                }
                
                // Update session on main actor
                await MainActor.run {
                    self.session = session
                    print("Updated session on MainActor: \(self.session == nil ? "nil" : "active")")
                    
                    // --- TEMPORARY DEBUG: Print Access Token ---
                    if let token = session?.accessToken {
                        print("\n--- USER ACCESS TOKEN ---")
                        print(token)
                        print("--- END USER ACCESS TOKEN ---\n")
                    }
                    // -------------------------------------------
                }

                // Handle logic based on event
                if event == .signedIn || event == .initialSession, let user = session?.user {
                    print("Handling signedIn/initialSession event for user: \(user.id)")
                    // Check status and fetch name (these methods are already @MainActor)
                    await self.checkOnboardingStatus(for: user.id)
                    print("After checkOnboardingStatus, isOnboardingCompleted = \(String(describing: self.isOnboardingCompleted))")
                    print("Event \(event) processing completed")
                } else if event == .signedOut {
                    print("Handling signedOut event")
                    // Clear status and name on main actor
                    await MainActor.run {
                        self.isOnboardingCompleted = nil
                        self.userName = nil
                        print("Cleared onboarding status and username")
                    }
                } else if event == .userUpdated, let user = session?.user {
                    // Add explicit handling for userUpdated event
                    print("Handling userUpdated event for user: \(user.id)")
                    print("Email confirmation status changed: \(user.emailConfirmedAt != nil)")
                    // Re-check onboarding status on user update (email verification)
                    await self.checkOnboardingStatus(for: user.id)
                    print("After userUpdated checkOnboardingStatus, isOnboardingCompleted = \(String(describing: self.isOnboardingCompleted))")
                }
                print("=== END EVENT PROCESSING ===\n")
            }
            print("Auth listener task finished.")
        }
    }

    // --- Authentication Methods ---

    // Renamed from signIn to match call from LoginView
    func signInWithEmailPassword(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        isOnboardingCompleted = nil // Reset status before checking
        do {
            let sessionResponse = try await supabase.auth.signIn(email: email, password: password)
            // Session will be set by authStateChanges listener
            print("Sign in successful for user: \(sessionResponse.user.id)")
            // Check onboarding status immediately after successful sign in
            // await checkOnboardingStatus(for: sessionResponse.user.id)
            // ^ No longer needed here, listener handles it
        } catch {
            print("Error signing in: \(error.localizedDescription)")
            errorMessage = error.localizedDescription // Display error to the user
            isLoading = false // Ensure loading stops on error
        }
        // isLoading will be set to false by the listener or after checkOnboardingStatus
        // isLoading = false // Removed from here
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        isOnboardingCompleted = nil // Reset status before checking
        do {
            // Note: Supabase signUp automatically signs the user in on success
            let sessionResponse = try await supabase.auth.signUp(
                email: email, 
                password: password
            )
            // Session will be set by authStateChanges listener
            print("Sign up successful, session created for user: \(sessionResponse.user.id)")
            
            // IMPORTANT: After sign up, a profile likely doesn't exist yet.
            // The onboarding flow should be responsible for creating it.
            // We assume `isOnboardingCompleted` will remain `false` (or default `nil`)
            // until the onboarding flow explicitly sets it to true in the DB.
            // await checkOnboardingStatus(for: sessionResponse.user.id)
            // ^ No longer needed here, listener handles it
        } catch {
            print("Error signing up: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false // Ensure loading stops on error
        }
       // isLoading = false // Removed from here
    }
    
    // --- Sign in with Google (OAuth) ---
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        isOnboardingCompleted = nil // Reset status before checking
        
        // Get the top-most presenting UIViewController (Might not be needed for Google)
        // guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        //       let topViewController = windowScene.windows.first?.rootViewController
        // else {
        //     errorMessage = "Could not get root view controller for OAuth."
        //     print(errorMessage!)
        //     isLoading = false
        //     return
        // }
        
        do {
            // Perform the OAuth sign-in for Google (removed presenting argument)
            try await supabase.auth.signInWithOAuth(provider: Provider.google)
            // The auth state listener will handle the session update and subsequent checks
            print("Initiated Google OAuth sign-in.")
            // isLoading will be handled by the listener flow
        } catch {
            print("Error initiating Google OAuth: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false // Ensure loading stops on error
        }
    }
    
    // --- Onboarding Status Check ---
    func checkOnboardingStatus(for userId: UUID) async {
        print("\n>>> CHECKING ONBOARDING STATUS <<<")
        print("User ID: \(userId)")
        print("Starting isLoading = true")
        isLoading = true 
        do {
            print("Querying 'user_profiles' table for user ID: \(userId)")
            // Fetch and decode using the .value property after execute()
            // Explicitly select the column we need, plus any others used later (like user_name if fetchUserName isn't called separately)
            // For now, just ensuring onboarding_completed is selected.
            let profiles: [UserProfile] = try await supabase
                .from("user_profiles")
                .select("id, onboarding_completed, user_name") 
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value // Decode using the value property

            print("Query completed. Found \(profiles.count) profiles")
            let profile: UserProfile? = profiles.first // Get the first profile if it exists
            
            // --- Add More Debugging ---
            if let profile = profile {
                print("Raw profile.onboardingCompleted value from DB: \(String(describing: profile.onboardingCompleted))")
                print("Raw profile.userName value from DB: \(String(describing: profile.userName))") // Also check username fetch
            } else {
                print("No profile found in database for this user.")
            }
            // --------------------------

            // Set status based on the fetched profile data
            let status = profile?.onboardingCompleted ?? false 
            print("Value being assigned to self.isOnboardingCompleted: \(status)") // <-- Debug this value
            self.isOnboardingCompleted = status
            self.userName = profile?.userName // <-- SET USERNAME HERE
            print("Value being assigned to self.userName: \(String(describing: self.userName))")
             
        } catch {
             print("Error checking onboarding status: \(error.localizedDescription)")
             print("Error details: \(error)")
             self.isOnboardingCompleted = false 
             self.errorMessage = "Could not verify profile status." 
             print("Setting isOnboardingCompleted = false due to error")
         }
        isLoading = false
        print("Set isLoading = false")
        print(">>> ONBOARDING STATUS CHECK COMPLETE <<<\n")
    }

    // --- Add function to manually mark onboarding as complete ---
    // Needs to be @MainActor because it updates a @Published property
    @MainActor 
    func markOnboardingComplete() {
        print("Marking onboarding as complete locally.")
        self.isOnboardingCompleted = true
        // Optionally, trigger fetchUserName immediately if needed
        // if let userId = session?.user.id {
        //     Task { await fetchUserName(for: userId) } 
        // }
    }

    // --- Fetch User Name --- 
    func fetchUserName(for userId: UUID) async {
        // If username is already populated (e.g., by checkOnboardingStatus), don't re-fetch or overwrite.
        guard self.userName == nil else {
            print("AuthManager.fetchUserName: userName already populated ('\\(self.userName ?? ",unknown,")'), skipping redundant fetch.")
            return
        }
        print("Fetching user name for user: \\(userId) via fetchUserName (because self.userName was nil)")

        do {
            // Use the select statement known to work from checkOnboardingStatus
            let profiles: [UserProfile] = try await supabase
                .from("user_profiles")
                .select("id, user_name, onboarding_completed") // Match select from checkOnboardingStatus
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value

            let profile: UserProfile? = profiles.first
            self.userName = profile?.userName // Set it
            print("User name fetched via fetchUserName: \\(self.userName ?? "Not Found")")
             
        } catch {
             print("Error fetching user name in fetchUserName: \\(error.localizedDescription)")
             // self.userName remains nil if it was nil at the start of this function and an error occurred
         }
    }

    func signOut() async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.auth.signOut()
            // Session and isOnboardingCompleted will be cleared by the listener
            print("Sign out successful")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // --- Helper ---
    var isLoggedIn: Bool {
        session != nil
    }
} 
