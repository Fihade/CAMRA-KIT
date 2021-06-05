//
//  ZoomFactorButton.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/25.
//

import UIKit

class ZoomFactorButton: ModeControlButton {
    
    
    override func setup() {
        self.backgroundColor = #colorLiteral(red: 0.3215686275, green: 0.3215686275, blue: 0.3215686275, alpha: 1)
        self.clipsToBounds = true
        self.bounds.size = CGSize(width: 30, height: 30)
    }
    
    override func awakeFromNib() {
        layer.cornerRadius = self.bounds.height / 2
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor
    }

}
