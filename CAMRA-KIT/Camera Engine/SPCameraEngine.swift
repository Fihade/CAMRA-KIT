//
//  CameraEngine.swift
//  CameraEngine
//
//  Created by Fihade on 2021/5/5.
//

import UIKit
import Foundation
import AVFoundation
import Accelerate

protocol SPCameraEngineDelegate: AnyObject {
    
    func displayRGBHistogramWith(layers: [CAShapeLayer]?)
    func toggleCamera(to back: Bool)
}

class SPCameraEngine: NSObject {
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    public enum RAWMode {
        case DNG
        case AppleRAW
    }
    
    private var setupResult: SessionSetupResult = .success
    
    private var captureSession = AVCaptureSession()
    private var previewView: SPPreviewView! {
        didSet {
            previewView?.session = captureSession
        }
    }
    
    private var sessionQueue = DispatchQueue(label: "Camera Session Queue")
    
    private var captureDeviceInput: AVCaptureDeviceInput!
    private let photoDataOutput = AVCapturePhotoOutput()
    
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    public var currentCamera: AVCaptureDevice? {
        didSet {
            isRAWSupported = (currentCamera == backCamera)
            if let currentCamera = currentCamera {
                maxBias = currentCamera.maxExposureTargetBias
                minBias = currentCamera.minExposureTargetBias
            }
        }
    }
    
    private var pinchRecognizer: UIPinchGestureRecognizer?
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera],
        mediaType: .video,
        position: .unspecified
    )
    
    // Related to RAW
    public var rawMode: RAWMode = .DNG
    public var rawOrMax = false
    public var isRAWSupported = true
    
    // Related to Focus/Flash
    private var focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus
    public var flashMode: AVCaptureDevice.FlashMode = .off
    
    // Related to Zoom
    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 3.0
    private var lastZoomFactor: CGFloat = 1.0
    
    // Related to exposure
    private var exposureMode: AVCaptureDevice.ExposureMode = .continuousAutoExposure
    private let exposureDurationPower: Float = 4.0 // the exposure slider gain
    private let exposureMininumDuration: Float64 = 1.0 / 2000.0
    public var maxBias: Float = 6
    public var minBias: Float = -6
    
    private var exposureValue: Float = 0.5
    private var translationY: Float = 0
    public var expoChange: ((Float) -> Void)?
    
    // Delay Capture Time
    public var delayTime = 0
    
    
    // Other
    public var swipeGestures: [UISwipeGestureRecognizer]?
    
    private var inProgressPhotoCaptureDelegates = [Int64: SPCapturePhotoCaptureDelegate]()
    
    public weak var delegate: SPCameraEngineDelegate?
    
    var cgImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        colorSpace: nil,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue),
        version: 0,
        decode: nil,
        renderingIntent: .defaultIntent)
    
    var converter: vImageConverter?
    
    var sourceBuffers = [vImage_Buffer]()
    var destinationBuffer = vImage_Buffer()
    let vNoFlags = vImage_Flags(kvImageNoFlags)
    
    public override init() {
        super.init()
        checkPermission()
        setupCaptureSession()
    }
    
    deinit {
        destinationBuffer.free()
    }
    
    // Check permission to use camera
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                break
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if !granted {
                        self.setupResult = .notAuthorized
                    }
                })
            default:
                setupResult = .notAuthorized
        }
    }
    
    public func startCameraRunning() {
        self.captureSession.startRunning()
    }
    
    public func stopCameraRunning() {
        self.captureSession.stopRunning()
    }
    
    private func setRaw(_ raw: Bool) {
        self.rawOrMax = raw
        if raw {
            do {
                try currentCamera?.lockForConfiguration()
                self.currentCamera?.videoZoomFactor = 1.0
                if let pinchRecognizer = pinchRecognizer {
                    self.previewView?.removeGestureRecognizer(pinchRecognizer)

                }
                currentCamera?.unlockForConfiguration()
            } catch  {
                fatalError()
            }
        } else {
            attachZoom(to: previewView!)
        }
    }
    
    // Set Flash
    public func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        self.flashMode = mode
    }
    
    // Set EV
    public func setDeviceBias(_ bias: Float) {
        if let device = currentCamera {
            do {
                try device.lockForConfiguration()
                device.setExposureTargetBias(bias, completionHandler: nil)
                device.unlockForConfiguration()
            } catch {
                fatalError("error: \(error)")
            }
        }
    }
   
}

