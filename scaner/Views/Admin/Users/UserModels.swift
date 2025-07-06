import Foundation

// MARK: - 用户模型
struct AdminUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let role: String
    let isActive: Bool
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, role
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

// MARK: - 分页信息
struct UserPagination: Codable {
    let limit: Int
    let page: Int
    let total: Int
}

// MARK: - API 响应模型
struct UserListData: Codable {
    let pagination: UserPagination
    let users: [AdminUser]
}

struct UserListResponse: Codable {
    let success: Bool
    let message: String
    let data: UserListData
}

// MARK: - 错误类型
enum UserError: Error, LocalizedError {
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