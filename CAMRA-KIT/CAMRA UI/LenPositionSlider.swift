//
//  LenPositionSlider.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/24.
//

import UIKit

class LenPositionSlider: UIView {
    
    private var lenPositionLable: UILabel!
    private var lenPositionSlider: UISlider!
    private var focusModeButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        focusModeButton = UIButton()
        focusModeButton.setTitle("AF", for: .normal)
        focusModeButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(focusModeButton)
        
        lenPositionSlider = UISlider()
        lenPositionSlider.tintColor = .gray
        lenPositionSlider.isUserInteractionEnabled = true
        lenPositionSlider.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(lenPositionSlider)
        
        lenPositionLable = UILabel()
        lenPositionLable.text = "len"
        lenPositionLable.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(lenPositionLable)
        
        NSLayoutConstraint.activate([

            
            lenPositionSlider.widthAnchor.constraint(equalToConstant: 250),
            lenPositionSlider.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            lenPositionSlider.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            focusModeButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            focusModeButton.heightAnchor.constraint(equalToConstant: 27),
            focusModeButton.widthAnchor.constraint(equalToConstant: 27),
            focusModeButton.leadingAnchor.constraint(equalTo: lenPositionSlider.trailingAnchor, constant: 20),
            
            lenPositionLable.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            lenPositionLable.trailingAnchor.constraint(equalTo: lenPositionSlider.leadingAnchor, constant: -20)
        ])
        
    }
}
