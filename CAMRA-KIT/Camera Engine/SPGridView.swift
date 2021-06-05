//
//  SPGridView.swift
//  CameraEngine
//
//  Created by Fihade on 2021/5/5.
//

import UIKit

class SPGridView: UIView {
    
    let color: UIColor = UIColor.white.withAlphaComponent(0.5)
    let shapeLayer = CAShapeLayer()

    override func didMoveToWindow() {
        self.layer.addSublayer(shapeLayer)
    }
    
    override func layoutSubviews() {
        setGridLayer()
    }
    
    private func setGridLayer() {
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor
        let path = UIBezierPath()
        let rect = self.bounds
        let pairs: [[CGPoint]] = [
            [CGPoint(x: rect.width / 3.0, y: rect.minY), CGPoint(x: rect.width / 3.0, y: rect.maxY)],
            [CGPoint(x: 2 * rect.width / 3.0, y: rect.minY), CGPoint(x: 2 * rect.width / 3.0, y: rect.maxY)],
            [CGPoint(x: rect.minX, y: rect.height / 3.0), CGPoint(x: rect.maxX, y: rect.height / 3.0)],
            [CGPoint(x: rect.minX, y: 2 * rect.height / 3.0), CGPoint(x: rect.maxX, y: 2 * rect.height / 3.0)]
        ]
        
        for pair in pairs {
            path.move(to: pair[0])
            path.addLine(to: pair[1])
        }
        
        shapeLayer.path = path.cgPath
    }
}
