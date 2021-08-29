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

extension Float {
    mutating func oneDecimals(){
        let s = String(format:"%.1f",self)
        self = Float(s)!
    }
}

@objc protocol SPCameraEngineDelegate: AnyObject {
    
    func displayRGBHistogramWith(layers: [CAShapeLayer]?)
    @objc optional func cameraEngineChangeBiasWith(value: Float)
    @objc optional func cameraEngine(bias: Float)
    @objc optional func cameraEngine(temperatureOfAWB: Float)
    @objc optional func cameraEngine(lenPosition: Float)
    @objc optional func cameraEngine(tap view: SPPreviewView, at point: CGPoint)
    @objc optional func cameraEngine(toggle position: AVCaptureDevice.Position)
}

// Note: imagining how we use the real camera like Sony、Fuji... SPCameraEngine not only has SPCamera, but also has preview、focus view.
// Theses components are wrappered in camera Engine that can make the workflow more like incorporation and reduce error to use the engine.
class SPCameraEngine: NSObject {
    
    private enum CameraPermissionStatus {
        case authorized
        case notAuthorized
        case configurationFailed
    }
    
    public weak var delegate: SPCameraEngineDelegate?
    private var cameraStatus: CameraPermissionStatus!
    private lazy var camera: SPCamera = SPCamera()
    
    private lazy var captureSession = AVCaptureSession()
    private lazy var sessionQueue = DispatchQueue(label: "Camera Session Queue")
    
    private(set) public var previewView: SPPreviewView! {
        didSet {
            previewView.session = captureSession
            self.addGestureToPreviewView()
        }
    }
    
    private var focusView: SPFocusView?
    
    private var captureDeviceInput: AVCaptureDeviceInput!
    private lazy var photoOutput = AVCapturePhotoOutput()
    
    // related to RAW
    public var rawOrMax = false
    
    private var inProgressPhotoCaptureDelegates = [Int64: SPCapturePhotoCaptureDelegate]()
    
    private(set) public var delayCaptureTime: UInt64 = 0
    
