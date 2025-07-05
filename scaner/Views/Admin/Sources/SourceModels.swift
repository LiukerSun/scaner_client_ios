import Foundation

// MARK: - Source Models
struct Source: Codable, Identifiable {
    let id: Int
    let name: String
    let code: String
    let status: Int
    let remark: String?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    
    // 状态描述
    var statusDescription: String {
        switch status {
        case 1:
            return "启用"
        case 0:
            return "禁用"
        default:
            return "未知"
        }
    }
    
    // 状态颜色
    var statusColor: String {
        switch status {
        case 1:
            return "green"
        case 0:
            return "red"
        default:
            return "gray"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, code, status, remark
        case createdAt, updatedAt, deletedAt
    }
}

// MARK: - API Response Models
struct SourceListResponse: Codable {
    let success: Bool
    let message: String
    let data: SourceListData
}

struct SourceListData: Codable {
    let items: [Source]
    let total: Int
}

struct SourceDetailResponse: Codable {
    let success: Bool
    let message: String
    let data: Source
}

// MARK: - Search Parameters
struct SourceSearchParams {
    var page: Int = 1
    var pageSize: Int = 20
    
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        items.append(URLQueryItem(name: "page", value: "\(page)"))
        items.append(URLQueryItem(name: "page_size", value: "\(pageSize)"))
        
        return items
    }
}

// MARK: - Error Models
enum SourceError: Error {
    case invalidURL
    case noData
    case invalidResponse
    case serverError(String)
    case decodingError
} 