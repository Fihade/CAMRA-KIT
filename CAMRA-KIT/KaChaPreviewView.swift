//
//  KaChaPreviewView.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/23.
//

import UIKit
import AVFoundation

class KaChaPreviewView: UIView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
             fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        
        layer.videoGravity = .resize
        return layer
    }
    
    var gridView: KaChaGridView? {
        didSet {
            oldValue?.removeFromSuperview()
            
            if let gridView = gridView {
                self.addSubview(gridView)
            }
        }
    }
    
    var showGridView: Bool = false {
        didSet {
            if self.showGridView == oldValue {
                return
            }
            
            if(self.showGridView) {
                self.gridView = KaChaGridView(frame: self.bounds)
            } else {
                self.gridView = nil
            }
        }
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
