//
//  TimerOptionBar.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/31.
//

import UIKit

struct Timer: Equatable {
    let value: Int
    let iconName: String
    let hightlightIcon: String
    
    public static let `default`: Timer = Timer(value: 0, iconName: "tc", hightlightIcon: "tc")
}

class TimerButton: UIButton {
    
    var timer: Timer! {
        didSet {
            self.setImage(UIImage(named: timer.iconName), for: .normal)
            self.setImage(UIImage(named: timer.hightlightIcon), for: .selected)
        }
    }
    var size: CGFloat = 25
    var tapEvent: ((Timer) -> Void)?
    
    convenience init(timer: Timer) {
        self.init()
        setValue(timer, forKey: "timer")
        setupUI()
    }
    
    convenience init(timer: Timer, size: CGFloat = 25) {
        self.init()
        
        setValue(timer, forKey: "timer")
        self.size = size
        setupUI()
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        guard let newVal = value as? Timer else { return }
        
        timer = newVal
    }
    
    private func setupUI() {
        
        self.setImage(UIImage(named: timer.iconName), for: .normal)
        self.setPreferredSymbolConfiguration(.init(pointSize: 25), forImageIn: .normal)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectTimer(_:))))
        
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: size),
            self.heightAnchor.constraint(equalToConstant: size)
        ])
        
    }
    
    @objc private func selectTimer(_ sender: UITapGestureRecognizer) {
        if let event = tapEvent {
            event(timer)
        }
        self.isSelected.toggle()
        NotificationCenter.default.post(name: .TimerDidSelected, object: nil)
    }
    
}

extension UIStackView {
    public func addArrangedSubviews(_ views: [UIView]) {
        for view in views {
            self.addArrangedSubview(view)
        }
    }
}

class TimerOptionBar: UIView {
    
    private var children = [TimerButton]()
    
    public var timer = Timer.default {
        didSet {
            for child in children {
                if child.timer != timer {
                    child.isSelected = false
                }
            }
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
        label.text = "Timer"
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .white
        stackView.setCustomSpacing(30, after: label)
        
        
        let closeButton = TimerButton(timer: Timer.default)
        closeButton.tapEvent = { sender in
            self.timer = sender
            self.disappear()
        }
        children.append(closeButton)
        
        let threeButton = TimerButton(timer: Timer(value: 3, iconName: "t3", hightlightIcon: "ht3"))
        threeButton.tapEvent = { sender in
            self.timer = sender
            self.disappear()
        }
        children.append(threeButton)
        
        let tenButton = TimerButton(timer: Timer(value: 10, iconName: "t10", hightlightIcon: "ht10"))
        tenButton.tapEvent = { sender in
            self.timer = sender
            self.disappear()
        }
        children.append(tenButton)
        
        let thirtyButton = TimerButton(timer: Timer(value: 30, iconName: "t30", hightlightIcon: "ht30"))
        thirtyButton.tapEvent = { sender in
            self.timer = sender
            self.disappear()
        }
        children.append(thirtyButton)
        
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

