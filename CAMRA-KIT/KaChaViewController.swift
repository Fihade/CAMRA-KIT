//
//  KaChaViewController.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/22.
//

import UIKit
import AVFoundation
import Photos
import BackgroundTasks


extension Notification.Name {
    static let CameraZoomDidChange = Notification.Name("CameraZoomDidChange")
}

//MARK: Enum Properties Of Control
enum CaptureDeviceSetupResult {
    case success
    case notAuthorized
    case failed
}
enum FlashMode {
    case on
    case off
    
    var AVCaptureFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .on:
            return .on
        default:
            return .off
        }
    }
    
    mutating func switchMode() {
        if self == .on {
            self = .off
        } else {
            self = .on
        }
    }
}

class KaChaViewController: UIViewController {
    
    //MARK: Outlet On Screen
    // preview
    @IBOutlet weak var previewView: KaChaPreviewView!
//    @IBOutlet weak var capturedImageView: CapturedImageView!
    @IBOutlet weak var imageView: CapturedImageView!
    // buttons about camera settings
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    
    @IBOutlet weak var captureButtonBG: UIView!
    @IBOutlet weak var rawButton: RawButton!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var gridView: UIButton!
    @IBOutlet weak var autoFocusButton: AutoFocusButton!
    @IBOutlet weak var zoomButton: ZoomFactorButton!
    
    @IBOutlet weak var EVStepper: UIStepper!
    @IBOutlet weak var isoLabel: UILabel!
    //    var capturedImageView: CapturedImageView!
    
    //focus frame View
    var focusView: UIView?
    
    let detailsView: FaceView = {
         let detailsView = FaceView()
         detailsView.setup()
         
         return detailsView
     }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    

    var previewOrientation: AVCaptureVideoOrientation! {
        get {
            return AVCaptureVideoOrientation.setOrientationFromWindow(view.window?.windowScene?.interfaceOrientation ?? UIInterfaceOrientation.portrait)
        }
    }
    
    private var camerasSetupResult: CaptureDeviceSetupResult = .success
    private var sessionQueue = DispatchQueue(label: "Camera Session Queue")
    private var session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private lazy var photoOutput = AVCapturePhotoOutput()
    private var zoomFactor: CGFloat = 1 {
        didSet {
//            guard let device = self.videoDeviceInput?.device else {
//                return
//            }
//
//            do {
//                try device.lockForConfiguration()
//                device.videoZoomFactor = zoomFactor
//                device.unlockForConfiguration()
//            } catch {
//                return
//            }
        }
    }
    private var flashMode: FlashMode = .off {
        didSet {
            flashButton.tintColor = (flashMode == .on) ? UIColor(named: "HighlightedColor") : .white
        }
    }
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
        mediaType: .video,
        position: .unspecified
     )
    private var photoQuality = AVCapturePhotoOutput.QualityPrioritization.quality
    
    private var inProgressPhotoCaptureDelegates = [Int64: KaChaCapturePhotoDelegate]()
    
    // lens setting
    public var supportedExtraLens = [AVCaptureDevice?]()
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    
    @IBAction func adjustEV(_ sender: UIStepper) {
        let device = videoDeviceInput.device
        
        do {
            try device.lockForConfiguration()
            device.setExposureTargetBias(Float(sender.value))
            device.unlockForConfiguration()
        } catch {
            fatalError()
        }
        
    }
    //MARK: View Cycle Control
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewView.session = session
        // check camera authorization
        checkAuthorizationOfCapture()
        // configure session
        sessionQueue.async {
            self.configureSession()
        }
        
        // Notification
        NotificationCenter.default.addObserver(
            forName: .CameraZoomDidChange,
            object: self,
            queue: .main,
            using: {_ in
                let s = "\(self.zoomFactor)".prefix(3)
                self.zoomButton.setTitle("\(s)x", for: .normal)
            }
        )
        // some layout
        setup()
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapImage(_:))))
        
    }
    
    let transition = PopAnimator()
    
    @objc func tapImage(_ sender: UITapGestureRecognizer) {
        let imageVC = storyboard?.instantiateViewController(identifier: "imageViewController") as! ImageViewController
//        imageVC.imageView.image = (sender.view as! CapturedImageView).image
        imageVC.image = imageView.image
        imageVC.transitioningDelegate = self
        
        present(imageVC, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // access capture button enable
        sessionQueue.async {
            switch self.camerasSetupResult {
                case .success:
                    DispatchQueue.main.async {[weak self] in
//                        self?.captureButton.isEnabled = true
                        self?.buttonsState(true)
                    }
                    self.session.startRunning()
                case .notAuthorized:
                    DispatchQueue.main.async {[weak self] in
                        self?.operateResultNotAuthorized()
                    }
                case .failed:
                    DispatchQueue.main.async {[weak self] in
                        self?.operateResultFailed()
                    }
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        view.addSubview(detailsView)
        view.bringSubviewToFront(detailsView)
    }
    
    private func setup() {
        buttonsState(true)
        
        captureButtonBG.layer.cornerRadius = 45
        rawButton.isEnabled = photoOutput.isAppleProRAWSupported
    }
    
    private func buttonsState(_ state: Bool) {
        captureButton.isEnabled = state
        gridView.isEnabled = state
        toggleButton.isEnabled = state
        zoomButton.isEnabled = state
//        rawButton.isEnabled = photoOutput.isAppleProRAWSupported
        autoFocusButton.isEnabled = state
        flashButton.isEnabled = state
        EVStepper.isEnabled = state
    }
}

extension KaChaViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.originFrame = imageView.superview!.convert(imageView.frame, to: nil)

        transition.presenting = true
        imageView.isHidden = true

        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = false
        imageView.isHidden = false
//        return transition
        return nil
    }
}