    // related to hisgoram
    private var cgImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        colorSpace: nil,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue),
        version: 0,
        decode: nil,
        renderingIntent: .defaultIntent)
    
    private var converter: vImageConverter?
    private var sourceBuffers = [vImage_Buffer]()
    private var destinationBuffer = vImage_Buffer()
    private let vNoFlags = vImage_Flags(kvImageNoFlags)
    
    // related to haptic engine
    private var feedbackGenerator : UIFeedbackGenerator? = nil
    
    convenience init(preview: SPPreviewView) {
        self.init()
        addPreview(preview)
    }
    
    override init() {
        super.init()
        self.checkCameraPermission()
//        self.setupCaptureSession()
        self.observe()
    }
    
    deinit {
        destinationBuffer.free()
        feedbackGenerator = nil
    }
    
    // Check permission about camera
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                cameraStatus = .authorized
                break
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if !granted { self.cameraStatus = .notAuthorized }
                })
                break
            default:
                cameraStatus = .notAuthorized
                break
        }
    }
    
    public func startCameraRunning() {
        sessionQueue.async {[weak self] in
            self?.captureSession.startRunning()
        }
        
    }
    
    public func stopCameraRunning() {
        sessionQueue.async {[weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
    private func observe() {
        NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceSubjectAreaDidChange,
            object: .none, queue: .none,
            using: {_ in
                print("AVCaptureDeviceSubjectAreaDidChange")
                self.focusView?.removeFromSuperview()
                self.focusAutomaticlly()
            }
        )
    }
    
    // NOTE: values: preview's pan gesture
    private var beganPanY: CGFloat!
    private var beganPanBias: Float!
}

//MARK: Related to gestures of preview
extension SPCameraEngine {
    
    private func addGestureToPreviewView() {
        guard let preview = previewView else { return }
        
        let tapFocusGesture = UITapGestureRecognizer(target: self, action: #selector(tapFocus(_:)))
        preview.addGestureRecognizer(tapFocusGesture)
        
        let biasPanGesture = UIPanGestureRecognizer(target: self, action: #selector(swipUpPreview(_:)))
        preview.addGestureRecognizer(biasPanGesture)
    }
    
    @objc private func tapFocus(_ recognizer: UITapGestureRecognizer) {
        
        if(feedbackGenerator == nil) {
            feedbackGenerator = UISelectionFeedbackGenerator()
        }
        feedbackGenerator?.prepare()
        (feedbackGenerator as? UISelectionFeedbackGenerator)?.selectionChanged()
        
        defer {
            self.feedbackGenerator = nil
        }
        
        if let view = recognizer.view as? SPPreviewView {
            // Get point where you tapped.
            let location = recognizer.location(in: view)
            
//            self.tappedFocus(on: view, at: location)
            let point = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)
            // If have explicit focus view on preview, need to remove it fistly
            if focusView != nil {
                focusView?.removeFromSuperview()
            }
            // Reset focus view and add subview
            focusView = SPFocusView(location: location)
            view.addSubview(focusView!)
            // Focus on point tapped
            focusOnPoint(at: point, with: .autoFocus, and: .autoExpose)
        }
        
    }
    
    @objc private func swipUpPreview(_ recogizer: UIPanGestureRecognizer) {
        guard let view = recogizer.view else {return}
        switch recogizer.state {
            case .began:
                if(feedbackGenerator == nil) {
                    feedbackGenerator = UISelectionFeedbackGenerator()
                }
                feedbackGenerator?.prepare()
                beganPanY = recogizer.translation(in: view).y
                beganPanBias = bias
            case .changed:
                let sy = recogizer.translation(in: view).y
                let height = view.bounds.height
                var value = beganPanBias - Float((sy - beganPanY) / height) * maxBias
                value.oneDecimals()
                // EV only .f
                var tmp = bias
                tmp.oneDecimals()
                if value != tmp {
                    (feedbackGenerator as? UISelectionFeedbackGenerator)?.selectionChanged()
                    self.setCameraBias(value)
                    delegate?.cameraEngine?(bias: bias)
                }
            default:
                break
        }
    }
}

//MARK: SPCameraSystemAbility protocol
extension SPCameraEngine: SPCameraSystemAbility {
    // NOTE: apply to SPCameraSystemAbility because SPCameraEngine will be exposed to outside to use SPCamera ability like check out parameters or operate the camera.
    // SPCameraEngine will save camera engine to only do itself work just like real camera's work flow that we usually use.
    var bias: Float { return camera.bias }
    var minBias: Float { return camera.minBias }
    var maxBias: Float { return camera.maxBias }
    var isRAWSupported: Bool { return camera.isRAWSupported }
    var flashMode: AVCaptureDevice.FlashMode { return camera.flashMode }
    var cameraPosition: AVCaptureDevice.Position { return camera.cameraPosition }
    var cameraType: AVCaptureDevice.DeviceType {return camera.cameraType}
    var availableCameraTypes: [AVCaptureDevice.DeviceType] { return camera.availableCameraTypes }
    
    func focusOnPoint(at point: CGPoint, with mode: AVCaptureDevice.FocusMode, and exposureMode: AVCaptureDevice.ExposureMode) {
        self.camera.focusOnPoint(at: point, with: mode, and: exposureMode)
    }
    
    func focusAutomaticlly() {
        self.camera.focusAutomaticlly()
    }
    
    func adjustLenPosition(with value: Float) {
        self.camera.adjustLenPosition(with: value)
    }
    
    func setCameraAWB(at temperature: Float) {
        self.camera.setCameraAWB(at: temperature)
    }
    
    func setCameraBias(_ bias: Float) {
        self.camera.setCameraBias(bias)
    }
    
    func toggleCamera() {
        self.camera.toggleCamera()
        sessionQueue.async {[weak self] in
            do {
                if let weakSelf = self {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: (weakSelf.camera.currentDevice)!)
                    weakSelf.captureSession.beginConfiguration()
                    weakSelf.captureSession.removeInput(weakSelf.captureDeviceInput)
                    if weakSelf.captureSession.canAddInput(videoDeviceInput) {
                        weakSelf.captureSession.addInput(videoDeviceInput)
                        weakSelf.captureDeviceInput = videoDeviceInput

                    } else {
                        weakSelf.captureSession.addInput(weakSelf.captureDeviceInput)
                    }
                    weakSelf.captureSession.commitConfiguration()
                    weakSelf.delegate?.cameraEngine?(toggle: weakSelf.cameraPosition)
                }
            } catch let error {
                debugPrint("toggle camera error: \(error)")
            }
        }
    }
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        self.camera.setFlashMode(mode)
    }
    
    func setZoomFactor(_ value: CGFloat) {
        self.camera.setZoomFactor(value)
    }
    
    func switchFocusMode(_ mode: AVCaptureDevice.FocusMode) {
        self.camera.switchFocusMode(mode)
    }
}

