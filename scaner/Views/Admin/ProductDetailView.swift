import SwiftUI

struct ProductDetailView: View {
    let product: Product
    let onProductUpdated: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex = 0
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @StateObject private var productService = ProductService()
    @State private var errorMessage = ""
    @State private var showingErrorAlert = false
    
    init(product: Product, onProductUpdated: (() -> Void)? = nil) {
        self.product = product
        self.onProductUpdated = onProductUpdated
        // 初始化时设置选中的图片索引
        self._selectedImageIndex = State(initialValue: 0)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 商品图片
                if let images = product.images, !images.isEmpty {
                    productImagesView(images: images)
                } else {
                    placeholderImageView
                }
                
                // 基本信息
                basicInfoSection
                
                // 价格信息
                priceInfoSection
                
                // 状态信息
                statusInfoSection
                
                // 货源信息
                if let source = product.source {
                    sourceInfoSection(source: source)
                }
                
                // 颜色信息
                if let colors = product.colors, !colors.isEmpty {
                    colorsSection(colors: colors)
                }
                
                // 其他信息
                otherInfoSection
            }
            .padding()
        }
        .onAppear {
            // 确保TabView状态正确
            if let images = product.images, !images.isEmpty {
                // 使用DispatchQueue确保状态更新在主线程
                DispatchQueue.main.async {
                    selectedImageIndex = 0
                }
            }
        }
        .navigationTitle("商品详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("编辑商品") {
                        showingEditView = true
                    }
                    
                    Button("删除商品", role: .destructive) {
                        showingDeleteAlert = true
                    }
                    .disabled(isDeleting)
                } label: {
                    if isDeleting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
            }
        }
            .sheet(isPresented: $showingEditView) {
                ProductEditView(product: product, onProductUpdated: onProductUpdated)
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteProduct()
                }
            } message: {
                Text("确定要删除商品「\(product.name.isEmpty ? "未知商品" : product.name)」吗？\n\n此操作不可撤销。")
            }
            .alert("删除失败", isPresented: $showingErrorAlert) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
    }
    
    private func deleteProduct() {
        guard !isDeleting else { return }
        
        isDeleting = true
        
        Task {
            do {
                try await productService.deleteProduct(id: product.id)
                
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                    onProductUpdated?()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = error.localizedDescription.isEmpty ? "删除失败，请重试" : error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func productImagesView(images: [ProductImage]) -> some View {
        guard !images.isEmpty else {
            return AnyView(placeholderImageView)
        }
        
        return AnyView(VStack(spacing: 12) {
            // 主图显示
            TabView(selection: $selectedImageIndex) {
                ForEach(images.indices, id: \.self) { index in
                    AsyncImage(url: URL(string: images[index].url)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.2)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure(_):
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo.badge.exclamationmark")
                                            .font(.system(size: 30))
                                            .foregroundColor(.red)
                                        Text("图片加载失败")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(12)
                    .tag(index)
                }
            }
            .frame(height: 250)
            .tabViewStyle(PageTabViewStyle())
            .animation(.easeInOut(duration: 0.3), value: selectedImageIndex)
            
            // 缩略图
            if images.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(images.indices, id: \.self) { index in
                            Button(action: {
                                selectedImageIndex = index
                            }) {
                                AsyncImage(url: URL(string: images[index].url)) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                ProgressView()
                                                    .scaleEffect(0.6)
                                            )
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure(_):
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "photo.badge.exclamationmark")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            )
                                    @unknown default:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedImageIndex == index ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        })
    }
    
    private var placeholderImageView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 250)
            .overlay(
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("暂无图片")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
            .cornerRadius(12)
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本信息")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "商品名称", value: product.name.isEmpty ? "未知商品" : product.name)
                InfoRow(label: "SKU", value: product.sku.isEmpty ? "未设置" : product.sku)
                
                if let productCode = product.productCode, !productCode.isEmpty {
                    InfoRow(label: "商品编码", value: productCode)
                }
                
                if let shippingTime = product.shippingTime, !shippingTime.isEmpty {
                    InfoRow(label: "发货时间", value: shippingTime)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var priceInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("价格信息")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "售价", value: String(format: "¥%.2f", product.price))
                InfoRow(label: "成本价", value: String(format: "¥%.2f", product.costPrice))
                
                if let discountPrice = product.discountPrice {
                    InfoRow(label: "优惠价", value: String(format: "¥%.2f", discountPrice))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var statusInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("状态信息")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                Label(
                    product.isEnabled ? "启用" : "停用",
                    systemImage: product.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .foregroundColor(product.isEnabled ? .green : .red)
                
                Spacer()
                
                if product.isDiscounted {
                    Label("促销中", systemImage: "tag.fill")
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func sourceInfoSection(source: ProductSource) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("货源信息")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "货源名称", value: source.name.isEmpty ? "未知货源" : source.name)
                InfoRow(label: "货源编码", value: source.code.isEmpty ? "未设置" : source.code)
                InfoRow(label: "状态", value: source.status == 1 ? "启用" : "停用")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func colorsSection(colors: [ProductColor]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("颜色信息")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(colors) { color in
                    HStack {
                        if let hexColor = color.hexColor, !hexColor.isEmpty {
                            Circle()
                                .fill(Color(hex: hexColor) ?? Color.gray)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Text(color.name.isEmpty ? "未知颜色" : color.name)
                            .font(.caption)
                        
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var otherInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("其他信息")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "商品ID", value: "\(product.id)")
                InfoRow(label: "创建时间", value: formatDate(product.createdAt ?? ""))
                InfoRow(label: "更新时间", value: formatDate(product.updatedAt ?? ""))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ dateString: String) -> String {
        guard !dateString.isEmpty else {
            return "未知时间"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        // 尝试多种日期格式
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                displayFormatter.timeStyle = .short
                displayFormatter.locale = Locale(identifier: "zh_CN")
                return displayFormatter.string(from: date)
            }
        }
        
        return dateString
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        guard !hex.isEmpty else { return nil }
        
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard !hex.isEmpty else { return nil }
        
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