//MARK: Configure Session
extension KaChaViewController {
    
    private func configureSession() {
        // check setup result
        if camerasSetupResult != .success { return }
        
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        var cameraDevice: AVCaptureDevice?
        // choose camera device
        if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back){
            cameraDevice = dualCameraDevice
        } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            cameraDevice = backCameraDevice
        } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            cameraDevice = frontCameraDevice
        }
        
        guard let device = cameraDevice else {
            print("Not Found any camera device availible")
            
            self.camerasSetupResult = .failed
    
            session.commitConfiguration()
            return
        }
        print("device: \(device)")
        
//        print("device camera types: \(session.i)")
//        print("min: \(device.minExposureTargetBias)")
    
        
        print("device init focus: \(device.focusMode == .continuousAutoFocus)  \(device.exposureMode.rawValue)")
        
        // try to add input
        do {
            let cameraDeviceInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(cameraDeviceInput) {
                session.addInput(cameraDeviceInput)
                videoDeviceInput = cameraDeviceInput

                DispatchQueue.main.async {[weak self] in
                    self?.previewView.videoPreviewLayer.connection?.videoOrientation = self?.previewOrientation ?? .portrait
                    self?.EVStepper.maximumValue = Double(device.maxExposureTargetBias)
                    self?.EVStepper.minimumValue = Double(device.minExposureTargetBias)
                    self?.EVStepper.value = 0
                    print("preview Orientation: \(String(describing: self?.previewOrientation.rawValue))")
                }
                                            
            } else {
                print("Couldn't add video device input to the session.")
                self.camerasSetupResult = .failed
                session.commitConfiguration()
                return
            }
   
        } catch {
            print("Couldn't create video device input: \(error)")
            camerasSetupResult = .failed
            session.commitConfiguration()
            return
        }
        
//        self.previewView.videoPreviewLayer.connection?.videoMinFrameDuration = CMTime(seconds: 0.8, preferredTimescale: 1)
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: .main)

        
        // try to add output
        if session.canAddOutput(photoOutput) {
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isAppleProRAWEnabled = photoOutput.isAppleProRAWSupported
            /// - Tag: photo quality 优先级
            // photo quality 优先级 尽量在 session running 之前设置, 不然 session 会 rebuilt
            /// - Tag:  it's so expensive
            photoOutput.maxPhotoQualityPrioritization = .quality
            session.addOutput(photoOutput)
            session.addOutput(output)
            
        } else {
            print("cant add output device")
            session.commitConfiguration()
            return
        }
        print("session.commitConfiguration")
        session.commitConfiguration()
    }
    
    /// - tag: when session failed
    private func operateResultFailed() {
        DispatchQueue.main.async {
            let alertMsg = "Alert message when something goes wrong during capture session configuration"
            let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
            let alertController = UIAlertController(title: "KaCha", message: message, preferredStyle: .alert)
            
            alertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("OK", comment: "Alert OK button"),
                    style: .cancel
                )
            )
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    /// - tag: when session is not authorized
    private func operateResultNotAuthorized() {
        
        let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
        let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        
        alertController.addAction(
            UIAlertAction(
                title: NSLocalizedString("OK", comment: "Alert OK button"),
                style: .cancel,
                handler: nil
            )
        )
        
        alertController.addAction(
            UIAlertAction(
                title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                style: .`default`,
                handler: { _ in
                    UIApplication.shared.open(
                        URL(string: UIApplication.openSettingsURLString)!,
                        options: [:],
                        completionHandler: nil
                    )
                }
            )
        )
        
        self.present(alertController, animated: true, completion: nil)
    }
}

