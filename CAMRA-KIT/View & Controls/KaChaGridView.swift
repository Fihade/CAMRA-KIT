//
//  KaChaGridView.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/24.
//

import UIKit

class KaChaGridView: UIView {
    
    var color: UIColor = UIColor.white.withAlphaComponent(0.5) {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        backgroundColor = .clear
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.setStrokeColor(self.color.cgColor)
        context.setLineWidth(1.0)
        
        let pairs: [[CGPoint]] = [
            [CGPoint(x: rect.width / 3.0, y: rect.minY), CGPoint(x: rect.width / 3.0, y: rect.maxY)],
            [CGPoint(x: 2 * rect.width / 3.0, y: rect.minY), CGPoint(x: 2 * rect.width / 3.0, y: rect.maxY)],
            [CGPoint(x: rect.minX, y: rect.height / 3.0), CGPoint(x: rect.maxX, y: rect.height / 3.0)],
            [CGPoint(x: rect.minX, y: 2 * rect.height / 3.0), CGPoint(x: rect.maxX, y: 2 * rect.height / 3.0)]
        ]
        
        for pair in pairs {
            context.addLines(between: pair)
        }
        
        context.strokePath()
    }


}
