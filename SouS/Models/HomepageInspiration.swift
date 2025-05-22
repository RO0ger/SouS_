import Foundation

struct HomepageInspiration: Decodable, Identifiable, Hashable {
    let id: Int
    let createdAt: Date // Supabase 'timestamptz' will be decoded to Date
    let title: String
    let imageName: String
    let duration: String
    let ingredients: String
    let instructions: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at" // Map to the snake_case column name in Supabase
        case title
        case imageName = "image_name" // Map to image_name
        case duration
        case ingredients
        case instructions
    }
} 