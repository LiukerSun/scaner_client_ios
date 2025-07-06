import SwiftUI

struct UserListView: View {
    @StateObject private var userService = UserService()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("用户总数: \(userService.total)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if userService.currentPage > 1 {
                        Text("第 \(userService.currentPage) 页")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if userService.isLoading && userService.users.isEmpty {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("正在加载用户...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if userService.users.isEmpty {
                    VStack {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("暂无用户")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(userService.users) { user in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(user.username)
                                        .font(.headline)
                                    Spacer()
                                    Text(user.role == "admin" ? "管理员" : "用户")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(user.role == "admin" ? Color.red : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let createdAt = user.createdAt {
                                    Text("创建时间: \(formatDate(createdAt))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 6)
                            .onAppear {
                                // 滚动到底部加载更多
                                if user.id == userService.users.last?.id {
                                    Task { await userService.loadMoreUsers() }
                                }
                            }
                        }
                        if userService.isLoading && !userService.users.isEmpty {
                            HStack { Spacer(); ProgressView(); Spacer() }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable { await userService.getUsers() }
                }
            }
            .navigationTitle("用户管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("关闭") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("刷新") { Task { await userService.getUsers() } } }
            }
            .alert("错误", isPresented: Binding<Bool>(get: { !userService.errorMessage.isEmpty }, set: { v in if !v { userService.errorMessage = "" } })) {
                Button("确定"){}
            } message: { Text(userService.errorMessage) }
            .onAppear { Task { await userService.getUsers() } }
        }
    }
    
    private func formatDate(_ str: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        if let date = fmt.date(from: str) {
            fmt.dateFormat = "yyyy-MM-dd HH:mm"
            return fmt.string(from: date)
        }
        return str
    }
}

#Preview {
    UserListView()
} 