//
//  AdminSettingsView.swift
//  scaner
//
//  Created by Evan on 2025/6/30.
//

import SwiftUI

struct AdminSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // 用户信息部分
                Section(header: Text("用户信息")) {
                    if let user = authService.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.username)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("角色: \(user.role == "admin" ? "管理员" : "用户")")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                    
                                    Spacer()
                                    
                                    if user.isActive {
                                        Text("活跃")
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.1))
                                            .foregroundColor(.green)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 系统设置部分
                Section(header: Text("系统设置")) {
                    NavigationLink(destination: AdminAboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("关于系统")
                        }
                    }
                }
                
                // 账户管理部分
                Section(header: Text("账户管理")) {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("退出登录")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .alert("退出登录", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) { }
                Button("确定", role: .destructive) {
                    authService.logout()
                }
            } message: {
                Text("确定要退出登录吗？")
            }
        }
    }
}

// AdminAboutView 已移动到 Components/AdminAboutView.swift
