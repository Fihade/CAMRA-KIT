//
//  KCPreviewView.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/17.
//

import UIKit
import AVFoundation

enum KCError: Error {
    case previewError
    
    
}

class KCPreviewView: UIView {

    var realTimePreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
//            fatalError(KCError.previewError)
            fatalError("preview not found")
        }
        
        return layer
    }
    
    var session: AVCaptureSession?

    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
