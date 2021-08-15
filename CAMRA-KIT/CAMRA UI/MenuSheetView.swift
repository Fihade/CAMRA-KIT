//
//  MenuSheetView.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/8.
//

import UIKit
import AVFoundation

protocol MenuSheetViewDelegate: AnyObject {
    // show grid view
    func showGirdView(using button: UIButton)
    
    func toggleCamera()
    
    func setFlashMode(using button: UIButton)
    
    func selectedAWBMode(with value: Int)
}

extension Notification.Name {
    static let TimerDidSelected = Notification.Name("TimerDidSelected")
    static let AWBDidSelected = Notification.Name("AWBDidSelected")
}

class MenuSheetView: UIView {
    
    weak var delegate: MenuSheetViewDelegate?
    
    var feedbackGenerator : UISelectionFeedbackGenerator? = nil
    
    // subViews
    private var dragBar: UIImageView!
    private var gridButton: UIButton!
    private var flashButton: UIButton!
    private var toggleCameraButton: UIButton!
    private var timerButton: UIButton!
    private var settingButton: UIButton!
    private var awbButton: UIButton!
    
    private var timerOptionBar: TimerOptionBar!
    private var whiteBalanceOptionBar: WhiteBalanceOptionBar!
    
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addButtonTarget()
        addObservers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        addButtonTarget()
        addObservers()
    }
    
    private func setupUI() {
        
        dragBar = UIImageView(image: UIImage(systemName: "minus"))
        dragBar.tintColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
        dragBar.preferredSymbolConfiguration = .init(font: UIFont.systemFont(ofSize: 15, weight: .bold))
        dragBar.translatesAutoresizingMaskIntoConstraints = false
        dragBar.contentMode = .scaleAspectFill
        self.addSubview(dragBar)
        
        NSLayoutConstraint.activate([
            dragBar.heightAnchor.constraint(equalToConstant: 7),
            dragBar.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            dragBar.topAnchor.constraint(equalTo: self.topAnchor, constant: 3)
        ])
        
        gridButton = UIButton(frame: .zero)
        gridButton.setPreferredSymbolConfiguration(.init(font: UIFont.preferredFont(forTextStyle: .title2)), forImageIn: .normal)
        gridButton.tintColor = .white
        gridButton.setImage(UIImage(systemName: "squareshape.split.3x3"), for: .normal)
        gridButton.translatesAutoresizingMaskIntoConstraints = false
        gridButton.isUserInteractionEnabled = true
        self.addSubview(gridButton)
        
        flashButton = UIButton()
        flashButton.setPreferredSymbolConfiguration(.init(font: UIFont.preferredFont(forTextStyle: .title2)), forImageIn: .normal)
        flashButton.tintColor = .white
        flashButton.layer.masksToBounds = true
        flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(flashButton)
        
        toggleCameraButton = UIButton()
        toggleCameraButton.setPreferredSymbolConfiguration(
            .init(font: UIFont.preferredFont(forTextStyle: .title2)),
            forImageIn: .normal
        )

        toggleCameraButton.tintColor = .white
        toggleCameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill"), for: .normal)
        toggleCameraButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(toggleCameraButton)
        
        let container = UILayoutGuide()
        self.addLayoutGuide(container)
        
        NSLayoutConstraint.activate([
            // Layout Guide
            container.heightAnchor.constraint(equalToConstant: 40),
            // Container
            container.topAnchor.constraint(equalTo: dragBar.bottomAnchor),
            container.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -20),
            container.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            
            // flash Button
            flashButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            flashButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            // grid Button
            gridButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            gridButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            // toggle Button
            toggleCameraButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            toggleCameraButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        
        
        timerButton = UIButton(frame: .zero)
        timerButton.setPreferredSymbolConfiguration(.init(font: UIFont.preferredFont(forTextStyle: .title2)), forImageIn: .normal)
        timerButton.tintColor = .white
        timerButton.setImage(UIImage(systemName: "timer"), for: .normal)
        timerButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(timerButton)
        
        settingButton = UIButton()
        settingButton.setPreferredSymbolConfiguration(
            .init(font: UIFont.preferredFont(forTextStyle: .title2)), forImageIn: .normal)
        settingButton.tintColor = .white
        settingButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(settingButton)
        
        awbButton = UIButton()
        awbButton.contentMode = .scaleAspectFit
        awbButton.setImage(UIImage(named: "awb"), for: .normal)
        awbButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(awbButton)
        
        let container1 = UILayoutGuide()
        
        self.addLayoutGuide(container1)
        
        timerOptionBar = TimerOptionBar()
        timerOptionBar.layer.opacity = 0
        timerOptionBar.backgroundColor = .black
        timerOptionBar.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(timerOptionBar)
        
        whiteBalanceOptionBar = WhiteBalanceOptionBar()
        whiteBalanceOptionBar.layer.opacity = 0
        whiteBalanceOptionBar.backgroundColor = .black
        whiteBalanceOptionBar.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(whiteBalanceOptionBar)
        
        NSLayoutConstraint.activate([
            // Layout Guide
            container1.heightAnchor.constraint(equalToConstant: 40),
            container1.topAnchor.constraint(equalTo: container.bottomAnchor),
            container1.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -20),
            container1.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            container1.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            
            timerButton.leadingAnchor.constraint(equalTo: container1.leadingAnchor),
            timerButton.centerYAnchor.constraint(equalTo: container1.centerYAnchor),
            timerButton.heightAnchor.constraint(equalToConstant: 25),
            timerButton.widthAnchor.constraint(equalToConstant: 25),
            
            // grid Button
            settingButton.centerYAnchor.constraint(equalTo: container1.centerYAnchor),
            settingButton.centerXAnchor.constraint(equalTo: container1.centerXAnchor),
            
            // toggle Button
            awbButton.centerYAnchor.constraint(equalTo: container1.centerYAnchor),
            awbButton.trailingAnchor.constraint(equalTo: container1.trailingAnchor),
            awbButton.heightAnchor.constraint(equalToConstant: 25),
            awbButton.widthAnchor.constraint(equalToConstant: 25),
            
//            timerOptionBar.widthAnchor.constraint(equalTo: self.widthAnchor),
            timerOptionBar.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            timerOptionBar.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            timerOptionBar.heightAnchor.constraint(equalTo: container1.heightAnchor),
            timerOptionBar.topAnchor.constraint(equalTo: container1.topAnchor),
            
            whiteBalanceOptionBar.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            whiteBalanceOptionBar.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            whiteBalanceOptionBar.heightAnchor.constraint(equalTo: container1.heightAnchor),
            whiteBalanceOptionBar.topAnchor.constraint(equalTo: container1.topAnchor),
            
        ])
        
        
        
    }
}

