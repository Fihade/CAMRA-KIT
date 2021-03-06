//
//  BottomSheetView.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/13.
//

import UIKit
import Foundation
import AVFoundation

@objc protocol BottomSheetViewDelegate: NSObjectProtocol {
    
    func toggleRAWMode(_ button: RAWButton)
    
    func toggleLen(_ button: LenButton)
    
    func capturePhoto()
    
//    func checkImageInfo(_ image: UIImage)
    
    func setLenPosition(with value: Float)
    
    func switchCameraFocusMode(is ManualFocus: Bool)
    
    @objc optional func switchLen(with button: LenButton)
    
}

class BottomSheetView: UIView {
    
    private var captureButton: UIButton!
    private var rawButton: RAWButton!
    private var lenButton: LenButton!
    private var capturedImageView: UIImageView!
    
    private var focusModeButton: UIButton!
    private var lenPositionSlider: UISlider!
    private var lenPositionLable: UILabel!
    
    
    weak var delegate: BottomSheetViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        attachBottomSheetView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        attachBottomSheetView()
    }
    
    override func draw(_ rect: CGRect) {
        let borderPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 10)
        UIColor(named: "bottom sheet")!.set()
        borderPath.fill()
    }
    
    private func setupUI() {
        // Set up low half area
        let lowHalfArea = UILayoutGuide()
        
        captureButton = UIButton()
        captureButton.backgroundColor = self.backgroundColor
        captureButton.layer.contents = UIImage(named: "Capture Button")?.cgImage
        captureButton.translatesAutoresizingMaskIntoConstraints = false

        self.addLayoutGuide(lowHalfArea)
        self.addSubview(captureButton)
        
        // setup captured-imageView
        capturedImageView = UIImageView()
        capturedImageView.backgroundColor = self.backgroundColor
        capturedImageView.layer.cornerRadius = 10
        capturedImageView.layer.borderColor = UIColor.white.cgColor
        capturedImageView.layer.borderWidth = 2
        capturedImageView.layer.masksToBounds = true
        capturedImageView.isUserInteractionEnabled = true
        capturedImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(capturedImageView)
        
        lenButton = LenButton()
        lenButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(lenButton)
        
        NSLayoutConstraint.activate([
            lowHalfArea.heightAnchor.constraint(equalToConstant: 80),
            lowHalfArea.widthAnchor.constraint(equalTo: self.widthAnchor),
            lowHalfArea.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20),
            
            captureButton.centerYAnchor.constraint(equalTo: lowHalfArea.centerYAnchor),
            captureButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 80),
            captureButton.heightAnchor.constraint(equalToConstant: 80),
            
            capturedImageView.heightAnchor.constraint(equalToConstant: 64),
            capturedImageView.widthAnchor.constraint(equalToConstant: 64),
            capturedImageView.centerYAnchor.constraint(equalTo: lowHalfArea.centerYAnchor),
            capturedImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            
            lenButton.centerYAnchor.constraint(equalTo: lowHalfArea.centerYAnchor),
            lenButton.heightAnchor.constraint(equalToConstant: 30),
            lenButton.widthAnchor.constraint(equalToConstant: 30),
            lenButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: 30),
        ])
        
        let topHalfArea = UILayoutGuide()
        self.addLayoutGuide(topHalfArea)
        
        focusModeButton = UIButton()
        focusModeButton.setTitle("AF", for: .normal)
        focusModeButton.setTitleColor(expand ? .white : .yellow, for: .normal)
        focusModeButton.layer.masksToBounds = true
        focusModeButton.layer.cornerRadius = 13
        focusModeButton.layer.borderColor = expand ? UIColor.white.cgColor : UIColor.yellow.cgColor
        focusModeButton.layer.borderWidth = 2
        focusModeButton.titleLabel?.backgroundColor = .black
        
        focusModeButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(focusModeButton)
        
        lenPositionSlider = UISlider()
        lenPositionSlider.layer.backgroundColor = self.backgroundColor?.cgColor
        lenPositionSlider.tintColor = .gray
        lenPositionSlider.value = 0
        lenPositionSlider.minimumValue = 0.0
        lenPositionSlider.maximumValue = 1.0
        lenPositionSlider.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(lenPositionSlider)
        
        lenPositionLable = UILabel()
        lenPositionLable.text = "0.0"
        lenPositionLable.layer.backgroundColor = self.backgroundColor?.cgColor
        lenPositionLable.textColor = .white
        lenPositionLable.layer.masksToBounds = true
        lenPositionLable.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(lenPositionLable)
        
        rawButton = RAWButton()
        rawButton.layer.masksToBounds = true
        rawButton.sizeToFit()
        rawButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(rawButton)
        
        NSLayoutConstraint.activate([
            topHalfArea.heightAnchor.constraint(equalToConstant: 40),
            topHalfArea.widthAnchor.constraint(equalTo: self.widthAnchor),
            topHalfArea.topAnchor.constraint(equalTo: self.topAnchor),
            topHalfArea.bottomAnchor.constraint(equalTo: lowHalfArea.topAnchor),
            topHalfArea.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            topHalfArea.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            focusModeButton.leadingAnchor.constraint(equalTo: topHalfArea.leadingAnchor, constant: 10),
            focusModeButton.centerYAnchor.constraint(equalTo: topHalfArea.centerYAnchor),
            focusModeButton.heightAnchor.constraint(equalToConstant: 27),
            focusModeButton.widthAnchor.constraint(equalToConstant: 27),
            
            lenPositionSlider.widthAnchor.constraint(equalToConstant: 200),
            lenPositionSlider.trailingAnchor.constraint(equalTo: topHalfArea.leadingAnchor, constant: -10),
            lenPositionSlider.centerYAnchor.constraint(equalTo: topHalfArea.centerYAnchor),
            
            lenPositionLable.centerYAnchor.constraint(equalTo: lenPositionSlider.centerYAnchor),
            lenPositionLable.trailingAnchor.constraint(equalTo: lenPositionSlider.leadingAnchor, constant: -10),
            
            rawButton.trailingAnchor.constraint(equalTo: topHalfArea.trailingAnchor, constant: -10),
            rawButton.centerYAnchor.constraint(equalTo: topHalfArea.centerYAnchor),
            rawButton.heightAnchor.constraint(equalToConstant: 16),
            rawButton.widthAnchor.constraint(equalToConstant: 32),
        ])
        
        focusModeButton.addTarget(self, action: #selector(selectFocusMode), for: .touchUpInside)
        lenPositionSlider.addTarget(self, action: #selector(slideLenPosition(_:)), for: .valueChanged)
    }
    
    @objc func slideLenPosition(_ sender: UISlider) {
        lenPositionLable.text = "\(String.localizedStringWithFormat("%.1f", sender.value))"
        delegate?.setLenPosition(with: sender.value)
    }
    
    private var expand = false
    
    @objc func selectFocusMode() {
        
        expand.toggle()
        delegate?.switchCameraFocusMode(is: expand)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            let distance = self.lenPositionSlider.bounds.width + 42
            self.lenPositionSlider.transform = CGAffineTransform(translationX: self.expand ? distance : 0, y: 0)
            self.focusModeButton.transform = CGAffineTransform(translationX: self.expand ? distance : 0, y: 0)
            self.lenPositionLable.transform = CGAffineTransform(translationX: self.expand ? distance : 0, y: 0)
            self.lenPositionSlider.alpha = self.expand ? 1 : 0
            self.lenPositionLable.alpha = self.expand ? 1 : 0
            
            self.focusModeButton.setTitleColor(self.expand ? .white : .yellow, for: .normal)
            self.focusModeButton.layer.borderColor = self.expand ? UIColor.white.cgColor : UIColor.yellow.cgColor
        })
    }
}