//MARK: Check Authorization Of Camera or PhotoLibraryUsage
extension KaChaViewController {
    private func checkAuthorizationOfCapture() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("authorized")
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                if !success {
                    self.camerasSetupResult = .notAuthorized
                }
            }
        default:
            self.camerasSetupResult = .notAuthorized
        }
    }
    
    private func checkAuthorizationOfPhotoLibraryUsage() -> Bool {
        var success = false;
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                success = true
            }
        }
        return success
    }
}

//MARK: Capture Photo
extension KaChaViewController {
    @IBAction func capturePhoto(_ sender: UIButton) {
        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            
            print("raw types: \(self.photoOutput.availableRawPhotoFileTypes)")
            print("raw enable: \(self.photoOutput.isAppleProRAWEnabled)")
            
            let query = self.photoOutput.isAppleProRAWEnabled ?
                { AVCapturePhotoOutput.isAppleProRAWPixelFormat($0) } :
                { AVCapturePhotoOutput.isBayerRAWPixelFormat($0) }

            guard let rawFormat = self.photoOutput.availableRawPhotoPixelFormatTypes.first(where: query) else {
                fatalError("No RAW format found.")
            }
            print("raw format: \(rawFormat)")
            
            let processedFormat = [AVVideoCodecKey: AVVideoCodecType.hevc]
//

            let photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat, processedFormat: processedFormat)
            
            
//            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
//                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
//            }
            
            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = self.flashMode.AVCaptureFlashMode
            }
            
            photoSettings.isHighResolutionPhotoEnabled = true
            
//            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
//                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
//            }
            // set photo quality
//            photoSettings.photoQualityPrioritization = .quality
            
            let captureDelegate = KaChaCapturePhotoDelegate(
                with: photoSettings,
                willCapturePhotoAnimation: {
                    DispatchQueue.main.async {
                        self.previewView.videoPreviewLayer.opacity = 0
                        UIView.animate(withDuration: 0.25) {
                            self.previewView.videoPreviewLayer.opacity = 1
                        }
                        self.captureButton.isEnabled = false
                        self.imageView.startAnimate()
                    }
                },
                photoProcessingHandler: { success in
                    self.imageView.stopAnimate()
                    
                },
                didFinishCaptureHandler: {data in
                    self.imageView.image = UIImage(data: data)
                    self.captureButton.isEnabled = true
                },
                occuredErrorWhenCapturing: {error in
//                    if let error = error {
//                        fatalError(error)
//                    }
                },
                completionHandler: {delegate in
                    self.sessionQueue.async {
                        self.inProgressPhotoCaptureDelegates[delegate.requestedPhotoSettings.uniqueID] = nil
                    }
                    
                })
            
            self.inProgressPhotoCaptureDelegates[captureDelegate.requestedPhotoSettings.uniqueID] = captureDelegate

            self.photoOutput.capturePhoto(with: photoSettings, delegate: captureDelegate)
        }

    }
}

//MARK: Operation of Camera such as flash, focus, zoom,
extension KaChaViewController {
    
