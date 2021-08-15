//
//  SPCameraSystemAbility.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/8/15.
//

import Foundation
import AVFoundation

@objc protocol SPCameraSystemAbility {
    
    var maxBias: Float {get}
    var minBias: Float {get}
    var bias: Float {get}
    var flashMode: AVCaptureDevice.FlashMode {get}
    var isRAWSupported: Bool {get}
    
    func toggleCamera()
    func focusOnPoint(at point: CGPoint, with mode: AVCaptureDevice.FocusMode, and exposureMode: AVCaptureDevice.ExposureMode)
    func focusAutomaticlly()
    func adjustLenPosition(with value: Float)
    func setCameraAWB(at temperature: Float)
    func setCameraBias(_ bias: Float)
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode)
    
    @objc optional var maxZoom: Float {get}
    @objc optional var minZoom: Float {get}
    @objc optional var zoomFactor: Float {get}
}
