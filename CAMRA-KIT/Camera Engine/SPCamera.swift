//
//  SPCamera.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/6/5.
//

import Foundation
import AVFoundation



class SPCamera {
    
    public enum RAWMode {
        case DNG
        case AppleRAW
    }
    
   
    // Related to RAW
    public var rawMode: RAWMode = .DNG
    public var rawOrMax = false
//    public var isRAWSupported = true
    
    // Related to Focus/Flash
    public var isFlashAvailable: Bool!{
        get {
            return currentDevice.isFlashAvailable
        }
    }
    
    // Related to Zoom
    private var _minZoom: CGFloat!
    private var _maxZoom: CGFloat!
    private var _zoomFactor: CGFloat = 1.0
    
    // Camera's status
    private(set) public var currentCameraPosition: AVCaptureDevice.Position!
    private(set) public var currentCameraType: AVCaptureDevice.DeviceType!
    
//    private var backCameraDevice: AVCaptureDevice?
//    private var frontCameraDevice: AVCaptureDevice?
    
    private lazy var videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [
            .builtInTelephotoCamera,
            .builtInWideAngleCamera,
            .builtInUltraWideCamera,
        ],
        mediaType: .video,
        position: .unspecified
    )
    
    public var currentDevice: AVCaptureDevice! {
        didSet {
            isRAWSupported = (currentCameraPosition == .back)
            if oldValue != currentDevice {
                setupCameraParameters(about: currentDevice)
            }
        }
    }
    
    // Camera Device parametes
    private(set) public var isRAWSupported = true
    private(set) public var RAWMode: RAWMode = .DNG
    private var _maxBias: Float!
    private var _minBias: Float!
    private var _bias: Float!
    private(set) public var currBias: Float!
    private var _flashMode: AVCaptureDevice.FlashMode!
    private(set) public var focusMode: AVCaptureDevice.FocusMode!
    private(set) public var exposureMode: AVCaptureDevice.ExposureMode!
    
    
    
    
    //MARK: init camera and setup
    convenience init() {
        self.init(position: .back, cameraType: .builtInWideAngleCamera)
    }
    
    public init(position: AVCaptureDevice.Position = .back, cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera) {
        self.currentCameraPosition = position
        self.currentCameraType = cameraType
        
        self.setupCamera()
        
        print("camera focus mode: \(currentDevice.focusMode.rawValue)")
    }
    
    //Setup current camera device
    private func setupCamera() {
        let devices = videoDeviceDiscoverySession.devices
        
        //Set whether contains current type and position
        if let device = devices.first(where: {($0.deviceType == currentCameraType && $0.position == currentCameraPosition)}) {
            currentDevice = device
            return
        }
        //Set default wide angle camera
        if let device = devices.first(where: {($0.position == currentCameraPosition && $0.deviceType == .builtInWideAngleCamera)}) {
            currentDevice = device
            return
        }
    }
    
    //configure camera parameters
    private func setupCameraParameters(about device: AVCaptureDevice) {
        focusMode = .continuousAutoFocus
        _maxBias = device.maxExposureTargetBias
        _minBias = device.minExposureTargetBias
        _flashMode = .off
        // Set Raw supported
        isRAWSupported = (currentCameraPosition == .back)
        focusMode = .continuousAutoFocus
        exposureMode = .continuousAutoExposure
        _maxZoom = device.maxAvailableVideoZoomFactor
        _minZoom = device.minAvailableVideoZoomFactor
    }
}

//MARK: Operations Of Camera
extension SPCamera: SPCameraSystemAbility {

    
    var flashMode: AVCaptureDevice.FlashMode { return _flashMode }
    
    var maxBias: Float { return _maxBias }
    var minBias: Float { return _minBias }
    var bias: Float { return _bias }
    
    // toggle camera position: back -> front and front -> back
    func toggleCamera() {
        currentCameraPosition = (currentCameraPosition == .back) ? .front : .back
        setupCamera()
    }
    
    // Focus on screen at point that you tapped
    func focusOnPoint(at point: CGPoint, with focusMode: AVCaptureDevice.FocusMode, and exposureMode: AVCaptureDevice.ExposureMode) {
        guard let device = currentDevice else { return }
        
        do {
            try device.lockForConfiguration()
            defer {
                device.unlockForConfiguration()
            }
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                device.focusPointOfInterest = point
                device.focusMode = focusMode
                self.focusMode = focusMode
            }
            
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                device.exposurePointOfInterest = point
                device.exposureMode = exposureMode
                self.exposureMode = exposureMode
            }
            //
            device.isSubjectAreaChangeMonitoringEnabled = true
        } catch let error {
            debugPrint("focus error: \(error)")
        }
    }
    
    //Set camera Auto Focus
    func focusAutomaticlly() {
        focusOnPoint(at: CGPoint(x: 0.5, y: 0.5), with: .continuousAutoFocus, and: .continuousAutoExposure)
        self.focusMode = .continuousAutoFocus
    }
    
    //Adjust to camera's len position
    func adjustLenPosition(with value: Float) {
        guard let device = currentDevice else { return }
        do {
            try device.lockForConfiguration()
            defer {
                device.unlockForConfiguration()
            }
            device.setFocusModeLocked(lensPosition: value)
        } catch let error {
            debugPrint("adjust len position error: \(error)")
        }
    }
    
    //Set Camera AWB temperature
    func setCameraAWB(at temperature: Float) {
        operateCameraWith(processer: {device in
            let mode: AVCaptureDevice.WhiteBalanceMode = temperature == 0 ? .continuousAutoWhiteBalance : .locked
            if device.isWhiteBalanceModeSupported(mode) {
                device.whiteBalanceMode = mode
            }
            if mode == .locked {
                let temp = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: temperature, tint: 0)
                let gains = device.deviceWhiteBalanceGains(for: temp)
                device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
            }
        })
    }
    
    //Set Camera Bias like EV value
    func setCameraBias(_ bias: Float) {
        _bias = bias
        operateCameraWith(processer: {device in
            device.setExposureTargetBias(bias)
        })
    }
    
    //Set Camerea Flash Mode like: on/off/auto
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        _flashMode = mode
    }
    
    //Do any operation need to lock and unlock device for configure
    private func operateCameraWith(processer: @escaping (_ device: AVCaptureDevice) -> Void) {
        guard let device = currentDevice else { return }
        do {
            try device.lockForConfiguration()
            defer {
                device.unlockForConfiguration()
            }
            processer(device)
        } catch let error {
            debugPrint("operate camera error: \(error)")
        }
    }
    
}