    //MARK: Toggle Camera front or rear
    @IBAction func toggleCamera(_ sender: UIButton) {
        captureButton.isEnabled = false
        
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInTrueDepthCamera
                
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
            }
            
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // seek a prefreed Device based current position and type
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let newVideoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: newVideoDevice)
                    
                    self.session.beginConfiguration()
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        // 替代
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }
                    
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                    
                    self.session.commitConfiguration()
                    
                } catch {
                    print("toggle have error: \(error)")
                }
            }
            DispatchQueue.main.async {[weak self] in
                self?.captureButton.isEnabled = true
            }
        }
    }
    
    @IBAction func toggleFlashMode(_ sender: UIButton) {
        print("falsh tap")
        flashMode.switchMode()
    }
    
    @IBAction func tapFocus(_ sender: UITapGestureRecognizer) {
        let location: CGPoint = sender.location(in: sender.view)
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(
            fromLayerPoint: sender.location(in: sender.view)
        )
        if let focusView = focusView {
            focusView.removeFromSuperview()
        }
        let focusOfFrame = UIView(frame: .zero)
        focusOfFrame.center = location
        focusOfFrame.bounds.size = CGSize(width: 100, height: 100)
        focusOfFrame.layer.borderColor = UIColor(named: "lightedColor")?.cgColor
        focusOfFrame.layer.borderWidth = 1
        sender.view?.addSubview(focusOfFrame)
        focusView = focusOfFrame
        
        print("tap focus: \(sender.location(in: previewView))")
        
        focus(with: .autoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    
    
    @IBAction func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .began {
            recognizer.scale = self.zoomFactor
        }
        
        let zoom = max(1.0, min(10.0, recognizer.scale))
        self.zoomFactor = zoom
        NotificationCenter.default.post(name: .CameraZoomDidChange, object: self)
        
        if recognizer.state == .ended {
            self.zoomFactor = zoom
        }
    }
    
    @IBAction func autoFocus(_ button: AutoFocusButton) {
        button.isOn.toggle()
        
        focusView?.removeFromSuperview()
        let device = videoDeviceInput.device
        do {
            try device.lockForConfiguration()
            device.focusMode = .autoFocus
            device.exposureMode = .continuousAutoExposure
            device.isSmoothAutoFocusEnabled = device.isSmoothAutoFocusSupported
            print("focus: \(device.focusMode == .autoFocus)")
            print("expo: \(device.exposureMode == .continuousAutoExposure)")
            device.unlockForConfiguration()
        } catch {
            return
        }
    }
    
    //Capture if RAW format
    @IBAction func captureRAW(_ button: RawButton) {
        button.isOn.toggle()
    }
    
    //Show grid view or not
    @IBAction func showGrid(_ sender: UIButton) {
        previewView.showGridView.toggle()
        if previewView.showGridView {
            gridView.tintColor = UIColor(named: "HighlightedColor")
        } else {
            gridView.tintColor = .white
        }
        
    }
    
    // zoom
    @IBAction func zoom(_ sender: UIButton) {
        
        switch zoomFactor {
            case 1:
                zoomFactor = 2
            case 2:
                zoomFactor = 0.5
            default:
                zoomFactor = 1
        }
    }
    
    /// Setup extra lens
    private func setupExtraLens() {
        // If triple camera, add telephoto and ultrawide settings.
        if AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) != nil {
            let extraLens = [
                AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back),
                AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
            ]
            
            supportedExtraLens = extraLens
            
        } else if AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) != nil {
            let extraLens = [
                AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
            ]
            
            supportedExtraLens = extraLens
            
        } else if AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) != nil {
            let extraLens = [
                AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
            ]
            
            supportedExtraLens = extraLens
            
        } else {
            supportedExtraLens = [nil]
        }
    }
    
    /// Get the next extra lens that should be presented
    private func getNextExtraLens() -> AVCaptureDevice? {
        guard let input = session.inputs[0] as? AVCaptureDeviceInput else { return backCamera }
        
        if var currentIndex = supportedExtraLens.firstIndex(of: input.device) {
            currentIndex += 1 // get the next value
            return currentIndex >= supportedExtraLens.count ? backCamera : supportedExtraLens[currentIndex]
            
        } else {
            return supportedExtraLens.first ?? backCamera
        }
    }
}

//MARK: Face detection
extension KaChaViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        
        let device = videoDeviceInput.device
        
        isoLabel.text = "ISO: \(Int(device.iso))"
        
        print("duration: \(device.exposureDuration.seconds)")
        
        print("expose mode: \(device.exposureMode.rawValue)")
//        print("is focusing: \(device.isAdjustingFocus)")
//        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
//        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as? [CIImageOption : Any])
//        let options: [String : Any] = [CIDetectorImageOrientation: exifOrientation(orientation: UIDevice.current.orientation),
//                                       CIDetectorSmile: true,
//                                       CIDetectorEyeBlink: true]
//        let allFeatures = faceDetector?.features(in: ciImage, options: options)
//
//        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
//        let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, originIsAtTopLeft: false)
//
//        guard let features = allFeatures else { return }
//
//        for feature in features {
//            if let faceFeature = feature as? CIFaceFeature {
//                let faceRect = calculateFaceRect(facePosition: faceFeature.mouthPosition, faceBounds: faceFeature.bounds, clearAperture: cleanAperture)
//                let featureDetails = ["has smile: \(faceFeature.hasSmile)",
//                    "has closed left eye: \(faceFeature.leftEyeClosed)",
//                    "has closed right eye: \(faceFeature.rightEyeClosed)"]
//                print("face detected")
//                update(with: faceRect, text: featureDetails.joined(separator: "\n"))
//            }
//        }
//
//        if features.count == 0 {
//            DispatchQueue.main.async {
//                self.detailsView.alpha = 0.0
//            }
//        }
    }
