//
//  UIViewExtension.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/10.
//

import Foundation
import UIKit

extension UIView {
    
    // make UIView orientation with UIDevice rotated
    func adjustOrientation(orientation: UIDeviceOrientation) {
        switch orientation {
            case .landscapeLeft:
                UIView.animate(
                    withDuration: 0.5,
                    animations: { self.transform = CGAffineTransform(rotationAngle: .pi / 2) })
        
            case .landscapeRight:
                UIView.animate(
                    withDuration: 0.5,
                    animations: { self.transform = CGAffineTransform(rotationAngle: -.pi / 2) })
            case .portraitUpsideDown:
                UIView.animate(
                    withDuration: 0.5,
                    animations: { self.transform = CGAffineTransform(rotationAngle: -.pi) })
            default:
                UIView.animate(
                    withDuration: 0.5,
                    animations: { self.transform = CGAffineTransform(rotationAngle: 0) })
        }
    }
}
