//
//  WhiteBalanceOptionBar.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/6/1.
//
import UIKit

struct WhiteBalance: Equatable {
    let value: Int
    let name: String
    let icon: String
    let highlightIcon: String
    
    public static let `default`: WhiteBalance = WhiteBalance(value: 0, name: "auto", icon: "tc", highlightIcon: "tc")
}

class WhiteBalanceButton: UIButton {
    
    
    var wb: WhiteBalance! {
        didSet {
            self.setImage(UIImage(named: wb.icon), for: .normal)
            self.setImage(UIImage(named: wb.highlightIcon), for: .selected)
        }
    }
    var size: CGFloat = 25
    var tapEvent: ((WhiteBalance) -> Void)?
    
    convenience init(wb: WhiteBalance) {
        self.init(wb: wb, size: 25)
    }
    
    convenience init(wb: WhiteBalance, size: CGFloat = 25) {
        self.init()
        self.setValue(wb, forKey: "wb")
        self.size = size
        setupUI()
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        guard let newVal = value as? WhiteBalance else {
            return
        }
        self.wb = newVal
    }
    
    func setupUI() {
        
        self.setImage(UIImage(named: wb.icon), for: .normal)
        self.setPreferredSymbolConfiguration(.init(pointSize: 25), forImageIn: .normal)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectTimer(_:))))
        
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: size),
            self.heightAnchor.constraint(equalToConstant: size)
        ])
        
    }
    
    @objc private func selectTimer(_ sender: UITapGestureRecognizer) {
        if let event = tapEvent {
            event(wb)
        }
        self.isSelected.toggle()
        NotificationCenter.default.post(name: .AWBDidSelected, object: nil)
    }
    
}

class WhiteBalanceOptionBar: UIView {
    
    public var whiteBalance = WhiteBalance.default {
        didSet {
            for child in children {
                if whiteBalance.name != child.wb.name {
                    child.isSelected = false
                }
            }
        }
    }
    
    private var children = [WhiteBalanceButton]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        

        self.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        let label = UILabel()
        label.text = "AWB"
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .white
        
        stackView.setCustomSpacing(30, after: label)

        
        let closeButton = WhiteBalanceButton(wb: WhiteBalance.default)
        closeButton.tapEvent = { sender in
            self.whiteBalance = sender
            self.disappear()
        }
        children.append(closeButton)
        
        let daylightButton = WhiteBalanceButton(wb: WhiteBalance(value: 5200, name: "daylight", icon: "wdaylight", highlightIcon: "hwdaylight"))
        daylightButton.tapEvent = { sender in
            self.whiteBalance = sender
            self.disappear()
        }
        children.append(daylightButton)
        
        let cloudyButton =  WhiteBalanceButton(wb: WhiteBalance(value: 6000, name: "cloudy", icon: "wcloudy", highlightIcon: "hwcloudy"))
        cloudyButton.tapEvent = { sender in
            self.whiteBalance = sender
            self.disappear()
        }
        children.append(cloudyButton)
        
        let tungstenButton = WhiteBalanceButton(wb: WhiteBalance(value: 3200, name: "tungsten", icon: "wtungsten", highlightIcon: "hwtungsten"))
        tungstenButton.tapEvent = { sender in
            self.whiteBalance = sender
            self.disappear()
        }
        children.append(tungstenButton)
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubviews(children)
        
    }
    
    func appear() {
        
        let moveLeft = CABasicAnimation(keyPath: "position.x")
        moveLeft.fromValue = self.bounds.size.width * 1.5
        moveLeft.toValue = self.bounds.size.width / 2
        moveLeft.duration = 0.5
        
        let appearOpacity = CABasicAnimation(keyPath: "opacity")
        appearOpacity.fromValue = 0
        appearOpacity.toValue = 1
        appearOpacity.duration = 0.5
        
        self.layer.add(moveLeft, forKey: nil)
        self.layer.add(appearOpacity, forKey: nil)
        
        self.layer.opacity = 1
        
    }
    
    func disappear() {

        let moveRight = CABasicAnimation(keyPath: "position.x")
        moveRight.fromValue = self.bounds.size.width / 2
        moveRight.toValue = self.bounds.width * 1.5
        moveRight.duration = 0.5
        moveRight.fillMode = .both
        
        let appearOpacity = CABasicAnimation(keyPath: "opacity")
        appearOpacity.fromValue = 1
        appearOpacity.toValue = 0
        appearOpacity.duration = 0.5
        appearOpacity.fillMode = .both
        
        self.layer.add(moveRight, forKey: nil)
        self.layer.add(appearOpacity, forKey: nil)
        
        
        self.layer.opacity = 0
    }
    
}
