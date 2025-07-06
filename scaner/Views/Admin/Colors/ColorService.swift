import Foundation
import SwiftUI

class ColorService: ObservableObject {
    @Published var colors: [AdminColor] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let baseURL = "https://erp.liukersun.com/api"
    
    // 获取颜色列表
    func getColors(orderBy: String? = nil, orderDir: String? = nil) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = ""
        }
        do {
            let list = try await fetchColorList(orderBy: orderBy, orderDir: orderDir)
            await MainActor.run {
                self.colors = list
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - 私有方法
    private func fetchColorList(orderBy: String?, orderDir: String?) async throws -> [AdminColor] {
        guard var components = URLComponents(string: "\(baseURL)/product/colors") else {
            throw ColorError.invalidURL
        }
        var items: [URLQueryItem] = []
        if let orderBy = orderBy { items.append(URLQueryItem(name: "order_by", value: orderBy)) }
        if let orderDir = orderDir { items.append(URLQueryItem(name: "order_dir", value: orderDir)) }
        if !items.isEmpty { components.queryItems = items }
        guard let url = components.url else { throw ColorError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResp = response as? HTTPURLResponse else { throw ColorError.invalidResponse }
        guard httpResp.statusCode == 200 else {
            if let err = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ColorError.serverError(err.error ?? "获取颜色列表失败")
            }
            throw ColorError.serverError("获取颜色列表失败")
        }
        let decoder = JSONDecoder()
        let resp = try decoder.decode(AdminColorListResponse.self, from: data)
        return resp.data
    }
} 