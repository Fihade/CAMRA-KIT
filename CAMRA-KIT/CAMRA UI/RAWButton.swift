//
//  RAWButton.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/10.
//

import UIKit

enum RAWMode: String {
    case RAW
    case RAWPlus =  "RAW+"
    case MAX
}

class RAWButton: UIButton {
    
    public var rawMode = RAWMode.RAW {
        didSet {
            self.setTitle(rawMode.rawValue, for: .normal)
        }
    }
    
    public var isOn = false {
        didSet {
            self.layer.borderColor = isOn ? UIColor.yellow.cgColor : UIColor.white.cgColor
            self.setTitleColor(isOn ? UIColor.yellow : UIColor.white, for: .normal)
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
        self.setTitle(rawMode.rawValue, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        self.layer.borderColor = isOn ? UIColor.yellow.cgColor : UIColor.white.cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        self.titleLabel?.backgroundColor = .black
    }
}

