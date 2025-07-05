//
//  AdminHomeView.swift
//  scaner
//
//  Created by Evan on 2025/6/30.
//

import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingProductManagement = false
    @State private var showingSourceManagement = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 欢迎信息
                    if let user = authService.currentUser {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("欢迎回来")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(user.username)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }
                            
                            Text("今天也要卖100W+!!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    // 管理功能卡片
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // 商品管理
                        AdminFunctionCard(
                            title: "商品管理",
                            subtitle: "管理商品信息",
                            icon: "cube.box",
                            color: .blue
                        ) {
                            showingProductManagement = true
                        }
                        
                        // 货源管理
                        AdminFunctionCard(
                            title: "货源管理",
                            subtitle: "管理货源信息",
                            icon: "building.2",
                            color: .green
                        ) {
                            showingSourceManagement = true
                        }
                        
                        // 用户管理
                        AdminFunctionCard(
                            title: "用户管理",
                            subtitle: "管理用户账户",
                            icon: "person.3",
                            color: .orange
                        ) {
                            // 这里可以导航到用户管理页面
                        }
                        
                        // 颜色管理
                        AdminFunctionCard(
                            title: "颜色管理",
                            subtitle: "管理颜色信息",
                            icon: "paintbrush",
                            color: .purple
                        ) {
                            // 这里可以导航到颜色管理页面
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("管理中心")
            .background(Color(.systemGroupedBackground))
            .fullScreenCover(isPresented: $showingProductManagement) {
                ProductManagementView()
            }
            .fullScreenCover(isPresented: $showingSourceManagement) {
                SourceListView()
            }
            .onAppear {
                // 确保用户信息正确加载
                authService.refreshUserInfo()
            }
        }
    }
}

// AdminFunctionCard 已移动到 Components/AdminFunctionCard.swift

