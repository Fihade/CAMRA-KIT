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
    public var isRAWSupported = true
    
    // Related to Focus/Flash
    private var focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus
    public var flashMode: AVCaptureDevice.FlashMode = .off
    
    // Related to Zoom
    public let minZoom: CGFloat = 1.0
    public let maxZoom: CGFloat = 3.0
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
    
    public var device: AVCaptureDevice! {
        // Switch Camera Device
        didSet {
            maxBias = device.maxExposureTargetBias
            minBias = device.minExposureTargetBias
        }
    }
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [
            .builtInDualCamera,
            .builtInWideAngleCamera,
            .builtInTripleCamera
        ],
        mediaType: .video,
        position: .unspecified
    )
    
    
    
    
}
