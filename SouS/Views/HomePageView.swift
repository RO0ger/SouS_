import SwiftUI

struct HomePageView: View {
    @EnvironmentObject var authManager: AuthManager
    // Binding passed down from the parent (AppTabView -> SouSApp)
    @Binding var showCameraFlow: Bool
    
    // State variable to hold fetched inspiration items
    @State private var fetchedInspirationItems: [HomepageInspiration] = []

    // State for programmatic navigation
    @Binding var selectedInspiration: HomepageInspiration?
    
    var body: some View {
        // ZStack might no longer be needed if its only purpose was the hidden NavigationLink.
        // We are applying .navigationDestination as a modifier now.
        if #available(iOS 17.0, *) {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Text("Hey \(authManager.userName ?? "there"),\nlet's find your next meal.")
                        .font(.largeTitle).bold()
                        .padding(.top)
                    
                    VStack(alignment: .leading) {
                        Text("Start with some inspiration")
                            .font(.title2).bold()
                        
                        if fetchedInspirationItems.isEmpty {
                            ProgressView()
                                .frame(height: 150)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(fetchedInspirationItems) { item in
                                        Button {
                                            print("Card Tapped: \(item.title)")
                                            self.selectedInspiration = item
                                        } label: {
                                            InspirationCardView(item: item)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("What would you like to do today?")
                            .font(.title3).bold()
                            .padding(.bottom, 5)
                        
                        Button {
                            print("Scan my fridge tapped - setting showCameraFlow = true")
                            showCameraFlow = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                Text("Scan my fridge")
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .onAppear {
                // Fetch data when the view appears
                Task {
                    await loadInspirationItems()
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    // Function to load inspiration items
    private func loadInspirationItems() async {
        do {
            let items = try await SupabaseManager.shared.fetchHomepageInspirations()
            // Update on the main thread
            DispatchQueue.main.async {
                self.fetchedInspirationItems = items
                print("Successfully fetched and updated \(items.count) inspiration items.")
            }
        } catch {
            // Handle errors, e.g., show an alert to the user
            print("Error fetching inspiration items: \(error.localizedDescription)")
            // Optionally, you could set an error state here to display a message in the UI
        }
    }
}

// --- Inspiration Card Subview ---
// It now uses HomepageInspiration
struct InspirationCardView: View {
    let item: HomepageInspiration
    
    var body: some View {
        VStack(alignment: .leading) {
            // Image(systemName: item.imageName) // Temporarily removed for diagnostics - Restoring this if needed after click works
            //     .resizable()
            //     .aspectRatio(contentMode: .fit)
            //     .frame(height: 100)
            //     .frame(maxWidth: .infinity)
            //     .clipped()
            //     .padding(.bottom, 5)
            
            Text(item.title)
                .font(.headline)
                .padding(.top, 5) // Add some padding if image is removed
            
            HStack {
                Image(systemName: "clock") // This small image should be fine
                Text(item.duration)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        // .frame(width: 180, height: 120) // Removing fixed height, let content decide or set by parent
        .frame(width: 180) // Keep original width constraint
        .contentShape(Rectangle()) 
    }
}

#Preview {
    // Wrap the HomePageView in a NavigationView for the preview to test navigation
    NavigationView {
        HomePageView(showCameraFlow: .constant(false), selectedInspiration: .constant(nil))
            .environmentObject(AuthManager())
    }
}

// MARK: - REMOVE Redundant Definitions
// These are no longer needed as the struct and data are removed or fetched.
/*
extension HomePageView {
    // ... removed duplicated struct and static data ...
}
*/

/*
struct InspirationCardView_Preview: View {
    // ... removed ...
}
*/ 
