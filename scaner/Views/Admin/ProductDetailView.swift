import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex = 0
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("商品详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func productImagesView(images: [ProductImage]) -> some View {
        VStack(spacing: 12) {
            // 主图显示
            TabView(selection: $selectedImageIndex) {
                ForEach(images.indices, id: \.self) { index in
                    AsyncImage(url: URL(string: images[index].url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                            )
                    }
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(12)
                    .tag(index)
                }
            }
            .frame(height: 250)
            .tabViewStyle(PageTabViewStyle())
            
            // 缩略图
            if images.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(images.indices, id: \.self) { index in
                            Button(action: {
                                selectedImageIndex = index
                            }) {
                                AsyncImage(url: URL(string: images[index].url)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
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
        }
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
                InfoRow(label: "商品名称", value: product.name)
                InfoRow(label: "SKU", value: product.sku)
                
                if let productCode = product.productCode {
                    InfoRow(label: "商品编码", value: productCode)
                }
                
                if let shippingTime = product.shippingTime {
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
                InfoRow(label: "货源名称", value: source.name)
                InfoRow(label: "货源编码", value: source.code)
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
                        if let hexColor = color.hexColor {
                            Circle()
                                .fill(Color(hex: hexColor) ?? Color.gray)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Text(color.name)
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
                InfoRow(label: "创建时间", value: formatDate(product.createdAt))
                InfoRow(label: "更新时间", value: formatDate(product.updatedAt))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
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
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
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
