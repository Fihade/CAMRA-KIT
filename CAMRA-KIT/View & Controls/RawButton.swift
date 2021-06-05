//
//  RawButton.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/27.
//

import UIKit

class RawButton: ModeControlButton {
    
    var isOn = false {
        didSet {
            setNeedsDisplay()
            backgroundColor = isOn ? .black : #colorLiteral(red: 0.4666666667, green: 0.4666666667, blue: 0.4666666667, alpha: 1)
            tintColor = isOn ? UIColor(named: "HighlightedColor") : .black
            layer.borderWidth = isOn ? 1 : 0
        }
    }
    
    override func setup() {
        self.clipsToBounds = true
        self.bounds.size = CGSize(width: 35, height: 23)
        self.backgroundColor = isOn ? UIColor(named: "HighlightedColor") : #colorLiteral(red: 0.4666666667, green: 0.4666666667, blue: 0.4666666667, alpha: 1)
        self.tintColor = isOn ? UIColor(named: "HighlightedColor") : .black
    }
    
    override func layerOperation(_ layer: CALayer) {
        layer.borderColor = UIColor(named: "HighlightedColor")?.cgColor
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        print("init coder raw button")
    }
    
    override func didMoveToWindow() {
        layer.cornerRadius = bounds.height / 4
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
    }
}