//MARK: Setup CaptureSession
extension SPCameraEngine {
    
    private func setupCaptureSession() {
        captureSession.sessionPreset = .photo
        // Note: At the step of session's setup, add device input and output to the session
        // device input means camera len
        // device output means preview of what we watch. 2 types of output is photo output and data output
        do {
            captureDeviceInput = try AVCaptureDeviceInput(device: camera.currentDevice)
            captureSession.beginConfiguration()
            defer {
                captureSession.commitConfiguration()
            }
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            if captureSession.canAddOutput(photoOutput) {
//                photoDataOutput.isAppleProRAWEnabled = photoDataOutput.isAppleProRAWSupported
                photoOutput.isHighResolutionCaptureEnabled = true
                photoOutput.maxPhotoQualityPrioritization = .quality
                captureSession.addOutput(photoOutput)
            }
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            let dataOutputQueue = DispatchQueue(label: "video data queue", qos: .userInitiated,
                                                attributes: [], autoreleaseFrequency: .workItem)
            videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
        } catch {
            cameraStatus = .configurationFailed
            captureSession.commitConfiguration()
            print("Setup capture session error: \(error)")
        }
        
        
    }
}

//MARK: Operations about preview view
extension SPCameraEngine {
    
    // add preview
    public func addPreview(_ view: SPPreviewView) {
        previewView = view
        setPreviewViewOrientation()
        previewView?.session = captureSession
    }
    
    // Setup previewView orientation
    private func setPreviewViewOrientation() {
        if let videoPreviewLayerConnection = previewView?.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    
    var showGrid: Bool { return previewView.showGrid }
    
    public func togglePreviewGrid() {
        self.previewView.toggleGrid()
    }
}

//MARK: Capture Photo
extension SPCameraEngine {
    
    public func capturePhoto(with delegate: SPCapturePhotoCaptureDelegate) {
        
        // Haptic feedback
        feedbackGenerator = UIImpactFeedbackGenerator()
        feedbackGenerator?.prepare()
        (feedbackGenerator as? UIImpactFeedbackGenerator)?.impactOccurred(intensity: 0.5)
        
        // Get preview video orientation
        if let connection = photoOutput.connection(with: .video), let videoPreviewLayerOrientation = self.previewView.videoPreviewLayer.connection?.videoOrientation {
            connection.videoOrientation = videoPreviewLayerOrientation
        }
        
        sessionQueue.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: delayCaptureTime), execute: {[weak self] in
            guard let output = self?.photoOutput else {return}
            var settings = AVCapturePhotoSettings()
            
            if let isRAW = self?.isRAWSupported {
                if isRAW {
                    let query = {AVCapturePhotoOutput.isBayerRAWPixelFormat($0)}
                    //
                    guard let rawFormat = output.availableRawPhotoPixelFormatTypes.first(where: query) else {
                        fatalError("No RAW format found.")
                    }
                    
                    if output.availablePhotoCodecTypes.contains(.hevc) {
                        let processedFormat = [AVVideoCodecKey: AVVideoCodecType.jpeg]
                        settings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat, processedFormat: processedFormat)
                    }
                } else {
                    settings.isHighResolutionPhotoEnabled = true
                }
            }
        
