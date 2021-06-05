//
//  TestViewController.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/15.
//

import UIKit

class TestViewController: UIViewController {

    var timerBar : WhiteBalanceOptionBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let slider = LenPositionSlider()
        slider.backgroundColor = .red
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.layer.borderColor = UIColor.white.cgColor
        slider.layer.borderWidth = 2
        view.addSubview(slider)
        
        NSLayoutConstraint.activate([
            
            slider.heightAnchor.constraint(equalToConstant: 40),
            slider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            slider.trailingAnchor.constraint(equalTo: view.leadingAnchor,constant: 20),
            slider.widthAnchor.constraint(equalTo: view.widthAnchor),
            
        ])
        
        slider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSlider(_ : ))))
        
        
        
//        timerBar = WhiteBalanceOptionBar(frame: CGRect(x: 0, y: 100, width: view.bounds.width, height: 40))
//        timerBar.backgroundColor = .systemBlue
//        timerBar.translatesAutoresizingMaskIntoConstraints = false
//        timerBar.layer.opacity = 0
//
//        view.addSubview(timerBar)
//
//        let moveRight = CABasicAnimation(keyPath: "position.x")
//        moveRight.fromValue = -view.bounds.size.width/2
//        moveRight.toValue = view.bounds.size.width/2
//        moveRight.duration = 0.3
//
//        NSLayoutConstraint.activate([
//            timerBar.widthAnchor.constraint(equalTo: view.widthAnchor),
//            timerBar.heightAnchor.constraint(equalToConstant: 40),
//            timerBar.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//
//        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapView)))
    }
    
    @objc func tapSlider(_ sender: UITapGestureRecognizer) {
        guard let v = sender.view else { return }
        
        v.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
    }
    
    var show = false
    
    @objc func tapView() {
//        timerBar.disappear()
        show.toggle()
        
        if show {
            timerBar.appear()
            
        } else {
            timerBar.disappear()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        timerBar.center.x -= view.bounds.width
    }
    
}


