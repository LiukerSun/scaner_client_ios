import Foundation
import SwiftUI

class AuthService: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let baseURL = "https://erp.liukersun.com/api"
    private let tokenKey = "jwt_token"
    private let userKey = "current_user"
    
    init() {
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            // 验证token是否有效
            validateToken(token)
        } else {
            isLoggedIn = false
            currentUser = nil
        }
    }
    
    func login(username: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let loginRequest = LoginRequest(username: username, password: password)
            let response = try await performLoginRequest(loginRequest)
            
            await MainActor.run {
                UserDefaults.standard.set(response.data.token, forKey: tokenKey)
                self.saveUserToDefaults(response.data.user)
                self.currentUser = response.data.user
                self.isLoggedIn = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        currentUser = nil
        isLoggedIn = false
    }
    
    private func validateToken(_ token: String) {
        // 恢复用户信息
        if let userData = UserDefaults.standard.data(forKey: userKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let user = try decoder.decode(User.self, from: userData)
                currentUser = user
                isLoggedIn = true
            } catch {
                print("无法解析用户数据: \(error)")
                // 如果无法解析用户数据，清除token并要求重新登录
                logout()
            }
        } else {
            // 如果没有用户数据，清除token并要求重新登录
            logout()
        }
    }
    
    private func saveUserToDefaults(_ user: User) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let userData = try encoder.encode(user)
            UserDefaults.standard.set(userData, forKey: userKey)
        } catch {
            print("无法保存用户数据: \(error)")
        }
    }
    
    // 刷新用户信息的方法
    func refreshUserInfo() {
        guard let token = UserDefaults.standard.string(forKey: tokenKey) else {
            logout()
            return
        }
        
        validateToken(token)
    }
    
    private func performLoginRequest(_ request: LoginRequest) async throws -> LoginResponse {
        guard let url = URL(string: "\(baseURL)/user/login") else {
            throw AuthError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorData.error ?? "登录失败")
            }
            throw AuthError.serverError("登录失败")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(LoginResponse.self, from: data)
    }
}

// MARK: - Data Models
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let success: Bool
    let message: String
    let data: LoginData
}

struct LoginData: Codable {
    let token: String
    let user: User
}

struct User: Codable {
    let id: Int
    let username: String
    let email: String
    let role: String
    let isActive: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, role
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct ErrorResponse: Codable {
    let success: Bool
    let message: String
    let error: String?
}

enum AuthError: Error, LocalizedError {
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