//
//  FocusView.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/14.
//

import UIKit

class FocusView: UIView {
    
    convenience init(location: CGPoint, size: CGSize) {
        self.init()
        setupUI(location: location, size: size)
    }
    
    private func setupUI(location: CGPoint, size: CGSize) {
        
        self.frame = CGRect(x: location.x - size.width / 2, y: location.y - size.height / 2, width: size.width, height: size.height)        
        self.backgroundColor = .clear
        self.layer.cornerRadius = 5
    }
    
    public func animate() {
        let animator = CABasicAnimation(keyPath: "borderColor")
        animator.fromValue = UIColor.white.cgColor
        animator.toValue = UIColor.yellow.cgColor
        animator.duration = 0.3
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
        
        self.layer.borderColor = UIColor.yellow.cgColor
        self.layer.borderWidth = 2
        
    }
    
    public func dismissAnimate(completionHandler: ((FocusView) -> Void)? = nil) {
        UIView.animate(withDuration: 1, animations: {
            self.transform = CGAffineTransform(scaleX: 100, y: 100)
            self.alpha = 0
        }, completion: {_ in
            if let handler = completionHandler {
                handler(self)
            }
        })
    }
    
    
    
    

}
