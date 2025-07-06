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
    
    // MARK: - Get Sources List
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
                let total = response.data.total ?? response.data.items.count
                self.totalPages = max(1, Int(ceil(Double(total) / Double(params.pageSize))))
                self.total = total
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Load More Sources
    func loadMoreSources(params: SourceSearchParams) async {
        guard !isLoading && currentPage < totalPages else { return }
        
        var newParams = params
        newParams.page = currentPage + 1
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let response = try await fetchSourceList(params: newParams)
            let page = newParams.page
            let pageSize = newParams.pageSize
            
            await MainActor.run {
                self.sources.append(contentsOf: response.data.items)
                self.currentPage = page
                let total = response.data.total ?? (self.sources.count)
                self.totalPages = max(1, Int(ceil(Double(total) / Double(pageSize))))
                self.total = total
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Get Source Detail
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
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw SourceError.serverError(errorData.error ?? "获取货源详情失败")
            }
            throw SourceError.serverError("获取货源详情失败")
        }
        
        let decoder = JSONDecoder()
        let sourceResponse = try decoder.decode(SourceDetailResponse.self, from: data)
        return sourceResponse.data
    }
    
    // MARK: - Create Source
    func createSource(request: CreateSourceRequest) async throws -> Source {
        guard let url = URL(string: "\(baseURL)/source") else {
            throw SourceError.invalidURL
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
            throw SourceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw SourceError.serverError(errorData.error ?? "创建货源失败")
            }
            throw SourceError.serverError("创建货源失败")
        }
        
        let decoder = JSONDecoder()
        let createResponse = try decoder.decode(CreateSourceResponse.self, from: data)
        return createResponse.data
    }
    
    // MARK: - Update Source
    func updateSource(id: Int, request: UpdateSourceRequest) async throws -> Source {
        guard let url = URL(string: "\(baseURL)/source/\(id)") else {
            throw SourceError.invalidURL
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
            throw SourceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw SourceError.serverError(errorData.error ?? "更新货源失败")
            }
            throw SourceError.serverError("更新货源失败")
        }
        
        let decoder = JSONDecoder()
        let updateResponse = try decoder.decode(CreateSourceResponse.self, from: data)
        return updateResponse.data
    }
    
    // MARK: - Delete Source
    func deleteSource(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/source/\(id)") else {
            throw SourceError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        // 添加JWT token
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SourceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw SourceError.serverError(errorData.error ?? "删除货源失败")
            }
            throw SourceError.serverError("删除货源失败")
        }
    }
    
    // MARK: - Get Active Sources
    func getActiveSources() async throws -> [Source] {
        guard let url = URL(string: "\(baseURL)/source/active") else {
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
                throw SourceError.serverError(errorData.error ?? "获取启用货源列表失败")
            }
            throw SourceError.serverError("获取启用货源列表失败")
        }
        
        let decoder = JSONDecoder()
        let sourceResponse = try decoder.decode(ActiveSourceListResponse.self, from: data)
        return sourceResponse.data
    }
    
    // MARK: - Private Methods
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
    
    // MARK: - Helper Methods
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