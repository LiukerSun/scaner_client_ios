import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo 和标题
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("商品管理系统")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("管理员登录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 登录表单
                VStack(spacing: 20) {
                    // 用户名输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("用户名")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("请输入用户名", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // 密码输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            if showPassword {
                                TextField("请输入密码", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else {
                                SecureField("请输入密码", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // 错误信息
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // 登录按钮
                    Button(action: {
                        Task {
                            await authService.login(username: username, password: password)
                            if authService.isLoggedIn {
                                isPresented = false
                            }
                        }
                    }) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            
                            Text(authService.isLoading ? "登录中..." : "登录")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canLogin ? Color.blue : Color.gray)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(!canLogin || authService.isLoading)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 底部信息
                VStack(spacing: 8) {
                    Text("请使用管理员账号登录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("如有问题，请联系系统管理员")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("登录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    private var canLogin: Bool {
        !username.isEmpty && !password.isEmpty
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isPresented: .constant(true))
            .environmentObject(AuthService())
    }
} 