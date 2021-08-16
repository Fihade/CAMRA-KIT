//
//  SPCameraSystemAbility.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/8/15.
//

import Foundation
import AVFoundation

@objc protocol SPCameraSystemAbility {
    
    
    
    @objc optional func toggleCamera()
    @objc optional func focusAutomaticlly()
    @objc optional func focusOnPoint(at point: CGPoint, with mode: AVCaptureDevice.FocusMode, and exposureMode: AVCaptureDevice.ExposureMode)
    @objc optional func adjustLenPosition(with value: Float)
    @objc optional func setCameraAWB(at temperature: Float)
    @objc optional func setCameraBias(_ bias: Float)
    @objc optional func setZoomFactor(_ value: CGFloat)
    @objc optional func setFlashMode(_ mode: AVCaptureDevice.FlashMode)
    @objc optional func switchFocusMode(_ mode: AVCaptureDevice.FocusMode) 
    
    @objc optional var bias: Float {get}
    @objc optional var maxBias: Float {get}
    @objc optional var minBias: Float {get}
    @objc optional var maxZoom: Float {get}
    @objc optional var minZoom: Float {get}
    @objc optional var zoomFactor: Float {get}
    @objc optional var isRAWSupported: Bool {get}
    @objc optional var flashMode: AVCaptureDevice.FlashMode {get}
    @objc optional var focusMode: AVCaptureDevice.FocusMode {get}
    @objc optional var exposureMode: AVCaptureDevice.ExposureMode {get}
    @objc optional var cameraPosition: AVCaptureDevice.Position {get}
    @objc optional var cameraType: AVCaptureDevice.DeviceType { get }
    
}
