//
//  ModeControlButton.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/26.
//

import UIKit

class ModeControlButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        
    }
    
    func layerOperation(_ layer: CALayer) {
        
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        self.layerOperation(self.layer)

        
    }
    
}
