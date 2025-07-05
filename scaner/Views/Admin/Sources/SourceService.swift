import Foundation
import SwiftUI

// 使用AuthService中的ErrorResponse
import UIKit

class SourceService: ObservableObject {
    @Published var sources: [Source] = []
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var total = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let baseURL = "https://erp.liukersun.com/api"
    
    func getSources(params: SourceSearchParams = SourceSearchParams()) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let response = try await fetchSourceList(params: params)
            
            await MainActor.run {
                self.sources = response.data.items
                self.currentPage = params.page
                self.totalPages = max(1, Int(ceil(Double(response.data.total) / Double(params.pageSize))))
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
    
    func loadMoreSources(params: SourceSearchParams) async {
        guard !isLoading && currentPage < totalPages else { return }
        
        var newParams = params
        newParams.page = currentPage + 1
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let response = try await fetchSourceList(params: newParams)
            
            await MainActor.run {
                self.sources.append(contentsOf: response.data.items)
                self.currentPage = newParams.page
                self.totalPages = max(1, Int(ceil(Double(response.data.total) / Double(newParams.pageSize))))
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
    
    func getSourceDetail(id: Int) async throws -> Source {
        guard let url = URL(string: "\(baseURL)/source/\(id)") else {
            throw SourceError.invalidURL
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
            throw SourceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw SourceError.serverError("获取货源详情失败")
        }
        
        let decoder = JSONDecoder()
        let sourceResponse = try decoder.decode(SourceDetailResponse.self, from: data)
        return sourceResponse.data
    }
    
    private func fetchSourceList(params: SourceSearchParams) async throws -> SourceListResponse {
        guard var urlComponents = URLComponents(string: "\(baseURL)/source") else {
            throw SourceError.invalidURL
        }
        
        urlComponents.queryItems = params.toQueryItems()
        
        guard let url = urlComponents.url else {
            throw SourceError.invalidURL
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
            throw SourceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw SourceError.serverError(errorData.error ?? "获取货源列表失败")
            }
            throw SourceError.serverError("获取货源列表失败")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(SourceListResponse.self, from: data)
    }
    
    func clearSources() {
        sources = []
        currentPage = 1
        totalPages = 1
        total = 0
        errorMessage = ""
    }
    
    func refreshSources() async {
        await getSources()
    }
} 