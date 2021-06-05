//
//  CapturedImageView.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/27.
//

import UIKit

class CapturedImageView: UIImageView {
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
//        self.bounds.size = CGSize(width: 60, height: 60)
        self.backgroundColor = .black
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowOpacity = 1
    }
}

