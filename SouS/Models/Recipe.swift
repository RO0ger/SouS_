import Foundation

/// Represents a recipe with its details.
struct Recipe: Identifiable, Decodable {
    let id = UUID() // Keep for Identifiable, won't be decoded from JSON
    var name: String
    var imageURLString: String? // Expect String? from JSON for image URL
    var duration: String
    var servings: Int
    var isMealPrepFriendly: Bool
    var ingredients: [Ingredient] // Expect array of Ingredient objects
    var instructions: [String]

    // Convert imageURLString to URL when needed
    var imageURL: URL? {
        guard let urlString = imageURLString else { return nil }
        return URL(string: urlString)
    }

    // CodingKeys to map JSON keys to struct properties if needed, and exclude id
    enum CodingKeys: String, CodingKey {
        case name
        case imageURLString = "imageURL" // Map JSON key "imageURL" to property
        case duration
        case servings
        case isMealPrepFriendly
        case ingredients
        case instructions
        // `id` is not included, so it won't be decoded
    }

    // Add a dummy instance for previews
    static let previewData = Recipe(
        name: "Healthy Stir-Fry",
        imageURLString: nil, // Use the String? property here now
        duration: "25 mins",
        servings: 2,
        isMealPrepFriendly: true,
        ingredients: [
            Ingredient(name: "Chicken", quantity: "150g", isMissing: false), // isMissing is set locally
            Ingredient(name: "Mixed Vegetables", quantity: "300g", isMissing: false),
            Ingredient(name: "Brown Rice", quantity: "150g", isMissing: true),
            Ingredient(name: "Soy Sauce", quantity: "2 tbsp", isMissing: false)
        ],
        instructions: [
            "Cook brown rice according to package directions.",
            "While rice cooks, heat oil in a large skillet or wok over medium-high heat.",
            "Add chicken and stir-fry until cooked through, about 5-7 minutes.",
            "Add mixed vegetables and stir-fry for another 3-5 minutes until tender-crisp.",
            "Stir in soy sauce (and any other desired seasonings).",
            "Serve stir-fry mixture over cooked brown rice."
        ]
    )

    // Manual init required if you define CodingKeys and still want previewData init
    init(name: String, imageURLString: String?, duration: String, servings: Int, isMealPrepFriendly: Bool, ingredients: [Ingredient], instructions: [String]) {
        self.name = name
        self.imageURLString = imageURLString
        self.duration = duration
        self.servings = servings
        self.isMealPrepFriendly = isMealPrepFriendly
        self.ingredients = ingredients
        self.instructions = instructions
    }
}

/// Represents a single ingredient for a recipe.
struct Ingredient: Identifiable, Decodable {
    let id = UUID()
    var name: String
    var quantity: String
    var isMissing: Bool = false // Default to false, not decoded from JSON

    // Define coding keys to only decode 'name' and 'quantity'
    enum CodingKeys: String, CodingKey {
        case name
        case quantity
        // Exclude `id` and `isMissing` from decoding process
    }
    
    // Need a manual initializer if using CodingKeys and want `isMissing` default
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(String.self, forKey: .quantity)
        isMissing = false // Explicitly set default
    }
    
    // Need another init for preview data compatibility
    init(name: String, quantity: String, isMissing: Bool) {
        self.name = name
        self.quantity = quantity
        self.isMissing = isMissing
    }
} 