import Foundation
import SwiftUI

class UserService: ObservableObject {
    @Published var users: [AdminUser] = []
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var total = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let baseURL = "https://erp.liukersun.com/api"
    
    // 获取用户列表
    func getUsers(page: Int = 1, limit: Int = 20) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = ""
        }
        do {
            let listData = try await fetchUserList(page: page, limit: limit)
            await MainActor.run {
                self.users = listData.users
                self.currentPage = listData.pagination.page
                self.total = listData.pagination.total
                self.totalPages = max(1, Int(ceil(Double(self.total) / Double(limit))))
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // 加载更多
    func loadMoreUsers(limit: Int = 20) async {
        guard !isLoading && currentPage < totalPages else { return }
        await MainActor.run { self.isLoading = true }
        let nextPage = currentPage + 1
        do {
            let listData = try await fetchUserList(page: nextPage, limit: limit)
            await MainActor.run {
                self.users.append(contentsOf: listData.users)
                self.currentPage = listData.pagination.page
                self.total = listData.pagination.total
                self.totalPages = max(1, Int(ceil(Double(self.total) / Double(limit))))
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
    private func fetchUserList(page: Int, limit: Int) async throws -> UserListData {
        guard var comp = URLComponents(string: "\(baseURL)/user/admin/users") else {
            throw UserError.invalidURL
        }
        comp.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        guard let url = comp.url else { throw UserError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw UserError.invalidResponse }
        guard http.statusCode == 200 else {
            if let err = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw UserError.serverError(err.error ?? "获取用户列表失败")
            }
            throw UserError.serverError("获取用户列表失败")
        }
        let decoder = JSONDecoder()
        let response = try decoder.decode(UserListResponse.self, from: data)
        return response.data
    }
} 