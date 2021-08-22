//
//  LenView.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/11.
//

import UIKit
import AVFoundation

struct Lens {
    var lens: [AVCaptureDevice.DeviceType]
    var currLen: AVCaptureDevice.DeviceType { return lens[currIdx] }
    private var currIdx: Int
    
    init(lens: [AVCaptureDevice.DeviceType], current: AVCaptureDevice.DeviceType) {
        self.lens = lens
        self.currIdx = lens.firstIndex(of: current)!
    }
    
    mutating func switchToNext() -> AVCaptureDevice.DeviceType {
        if currIdx == lens.count - 1 {
            currIdx = 0
        } else {
            currIdx += 1
        }
        
        return currLen
    }
}


class LenButton: UIButton {
    
    var extraLens = [".5", "1", "2"]
    public var lens: Lens! {
        didSet {
            currentLen = lens.currLen
        }
    }
    
    var name: String = "1" {
        didSet {
            self.setTitle(name, for: .normal)
        }
    }
    
    private var currentLen: AVCaptureDevice.DeviceType = .builtInWideAngleCamera {
        didSet {
            switch currentLen {
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
    
    convenience init(lens: [AVCaptureDevice.DeviceType], currentLen: AVCaptureDevice.DeviceType) {
        self.init()
        self.lens = Lens(lens: lens, current: currentLen)
//        setupUI()
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
