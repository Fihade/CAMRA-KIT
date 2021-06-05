//
//  EVLabel.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/11.
//

import UIKit

class EVLabel: UILabel {

    var bias: Float = 0.0 {
        didSet {
            if bias < 0 {
                self.text = " - \(String.localizedStringWithFormat("%.1f", -bias)) "
            } else {
                self.text = " + \(String.localizedStringWithFormat("%.1f", bias)) "
            }
            
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    convenience init(maxEV: CGFloat, minEV: CGFloat) {
        self.init()
    }
    
//    override func draw(_ rect: CGRect) {
//        super.draw(rect)
//
//
//    }
//
    private func setupUI() {
        self.text = " + \(bias) "
        self.textColor = UIColor.yellow
        self.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.masksToBounds = true
//        self.layer.borderWidth = 1
//        self.layer.cornerRadius = 5
//        self.layer.masksToBounds = true
//        self.layer.backgroundColor =
        
    }
    
    override func didMoveToWindow() {
        self.layer.mask = maskLayer
    }
    
    let shapeLayer = CAShapeLayer()
    let maskLayer = CAShapeLayer()
        
    override func layoutSubviews() {

        shapeLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 5).cgPath
        shapeLayer.strokeColor = UIColor.yellow.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.fillColor = UIColor.black.withAlphaComponent(0.4).cgColor
        maskLayer.path = shapeLayer.path
    }
    
    func setBias(_ val: Float) {
        self.bias = val
    }
}
