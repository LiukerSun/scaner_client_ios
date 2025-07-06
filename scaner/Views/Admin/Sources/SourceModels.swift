import Foundation

// MARK: - Source Models
struct Source: Codable, Identifiable {
    let id: Int
    let name: String
    let code: String
    let status: Int
    let remark: String?
    let createdAt: String?
    let updatedAt: String?
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
    // 有些接口未必返回 success/message，或 message 可能为 null
    let success: Bool?
    let message: String?
    let data: SourceListData
}

struct SourceListData: Codable {
    let items: [Source]
    let total: Int?
}

struct SourceDetailResponse: Codable {
    let success: Bool
    let message: String
    let data: Source
}

struct CreateSourceResponse: Codable {
    let success: Bool
    let message: String
    let data: Source
}

struct ActiveSourceListResponse: Codable {
    let success: Bool
    let message: String
    let data: [Source]
}

// MARK: - API Request Models
struct CreateSourceRequest: Codable {
    let name: String
    let code: String
    let status: Int
    let remark: String?
    
    init(name: String, code: String, status: Int = 1, remark: String? = nil) {
        self.name = name
        self.code = code
        self.status = status
        self.remark = remark
    }
}

struct UpdateSourceRequest: Codable {
    let name: String
    let code: String
    let status: Int
    let remark: String?
    
    init(name: String, code: String, status: Int, remark: String? = nil) {
        self.name = name
        self.code = code
        self.status = status
        self.remark = remark
    }
}

// MARK: - Search Parameters
struct SourceSearchParams {
    var page: Int = 1
    var pageSize: Int = 20
    var name: String? = nil
    var code: String? = nil
    var status: Int? = nil
    var orderBy: String? = nil
    var orderDir: String? = nil
    
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        items.append(URLQueryItem(name: "page", value: "\(page)"))
        items.append(URLQueryItem(name: "page_size", value: "\(pageSize)"))
        
        if let name = name, !name.isEmpty {
            items.append(URLQueryItem(name: "name", value: name))
        }
        
        if let code = code, !code.isEmpty {
            items.append(URLQueryItem(name: "code", value: code))
        }
        
        if let status = status {
            items.append(URLQueryItem(name: "status", value: "\(status)"))
        }
        
        if let orderBy = orderBy, !orderBy.isEmpty {
            items.append(URLQueryItem(name: "order_by", value: orderBy))
        }
        
        if let orderDir = orderDir, !orderDir.isEmpty {
            items.append(URLQueryItem(name: "order_dir", value: orderDir))
        }
        
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
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有数据"
        case .invalidResponse:
            return "无效的响应"
        case .serverError(let message):
            return message
        case .decodingError:
            return "数据解析错误"
        }
    }
} 