import Foundation

// MARK: - Category
struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let parentId: Int?
    let icon: String?
}

struct CreateCategoryRequest: Codable {
    let name: String
    let description: String?
    let parentId: Int?
    let icon: String?
}

// MARK: - Category Property
struct CategoryProperty: Codable, Identifiable {
    let id: Int
    let categoryId: Int
    let name: String
    let type: String
    let options: [String]?
}

struct CreatePropertyRequest: Codable {
    let categoryId: Int
    let name: String
    let type: String
    let options: [String]?
}

// MARK: - Item
struct Item: Codable, Identifiable {
    let id: Int
    let name: String
    let brand: String?
    let categoryId: Int
    let price: String?
    let colorTier: String
    let notes: String?
    let properties: [String: String]?
    let purchaseDate: String?
    
    var rank: Int {
        if let properties = properties,
           let rankString = properties["_rank"],
           let rankValue = Int(rankString) {
            return rankValue
        }
        return 999
    }
}

struct CreateItemRequest: Codable {
    let name: String
    let brand: String?
    let categoryId: Int
    let price: String?
    let colorTier: String?
    let notes: String?
    let properties: [String: String]?
}

struct UpdateItemRequest: Codable {
    let name: String?
    let brand: String?
    let price: String?
    let colorTier: String?
    let notes: String?
    let properties: [String: String]?
}

// MARK: - Color Tier
enum ColorTier: String, Codable, CaseIterable {
    case gold = "gold"
    case purple = "purple"
    case blue = "blue"
    case gray = "gray"
    
    var displayName: String {
        switch self {
        case .gold: return "完美"
        case .purple: return "优秀"
        case .blue: return "普通"
        case .gray: return "劣质"
        }
    }
    
    var limit: Int {
        switch self {
        case .gold: return 1
        case .purple: return 3
        case .blue: return 6
        case .gray: return Int.max
        }
    }
    
    var color: String {
        switch self {
        case .gold: return "#FFD700"
        case .purple: return "#9D4EDD"
        case .blue: return "#4A90E2"
        case .gray: return "#808080"
        }
    }
}

// MARK: - API Error
struct APIError: Codable, Error {
    let message: String
    let field: String?
}

