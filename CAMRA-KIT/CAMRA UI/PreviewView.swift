//
//  PreviewView.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/11.
//

import UIKit

class PreviewView: SPPreviewView {
    
    override func draw(_ rect: CGRect) {
        let borderPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 10)
        borderPath.fill()
    }
}
