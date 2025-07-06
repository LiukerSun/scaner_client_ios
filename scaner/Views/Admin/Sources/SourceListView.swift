import SwiftUI

struct SourceListView: View {
    @StateObject private var sourceService = SourceService()
    @State private var searchParams = SourceSearchParams()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // 统计信息
                HStack {
                    Text("货源总数: \(sourceService.total)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if sourceService.currentPage > 1 {
                        Text("第 \(sourceService.currentPage) 页")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 货源列表
                if sourceService.isLoading && sourceService.sources.isEmpty {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("正在加载货源...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sourceService.sources.isEmpty && !sourceService.isLoading {
                    VStack {
                        Image(systemName: "building.2")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("暂无货源")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(sourceService.sources) { source in
                            SourceRowView(source: source)
                                .onAppear {
                                    // 滚动到最后一个时加载更多
                                    if source.id == sourceService.sources.last?.id {
                                        Task {
                                            await sourceService.loadMoreSources(params: searchParams)
                                        }
                                    }
                                }
                        }
                        
                        if sourceService.isLoading && !sourceService.sources.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("加载更多...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await sourceService.refreshSources()
                    }
                }
            }
            .navigationTitle("货源管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        Task {
                            await sourceService.refreshSources()
                        }
                    }
                }
            }

            .alert("错误", isPresented: Binding<Bool>(
                get: { !sourceService.errorMessage.isEmpty },
                set: { newValue in
                    if !newValue {
                        sourceService.errorMessage = ""
                    }
                }
            )) {
                Button("确定") { }
            } message: {
                Text(sourceService.errorMessage)
            }
        }
        .onAppear {
            Task {
                await sourceService.getSources()
            }
        }
    }
    

}

// MARK: - 货源行视图
struct SourceRowView: View {
    let source: Source
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 基本信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("编码: \(source.code)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 状态标签
                Text(source.statusDescription)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: source.status))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            // 详细信息
            if let remark = source.remark, !remark.isEmpty {
                Text("备注: \(remark)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            
            // 时间信息
            HStack {
                Text("创建时间:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatDate(source.createdAt ?? ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("更新时间:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatDate(source.updatedAt ?? ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
    
    private func statusColor(for status: Int) -> Color {
        switch status {
        case 1:
            return .green
        case 0:
            return .red
        default:
            return .gray
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter.string(from: date)
        }
        
        // 如果解析失败，尝试其他格式
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}



#Preview {
    SourceListView()
} 