// Setup CaptureSession
extension SPCameraEngine {
    
    private func setupCaptureSession() {
        captureSession.sessionPreset = .photo
        
        // Make sure our device
        let devices = videoDeviceDiscoverySession.devices
        
        for device in devices {

            if device.position == .back {
                backCamera = device
            } else if device.position == .front {
                frontCamera = device
            }
        }
        // Default camera is back camera
        currentCamera = backCamera == nil ? frontCamera : backCamera
        
        guard let currentCamera = currentCamera else {
            print("No Current Camera now")
            return
        }
        
        do {
            captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera)
            
            captureSession.beginConfiguration()
            // Set up video input
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            // Set up photo output
            if captureSession.canAddOutput(photoDataOutput) {
                photoDataOutput.isAppleProRAWEnabled = photoDataOutput.isAppleProRAWSupported
                photoDataOutput.isHighResolutionCaptureEnabled = true
                /// - Tag: photo quality
                photoDataOutput.maxPhotoQualityPrioritization = .quality
                
                captureSession.addOutput(photoDataOutput)
            }
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            let dataOutputQueue = DispatchQueue(label: "video data queue",
                                                qos: .userInitiated,
                                                attributes: [],
                                                autoreleaseFrequency: .workItem)
            videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
//            // Set up video data output
            if captureSession.canAddOutput(videoDataOutput) {
                /// - Tag: Data output
                captureSession.addOutput(videoDataOutput)
////
            }
        } catch {
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            print("Setup capture session error: \(error)")
        }
        
        captureSession.commitConfiguration()
    }
}

//MARK: Setup Preview
extension SPCameraEngine {
    
    // Add Preview
    public func addPreview(_ view: SPPreviewView) {
        previewView = view
        setPreviewViewOrientation()
        previewView?.session = captureSession
    }
    
    // Setup previewView orientation
    func setPreviewViewOrientation() {
        if let videoPreviewLayerConnection = previewView?.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
}

//MARK: Capture Photo
extension SPCameraEngine {
    
    public func capturePhoto(with delegate: SPCapturePhotoCaptureDelegate) {
        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        sleep(UInt32(self.delayTime))
        sessionQueue.async {
            
            
            
            var settings: AVCapturePhotoSettings!
            // Orientation
            if let photoOutputConnection = self.photoDataOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            
            if self.isRAWSupported && self.rawOrMax {
                //DNG
                let query = {AVCapturePhotoOutput.isBayerRAWPixelFormat($0)}

                guard let rawFormat = self.photoDataOutput.availableRawPhotoPixelFormatTypes.first(where: query) else {
                    fatalError("No RAW format found.")
                }
                if self.photoDataOutput.availablePhotoCodecTypes.contains(.jpeg) {
                    print("types: \(self.photoDataOutput.availablePhotoCodecTypes)")
                    let processedFormat = [AVVideoCodecKey: AVVideoCodecType.jpeg]
                    settings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat, processedFormat: processedFormat)

                }
            } else if(!self.isRAWSupported) {
                settings = AVCapturePhotoSettings()
                settings.isHighResolutionPhotoEnabled = self.rawOrMax
            } else {
                if self.photoDataOutput.availablePhotoCodecTypes.contains(.hevc) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                } else {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                }
            }
            
            guard let currentCamera = self.currentCamera else {
                return
            }
            if currentCamera.isFlashAvailable {
                settings.flashMode = self.flashMode
            }
            
            settings.isHighResolutionPhotoEnabled = true
            delegate.requestedPhotoSettings = settings
            
            self.inProgressPhotoCaptureDelegates[delegate.requestedPhotoSettings.uniqueID] = delegate
            
            sleep(UInt32(self.delayTime))
            self.photoDataOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
    
