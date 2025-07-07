import SwiftUI
import AVFoundation

// MARK: - 条形码扫描视图
struct BarcodeScannerView: UIViewControllerRepresentable {
    /// 扫描成功回调
    var onFound: (String) -> Void
    /// 取消回调（可选）
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        // 无需动态更新
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: BarcodeScannerView
        private var isFound = false

        init(parent: BarcodeScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                             didOutput metadataObjects: [AVMetadataObject],
                             from connection: AVCaptureConnection) {
            guard !isFound,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue else { return }

            isFound = true
            // 返回扫描结果
            parent.onFound(value)
        }
    }
}

// MARK: - 内部控制器
class ScannerViewController: UIViewController {
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    var onCancel: (() -> Void)?
    private let session = AVCaptureSession()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    // 专用串行队列，避免在主线程上调用 session 的耗时操作
    private let sessionQueue = DispatchQueue(label: "scanner.session.queue")
    // MARK: - Torch Control
    private func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch configuration error: \(error)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()

        // 关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.startRunning()
            let torchOn = UserDefaults.standard.bool(forKey: "scannerTorchOn")
            self.setTorch(on: torchOn)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.stopRunning()
            self.setTorch(on: false)
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.stopRunning()
            self.setTorch(on: false)
        }
        onCancel?()
    }

    private func configureSession() {
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        if session.canAddInput(videoInput) { session.addInput(videoInput) }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: .main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code39, .code93, .code128, .qr, .dataMatrix, .itf14, .interleaved2of5]
        }

        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)

        // 如需添加关闭按钮可在此处扩展
    }
} 