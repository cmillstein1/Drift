//
//  FaceVerificationCameraView.swift
//  Drift
//
//  Custom camera view with face guide overlay for verification
//

import SwiftUI
import AVFoundation

struct FaceVerificationCameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    init(capturedImage: Binding<UIImage?>) {
        self._capturedImage = capturedImage
    }
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        controller.modalPresentationStyle = .fullScreen
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: FaceVerificationCameraView
        
        init(_ parent: FaceVerificationCameraView) {
            self.parent = parent
        }
        
        func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage) {
            parent.capturedImage = image
            parent.dismiss()
        }
        
        func cameraViewControllerDidCancel(_ controller: CameraViewController) {
            parent.dismiss()
        }
    }
}

protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
}

class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var overlayView: FaceGuideOverlayView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
        // Ensure preview layer frame is set after view appears
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.previewLayer?.frame = self.view.bounds
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func setupCamera() {
        // Check current permission status
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            configureCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.configureCamera()
                    }
                } else {
                }
            }
        default:
            break
        }
    }
    
    private func configureCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                return
            }
            
            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                photoOutput = output
            } else {
                return
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            
            // Insert preview layer at the back
            view.layer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer
            self.captureSession = session
            
            // Set frame after adding to layer
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.previewLayer?.frame = self.view.bounds
            }
        } catch {
        }
    }
    
    private func setupUI() {
        // Overlay with face guide
        let overlay = FaceGuideOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = .clear
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.overlayView = overlay
        
        // Native-style capture button container
        let captureButtonContainer = UIView()
        captureButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButtonContainer)
        
        // Outer ring (larger circle)
        let outerRing = UIView()
        outerRing.backgroundColor = .clear
        outerRing.layer.borderWidth = 4
        outerRing.layer.borderColor = UIColor.white.cgColor
        outerRing.layer.cornerRadius = 40
        outerRing.translatesAutoresizingMaskIntoConstraints = false
        captureButtonContainer.addSubview(outerRing)
        
        // Inner capture button (white circle)
        let captureButton = UIButton(type: .custom)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 30
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButtonContainer.addSubview(captureButton)
        
        NSLayoutConstraint.activate([
            captureButtonContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButtonContainer.widthAnchor.constraint(equalToConstant: 80),
            captureButtonContainer.heightAnchor.constraint(equalToConstant: 80),
            
            outerRing.centerXAnchor.constraint(equalTo: captureButtonContainer.centerXAnchor),
            outerRing.centerYAnchor.constraint(equalTo: captureButtonContainer.centerYAnchor),
            outerRing.widthAnchor.constraint(equalToConstant: 80),
            outerRing.heightAnchor.constraint(equalToConstant: 80),
            
            captureButton.centerXAnchor.constraint(equalTo: captureButtonContainer.centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: captureButtonContainer.centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 60),
            captureButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }
    
    @objc private func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            settings = AVCapturePhotoSettings()
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func cancel() {
        delegate?.cameraViewControllerDidCancel(self)
    }
    
    private func startSession() {
        guard let session = captureSession else { return }
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    private func stopSession() {
        guard let session = captureSession else { return }
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // Fix orientation for front camera
        let fixedImage = image.fixedOrientation()
        delegate?.cameraViewController(self, didCaptureImage: fixedImage)
    }
}

// MARK: - Face Guide Overlay

class FaceGuideOverlayView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Semi-transparent background
        context.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        context.fill(rect)
        
        // Calculate oval frame (centered, portrait-oriented)
        let ovalWidth: CGFloat = min(rect.width * 0.7, 280)
        let ovalHeight: CGFloat = ovalWidth * 1.3 // Slightly taller for face
        let ovalX = (rect.width - ovalWidth) / 2
        let ovalY = (rect.height - ovalHeight) / 2 - 40 // Slightly higher
        let ovalRect = CGRect(x: ovalX, y: ovalY, width: ovalWidth, height: ovalHeight)
        
        // Clear the oval area
        context.setBlendMode(.clear)
        context.fillEllipse(in: ovalRect)
        context.setBlendMode(.normal)
        
        // Draw dotted oval border
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(3.0)
        context.setLineDash(phase: 0, lengths: [8, 8])
        context.addEllipse(in: ovalRect)
        context.strokePath()
        
        // Draw instruction text
        let instructionText = "Position your face in the oval"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        let textSize = instructionText.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: ovalRect.maxY + 20,
            width: textSize.width,
            height: textSize.height
        )
        instructionText.draw(in: textRect, withAttributes: attributes)
    }
}

// MARK: - UIImage Extension for Orientation Fix and Resizing

extension UIImage {
    func fixedOrientation() -> UIImage {
        // Front camera images are mirrored, so we need to flip horizontally
        guard let cgImage = self.cgImage else { return self }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return self
        }
        
        // Flip horizontally for front camera
        context.translateBy(x: CGFloat(width), y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let flippedImage = context.makeImage() else {
            return self
        }
        
        return UIImage(cgImage: flippedImage, scale: self.scale, orientation: .up)
    }
    
    func resized(to targetSize: CGSize, aspectFill: Bool = true) -> UIImage {
        let size = self.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize: CGSize
        if aspectFill {
            // Scale to fill
            let ratio = max(widthRatio, heightRatio)
            newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        } else {
            // Scale to fit
            let ratio = min(widthRatio, heightRatio)
            newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        }
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? self
    }
}