//MARK: Operations in BottomSheetView
extension BottomSheetView {
    
    // Set Button GestureRecognizer
    private func attachBottomSheetView() {
        rawButton.addTarget(self, action: #selector(tapRAW), for: .touchDown)
        lenButton.addTarget(self, action: #selector(tapLen(_:)), for: .touchDown)
        captureButton.addTarget(self, action: #selector(capture(_:)), for: .touchDown)
//        capturedImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
    }
    
    @objc private func tapRAW(_ sender: RAWButton) {
        delegate?.toggleRAWMode(sender)
    }
    
    @objc private func tapLen(_ sender: LenButton) {
        #if DEBUG
        print("tap len")
        #endif
        delegate?.switchLen?(with: sender)
    }
    
    @objc private func capture(_ sender: UIButton) {
        delegate?.capturePhoto()
    }
    
//    @objc private func tap(_ sender: UITapGestureRecognizer) {
//    }
}

extension BottomSheetView {
    public func willCapture() {
        let borderWidthAnimate = CABasicAnimation(keyPath: "borderWidth")
        borderWidthAnimate.fromValue = 0
        borderWidthAnimate.toValue = 5
        borderWidthAnimate.duration = 1
        borderWidthAnimate.repeatCount = .infinity
        borderWidthAnimate.autoreverses = true

        let borderColorAnimate = CABasicAnimation(keyPath: "borderColor")
        borderColorAnimate.toValue = UIColor.yellow.cgColor
        borderColorAnimate.duration = 1
        borderColorAnimate.repeatCount = .infinity
        borderColorAnimate.autoreverses = true

        capturedImageView.layer.add(borderWidthAnimate, forKey: nil)
        capturedImageView.layer.add(borderColorAnimate, forKey: nil)
    }
    
    public func didCapture() {
        capturedImageView.layer.removeAllAnimations()
    }
    
    public func getPhotoThumbnail(_ data: Data) {
        capturedImageView.image = UIImage(data: data)
    }
    
    public func setRAWStatus(_ mode: RAWMode) {
        self.rawButton.rawMode = mode
    }
}

extension BottomSheetView {
    public func adjustOrientationFromDevice(_ orientation: UIDeviceOrientation) {
        rawButton.adjustOrientation(orientation: orientation)
        capturedImageView.adjustOrientation(orientation: orientation)
        focusModeButton.adjustOrientation(orientation: orientation)
        lenPositionLable.adjustOrientation(orientation: orientation)
    }
}
