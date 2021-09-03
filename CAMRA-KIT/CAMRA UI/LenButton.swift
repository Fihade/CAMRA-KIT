//
//  LenView.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/11.
//

import UIKit
import AVFoundation

struct Lens {
    
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
    
//    lazy var lens: [AVCaptureDevice.DeviceType] = backAvailableCaptureDevices.devices.map {$0.deviceType}
    var lens: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera]
    
    var current: AVCaptureDevice.DeviceType { return lens[_idx] }
    private var _idx: Int = 0
    
    init(len: AVCaptureDevice.DeviceType) {
        _idx = lens.firstIndex(of: current) ?? 0
//        lens = backAvailableCaptureDevices.devices.map{$0.deviceType}
    }
    
    init() {
        
    }
    
    mutating func switchToNext() -> AVCaptureDevice.DeviceType {
        _idx = (_idx + 1) % lens.count
        return current
    }
}


class LenButton: UIButton {
    
    public var lens: Lens = Lens() {
        didSet {
            len = lens.current
        }
    }
    
    var name: String = "1" {
        didSet {
            self.setTitle(name, for: .normal)
        }
    }
    
    private var len: AVCaptureDevice.DeviceType = .builtInWideAngleCamera {
        didSet {
            switch len {
                case .builtInWideAngleCamera:
                    name = "1"
                case .builtInTelephotoCamera:
                    name = ".5"
                case .builtInUltraWideCamera:
                    name = "2"
                default:
                    name = "1"
            }
        }
    }
    
    convenience init(len: AVCaptureDevice.DeviceType) {
        self.init()
        self.lens = Lens(len: len)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()

    }
    
    func turnNextLen() -> AVCaptureDevice.DeviceType{
        return self.lens.switchToNext()
    }
    
    private func setupUI() {
        self.backgroundColor = #colorLiteral(red: 0.3215686275, green: 0.3215686275, blue: 0.3215686275, alpha: 1)
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1
        self.clipsToBounds = true
        self.layer.cornerRadius = 15
        self.setTitle(name, for: .normal)
    }

}