            if let flashMode = self?.flashMode {
                settings.flashMode = flashMode
            }
            settings.isHighResolutionPhotoEnabled = true
            delegate.requestedPhotoSettings = settings
            self?.inProgressPhotoCaptureDelegates[delegate.requestedPhotoSettings.uniqueID] = delegate
            self?.photoOutput.capturePhoto(with: settings, delegate: delegate)
            
        })
    }
    
    public func setDelegateNil(using delegate: SPCapturePhotoCaptureDelegate) {
        self.sessionQueue.async {
            self.inProgressPhotoCaptureDelegates[delegate.requestedPhotoSettings.uniqueID] = nil
        }
    }
}

//MARK: Zoom Operation
//extension SPCameraEngine {
//    // Setup Zoom
//    private func attachZoom(to view: UIView) {
//        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
//        view.addGestureRecognizer(pinchRecognizer!)
//    }
//
//    @objc private func pinch(_ pinch: UIPinchGestureRecognizer) {
//        guard let device = currentCamera else { return }
//
//        // Return zoom value between the minimum and maximum zoom values
//        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
//            return min(min(max(factor, minZoom), maxZoom), device.activeFormat.videoMaxZoomFactor)
//        }
//
//        func update(scale factor: CGFloat) {
////            do {
////                try device.lockForConfiguration()
////                defer { device.unlockForConfiguration() }
////                device.videoZoomFactor = factor
////            } catch {
////                print("\(error.localizedDescription)")
////            }
//
//            configCaptureSessionWith(handler: {device in
//                device.videoZoomFactor = factor
//            })
//        }
//
//        let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)
//
//        switch pinch.state {
//            case .changed: update(scale: newScaleFactor)
//            case .ended:
//                lastZoomFactor = minMaxZoom(newScaleFactor)
//                update(scale: lastZoomFactor)
//            default: break
//        }
//    }
//
//}

extension SPCameraEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            return
//        }
//        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
//        displayEqualizedPixelBuffer(pixelBuffer: imageBuffer)
//        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
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
            getRBGLayersFrom(data: data, uiOperate: {layers in
                self.delegate?.displayRGBHistogramWith(layers: layers)
            })
            
        }
        
        guard error == kvImageNoError else {
            return
        }
        guard error == kvImageNoError else {
            return
        }
    }
    
    
    
    private func getRBGLayersFrom(data levels: HistogramLevels, uiOperate:@escaping ([CAShapeLayer]) -> Void) {
        
        let imageProcessingQueue = DispatchQueue(label: "image processing queue", attributes: .concurrent)
        let group = DispatchGroup()
        var layers = [CAShapeLayer]()
        
        var redLayer: CAShapeLayer!
        var greenLayer: CAShapeLayer!
        var blueLayer: CAShapeLayer!
        
        imageProcessingQueue.async(group: group, execute: {
            redLayer = self.getLayer(channel: levels.red, color: .red)
//            layers.append(self.getLayer(channel: levels.red, color: .red))
        })

        imageProcessingQueue.async(group: group, execute: {
            greenLayer = self.getLayer(channel: levels.green, color: .green)
//            layers.append(self.getLayer(channel: levels.green, color: .green))
        })

        imageProcessingQueue.async(group: group, execute: {
            
            blueLayer = self.getLayer(channel: levels.blue, color: .blue)
        })

        group.notify(queue: .main, execute: {
            
            layers = [redLayer, greenLayer, blueLayer]
            uiOperate(layers)
        })
//
//        layers.append(getLayer(channel: levels.red, color: .red))
//        layers.append(getLayer(channel: levels.green, color: .green))
//        layers.append(getLayer(channel: levels.blue, color: .blue))
//
//        uiOperate(layers)
        
//        return layers
    }
    
    private func getLayer(channel: [UInt], color: UIColor) -> CAShapeLayer {
        
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
