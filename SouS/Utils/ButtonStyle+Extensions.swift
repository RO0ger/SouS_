import SwiftUI

// Style for primary action buttons (Solid Blue)
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity) // Make button wide
            .background(Color.primaryBlue) // Use custom blue
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0) // Subtle press effect
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

// Style for secondary/back buttons (Bordered Blue)
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.primaryBlue) // Use custom blue for text
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primaryBlue, lineWidth: 1) // Blue border
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

// Convenience extensions for easy application
extension Button {
    func primaryStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
} 