//
//  FocusView.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/14.
//

import UIKit

class SPFocusView: UIView {
    
    convenience init(location: CGPoint) {
        self.init(location: location, size: CGSize(width: 100, height: 100))
    }
    
    convenience init(location: CGPoint, size: CGSize) {
        self.init()
        setupUI(location: location, size: size)
    }
    
    private func setupUI(location: CGPoint, size: CGSize) {
        self.frame = CGRect(x: location.x - size.width / 2, y: location.y - size.height / 2, width: size.width, height: size.height)        
        self.backgroundColor = nil
        self.layer.cornerRadius = 8
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.animatedAppear()
    }
    
    override func removeFromSuperview() {
        self.animatedDisappear()
        super.removeFromSuperview()
    }
    
    private func animatedAppear() {
        let animator = CABasicAnimation(keyPath: "borderColor")
        animator.fromValue = UIColor.black.cgColor
        animator.toValue = UIColor.yellow.cgColor
        animator.duration = 0.5
        animator.repeatCount = 2
        animator.autoreverses = true
        
        let borderAnimator = CABasicAnimation(keyPath: "borderWidth")
        borderAnimator.fromValue = 0
        borderAnimator.toValue = 4
        borderAnimator.duration = 0.3
        borderAnimator.repeatCount = 2
        borderAnimator.autoreverses = true
        
        self.layer.add(animator, forKey: nil)
        self.layer.add(borderAnimator, forKey: nil)
        
        self.layer.opacity = 0.7
        self.layer.borderColor = UIColor.yellow.cgColor
        self.layer.borderWidth = 2
    }
    
    private func animatedDisappear() {
        let disappearAnimator = CABasicAnimation(keyPath: "opacity")
        disappearAnimator.fromValue = 1
        disappearAnimator.toValue = 0
        disappearAnimator.duration = 0.5
        
        self.layer.add(disappearAnimator, forKey: "disappear animator")
        
    }
}
