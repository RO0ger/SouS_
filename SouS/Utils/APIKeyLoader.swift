import Foundation

enum APIKeyLoaderError: Error, LocalizedError {
    case fileNotFound
    case keyNotFound
    case invalidPlistFormat
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "Secrets.plist file not found."
        case .keyNotFound: return "GeminiAPIKey not found in Secrets.plist."
        case .invalidPlistFormat: return "Could not read Secrets.plist format."
        }
    }
}

struct APIKeyLoader {
    static func loadAPIKey() throws -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else {
            throw APIKeyLoaderError.fileNotFound
        }
        
        guard let plist = NSDictionary(contentsOfFile: path) else {
             throw APIKeyLoaderError.invalidPlistFormat
        }
        
        guard let key = plist["GeminiAPIKey"] as? String, !key.isEmpty, !key.starts(with: "YOUR_") else {
            throw APIKeyLoaderError.keyNotFound
        }
        
        return key
    }
} 