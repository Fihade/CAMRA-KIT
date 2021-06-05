//
//  LenView.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/11.
//

import UIKit

class LenButton: UIButton {
    
    var extraLens = [".5", "1", "2"]
    var currentIndex = 1 {
        didSet {
            setName("\(extraLens[currentIndex])x")
        }
    }
    
    private var name: String? {
        didSet {
            self.setTitle(name, for: .normal)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()

    }
    
    private func setupUI() {
        self.backgroundColor = #colorLiteral(red: 0.3215686275, green: 0.3215686275, blue: 0.3215686275, alpha: 1)
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1
        self.clipsToBounds = true
        self.layer.cornerRadius = 15
        
        setName("\(extraLens[currentIndex])x")
    }
    
    public func setName(_ name: String) {
        self.name = name
    }
    
    public func getNextLen() {
        if currentIndex + 1 < extraLens.count {
            currentIndex = currentIndex + 1
        } else {
            currentIndex = 0
        }
    }
}
