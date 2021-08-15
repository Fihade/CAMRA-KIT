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

@objc protocol SPCameraEngineDelegate: AnyObject {
    
    func displayRGBHistogramWith(layers: [CAShapeLayer]?)
    func toggleCamera(to position: AVCaptureDevice.Position)
    
    @objc optional func cameraEngineChangeBiasWith(value: Float)
//    @objc optional func
}

class SPCameraEngine: NSObject {
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private var setupResult: SessionSetupResult!
    
    private lazy var captureSession = AVCaptureSession()
    private lazy var sessionQueue = DispatchQueue(label: "Camera Session Queue")
    
    private(set) public var previewView: SPPreviewView! {
        didSet {
            previewView.session = captureSession
            self.addGestureToPreviewView()
        }
    }
    
    private var captureDeviceInput: AVCaptureDeviceInput!
    private lazy var photoDataOutput = AVCapturePhotoOutput()

    private var pinchRecognizer: UIPinchGestureRecognizer?
    
    // Related to RAW
//    public var rawMode: RAWMode = .DNG
    public var rawOrMax = false
    public var isRAWSupported = true
    
    // Delay Capture Time
    private var delayTime = 0
    
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
    
    //----------------
    lazy var camera: SPCamera = SPCamera()
    //----------------
    
    
    convenience init(preview: SPPreviewView) {
        self.init()
        self.previewView = preview
    }
    
    override init() {
        super.init()
        self.checkPermission()
        self.setupCaptureSession()
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
    
    
    private func addGestureToPreviewView() {
        guard let preview = previewView else { return }
        
        let tapFocusGesture = UITapGestureRecognizer(target: self, action: #selector(tapFocus(_:)))
        preview.addGestureRecognizer(tapFocusGesture)
        
        let biasPanGesture = UIPanGestureRecognizer(target: self, action: #selector(swipUpPreview(_:)))
        preview.addGestureRecognizer(biasPanGesture)
    }
    

    @objc private func tapFocus(_ recognizer: UITapGestureRecognizer) {
        let point = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: recognizer.location(in: previewView))
        focusOnPoint(at: point, with: .autoFocus, and: .autoExpose)
    }
    
    @objc private func swipUpPreview(_ recogizer: UIPanGestureRecognizer) {
        guard let view = recogizer.view else {return}
        switch recogizer.state {
            case .changed:
                let y = recogizer.translation(in: view).y
                var value = bias - (Float(y) / 10)
                if value > maxBias {
                    value = maxBias
                }else if(value < minBias) {
                    value = minBias
                }
                delegate?.cameraEngineChangeBiasWith?(value: value)
                self.setCameraBias(value)
            default:
                break
        }
    }
//    private func setRaw(_ raw: Bool) {
//        self.rawOrMax = raw
//        if raw {
//            do {
//                try currentCamera?.lockForConfiguration()
//                self.currentCamera?.videoZoomFactor = 1.0
//                if let pinchRecognizer = pinchRecognizer {
//                    self.previewView?.removeGestureRecognizer(pinchRecognizer)
//
//                }
//                currentCamera?.unlockForConfiguration()
//            } catch  {
//                fatalError()
//            }
//        } else {
//            attachZoom(to: previewView!)
//        }
//    }

    
}

//MARK: SPCameraSystemAbility protocol
extension SPCameraEngine: SPCameraSystemAbility {
    var minBias: Float { return camera.minBias }
    var maxBias: Float { return camera.minBias }
    var bias: Float { return camera.bias }
    var flashMode: AVCaptureDevice.FlashMode { return camera.flashMode }
    
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
        
        sessionQueue.async {
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: self.camera.currentDevice)
                self.captureSession.beginConfiguration()
                self.captureSession.removeInput(self.captureDeviceInput)
                if self.captureSession.canAddInput(videoDeviceInput) {
                    self.captureSession.addInput(videoDeviceInput)
                    self.captureDeviceInput = videoDeviceInput

                } else {
                    self.captureSession.addInput(self.captureDeviceInput)
                }
                self.captureSession.commitConfiguration()
                self.delegate?.toggleCamera(to: self.camera.currentCameraPosition)
                
            } catch let error {
                debugPrint("toggle camera error: \(error)")
            }
        }
    }
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        self.camera.setFlashMode(mode)
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
            if captureSession.canAddOutput(photoDataOutput) {
//                photoDataOutput.isAppleProRAWEnabled = photoDataOutput.isAppleProRAWSupported
                photoDataOutput.isHighResolutionCaptureEnabled = true
                photoDataOutput.maxPhotoQualityPrioritization = .quality
                captureSession.addOutput(photoDataOutput)
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
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            print("Setup capture session error: \(error)")
        }
        
        
    }
}

