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
    var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            videoPreviewLayer.videoGravity = videoGravity
        }
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
             fatalError("Expected `Preview Layer` type for layer. Check PreviewView.layerClass implementation.")
        }
        layer.videoGravity = .resize
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
    
    private var gridView: SPGridView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let gridView = gridView {
                self.addSubview(gridView)
            }
        }
    }
    
    private(set) public var showGrid: Bool = false {
        didSet {
            if oldValue {
                self.gridView = nil
            } else {
                self.gridView = SPGridView(frame: self.bounds)
            }
        }
    }
    
    public func toggleGrid() {
        showGrid.toggle()
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

}