    public func setDelegateNil(using delegate: SPCapturePhotoCaptureDelegate) {
        self.sessionQueue.async {
            self.inProgressPhotoCaptureDelegates[delegate.requestedPhotoSettings.uniqueID] = nil
        }
    }
}

//MARK: Toggle Camera
extension SPCameraEngine {
    // Toggle Camera between front and rear
    public func toggleCamera() -> Void {
        
        sessionQueue.async {
            let newCamera = self.currentCamera?.position == AVCaptureDevice.Position.back ? self.frontCamera : self.backCamera
                        
            if let newCamera = newCamera {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: newCamera)
                    
                    self.captureSession.beginConfiguration()
                    
                    self.captureSession.removeInput(self.captureDeviceInput)
                    
                    if self.captureSession.canAddInput(videoDeviceInput) {
                        self.captureSession.addInput(videoDeviceInput)
                        self.captureDeviceInput = videoDeviceInput
                        
                    } else {
                        self.captureSession.addInput(self.captureDeviceInput)
                    }
                    self.currentCamera = newCamera
                    self.captureSession.commitConfiguration()
                    
                    self.delegate?.toggleCamera(to: self.currentCamera?.position == .back)
                } catch {
                    return
                }
            }
        }
    }
}

//MARK: Focus Operation
extension SPCameraEngine {
    
    // Setup Focus
    private func attachFocus(to view: UIView) {
        let focusTapGesture = UITapGestureRecognizer(target: self, action: #selector(onFocusTapped))
        view.addGestureRecognizer(focusTapGesture)
    }
    
    @objc private func onFocusTapped(_ recognizer: UITapGestureRecognizer) {
        print("tap focus")
        if let view = recognizer.view as? SPPreviewView {
            let devicePoint = view.videoPreviewLayer.captureDevicePointConverted(
                fromLayerPoint: recognizer.location(in: view)
            )
            focus(with: .autoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: true)
        }
    }
    
    // Focus on given point
    public func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            let videoDevice = self.currentCamera!
            do {
                try videoDevice.lockForConfiguration()
                if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
                    videoDevice.focusPointOfInterest = devicePoint
                    videoDevice.focusMode = focusMode
                }
                
                if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
                    videoDevice.exposurePointOfInterest = devicePoint
                    videoDevice.exposureMode = exposureMode
                }
                
                videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                videoDevice.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    // auto focus
    public func autoFocus() {
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: CGPoint(x: 0.5, y: 0.5), monitorSubjectAreaChange: true)
    }
}

//MARK: Zoom Operation
extension SPCameraEngine {
    // Setup Zoom
    private func attachZoom(to view: UIView) {
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        view.addGestureRecognizer(pinchRecognizer!)
    }
    
    @objc private func pinch(_ pinch: UIPinchGestureRecognizer) {
        guard let device = currentCamera else { return }
        
        // Return zoom value between the minimum and maximum zoom values
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minZoom), maxZoom), device.activeFormat.videoMaxZoomFactor)
        }
        
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        
        let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)
        
        switch pinch.state {
            case .changed: update(scale: newScaleFactor)
            case .ended:
                lastZoomFactor = minMaxZoom(newScaleFactor)
                update(scale: lastZoomFactor)
            default: break
        }
    }
    
}

