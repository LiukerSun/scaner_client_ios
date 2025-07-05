import Foundation

class ProductService: ObservableObject {
    @Published var products: [Product] = []
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var total = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let baseURL = "https://erp.liukersun.com/api"
    
    func getProducts(params: ProductSearchParams = ProductSearchParams()) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let response = try await fetchProductList(params: params)
            
            await MainActor.run {
                self.products = response.data.items
                self.currentPage = response.data.page
                self.totalPages = response.data.totalPages
                self.total = response.data.total
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func loadMoreProducts(params: ProductSearchParams) async {
        guard !isLoading && currentPage < totalPages else { return }
        
        var newParams = params
        newParams.page = currentPage + 1
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let response = try await fetchProductList(params: newParams)
            
            await MainActor.run {
                self.products.append(contentsOf: response.data.items)
                self.currentPage = response.data.page
                self.totalPages = response.data.totalPages
                self.total = response.data.total
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func getProductDetail(id: Int) async throws -> Product {
        guard let url = URL(string: "\(baseURL)/product/\(id)") else {
            throw ProductError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加JWT token
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProductError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ProductError.serverError("获取商品详情失败")
        }
        
        let decoder = JSONDecoder()
        let productResponse = try decoder.decode(ProductDetailResponse.self, from: data)
        return productResponse.data
    }
    
    func searchProductBySKU(_ sku: String) async throws -> Product {
        guard let url = URL(string: "\(baseURL)/product/sku/\(sku)") else {
            throw ProductError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加JWT token
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProductError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ProductError.serverError("商品不存在")
        }
        
        let decoder = JSONDecoder()
        let productResponse = try decoder.decode(ProductDetailResponse.self, from: data)
        return productResponse.data
    }
    
    private func fetchProductList(params: ProductSearchParams) async throws -> ProductListResponse {
        guard var urlComponents = URLComponents(string: "\(baseURL)/product") else {
            throw ProductError.invalidURL
        }
        
        urlComponents.queryItems = params.toQueryItems()
        
        guard let url = urlComponents.url else {
            throw ProductError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加JWT token
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProductError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ProductError.serverError(errorData.error ?? "获取商品列表失败")
            }
            throw ProductError.serverError("获取商品列表失败")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ProductListResponse.self, from: data)
    }
    
    func clearProducts() {
        products = []
        currentPage = 1
        totalPages = 1
        total = 0
        errorMessage = ""
    }
    
    // MARK: - Create Product
    func createProduct(request: CreateProductRequest) async throws -> Product {
        guard let url = URL(string: "\(baseURL)/product") else {
            throw ProductError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加JWT token
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProductError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ProductError.serverError(errorData.error ?? "创建商品失败")
            }
            throw ProductError.serverError("创建商品失败")
        }
        
        let decoder = JSONDecoder()
        let createResponse = try decoder.decode(CreateProductResponse.self, from: data)
        return createResponse.data
    }
    
    // MARK: - Update Product
    func updateProduct(id: Int, request: CreateProductRequest) async throws -> Product {
        guard let url = URL(string: "\(baseURL)/product/\(id)") else {
            throw ProductError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加JWT token
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProductError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ProductError.serverError(errorData.error ?? "更新商品失败")
            }
            throw ProductError.serverError("更新商品失败")
        }
        
        let decoder = JSONDecoder()
        let updateResponse = try decoder.decode(CreateProductResponse.self, from: data)
        return updateResponse.data
    }
    
    // MARK: - Delete Product
    func deleteProduct(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/product/\(id)") else {
            throw ProductError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        // 添加JWT token
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProductError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ProductError.serverError(errorData.error ?? "删除商品失败")
            }
            throw ProductError.serverError("删除商品失败")
        }
    }
    
    // MARK: - Get Available Colors
    func getAvailableColors() async throws -> [ProductColor] {
        guard let url = URL(string: "\(baseURL)/product/colors") else {
            throw ProductError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加JWT token
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProductError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ProductError.serverError("获取颜色列表失败")
        }
        
        let decoder = JSONDecoder()
        let colorResponse = try decoder.decode(ColorListResponse.self, from: data)
        return colorResponse.data
    }
    
    // MARK: - Get Available Sources
    func getAvailableSources() async throws -> [Source] {
        guard let url = URL(string: "\(baseURL)/source/active") else {
            throw ProductError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加JWT token
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProductError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ProductError.serverError("获取货源列表失败")
        }
        
        let decoder = JSONDecoder()
        let sourceResponse = try decoder.decode(SourceListResponse.self, from: data)
        return sourceResponse.data
    }
}

// MARK: - Error Handling
enum ProductError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的响应"
        case .serverError(let message):
            return message
        }
    }
} 
