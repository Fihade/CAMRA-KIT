//
//  SPPreviewView.swift
//  CameraEngine
//
//  Created by Fihade on 2021/5/5.
//

import UIKit
import AVFoundation


class SPPreviewView: UIView {

    // Video gravity. Default is Aspect
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            videoPreviewLayer.videoGravity = videoGravity
        }
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
             fatalError("Expected `Preview Layer` type for layer. Check PreviewView layerClass implementation.")
        }
        layer.videoGravity = videoGravity
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    private var shapeLayer: CAShapeLayer!
//    private lazy var color: UIColor = UIColor.white
   
    private(set) public var showGrid: Bool = false {
        didSet {
            if showGrid {
                addGridLayer()
            } else {
                shapeLayer.removeFromSuperlayer()
            }
        }
    }
    
    public func toggleGrid() {
        showGrid.toggle()
    }
    
    private func addGridLayer() {
        let path = UIBezierPath()
        let rect = self.bounds
        let color = #colorLiteral(red: 0.5176470588, green: 0.5176470588, blue: 0.5176470588, alpha: 1)
        
        DispatchQueue.global(qos: .userInteractive).async {[weak self] in
            self?.shapeLayer = CAShapeLayer()
            self?.shapeLayer.backgroundColor = UIColor.clear.cgColor
            self?.shapeLayer.strokeColor = color.cgColor
            
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
            
            self?.shapeLayer.path = path.cgPath
            DispatchQueue.main.async {
                self?.layer.addSublayer(self!.shapeLayer)
            }
        
        }
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

}
