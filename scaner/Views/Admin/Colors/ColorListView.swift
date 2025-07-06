import SwiftUI

struct ColorListView: View {
    @StateObject private var colorService = ColorService()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if colorService.isLoading && colorService.colors.isEmpty {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("正在加载颜色...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if colorService.colors.isEmpty {
                    VStack {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("暂无颜色")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(colorService.colors) { color in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(color.name)
                                .font(.headline)
                            if let code = color.code {
                                Text("代码: \(code)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            if let hex = color.hexColor {
                                Text("HEX: \(hex)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await colorService.getColors()
                    }
                }
            }
            .navigationTitle("颜色管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        Task { await colorService.getColors() }
                    }
                }
            }
            .alert("错误", isPresented: Binding<Bool>(
                get: { !colorService.errorMessage.isEmpty },
                set: { val in if !val { colorService.errorMessage = "" } }
            )) {
                Button("确定") {}
            } message: {
                Text(colorService.errorMessage)
            }
            .onAppear {
                Task { await colorService.getColors() }
            }
        }
    }
}

#Preview {
    ColorListView()
} 