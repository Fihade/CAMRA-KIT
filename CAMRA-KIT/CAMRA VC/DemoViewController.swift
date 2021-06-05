//
//  DemoViewController.swift
//  CAMRA-KIT
//
//  Created by fihade on 2021/5/8.
//

import UIKit
import AVFoundation
import Accelerate

class DemoViewController: UIViewController {

    private var mainView: PreviewView!
    private var bottomSheet: BottomSheetView!
    private var imageView: UIImageView!
    private var menuSheet: MenuSheetView!
    private var histogramView: UIView!
    
    private var focusView: FocusView?
    private var feedbackGenerator : UISelectionFeedbackGenerator? = nil
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var evLabel: EVLabel!
    
    private var bias: Float = 0
    private var delayTime = 0
    
    private let cameraEngine = SPCameraEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        cameraEngine.delegate = self
        menuSheet.delegate = self
        bottomSheet.delegate = self

        // Notification
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil, queue: .main,
            using: {_ in
                self.menuSheet.adjustOrientationFromDevice(UIDevice.current.orientation)
                self.bottomSheet.adjustOrientationFromDevice(UIDevice.current.orientation)
            })
        
        NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceSubjectAreaDidChange,
            object: .none, queue: .none,
            using: {_ in
                self.cameraEngine.autoFocus()
                self.focusView?.dismissAnimate(completionHandler: {view in
                    view.removeFromSuperview()
                })
            })

        
        NotificationCenter.default.addObserver(
            forName: .AWBDidSelected,
            object: .none, queue: .main,
            using: { value in
                guard let wb = value.object as? WhiteBalance else { return }
                self.cameraEngine.setCameraAWB(in: wb.value)
            }
        )
        
//        cameraEngine.addPreview(mainView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        cameraEngine.startCameraRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraEngine.stopCameraRunning()
    }
    
    private func setupUI() {
        // self UI
        self.view.backgroundColor = .black
  
        //setup main view
        mainView = PreviewView()
        mainView.layer.masksToBounds = true
        
        mainView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainView)
        
        //setup menu sheet
        menuSheet = MenuSheetView()
        menuSheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuSheet)
        
        // setup bottom sheet
        bottomSheet = BottomSheetView()
        bottomSheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomSheet)
        
        NSLayoutConstraint.activate([
            
            bottomSheet.widthAnchor.constraint(equalTo: view.widthAnchor),
            bottomSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            menuSheet.widthAnchor.constraint(equalTo: view.widthAnchor),
            menuSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuSheet.topAnchor.constraint(equalTo: bottomSheet.topAnchor, constant: -50),
            
            mainView.bottomAnchor.constraint(equalTo: menuSheet.topAnchor, constant: 10),
            mainView.widthAnchor.constraint(equalTo: view.widthAnchor),
            mainView.topAnchor.constraint(equalTo: view.topAnchor),
            mainView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            topBarView.topAnchor.constraint(equalTo: mainView.topAnchor),
        ])
        
        view.bringSubviewToFront(topBarView)
        
       
        histogramView = UIView(frame: CGRect(x: 10, y: 30, width: 100, height: 50))
        histogramView.translatesAutoresizingMaskIntoConstraints = false
        histogramView.layer.backgroundColor = UIColor.black.cgColor

        self.view.addSubview(histogramView)
        
        
        
        attachMainView()
    }
}

// MARK: Preview Some Gesture
extension DemoViewController {
    
