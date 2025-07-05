import SwiftUI

struct ProductFilterView: View {
    @Binding var searchParams: ProductSearchParams
    let onApply: (ProductSearchParams) -> Void
    
    @State private var localParams: ProductSearchParams
    @State private var minPriceText = ""
    @State private var maxPriceText = ""
    @Environment(\.dismiss) private var dismiss
    
    init(searchParams: Binding<ProductSearchParams>, onApply: @escaping (ProductSearchParams) -> Void) {
        self._searchParams = searchParams
        self.onApply = onApply
        self._localParams = State(initialValue: searchParams.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("价格范围")) {
                    HStack {
                        TextField("最低价", text: $minPriceText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Text("至")
                            .foregroundColor(.secondary)
                        
                        TextField("最高价", text: $maxPriceText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("商品状态")) {
                    Toggle("仅显示启用商品", isOn: Binding(
                        get: { localParams.isEnabled == true },
                        set: { localParams.isEnabled = $0 ? true : nil }
                    ))
                    
                    Toggle("仅显示优惠商品", isOn: Binding(
                        get: { localParams.isDiscounted == true },
                        set: { localParams.isDiscounted = $0 ? true : nil }
                    ))
                }
                
                Section(header: Text("发货时间")) {
                    TextField("发货时间", text: Binding(
                        get: { localParams.shippingTime ?? "" },
                        set: { localParams.shippingTime = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("排序")) {
                    Picker("排序字段", selection: Binding(
                        get: { localParams.orderBy ?? "id" },
                        set: { localParams.orderBy = $0 }
                    )) {
                        Text("ID").tag("id")
                        Text("名称").tag("name")
                        Text("SKU").tag("sku")
                        Text("价格").tag("price")
                        Text("优惠价").tag("discount_price")
                        Text("成本价").tag("cost_price")
                        Text("创建时间").tag("created_at")
                        Text("更新时间").tag("updated_at")
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("排序方向", selection: Binding(
                        get: { localParams.orderDir ?? "desc" },
                        set: { localParams.orderDir = $0 }
                    )) {
                        Text("升序").tag("asc")
                        Text("降序").tag("desc")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("筛选条件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("应用") {
                        applyFilters()
                    }
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    private func setupInitialValues() {
        localParams = searchParams
        minPriceText = localParams.minPrice?.description ?? ""
        maxPriceText = localParams.maxPrice?.description ?? ""
    }
    
    private func applyFilters() {
        // 更新价格范围
        localParams.minPrice = Double(minPriceText.isEmpty ? "" : minPriceText)
        localParams.maxPrice = Double(maxPriceText.isEmpty ? "" : maxPriceText)
        
        // 重置页码
        localParams.page = 1
        
        // 应用筛选
        onApply(localParams)
        dismiss()
    }
}

// MARK: - Preview
struct ProductFilterView_Previews: PreviewProvider {
    static var previews: some View {
        ProductFilterView(searchParams: .constant(ProductSearchParams())) { _ in }
    }
} 