//MARK: Exposure Operation
extension SPCameraEngine {
    // Attach exposure
    private func attachExposure(to view: UIView) {
        // If fails, don't attach exposure gesture
        let exposureGesture = UIPanGestureRecognizer(target: self, action: #selector(exposureStart(_:)))
        
        view.addGestureRecognizer(exposureGesture)

    }
    
    @objc private func exposureStart(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view else { return }
        
        changeExposureMode(mode: .custom)
        
        let translation = gestureRecognizer.translation(in: view)
        let currentTranslation = translationY + Float(translation.y)
        
        if currentTranslation < 0 {
            // up - brighter
            exposureValue = 0.5 + min(abs(currentTranslation) / 400, 1) / 2
        } else if currentTranslation >= 0 {
            // down - lower
            exposureValue = 0.5 - min(abs(currentTranslation) / 400, 1) / 2
        }
        
        if let expoChange = expoChange {
            expoChange(exposureValue)
        }
        
        changeExposureDuration(value: exposureValue)
    }
    
    private func changeExposureMode(mode: AVCaptureDevice.ExposureMode) {
        guard let device = currentCamera else { return }
        if device.exposureMode == mode { return }
        
        do {
            try device.lockForConfiguration()
            if device.isExposureModeSupported(mode) {
                device.exposureMode = mode
            }
            device.unlockForConfiguration()
        } catch {
            return
        }
        
    }
    
    private func changeExposureDuration(value: Float) {
        guard let device = currentCamera else {  return }
        do {
            try device.lockForConfiguration()
            let p = Float64(pow(value, exposureDurationPower)) // Apply power function to expand slider's low-end range
            let minDurationSeconds = Float64(max(CMTimeGetSeconds(device.activeFormat.minExposureDuration), exposureMininumDuration))
            let maxDurationSeconds = Float64(CMTimeGetSeconds(device.activeFormat.maxExposureDuration))
            let newDurationSeconds = Float64(p * (maxDurationSeconds - minDurationSeconds)) + minDurationSeconds // Scale from 0-1 slider range to actual duration
            if device.exposureMode == .custom {
                let newExposureTime = CMTimeMakeWithSeconds(Float64(newDurationSeconds), preferredTimescale: 1000 * 1000 * 1000)
                device.setExposureModeCustom(duration: newExposureTime, iso: AVCaptureDevice.currentISO, completionHandler: nil)
            }
            
            device.unlockForConfiguration()
            
        } catch {
            return
        }
    }
}

extension SPCameraEngine {
    
    public func setLenPosition(with value: Float) {
        guard let device = currentCamera else {
            return
        }
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                device.setFocusModeLocked(lensPosition: value)
                device.unlockForConfiguration()
            } catch {
                return
            }
        }
    }
    
    public func switchCameraFocusMode(isAuto auto: Bool) {
        
        guard let device = currentCamera else {
            return
        }
        
        if auto {
            autoFocus()
        } else {
            sessionQueue.async {
                do {
                    try device.lockForConfiguration()
                    if device.isFocusModeSupported(.locked) {
                        device.focusMode = .locked
                    }
                    device.unlockForConfiguration()
                } catch {
                    return
                }
            }
        }
    }
}

//MARK: Setup White Balance Of Camera
extension SPCameraEngine {
    public func setCameraAWB(in temperature: Int) {
        guard let device = currentCamera else {
            return
        }
        
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                let mode: AVCaptureDevice.WhiteBalanceMode = temperature == 0 ? .continuousAutoWhiteBalance : .locked
                if device.isWhiteBalanceModeSupported(mode) {
                    device.whiteBalanceMode = mode
                }
                if mode == .locked {
                    let gains = device.deviceWhiteBalanceGains(for: .init(temperature: Float(temperature), tint: 0))
                    device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
                }

                device.unlockForConfiguration()
            } catch {
                return
            }
            
        }
        
        
    }
}