    private func attachMainView() {
        mainView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(swipUpPreview(_:))))
        mainView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapFocusPreview(_:))))
    }
    
    @objc func swipUpPreview(_ recogizer: UIPanGestureRecognizer) {
        switch recogizer.state {
            case .changed:
                let y = recogizer.translation(in: view).y
                
                var current = bias - (Float(y) / 10)
                
                if current > cameraEngine.maxBias {
                    current = cameraEngine.maxBias
                }else if(current < cameraEngine.minBias) {
                    current = cameraEngine.minBias
                }
                evLabel.setBias(current)
                cameraEngine.setDeviceBias(current)
            case .ended:
                self.bias = evLabel.bias
            default:
                break
        }
    }
    
    @objc private func tapFocusPreview(_ recognizer: UITapGestureRecognizer) {
        
        feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator?.prepare()
        feedbackGenerator?.selectionChanged()
        
        if let view = recognizer.view as? SPPreviewView {
            let devicePoint =  view.videoPreviewLayer.captureDevicePointConverted(
                fromLayerPoint: recognizer.location(in: view)
            )

            if let focusView = focusView {
                focusView.removeFromSuperview()
            }

            let location = recognizer.location(in: recognizer.view)
            let focusOfFrame = FocusView(
                location: location,
                size: CGSize(width: 80, height: 80)
            )

            recognizer.view?.addSubview(focusOfFrame)

            focusOfFrame.animate()
            focusView = focusOfFrame
            cameraEngine.focus(with: .autoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: true)
            
            self.feedbackGenerator = nil
        }
        
    }
}

extension DemoViewController: SPCameraEngineDelegate {
    
    func displayRGBHistogramWith(layers: [CAShapeLayer]?) {
        self.histogramView.layer.sublayers?.removeAll()
        
        if let layers = layers {
            DispatchQueue.main.async {[weak self] in
                for layer in layers {
                    self?.histogramView.layer.addSublayer(layer)
                }
            }
        }
    }
    
    
    func toggleCamera(to back: Bool) {
        DispatchQueue.main.async {
            self.bottomSheet.setRAWStatus(back ? .RAW : .MAX)
        }
    }
}

extension DemoViewController: MenuSheetViewDelegate {
    
    
    
    func showGirdView(using button: UIButton) {
        mainView.showGrid.toggle()
        button.tintColor = mainView.showGrid ? .yellow : .white
    }
    
    func toggleCamera() {
        cameraEngine.toggleCamera()
    }
    
    func setFlashMode(using button: UIButton) {
        switch cameraEngine.flashMode {
            case .on:
                cameraEngine.setFlashMode(.off)
                button.tintColor = .white
            default:
                cameraEngine.setFlashMode(.on)
                button.tintColor = .yellow
        }
    }
}

extension DemoViewController: BottomSheetViewDelegate {
    
    
    func switchCameraFocusMode(is MFocus: Bool) {
        if focusView != nil { self.focusView?.removeFromSuperview() }
        self.cameraEngine.switchCameraFocusMode(isAuto: MFocus)
    }
    
    
    func setLenPosition(with value: Float) {
        cameraEngine.setLenPosition(with: value)
    }

    func checkImageInfo(_ image: UIImage) {
        guard let detailVC = storyboard?.instantiateViewController(withIdentifier: "detailVC") as? CaptureImageDetailViewController else {
            return
        }
        
        detailVC.transitioningDelegate = self
        detailVC.sourceImage = image
        showDetailViewController(detailVC, sender: nil)
    }
    
    
    func toggleRAWMode(_ button: RAWButton) {
        cameraEngine.rawOrMax.toggle()
        button.isOn = cameraEngine.rawOrMax
    }
    
    func toggleLen(_ button: LenButton) {
        UIView.transition(
            with: button, duration: 0.3,
            options: [.transitionFlipFromLeft, .curveEaseInOut],
            animations: {
                button.getNextLen()
            }
        )
    }
    
    func capturePhoto() {
        
        let delegate = SPCapturePhotoCaptureDelegate(
            willCapture: {
                self.bottomSheet.willCapture()
            },
            photoProcessing: {_ in
                self.bottomSheet.didCapture()
            },
            finishCapturing: {data in
                self.bottomSheet.getPhotoThumbnail(data)
            },
            completionHandler: {delegate in
                self.cameraEngine.setDelegateNil(using: delegate)
            }
        )
        cameraEngine.delayTime = delayTime
        cameraEngine.capturePhoto(with: delegate)
    }
    
}

extension DemoViewController: UIViewControllerTransitioningDelegate {
    
}