// MenuSheetView KVO
extension MenuSheetView {
    
    private func addObservers() {
        NotificationCenter.default.addObserver(
            forName: .TimerDidSelected,
            object: nil, queue: .main,
            using: {_ in
                if self.timerOptionBar.timer == .default {
                    self.timerButton.setImage(UIImage(systemName: "timer"), for: .normal)
                } else {
                    self.timerButton.setImage(UIImage(named: self.timerOptionBar.timer.hightlightIcon), for: .normal)
                }
            }
        )
        
        NotificationCenter.default.addObserver(
            forName: .AWBDidSelected,
            object: .none, queue: .main,
            using: {_ in
                if self.whiteBalanceOptionBar.whiteBalance == .default {
                    self.awbButton.setImage(UIImage(named: "awb"), for: .normal)
                } else {
                    self.awbButton.setImage(UIImage(named: self.whiteBalanceOptionBar.whiteBalance.highlightIcon), for: .normal)
                }
            }
        )
    }
}

// Button Action
extension MenuSheetView {
    
    // Attach to Subutton Action
    private func addButtonTarget() {
        self.gridButton.addTarget(self, action: #selector(showGrid), for: .touchUpInside)
        self.toggleCameraButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
        self.flashButton.addTarget(self, action: #selector(setFlashMode), for: .touchUpInside)
        self.timerButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectTimer)))
        self.awbButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectAWB)))
    }
    
    // Show grid
    @objc private func showGrid(_ sender: UIButton) {
        delegate?.showGirdView(using: sender)
    }
    
    // Toggle Camera
    @objc private func toggleCamera(_ sender: UIButton) {
        delegate?.toggleCamera()
    }
    
    // Set Flash Mode
    @objc private func setFlashMode(_ sender: UIButton) {
        delegate?.setFlashMode(using: sender)
    }
    
    @objc private func selectTimer() {
//        optionWillSelectedAnimate()
        timerOptionBar.appear()
    }
    
    @objc private func selectAWB() {
//        optionWillSelectedAnimate()
        whiteBalanceOptionBar.appear()
    }
}

// Drag pull gesture
extension MenuSheetView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator?.prepare()
        feedbackGenerator?.selectionChanged()

        self.dragBar.image = UIImage(systemName: "minus")
    }

    // Swipe Up Gesture
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        feedbackGenerator?.prepare()
        for touch in touches {
            let distance = touch.previousLocation(in: self).y - touch.location(in: self).y
            
            if distance > 0 {
                self.transform = CGAffineTransform(
                    translationX: 0,
                    y: transform.ty > -40 ? transform.ty - distance : -40)
            } else {
                if transform.ty  < 0 {
                    transform = CGAffineTransform(translationX: 0, y: transform.ty - distance > 0 ? 0 : transform.ty - distance)
                }
                
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if -transform.ty < 90 / 4 {
            UIView.animate(
                withDuration: 0.3,
                animations: {self.transform = CGAffineTransform(translationX: 0, y: 0)},
                completion: {_ in
                    self.feedbackGenerator?.selectionChanged()
                    self.feedbackGenerator = nil
                })
        } else {
            UIView.animate(
                withDuration: 0.3,
                animations: { self.transform = CGAffineTransform(translationX: 0, y: -40)},
                completion: {_ in
                    self.dragBar.image = UIImage(systemName: "chevron.compact.down")
                    self.feedbackGenerator?.selectionChanged()
                    self.feedbackGenerator = nil
                })
        }
        
    }
}

extension MenuSheetView {
    public func adjustOrientationFromDevice(_ orientation: UIDeviceOrientation) {
        gridButton.adjustOrientation(orientation: orientation)
        awbButton.adjustOrientation(orientation: orientation)
        flashButton.adjustOrientation(orientation: orientation)
        timerButton.adjustOrientation(orientation: orientation)
        settingButton.adjustOrientation(orientation: orientation)
        toggleCameraButton.adjustOrientation(orientation: orientation)
    }
}
