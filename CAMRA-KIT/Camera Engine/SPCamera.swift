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
    private(set) public var _position: AVCaptureDevice.Position!
    private(set) public var _type: AVCaptureDevice.DeviceType!
    
//    private var backCameraDevice: AVCaptureDevice?
//    private var frontCameraDevice: AVCaptureDevice?
    
    private lazy var backAvailableCaptureDevices = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera],
        mediaType: .video,
        position: .back
    )

    private lazy var frontAvailableCaptureDevices = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera],
        mediaType: .video,
        position: .front
    )
    
    private(set) public var currentDevice: AVCaptureDevice! {
        didSet {
            // setup RAW support
            if (_type == .builtInWideAngleCamera || _type == .builtInTelephotoCamera || _type == .builtInUltraWideCamera) && _position == .back {
                _isRAWSupported = true
            } else {
                _isRAWSupported = false
            }
            // setup camera parameters
            if oldValue != currentDevice {
                setupCameraParameters(about: currentDevice)
            }
        }
    }
    
    // camera Device parametes
    private(set) public var RAWMode: RAWMode = .DNG
    private var _maxBias: Float = 8.0
    private var _minBias: Float = -8.0
    private var _bias: Float = 0.0
    private var _flashMode: AVCaptureDevice.FlashMode!
    private var _focusMode: AVCaptureDevice.FocusMode!
    private var _exposureMode: AVCaptureDevice.ExposureMode!
    private var _isRAWSupported: Bool!
    
    // init camera and setup
    convenience init() {
        self.init(position: .back, cameraType: .builtInWideAngleCamera)
    }
    
    public init(position: AVCaptureDevice.Position = .back, cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera) {
        self._position = position
        self._type = cameraType
        self.setupCamera()
    }
    
    // setup current camera device
    private func setupCamera() {
        var devices: [AVCaptureDevice] = []
        if _position == .back {
            devices = backAvailableCaptureDevices.devices
        } else {
            devices = frontAvailableCaptureDevices.devices
        }
        // get a wide angle camera device, if the iPhone/ iPad / Mac have no type of camera.
        guard let defaultDevice = devices.first(where: {$0.deviceType == .builtInWideAngleCamera}) else { return }
        // setup current device
        if let device = devices.first(where: {$0.deviceType == _type}) {
            currentDevice = device
        } else {
            currentDevice = defaultDevice
        }
    }
    
    //configure camera parameters
    private func setupCameraParameters(about device: AVCaptureDevice) {
        _focusMode = .continuousAutoFocus
        _maxBias = device.maxExposureTargetBias
        _minBias = device.minExposureTargetBias
        _bias = 0.0
        _flashMode = .off
        _exposureMode = .continuousAutoExposure
        _maxZoom = device.maxAvailableVideoZoomFactor
        _minZoom = device.minAvailableVideoZoomFactor
    }
}

//MARK: Operations Of Camera
extension SPCamera: SPCameraSystemAbility {
    
    var maxBias: Float { return _maxBias }
    var minBias: Float { return _maxBias }
    var bias: Float { return currentDevice.exposureTargetBias }

    var isRAWSupported: Bool { return _isRAWSupported}
    var flashMode: AVCaptureDevice.FlashMode { return _flashMode }
    var focusMode: AVCaptureDevice.FocusMode { return _focusMode }
    var exposureMode: AVCaptureDevice.ExposureMode { return _exposureMode }
    var cameraPosition: AVCaptureDevice.Position { return _position }
    var cameraType: AVCaptureDevice.DeviceType { return _type }
    
    // toggle camera position: back -> front and front -> back
    func toggleCamera() {
        _position = (_position == .back) ? .front : .back
        setupCamera()
    }
    
    // Set camera zoom factor
    func setZoomFactor(_ value: CGFloat) {
        operateCameraWith(processer: {device in
            device.videoZoomFactor = value
        })
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
                _focusMode = focusMode
            }
            
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                device.exposurePointOfInterest = point
                device.exposureMode = exposureMode
                _exposureMode = exposureMode
            }
            //
            device.isSubjectAreaChangeMonitoringEnabled = true
        } catch let error {
            debugPrint("focus error: \(error)")
        }
    }
    
    //Auto Focus
    func focusAutomaticlly() {
        focusOnPoint(at: CGPoint(x: 0.5, y: 0.5), with: .continuousAutoFocus, and: .continuousAutoExposure)
        _focusMode = .continuousAutoFocus
        _exposureMode = .continuousAutoExposure
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
    
    //Set Camera Bias with EV value
    func setCameraBias(_ bias: Float) {
        var tmp: Float = bias
        if bias > _maxBias {
            tmp = _maxBias
        } else if bias < _minBias {
            tmp = minBias
        }
        operateCameraWith(processer: {device in
            device.setExposureTargetBias(tmp)
        })
    }
    
    // Set Camerea Flash Mode like: on/off/auto
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        if isFlashAvailable {
            _flashMode = mode
        }
    }
    
    // Switch camera focus mode: auto focus or manual focus mode
    func switchFocusMode(_ mode: AVCaptureDevice.FocusMode) {
        self.operateCameraWith(processer: {device in
            if mode == .continuousAutoFocus {
                self.focusAutomaticlly()
            } else {
                if device.isFocusModeSupported(mode) {
                    device.focusMode = mode
                } else {
                    self.focusAutomaticlly()
                }
            }
        })
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
