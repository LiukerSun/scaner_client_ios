import Foundation

// MARK: - Product Models
struct Product: Codable, Identifiable {
    let id: Int
    let name: String
    let sku: String
    let productCode: String?
    let price: Double
    let discountPrice: Double?
    let costPrice: Double
    let isDiscounted: Bool
    let isEnabled: Bool
    let shippingTime: String?
    let sourceId: Int?
    let createdAt: String
    let updatedAt: String
    let source: ProductSource?
    let colors: [ProductColor]?
    let images: [ProductImage]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, sku, price, colors, images, source
        case productCode = "product_code"
        case discountPrice = "discount_price"
        case costPrice = "cost_price"
        case isDiscounted = "is_discounted"
        case isEnabled = "is_enabled"
        case shippingTime = "shipping_time"
        case sourceId = "source_id"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
    }
}

struct ProductColor: Codable, Identifiable {
    let id: Int
    let name: String
    let code: String?
    let hexColor: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, code
        case hexColor = "hex_color"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
    }
}

struct ProductImage: Codable {
    let url: String
    let alt: String?
    let title: String?
    let isMain: Bool
    let sort: Int
    
    enum CodingKeys: String, CodingKey {
        case url, alt, title, sort
        case isMain = "is_main"
    }
}

struct ProductSource: Codable {
    let id: Int
    let name: String
    let code: String
    let status: Int
}

// MARK: - API Response Models
struct ProductListResponse: Codable {
    let success: Bool
    let message: String
    let data: ProductListData
}

struct ProductListData: Codable {
    let items: [Product]
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case items, page, total
        case pageSize = "page_size"
        case totalPages = "total_pages"
    }
}

struct ProductDetailResponse: Codable {
    let success: Bool
    let message: String
    let data: Product
}

struct ColorListResponse: Codable {
    let success: Bool
    let message: String
    let data: [ProductColor]
}

// MARK: - Search and Filter Models
struct ProductSearchParams {
    var page: Int = 1
    var pageSize: Int = 20
    var name: String?
    var sku: String?
    var productCode: String?
    var sourceId: Int?
    var minPrice: Double?
    var maxPrice: Double?
    var isDiscounted: Bool?
    var isEnabled: Bool?
    var colors: [String]?
    var shippingTime: String?
    var orderBy: String?
    var orderDir: String?
    
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        items.append(URLQueryItem(name: "page", value: "\(page)"))
        items.append(URLQueryItem(name: "page_size", value: "\(pageSize)"))
        
        if let name = name, !name.isEmpty {
            items.append(URLQueryItem(name: "name", value: name))
        }
        if let sku = sku, !sku.isEmpty {
            items.append(URLQueryItem(name: "sku", value: sku))
        }
        if let productCode = productCode, !productCode.isEmpty {
            items.append(URLQueryItem(name: "product_code", value: productCode))
        }
        if let sourceId = sourceId {
            items.append(URLQueryItem(name: "source_id", value: "\(sourceId)"))
        }
        if let minPrice = minPrice {
            items.append(URLQueryItem(name: "min_price", value: "\(minPrice)"))
        }
        if let maxPrice = maxPrice {
            items.append(URLQueryItem(name: "max_price", value: "\(maxPrice)"))
        }
        if let isDiscounted = isDiscounted {
            items.append(URLQueryItem(name: "is_discounted", value: "\(isDiscounted)"))
        }
        if let isEnabled = isEnabled {
            items.append(URLQueryItem(name: "is_enabled", value: "\(isEnabled)"))
        }
        if let colors = colors, !colors.isEmpty {
            items.append(URLQueryItem(name: "colors", value: colors.joined(separator: ",")))
        }
        if let shippingTime = shippingTime, !shippingTime.isEmpty {
            items.append(URLQueryItem(name: "shipping_time", value: shippingTime))
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

// MARK: - Create Product Models
struct CreateProductRequest: Codable {
    let name: String
    let sku: String
    let price: Double
    let discountPrice: Double?
    let costPrice: Double
    let isDiscounted: Bool
    let isEnabled: Bool
    let shippingTime: String?
    let sourceId: Int?
    let colors: [String]?
    let images: [CreateProductImage]?
    
    enum CodingKeys: String, CodingKey {
        case name, sku, price, colors, images
        case discountPrice = "discount_price"
        case costPrice = "cost_price"
        case isDiscounted = "is_discounted"
        case isEnabled = "is_enabled"
        case shippingTime = "shipping_time"
        case sourceId = "source_id"
    }
}

struct CreateProductImage: Codable {
    let url: String
    let alt: String?
    let title: String?
    let isMain: Bool
    let sort: Int
    
    enum CodingKeys: String, CodingKey {
        case url, alt, title, sort
        case isMain = "is_main"
    }
}

struct CreateProductResponse: Codable {
    let success: Bool
    let message: String
    let data: Product
}

// MARK: - Source Models
struct Source: Codable, Identifiable {
    let id: Int
    let name: String
    let code: String
    let status: Int
    let remark: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, code, status, remark
        case createdAt, updatedAt
    }
}

struct SourceListResponse: Codable {
    let success: Bool
    let message: String
    let data: [Source]
} 