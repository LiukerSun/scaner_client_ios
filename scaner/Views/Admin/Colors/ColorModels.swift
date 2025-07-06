import Foundation

// MARK: - 颜色模型
struct AdminColor: Codable, Identifiable {
    let id: Int
    let name: String
    let code: String?
    let hexColor: String?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, code
        case hexColor = "hex_color"
        case createdAt, updatedAt, deletedAt
    }
}

// MARK: - API 响应模型
struct AdminColorListResponse: Codable {
    let success: Bool
    let message: String
    let data: [AdminColor]
}

struct CreateColorRequest: Codable {
    let name: String
    let code: String?
    let hexColor: String?
    
    enum CodingKeys: String, CodingKey {
        case name, code
        case hexColor = "hex_color"
    }
}

struct CreateColorResponse: Codable {
    let success: Bool
    let message: String
    let data: AdminColor
}

// MARK: - 错误类型
enum ColorError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的响应"
        case .serverError(let msg):
            return msg
        }
    }
} 