//
//  EVLabel.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/11.
//

import UIKit

class EVLabel: UILabel {

    var bias: Float = 0.0 {
        didSet {
            if bias < 0 {
                self.text = " - \(String.localizedStringWithFormat("%.1f", -bias)) "
            } else {
                self.text = " + \(String.localizedStringWithFormat("%.1f", bias)) "
            }
            
        }
    }
    
//    private var lens: Lens!
//    
//    convenience init(lens: Lens) {
//        self.init()
//        self.lens = lens
//    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        bias = 0.0
        self.textColor = UIColor.yellow
        self.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 5
        self.backgroundColor = .black.withAlphaComponent(0.6)
    }
    
    func setBias(_ val: Float) {
        self.bias = val
    }
}
