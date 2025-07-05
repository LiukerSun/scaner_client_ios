import SwiftUI
import QuickLook
import UIKit // 用于保存图片到相册
import Photos // 请求相册权限
import Combine

struct ProductManagementView: View {
    @StateObject private var productService = ProductService()
    @State private var searchParams = ProductSearchParams()
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedProduct: Product?
    @State private var showingProductDetail = false
    @State private var showingCreateProduct = false
    @State private var selectedImageURL: String?
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
            .overlay(
                // 浮动创建按钮
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingCreateProduct = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(productService.isLoading ? Color.gray : Color.blue)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .disabled(productService.isLoading)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 加载指示器
                    if productService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(hasActiveFilters ? .blue : .primary)
                    }
                    .disabled(productService.isLoading)
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
                    ProductDetailView(product: product) {
                        // 商品更新或删除后刷新列表
                        Task {
                            await productService.getProducts(params: searchParams)
                        }
                    }
                }
            }
            .onChange(of: showingProductDetail) { isShowing in
                // 当sheet关闭时，清除selectedProduct
                if !isShowing {
                    selectedProduct = nil
                }
            }
            .sheet(isPresented: $showingCreateProduct) {
                ProductCreateView()
                    .onDisappear {
                        // 当创建商品页面关闭时刷新列表
                        Task {
                            await productService.getProducts(params: searchParams)
                        }
                    }
            }
            // 仅在selectedImageURL有值时才展示，避免首次进入白屏
            .fullScreenCover(item: $selectedImageURL, onDismiss: {
                // 关闭后重置图片URL
                selectedImageURL = nil
            }) { imageURL in
                FullScreenImageViewer(imageURL: imageURL)
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
            .disabled(productService.isLoading)
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
            
            Button("清除全部") {
                clearFilters()
            }
            .font(.caption)
            .foregroundColor(.blue)
            .disabled(productService.isLoading)
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
                        // 顶部加载指示器
                        if productService.isLoading && !productService.products.isEmpty {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("刷新中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        ForEach(productService.products) { product in
                            ProductRowView(product: product, onTap: {
                                // 确保状态在主线程更新
                                DispatchQueue.main.async {
                                    selectedProduct = product
                                    showingProductDetail = true
                                }
                            }, onImageTap: { imageURL in
                                // 检查 imageURL 是否为空或无效，避免崩溃
                                guard !imageURL.isEmpty, 
                                      URL(string: imageURL) != nil,
                                      selectedImageURL == nil else { return }
                                
                                // 确保在主线程上更新状态
                                DispatchQueue.main.async {
                                    selectedImageURL = imageURL
                                }
                            })
                        }
                        
                        // 加载更多
                        if productService.currentPage < productService.totalPages {
                            loadMoreView
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await productService.getProducts(params: searchParams)
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
        searchParams.name != nil ||
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
    let onImageTap: (String) -> Void
    
    // 获取主图或第一张图片
    private var mainImageURL: String? {
        if let images = product.images, !images.isEmpty {
            // 优先返回主图
            if let mainImage = images.first(where: { $0.isMain }) {
                return mainImage.url
            }
            // 如果没有主图，返回第一张图片
            return images.first?.url
        }
        return nil
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // 商品缩略图
                    if let imageURL = mainImageURL {
                        Button(action: {
                            onImageTap(imageURL)
                        }) {
                            AsyncImage(url: URL(string: imageURL)) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(0.8)
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
                                                .foregroundColor(.red)
                                        )
                                @unknown default:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
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

// MARK: - QuickLook Preview
struct QuickLookPreview: UIViewControllerRepresentable {
    let imageURL: String
    @State private var previewItem: PreviewItem?
    @State private var isLoading = true
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        
        // 添加完成按钮和分享按钮
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(context.coordinator.dismissPreview)
        )
        
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: context.coordinator,
            action: #selector(context.coordinator.shareImage)
        )
        
        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .fullScreen
        
        // 禁用向下滑动关闭手势
        navController.isModalInPresentation = true
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // 只在第一次加载时下载图片
        if isLoading {
            Task {
                await context.coordinator.downloadImage(from: imageURL)
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let previewController = uiViewController.topViewController as? QLPreviewController {
                        previewController.reloadData()
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: QuickLookPreview
        private var previewItem: PreviewItem?
        private weak var previewController: QLPreviewController?
        
        init(_ parent: QuickLookPreview) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            self.previewController = controller
            return 1 // 始终返回1，显示加载或实际内容
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            if let item = previewItem {
                return item
            } else {
                // 创建一个加载占位符
                let tempURL = createLoadingPlaceholder()
                return PreviewItem(url: tempURL, title: "正在加载...")
            }
        }
        
        private func createLoadingPlaceholder() -> URL {
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempURL = tempDirectory.appendingPathComponent("loading.txt")
            
            let loadingText = "正在加载图片，请稍候..."
            try? loadingText.write(to: tempURL, atomically: true, encoding: .utf8)
            
            return tempURL
        }
        
        private func createErrorPlaceholder() -> URL {
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempURL = tempDirectory.appendingPathComponent("error.txt")
            
            let errorText = "图片加载失败，请检查网络连接或稍后重试。"
            try? errorText.write(to: tempURL, atomically: true, encoding: .utf8)
            
            return tempURL
        }
        
        // 启用分享功能
        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
            return .createCopy
        }
        
        @objc func dismissPreview() {
            previewController?.dismiss(animated: true)
        }
        
        @objc func shareImage() {
            guard let previewItem = previewItem,
                  let url = previewItem.previewItemURL else { return }
            
            let activityViewController = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            // 为iPad设置popover
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.barButtonItem = previewController?.navigationItem.rightBarButtonItem
            }
            
            previewController?.present(activityViewController, animated: true)
        }
        
        @MainActor
        func downloadImage(from urlString: String) async {
            guard let url = URL(string: urlString) else { 
                print("无效的图片URL: \(urlString)")
                return 
            }
            
            do {
                // 设置超时时间
                var request = URLRequest(url: url)
                request.timeoutInterval = 30.0
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // 检查响应状态
                if let httpResponse = response as? HTTPURLResponse {
                    guard httpResponse.statusCode == 200 else {
                        print("图片下载失败，状态码: \(httpResponse.statusCode)")
                        return
                    }
                }
                
                // 检查数据是否有效
                guard data.count > 0 else {
                    print("图片数据为空")
                    return
                }
                
                // 创建临时文件
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileName = url.lastPathComponent.isEmpty ? "image.jpg" : url.lastPathComponent
                let tempURL = tempDirectory.appendingPathComponent(fileName)
                
                // 如果文件已存在，先删除
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                
                try data.write(to: tempURL)
                
                // 验证文件是否成功写入
                guard FileManager.default.fileExists(atPath: tempURL.path) else {
                    print("临时文件写入失败")
                    return
                }
                
                self.previewItem = PreviewItem(url: tempURL, title: "商品图片")
                
                // 立即刷新预览
                DispatchQueue.main.async {
                    self.previewController?.reloadData()
                }
                
            } catch {
                print("下载图片失败: \(error.localizedDescription)")
                
                // 创建错误占位符
                let errorURL = self.createErrorPlaceholder()
                self.previewItem = PreviewItem(url: errorURL, title: "图片加载失败")
                
                DispatchQueue.main.async {
                    self.previewController?.reloadData()
                }
            }
        }
    }
}

// MARK: - Preview Item
class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
    
    init(url: URL, title: String) {
        self.previewItemURL = url
        self.previewItemTitle = title
    }
}

// MARK: - Full Screen Image Viewer
struct FullScreenImageViewer: View {
    let imageURL: String
    @Environment(\.dismiss) private var dismiss
    // 当 sharePayload 被赋值时弹出分享面板
    @State private var sharePayload: SharePayload?
    // 保存结果提示
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    // 长按后显示操作菜单
    @State private var showActionMenu = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var imageSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            // 黑色背景
            Color.black
                .ignoresSafeArea()
            
            // 图片内容（支持自然缩放与拖动）
            ZoomableAsyncImage(imageURL: imageURL) {
                // 长按回调
                showActionMenu = true
            }
            
            // 顶部工具栏
            VStack {
                HStack {
                    // 返回按钮
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // 分享按钮
                    Button(action: {
                        shareImage()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .statusBarHidden()
        // 当 sharePayload 有值时显示分享弹窗
        .sheet(item: $sharePayload) { payload in
            ActivityView(activityItems: payload.items)
        }
        // 保存完成/失败提示
        .alert(saveAlertMessage, isPresented: $showSaveAlert) {
            Button("确定", role: .cancel) {}
        }
        // 操作菜单
        .confirmationDialog("请选择操作", isPresented: $showActionMenu, titleVisibility: .visible) {
            Button("保存到相册") {
                saveImageToAlbum()
            }
            Button("取消", role: .cancel) {}
        }
    }
    
    private func shareImage() {
        // 异步下载图片到本地后再分享，避免直接分享远程URL导致白屏
        Task {
            guard let url = URL(string: imageURL) else { return }
            do {
                // 30秒超时
                var request = URLRequest(url: url)
                request.timeoutInterval = 30
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200, !data.isEmpty {
                    // 写入临时文件
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileName: String
                    if url.lastPathComponent.isEmpty {
                        fileName = UUID().uuidString + ".jpg"
                    } else {
                        fileName = url.lastPathComponent
                    }
                    let tempURL = tempDir.appendingPathComponent(fileName)
                    // 如果已存在则覆盖
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try data.write(to: tempURL)
                    // 更新状态触发分享面板
                    await MainActor.run {
                        sharePayload = SharePayload(items: [UIImage(data: data) ?? tempURL])
                    }
                    return
                }
                // 如果下载失败，则直接分享原URL（可能仍然可行）
                await MainActor.run {
                    sharePayload = SharePayload(items: [url])
                }
            } catch {
                // 下载出错时，直接分享原URL
                await MainActor.run {
                    sharePayload = SharePayload(items: [url])
                }
            }
        }
    }

    // MARK: - 保存图片到相册
    private func saveImageToAlbum() {
        Task {
            guard let url = URL(string: imageURL) else { return }
            do {
                // 30秒超时
                var request = URLRequest(url: url)
                request.timeoutInterval = 30
                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200, !data.isEmpty,
                   let image = UIImage(data: data) {
                    // 请求相册权限（仅添加权限即可）
                    let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
                    if status == .notDetermined {
                        _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                    }

                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    await MainActor.run {
                        saveAlertMessage = "已保存到相册"
                        showSaveAlert = true
                    }
                } else {
                    await MainActor.run {
                        saveAlertMessage = "保存失败"
                        showSaveAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    saveAlertMessage = "保存失败: \(error.localizedDescription)"
                    showSaveAlert = true
                }
            }
        }
    }
}

// MARK: - ZoomableAsyncImage - 更自然的缩放与拖动
struct ZoomableAsyncImage: UIViewRepresentable {
    let imageURL: String
    let onLongPress: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5
        scrollView.minimumZoomScale = 1
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        
        // ImageView
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        // Loading indicator
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])
        indicator.startAnimating()
        
        // Long press
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        scrollView.addGestureRecognizer(longPress)
        
        context.coordinator.imageView = imageView
        context.coordinator.indicator = indicator
        context.coordinator.loadImage(from: imageURL)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Nothing to update; the image only loads once.
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: ZoomableAsyncImage
        var imageView: UIImageView?
        var indicator: UIActivityIndicatorView?
        private var cancellable: AnyCancellable?
        
        init(_ parent: ZoomableAsyncImage) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
        
        @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
            if sender.state == .began {
                parent.onLongPress()
            }
        }
        
        func loadImage(from urlString: String) {
            guard let url = URL(string: urlString) else { 
                // URL无效时停止加载指示器
                DispatchQueue.main.async { [weak self] in
                    self?.indicator?.stopAnimating()
                }
                return 
            }
            cancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map { UIImage(data: $0.data) }
                .replaceError(with: nil)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] image in
                    guard let self = self else { return }
                    self.indicator?.stopAnimating()
                    self.imageView?.image = image
                }
        }
    }
}

// 通用的分享 ActivityView
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity] = []
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 让String支持Identifiable，便于作为fullScreenCover(item:)的绑定类型
extension String: Identifiable {
    public var id: String { self }
} 

// MARK: - 让 URL 支持 Identifiable，以便用作 sheet(item:) 绑定类型
extension URL: Identifiable {
    public var id: String { absoluteString }
} 

// MARK: - 分享负载结构
struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
} 
