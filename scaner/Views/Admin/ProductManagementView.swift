import SwiftUI

struct ProductManagementView: View {
    @StateObject private var productService = ProductService()
    @State private var searchParams = ProductSearchParams()
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedProduct: Product?
    @State private var showingProductDetail = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                searchBar
                
                // 筛选器提示
                if hasActiveFilters {
                    filterStatusBar
                }
                
                // 商品列表
                productList
            }
            .navigationTitle("商品管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("筛选") {
                        showingFilters = true
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                ProductFilterView(searchParams: $searchParams) { params in
                    self.searchParams = params
                    Task {
                        await productService.getProducts(params: params)
                    }
                }
            }
            .sheet(isPresented: $showingProductDetail) {
                if let product = selectedProduct {
                    ProductDetailView(product: product)
                }
            }
            .task {
                await productService.getProducts(params: searchParams)
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            TextField("搜索商品名称、SKU或商品编码", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    performSearch()
                }
            
            Button("搜索") {
                performSearch()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private var filterStatusBar: some View {
        HStack {
            Text("已应用筛选条件")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("清除筛选") {
                clearFilters()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
    }
    
    private var productList: some View {
        Group {
            if productService.isLoading && productService.products.isEmpty {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if productService.products.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(productService.products) { product in
                            ProductRowView(product: product) {
                                selectedProduct = product
                                showingProductDetail = true
                            }
                        }
                        
                        // 加载更多
                        if productService.currentPage < productService.totalPages {
                            loadMoreView
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.box")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无商品")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("请尝试调整搜索条件或添加新商品")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadMoreView: some View {
        Group {
            if productService.isLoading {
                ProgressView()
                    .frame(height: 50)
            } else {
                Button("加载更多") {
                    Task {
                        await productService.loadMoreProducts(params: searchParams)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        searchParams.sourceId != nil ||
        searchParams.minPrice != nil ||
        searchParams.maxPrice != nil ||
        searchParams.isDiscounted != nil ||
        searchParams.isEnabled != nil ||
        !(searchParams.colors?.isEmpty ?? true) ||
        searchParams.shippingTime != nil
    }
    
    private func performSearch() {
        searchParams.name = searchText.isEmpty ? nil : searchText
        searchParams.page = 1
        
        Task {
            await productService.getProducts(params: searchParams)
        }
    }
    
    private func clearFilters() {
        searchParams = ProductSearchParams()
        searchText = ""
        
        Task {
            await productService.getProducts(params: searchParams)
        }
    }
}

// MARK: - Product Row View
struct ProductRowView: View {
    let product: Product
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text("SKU: \(product.sku)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "¥%.2f", product.price))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if product.isDiscounted, let discountPrice = product.discountPrice {
                            Text(String(format: "优惠价: ¥%.2f", discountPrice))
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                HStack {
                    // 状态标签
                    Group {
                        if product.isEnabled {
                            Label("启用", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Label("停用", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if product.isDiscounted {
                            Label("促销", systemImage: "tag.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    // 货源信息
                    if let source = product.source {
                        Text(source.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 颜色信息
                if let colors = product.colors, !colors.isEmpty {
                    HStack {
                        Text("颜色:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(colors.prefix(3)) { color in
                            Text(color.name)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        if colors.count > 3 {
                            Text("+\(colors.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 发货时间
                if let shippingTime = product.shippingTime {
                    Text("发货时间: \(shippingTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct ProductManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ProductManagementView()
    }
} 