//MARK: Setup Preview
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
}

//MARK: Capture Photo
extension SPCameraEngine {
    
    public func capturePhoto(with delegate: SPCapturePhotoCaptureDelegate) {
        
//        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
//        sleep(UInt32(self.delayTime))
        
//        sessionQueue.async {[weak self] in
//            var settings: AVCapturePhotoSettings!
//            // Orientation
//            if let photoOutputConnection = self?.photoDataOutput.connection(with: .video) {
//                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
//            }
//
//
//
//            if self.isRAWSupported && self.rawOrMax {
//                //DNG
//                let query = {AVCapturePhotoOutput.isBayerRAWPixelFormat($0)}
//
//                guard let rawFormat = self.photoDataOutput.availableRawPhotoPixelFormatTypes.first(where: query) else {
//                    fatalError("No RAW format found.")
//                }
//                if self.photoDataOutput.availablePhotoCodecTypes.contains(.jpeg) {
//                    print("types: \(self.photoDataOutput.availablePhotoCodecTypes)")
//                    let processedFormat = [AVVideoCodecKey: AVVideoCodecType.jpeg]
//                    settings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat, processedFormat: processedFormat)
//
//                }
//            } else if(!self.isRAWSupported) {
//                settings = AVCapturePhotoSettings()
//                settings.isHighResolutionPhotoEnabled = self.rawOrMax
//            } else {
//                if self.photoDataOutput.availablePhotoCodecTypes.contains(.hevc) {
//                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
//                } else {
//                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
//                }
//            }
//
////            guard let currentCamera = self.currentCamera else {
////                return
////            }
//            if self.camera.isFlashAvailable {
//                settings.flashMode = camera.flashMode
//            }
//
//            settings.isHighResolutionPhotoEnabled = true
//            delegate.requestedPhotoSettings = settings
//
//            self.inProgressPhotoCaptureDelegates[delegate.requestedPhotoSettings.uniqueID] = delegate
//
//            sleep(UInt32(self.delayTime))
//            self.photoDataOutput.capturePhoto(with: settings, delegate: delegate)
//        }
    }
    
    public func setDelegateNil(using delegate: SPCapturePhotoCaptureDelegate) {
        self.sessionQueue.async {
            self.inProgressPhotoCaptureDelegates[delegate.requestedPhotoSettings.uniqueID] = nil
        }
    }
}

//MARK: add focus gesture to preview
extension SPCameraEngine {

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

//MARK: Switch camera Focus mode
extension SPCameraEngine {
    
//    public func switchCameraFocusMode(isAuto auto: Bool) {
//
////        guard let device = currentCamera else {
////            return
////        }
//
//        if auto {
//            autoFocus()
//        } else {
////            sessionQueue.async {
////                do {
////                    try device.lockForConfiguration()
////                    if device.isFocusModeSupported(.locked) {
////                        device.focusMode = .locked
////                    }
////                    device.unlockForConfiguration()
////                } catch {
////                    return
////                }
////            }
//
//            configCaptureSessionWith(handler: { device in
//                if device.isFocusModeSupported(.locked) {
//                    device.focusMode = .locked
//                }
//            })
//        }
//    }
}

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
