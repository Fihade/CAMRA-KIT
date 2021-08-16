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
    
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var evLabel: EVLabel!
    
    private var bias: Float = 0
    private var delayTime = 0
    
    private lazy var cameraEngine: SPCameraEngine = SPCameraEngine(preview: mainView)
    
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
            forName: .AWBDidSelected,
            object: .none, queue: nil,
            using: { value in
                guard let wb = value.object as? WhiteBalance else { return }
                self.cameraEngine.setCameraAWB(at: Float(wb.value))
            }
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraEngine.startCameraRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraEngine.stopCameraRunning()
    }
    
    private func setupUI() {
        // self UI
        self.view.backgroundColor = .black
  
        //setup main view
        mainView = PreviewView()
        
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
    }
}

//MARK: SPCameraEngineDelegate
extension DemoViewController: SPCameraEngineDelegate {
    
    func cameraEngine(toggle position: AVCaptureDevice.Position) {
        DispatchQueue.main.async {[weak self] in
            self?.bottomSheet.setRAWStatus(position == .back ? .RAW : .MAX)
        }
    }
    
    func displayRGBHistogramWith(layers: [CAShapeLayer]?) {
        self.histogramView.layer.sublayers?.removeAll()
        
        if let layers = layers {
//            DispatchQueue.main.async {[weak self] in
                for layer in layers {
                    self.histogramView.layer.addSublayer(layer)
                }
//            }
        }
    }
    
    func cameraEngine(bias: Float) {
        DispatchQueue.main.async {[weak self] in
            self?.evLabel.setBias(bias)
        }
    }
}

extension DemoViewController: MenuSheetViewDelegate {
    
    func showGirdView(using button: UIButton) {
        cameraEngine.togglePreviewGrid()
        button.tintColor = cameraEngine.showGrid ? .yellow : .white
    }
    
    func toggleCamera() {
        cameraEngine.toggleCamera()
    }
    
    func setFlashMode(using button: UIButton) {
        switch cameraEngine.flashMode {
            case .on:
                cameraEngine.setFlashMode(.off)
                button.tintColor = .white
            case .off:
                cameraEngine.setFlashMode(.on)
                button.tintColor = .yellow
            case .auto:
                cameraEngine.setFlashMode(.off)
                button.tintColor = .white
            default:
                cameraEngine.setFlashMode(.off)
                button.tintColor = .white
        }
    }
    
    func selectedAWBMode(with value: Int) {
        cameraEngine.setCameraAWB(at: Float(value))
    }
}

//MARK: Receive bottom sheet delegate methods
extension DemoViewController: BottomSheetViewDelegate {
    
    // When tap focus button to switch focus mode from auto to manual mode,
    // the VC need to deal with focus mode switch to tell camera engine to switch it.
    func switchCameraFocusMode(is MFocus: Bool) {
//        if focusView != nil { self.focusView?.removeFromSuperview() }
        cameraEngine.switchFocusMode(MFocus ? .autoFocus : .continuousAutoFocus)
    }
    
    // When sanp slider to change len position and tell camera engine to adjust len position
    func setLenPosition(with value: Float) {
        cameraEngine.adjustLenPosition(with: value)
    }

//    func checkImageInfo(_ image: UIImage) {
//        guard let detailVC = storyboard?.instantiateViewController(withIdentifier: "detailVC") as? CaptureImageDetailViewController else {
//            return
//        }
//        
////        detailVC.transitioningDelegate = self
//        detailVC.sourceImage = image
//        showDetailViewController(detailVC, sender: nil)
//    }
    
    
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
        cameraEngine.capturePhoto(with: delegate)
    }
    
}

