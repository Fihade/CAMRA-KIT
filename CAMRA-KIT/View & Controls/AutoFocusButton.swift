//
//  AutoFocusButton.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/27.
//

import UIKit

class AutoFocusButton: ModeControlButton {
    
    var isOn = false {
        didSet {
            if isOn {
                tintColor = UIColor(named: "HighlightedColor")
                backgroundColor = #colorLiteral(red: 0.3019607843, green: 0.3019607843, blue: 0.06274509804, alpha: 1)
            } else {
                tintColor = .white
                self.backgroundColor = #colorLiteral(red: 0.3215686275, green: 0.3215686275, blue: 0.3215686275, alpha: 1)
            }
        }
    }
    
    override func setup() {
        self.clipsToBounds = true
        self.bounds.size = CGSize(width: 30, height: 30)
    }
    
    override func layerOperation(_ layer: CALayer) {
        if isOn {
            layer.borderColor = UIColor(named: "HighlightedColor")?.cgColor
        } else {
            layer.borderColor = UIColor.white.cgColor
        }
    }

    override func awakeFromNib() {
        layer.cornerRadius = self.bounds.height / 2
        layer.borderWidth = 1
    }
}
