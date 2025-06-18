import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    let onFound: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onCodeScanned = onFound
        vc.onCancelled = onCancel
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var onCodeScanned: ((String) -> Void)?
        var onCancelled: (() -> Void)?

        private var captureSession: AVCaptureSession?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            captureSession = AVCaptureSession()

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice)

            if let input = videoInput, captureSession!.canAddInput(input) {
                captureSession!.addInput(input)
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession!.canAddOutput(metadataOutput) {
                captureSession!.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            captureSession!.startRunning()

            let cancelButton = UIButton(type: .system)
            cancelButton.setTitle("Cancel", for: .normal)
            cancelButton.tintColor = .white
            cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
            cancelButton.frame = CGRect(x: 20, y: 40, width: 80, height: 40)
            view.addSubview(cancelButton)
        }

        @objc func cancel() {
            captureSession?.stopRunning()
            onCancelled?()
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let code = metadataObject.stringValue {
                captureSession?.stopRunning()
                onCodeScanned?(code)
            }
        }
    }
}
