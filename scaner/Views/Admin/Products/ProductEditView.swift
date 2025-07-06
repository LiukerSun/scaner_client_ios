import SwiftUI

struct ProductEditView: View {
    let product: Product
    let onProductUpdated: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var productService = ProductService()
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // 商品基本信息
    @State private var name = ""
    @State private var sku = ""
    @State private var price: Double = 0.0
    @State private var discountPrice: Double = 0.0
    @State private var costPrice: Double = 0.0
    @State private var isDiscounted = false
    @State private var isEnabled = true
    @State private var shippingTime = ""
    
    // 颜色相关
    @State private var availableColors: [ProductColor] = []
    @State private var selectedColors: Set<Int> = []
    @State private var isLoadingColors = false
    @State private var showingColorPicker = false
    
    // 货源相关
    @State private var availableSources: [Source] = []
    @State private var selectedSource: Source?
    @State private var isLoadingSources = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("商品名称", text: $name)
                        .textContentType(.name)
                    
                    TextField("SKU", text: $sku)
                        .textContentType(.username)
                }
                
                Section("货源选择") {
                    if isLoadingSources {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("加载货源...")
                                .foregroundColor(.secondary)
                        }
                    } else if availableSources.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("暂无可用货源")
                                .foregroundColor(.secondary)
                            Button("重新加载") {
                                Task {
                                    await loadSources()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    } else {
                        Menu {
                            ForEach(availableSources) { source in
                                Button(action: {
                                    selectedSource = source
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(source.name)
                                            Text(source.code)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if selectedSource?.id == source.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("选择货源")
                                        .font(.headline)
                                    if let selectedSource = selectedSource {
                                        Text("\(selectedSource.name) (\(selectedSource.code))")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("请选择货源")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section("价格信息") {
                    VStack(alignment: .leading) {
                        Text("销售价格")
                            .font(.headline)
                        SelectAllCurrencyTextField(value: $price, placeholder: "请输入销售价格")
                    }
                    
                    VStack(alignment: .leading) {
                        Text("成本价格")
                            .font(.headline)
                        SelectAllCurrencyTextField(value: $costPrice, placeholder: "请输入成本价格")
                    }
                    
                    Toggle("启用优惠", isOn: $isDiscounted)
                    
                    if isDiscounted {
                        VStack(alignment: .leading) {
                            Text("优惠价格")
                                .font(.headline)
                            SelectAllCurrencyTextField(value: $discountPrice, placeholder: "请输入优惠价格")
                        }
                    }
                }
                
                Section("状态设置") {
                    Toggle("启用商品", isOn: $isEnabled)
                    
                    TextField("发货时间（可选）", text: $shippingTime)
                        .textContentType(.name)
                }
                
                Section("颜色选择") {
                    if isLoadingColors {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("加载颜色...")
                                .foregroundColor(.secondary)
                        }
                    } else if availableColors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("暂无可用颜色")
                                .foregroundColor(.secondary)
                            Button("重新加载") {
                                Task {
                                    await loadColors()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button(action: {
                            showingColorPicker = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("选择颜色")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                
                                if selectedColors.isEmpty {
                                    Text("请选择颜色（可多选）")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 6) {
                                        ForEach(getSelectedColors()) { color in
                                            selectedColorChip(color)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section("操作") {
                    Button("更新商品") {
                        updateProduct()
                    }
                    .disabled(isLoading || !isFormValid)
                    .foregroundColor(isFormValid ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("更新中...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("编辑商品")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("确定") {
                    if alertTitle == "更新成功" {
                        dismiss()
                        onProductUpdated?()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .task {
                await loadInitialData()
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(
                    availableColors: availableColors,
                    selectedColors: $selectedColors
                )
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        UIApplication.shared.endEditing()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getSelectedColors() -> [ProductColor] {
        return availableColors.filter { selectedColors.contains($0.id) }
    }
    
    private func getSelectedColorNames() -> [String] {
        return getSelectedColors().map { $0.name }
    }
    
    private func selectedColorChip(_ color: ProductColor) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(colorFromHex(color.hexColor) ?? Color.gray)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text(color.name)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && 
        !sku.isEmpty && 
        price > 0 && 
        costPrice > 0 &&
        selectedSource != nil &&
        (!isDiscounted || discountPrice > 0)
    }
    
    private func loadInitialData() async {
        // 初始化表单数据
        await MainActor.run {
            name = product.name
            sku = product.sku
            price = product.price
            costPrice = product.costPrice
            isDiscounted = product.isDiscounted
            if let discountPrice = product.discountPrice {
                self.discountPrice = discountPrice
            }
            isEnabled = product.isEnabled
            shippingTime = product.shippingTime ?? ""
        }
        
        // 并行加载颜色和货源数据
        await loadColors()
        await loadSources()
        
        // 设置已选择的颜色和货源
        await MainActor.run {
            if let productColors = product.colors {
                selectedColors = Set(productColors.map { $0.id })
            }
            
            if let productSource = product.source {
                selectedSource = availableSources.first { $0.id == productSource.id }
            }
        }
    }
    
    private func updateProduct() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let request = CreateProductRequest(
                    name: name,
                    sku: sku,
                    price: price,
                    discountPrice: isDiscounted && discountPrice > 0 ? discountPrice : nil,
                    costPrice: costPrice,
                    isDiscounted: isDiscounted,
                    isEnabled: isEnabled,
                    shippingTime: shippingTime.isEmpty ? nil : shippingTime,
                    sourceId: selectedSource?.id,
                    colors: selectedColors.isEmpty ? nil : getSelectedColorNames(),
                    images: nil
                )
                
                _ = try await productService.updateProduct(id: product.id, request: request)
                
                await MainActor.run {
                    isLoading = false
                    alertTitle = "更新成功"
                    alertMessage = "商品更新成功！"
                    showingAlert = true
                    onProductUpdated?()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "更新失败"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func loadColors() async {
        await MainActor.run {
            isLoadingColors = true
        }
        
        do {
            let colors = try await productService.getAvailableColors()
            await MainActor.run {
                availableColors = colors
                isLoadingColors = false
            }
        } catch {
            await MainActor.run {
                availableColors = []
                isLoadingColors = false
                print("加载颜色失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadSources() async {
        await MainActor.run {
            isLoadingSources = true
        }
        
        do {
            let sources = try await productService.getAvailableSources()
            await MainActor.run {
                availableSources = sources
                isLoadingSources = false
            }
        } catch {
            await MainActor.run {
                availableSources = []
                isLoadingSources = false
                print("加载货源失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func colorFromHex(_ hex: String?) -> Color? {
        guard let hex = hex else { return nil }
        
        let cleanHex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleanHex.count == 6 else { return nil }
        
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        
        let red = Double((int >> 16) & 0xFF) / 255.0
        let green = Double((int >> 8) & 0xFF) / 255.0
        let blue = Double(int & 0xFF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
}
