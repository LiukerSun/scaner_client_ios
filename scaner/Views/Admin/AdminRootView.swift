//
//  AdminRootView.swift
//  scaner
//
//  Created by Evan on 2025/6/30.
//

import SwiftUI

struct AdminRootView: View {
    @StateObject private var authService = AuthService()
    @State private var showLoginSheet = false
    
    var body: some View {
        Group {
            if authService.isLoggedIn {
                TabView {
                    AdminHomeView()
                        .tabItem {
                            VStack {
                                Image(systemName: "house")
                                    .font(.system(size: 22))
                                Text("首页")
                                    .font(.system(size: 15, weight: .medium))
                            }
                        }

                    AdminSettingsView()
                        .tabItem {
                            VStack {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 22))
                                Text("设置")
                                    .font(.system(size: 15, weight: .medium))
                            }
                        }
                }
                .navigationTitle("商品管理系统")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("注销", action: {
                                authService.logout()
                            })
                        } label: {
                            HStack {
                                Image(systemName: "person.circle")
                                if let user = authService.currentUser {
                                    Text(user.username)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "lock.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("需要登录")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("请登录管理员账号以访问系统")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("立即登录") {
                            showLoginSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    Spacer()
                }
                .navigationTitle("商品管理系统")
            }
        }
        .environmentObject(authService)
        .sheet(isPresented: $showLoginSheet) {
            LoginView(isPresented: $showLoginSheet)
                .environmentObject(authService)
        }
        .onAppear {
            // 刷新用户信息
            authService.refreshUserInfo()
            
            if !authService.isLoggedIn {
                showLoginSheet = true
            }
        }
    }
}