//
//    func update(with faceRect: CGRect, text: String) {
//        DispatchQueue.main.async {
//            UIView.animate(withDuration: 0.2) {
//                self.detailsView.detailsLabel.text = text
//                self.detailsView.alpha = 1.0
//                self.detailsView.frame = faceRect
//            }
//        }
//    }
//
//    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
//        switch orientation {
//        case .portraitUpsideDown:
//            return 8
//        case .landscapeLeft:
//            return 3
//        case .landscapeRight:
//            return 1
//        default:
//            return 6
//        }
//    }
//
//    func videoBox(frameSize: CGSize, apertureSize: CGSize) -> CGRect {
//        let apertureRatio = apertureSize.height / apertureSize.width
//        let viewRatio = frameSize.width / frameSize.height
//
//        var size = CGSize.zero
//
//        if (viewRatio > apertureRatio) {
//            size.width = frameSize.width
//            size.height = apertureSize.width * (frameSize.width / apertureSize.height)
//        } else {
//            size.width = apertureSize.height * (frameSize.height / apertureSize.width)
//            size.height = frameSize.height
//        }
//
//        var videoBox = CGRect(origin: .zero, size: size)
//
//        if (size.width < frameSize.width) {
//            videoBox.origin.x = (frameSize.width - size.width) / 2.0
//        } else {
//            videoBox.origin.x = (size.width - frameSize.width) / 2.0
//        }
//
//        if (size.height < frameSize.height) {
//            videoBox.origin.y = (frameSize.height - size.height) / 2.0
//        } else {
//            videoBox.origin.y = (size.height - frameSize.height) / 2.0
//        }
//
//        return videoBox
//    }
//
//    func calculateFaceRect(facePosition: CGPoint, faceBounds: CGRect, clearAperture: CGRect) -> CGRect {
//        let parentFrameSize = previewView.layer.frame.size
//        let previewBox = videoBox(frameSize: parentFrameSize, apertureSize: clearAperture.size)
//
//        var faceRect = faceBounds
//
//        swap(&faceRect.size.width, &faceRect.size.height)
//        swap(&faceRect.origin.x, &faceRect.origin.y)
//
//        let widthScaleBy = previewBox.size.width / clearAperture.size.height
//        let heightScaleBy = previewBox.size.height / clearAperture.size.width
//
//        faceRect.size.width *= widthScaleBy
//        faceRect.size.height *= heightScaleBy
//        faceRect.origin.x *= widthScaleBy
//        faceRect.origin.y *= heightScaleBy
//
//        faceRect = faceRect.offsetBy(dx: 0.0, dy: previewBox.origin.y)
//        let frame = CGRect(x: parentFrameSize.width - faceRect.origin.x - faceRect.size.width / 2.0 - previewBox.origin.x / 2.0, y: faceRect.origin.y, width: faceRect.width, height: faceRect.height)
//
//        return frame
//    }
}

extension AVCaptureVideoOrientation {
    
    static func setOrientationFromWindow(_ windowOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch windowOrientation {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portrait
        default:
            return .portrait
        }
    }
}

//MARK: ADD Animation to UIImageView
extension UIImageView {
    func startAnimate() {

        
    
        
        let borderWidthAnimate = CABasicAnimation(keyPath: "borderWidth")
        borderWidthAnimate.fromValue = 0
        borderWidthAnimate.toValue = 5
        borderWidthAnimate.duration = 1
        borderWidthAnimate.autoreverses = true

        let borderColorAnimate = CABasicAnimation(keyPath: "borderColor")
        borderColorAnimate.toValue = UIColor(named: "HighlightedColor")?.cgColor
        borderColorAnimate.duration = 1
        
        self.layer.add(borderWidthAnimate, forKey: nil)
        self.layer.add(borderColorAnimate, forKey: nil)

    }
    
    func stopAnimate() {
        DispatchQueue.main.async {
            self.layer.removeAllAnimations()
        }
    }
}