extension SPCameraEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        displayEqualizedPixelBuffer(pixelBuffer: imageBuffer)
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
    }

    
    
    func displayEqualizedPixelBuffer(pixelBuffer: CVPixelBuffer) {
        var error = kvImageNoError
        
        if converter == nil {
            let cvImageFormat = vImageCVImageFormat_CreateWithCVPixelBuffer(pixelBuffer).takeRetainedValue()
            vImageCVImageFormat_SetColorSpace(cvImageFormat, CGColorSpaceCreateDeviceRGB())
            vImageCVImageFormat_SetChromaSiting(cvImageFormat, kCVImageBufferChromaLocation_Center)
            
            guard
                let unmanagedConverter = vImageConverter_CreateForCVToCGImageFormat(
                    cvImageFormat,
                    &cgImageFormat,
                    nil,
                    vImage_Flags(kvImagePrintDiagnosticsToConsole),
                    &error),
                error == kvImageNoError else {
                    print("vImageConverter_CreateForCVToCGImageFormat error:", error)
                    return
            }
            
            converter = unmanagedConverter.takeRetainedValue()
        }
        
        if sourceBuffers.isEmpty {
            let numberOfSourceBuffers = Int(vImageConverter_GetNumberOfSourceBuffers(converter!))
            sourceBuffers = [vImage_Buffer](repeating: vImage_Buffer(), count: numberOfSourceBuffers)
            
        }
        
        error = vImageBuffer_InitForCopyFromCVPixelBuffer(&sourceBuffers, converter!, pixelBuffer, vImage_Flags(kvImageNoAllocate))
        
        guard error == kvImageNoError else {
            return
        }
        
        
        if destinationBuffer.data == nil {
            error = vImageBuffer_Init(&destinationBuffer,
                                      UInt(CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)),
                                      UInt(CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)),
                                      cgImageFormat.bitsPerPixel,
                                      vImage_Flags(kvImageNoFlags))
            
            guard error == kvImageNoError else {
                return
            }
        }
        error = vImageConvert_AnyToAny(converter!, &sourceBuffers, &destinationBuffer, nil, vImage_Flags(kvImageNoFlags))

        
        if let data = getHistogram(destinationBuffer) {
            
            let layers = getRBGLayersFrom(data: data)
            
            delegate?.displayRGBHistogramWith(layers: layers)
        }
        
        
        guard error == kvImageNoError else {
            return
        }
        guard error == kvImageNoError else {
            return
        }
    }
    
    func getRBGLayersFrom(data levels: HistogramLevels) -> [CAShapeLayer] {
        var layers = [CAShapeLayer]()
        
        layers.append(getLayer(channel: levels.red, color: .red))
        layers.append(getLayer(channel: levels.green, color: .green))
        layers.append(getLayer(channel: levels.blue, color: .blue))
        return layers
    }
    
    func getLayer(channel: [UInt], color: UIColor) -> CAShapeLayer {
        
        let max = channel.max()!
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = color.cgColor
        let path = UIBezierPath()
        for index in 0 ..< 256 {
            let newPoint = CGPoint(
                x: xForBin(index, proxy: CGSize(width: 100, height: 50)),
                y: yForCount(channel[index], proxy: CGSize(width: 100, height: 50), maxValue: CGFloat(max))
            )
            path.move(to: CGPoint(x: newPoint.x, y: 50))
            path.addLine(to: newPoint)
        }
        
        shapeLayer.path = path.cgPath
        
        return shapeLayer
        
        
        
    }
    
    func xForBin(_ bin: Int, proxy: CGSize) -> CGFloat {
        let widthOfBin = proxy.width / CGFloat(256)
        return CGFloat(bin) * widthOfBin
    }

    func yForCount(_ count: UInt, proxy: CGSize, maxValue: CGFloat) -> CGFloat {
        let heightOfLevel = proxy.height / maxValue
        return proxy.height - CGFloat(count) * heightOfLevel
    }
   
    // get RBBA data
    private func getHistogram(_ buffer: vImage_Buffer) -> HistogramLevels? {

        var imageBuffer = buffer
       

        var redArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var greenArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var blueArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var alphaArray: [vImagePixelCount] = Array(repeating: 0, count: 256)
        var error: vImage_Error = kvImageNoError
        

        redArray.withUnsafeMutableBufferPointer { rPointer in
            greenArray.withUnsafeMutableBufferPointer { gPointer in
                blueArray.withUnsafeMutableBufferPointer { bPointer in
                    alphaArray.withUnsafeMutableBufferPointer { aPointer in
                        var histogram = [
                            aPointer.baseAddress,
                            rPointer.baseAddress, gPointer.baseAddress,
                            bPointer.baseAddress
                        ]
                        histogram.withUnsafeMutableBufferPointer { hPointer in
                            if let hBaseAddress = hPointer.baseAddress {
                                error = vImageHistogramCalculation_ARGB8888(
                                    &imageBuffer,
                                    hBaseAddress,
                                    vNoFlags
                                )
                            }
                        }
                    }
                }
            }
        }

        guard error == kvImageNoError else {
            
            return nil
        }
        let histogramData = HistogramLevels(
            red: redArray,
            green: greenArray,
            blue: blueArray,
            alpha: alphaArray
        )
        return histogramData
    }

}
