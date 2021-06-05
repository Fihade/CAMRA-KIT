//
//  CaptureButtonView.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/30.
//

import UIKit

class CaptureButton: UIView {

    let photoLayer = CALayer()
    let circleLayer = CAShapeLayer()
    let maskLayer = CAShapeLayer()
    let image = UIImage(named: "Capture Button")!
    
    let lineWidth: CGFloat = 1
    
    var button: UIButton = UIButton()
    
    private var handler: (() -> Void)?
    
    convenience init(handler: @escaping () -> Void) {
        self.init()
        self.handler = handler
        self.setupUI()
    }
    
    private func setupUI() {

        button.layer.contentsGravity = .resizeAspectFill
        button.layer.masksToBounds = true
        button.backgroundColor = .black
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            button.topAnchor.constraint(equalTo: self.topAnchor),
            button.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        
        
        button.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
    }
    
    override func didMoveToWindow() {
        button.layer.mask = maskLayer
        button.imageView!.layer.addSublayer(circleLayer)
//        button.layer.addSublayer(circleLayer)

    }
    
    override func layoutSubviews() {
        
//        photoLayer.frame = bounds
        
        circleLayer.path = UIBezierPath(ovalIn: button.imageView?.bounds ?? button.bounds).cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineWidth = lineWidth
        circleLayer.strokeColor = UIColor.white.cgColor
        
        
        maskLayer.path = circleLayer.path
        maskLayer.frame = CGRect(
            origin: CGPoint(
                x: bounds.minX + button.imageView!.frame.minX,
                y: bounds.minY + button.imageView!.frame.minY
            ),
            size: button.bounds.size
        )
        
    }
    
    @objc func tap(_ sender: UIButton) {
        guard let handler = handler else {
            return
        }
        handler()
    }

}
