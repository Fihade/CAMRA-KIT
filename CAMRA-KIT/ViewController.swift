//
//  ViewController.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/12.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {
    
    enum LivePhotoMode {
        case on
        case off
        
        mutating func switchMode() {
            self = (self == .on) ? .off : .on
        }
    }

    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var preview: PreviewView!
    @IBOutlet weak var lastImageView: UIImageView!
    @IBOutlet weak var lastImageLoading: UIActivityIndicatorView!
    @IBOutlet weak var livePhotoModeButton: UIButton!
    @IBOutlet weak var isoButton: UIButton!
    
    var livePhotoMode = LivePhotoMode.on
    
    @IBAction func switchLivePhotoMode(_ sender: UIButton) {
        
        livePhotoMode.switchMode()
        
        livePhotoModeButton.tintColor = (livePhotoMode == .on) ? .systemYellow : .systemGray4
        
    }
    
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    @objc func longPressFocuss(_ recognizer: UILongPressGestureRecognizer) {
        var point: CGPoint?
        if recognizer.state == .began {
            point = recognizer.location(in: preview)
            print("point: \(point)")
            if let input = videoDeviceInput {
                let device = input.device
                if device.isFocusPointOfInterestSupported {
                    do {
                        try device.lockForConfiguration()
                        device.isSmoothAutoFocusEnabled = true
                        device.focusPointOfInterest = point!
                        device.focusMode = .autoFocus
                        device.unlockForConfiguration()
                    } catch _ {
                        
                    }
                } else {
                    print("device: \(device) \n not support")
                }
                print("device.autoFocusRangeRestriction : \(device.autoFocusRangeRestriction)")
                
                
                
            }
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureButton.isEnabled = true
        preview.session = session
        
        livePhotoModeButton.setImage(UIImage(systemName: "livephoto"), for: .selected)
        livePhotoModeButton.setTitleColor(.systemYellow, for: .selected)
        
        livePhotoModeButton.setImage(UIImage(systemName: "livephoto"), for: .normal)
        livePhotoModeButton.setTitleColor(.systemGray4, for: .normal)
        
        preview.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressFocuss(_:))))
        
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            setupResult = .notAuthorized
        }
        
//        sessionQueue.async {
//            self.configureSession()
//        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
                case .success:
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                
                case .notAuthorized:
                    DispatchQueue.main.async {
                        let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                        let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                        
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                                style: .cancel,
                                                                handler: nil))
                        
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                                style: .`default`,
                                                                handler: { _ in
                                                                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                              options: [:],
                                                                                              completionHandler: nil)
                        }))
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                case .configurationFailed:
                    DispatchQueue.main.async {
                        let alertMsg = "Alert message when something goes wrong during capture session configuration"
                        let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                        
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                                style: .cancel,
                                                                handler: nil))
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = preview.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    
    //MARK: Session Configuration
    
    // enum session 设置结果
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    private var session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "seesion queue")
    private var setupResult: SessionSetupResult = .success
    private var videoDeviceInput: AVCaptureDeviceInput! 
    private let photoOutput = AVCapturePhotoOutput()
    
    
    
    @IBAction func adjustCameraISO(_ sender: UISlider) {
        print(sender.state)
        if let deviceInput = videoDeviceInput {
            let device = deviceInput.device
            
            
            
            do {
                try device.lockForConfiguration()
                device.setExposureModeCustom(
                    duration: CMTime(seconds: 1/20, preferredTimescale: .max),
                    iso: sender.value
                    
                )
                
                device.unlockForConfiguration()
                
                
            } catch let error {
                fatalError("error: \(error)")
            }
            print("iso range \(device.activeFormat.minISO) - \(device.activeFormat.maxISO)")
            print("current iso : \(device.iso)")
        }
    }
    
    @IBAction func addISO(_ sender: UIButton) {
        if let deviceInput = videoDeviceInput {
            let device = deviceInput.device
            
            print(videoDeviceDiscoverySession.devices)
            
            do {
                try device.lockForConfiguration()
//                device.exposureMode
                if device.exposureTargetBias >= device.maxExposureTargetBias  {
                    device.setExposureTargetBias(device.exposureTargetBias - 1)
                } else {
                    device.setExposureTargetBias(device.exposureTargetBias + 1)
                }
                
                device.unlockForConfiguration()
                
                
            } catch let error {
                fatalError("error: \(error)")
            }
            print("bias: \(device.minExposureTargetBias) - \(device.maxExposureTargetBias)")
            print("iso range \(device.activeFormat.minISO) - \(device.activeFormat.maxISO)")
            print("current iso : \(device.iso)")
        }
    }
    
    
    // Seesion
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        session.sessionPreset = .photo
        
        var defaultVideoDevice: AVCaptureDevice?
        
        
        if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            defaultVideoDevice = dualCameraDevice
        } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            // If a rear dual camera is not available, default to the rear wide angle camera.
            defaultVideoDevice = backCameraDevice
        } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            // If the rear wide angle camera isn't available, default to the front wide angle camera.
            defaultVideoDevice = frontCameraDevice
        }
        
        guard let videoDevice = defaultVideoDevice else {
            print("video device is unavailble")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.exposureMode = .continuousAutoExposure
            videoDevice.unlockForConfiguration()
        } catch {
            //
        }
        
        print("max zoom: \(videoDevice.maxAvailableVideoZoomFactor)")
        print("min zoom: \(videoDevice.minAvailableVideoZoomFactor)")

        // 设置输入设备
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                

                
                DispatchQueue.main.async {
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(rawValue: self.windowOrientation.rawValue) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.preview.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                    
                }
            } else {
                print("Couldn't add video device input to the session.")
                self.setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }

        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
            
        } catch {
            print("can't create audio device: \(error)")
        }
        
        /// - Tag: AVCaptureVideoDataOutput to make real time process
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        let videoDataOutputSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA]
        videoDataOutput.videoSettings = videoDataOutputSettings
        videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
//        videoDataOutput.
//        session.addOutput(videoDataOutput)

        // 设置输出设备
        if session.canAddOutput(photoOutput) {
            // 添加
            session.addOutput(photoOutput)
            session.addOutput(videoDataOutput)
            // 配置
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = true
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            print("cant add output device")
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        
    }
    
    var isRecording = false
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        
        if switchModeControl.selectedSegmentIndex == 1 {
            
            print("recoding")
            guard let movieFileOutput = self.movieFileOutput else {
                return
            }
            
            
            switchModeControl.isEnabled = false
            let videoPreviewLayerOrientation = preview.videoPreviewLayer.connection?.videoOrientation
            print("movieFileOutput.isRecording : \(movieFileOutput.isRecording)")
            sessionQueue.async {
                if !movieFileOutput.isRecording {
                    print("movie file output start recording")
                    if UIDevice.current.isMultitaskingSupported {
                        self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                    }
                    
                    let movieFileOutputConnection = movieFileOutput.connection(with: .video)
                    movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
                    
                    let availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes
                    
                    if availableVideoCodecTypes.contains(.hevc) {
                        movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                    }
                    
                    // Start recording video to a temporary file.
                    let outputFileName = NSUUID().uuidString
                    let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                    movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
                } else {
                    movieFileOutput.stopRecording()
                }
            }
        } else {
            let photoSettings: AVCapturePhotoSettings
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                photoSettings = AVCapturePhotoSettings()
            }
            
            
            photoSettings.flashMode = .auto
            
            if livePhotoMode == .on {
                let livePhotoMovieFileName = NSUUID().uuidString
                let livePhotoMovieFilePath =
                    (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
                photoSettings.livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
            }
            
            
            
            
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }

    }
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera, .builtInDualWideCamera, .builtInWideAngleCamera],
        mediaType: .video,
        position: .unspecified
     )
    
    @IBAction func toggleCamera(_ sender: UIButton) {
        
        
        print("toggle camera")
        
        DispatchQueue.main.async {
            
            UIView.transition(
                with: self.preview,
                duration: 0.8,
                options: .transitionFlipFromBottom,
                animations: {
                    self.captureButton.isEnabled = false
                    self.sessionQueue.async {
                        let currentInputDevice = self.videoDeviceInput.device
                        let currentPosition = currentInputDevice.position
                        
                        let togglePosition: AVCaptureDevice.Position
                        let toggleDeviceType: AVCaptureDevice.DeviceType
                        
                        switch currentPosition {
                        case .unspecified, .front:
                            togglePosition = .back
                            toggleDeviceType = .builtInDualCamera
                        case .back:
                            togglePosition = .front
                            toggleDeviceType = .builtInTrueDepthCamera
                        @unknown default:
                            togglePosition = .back
                            toggleDeviceType = .builtInDualCamera
                        }
                        let devices = self.videoDeviceDiscoverySession.devices
                        var newVideoDevice: AVCaptureDevice? = nil
                        
                        if let device = devices.first(where: {$0.position == togglePosition && $0.deviceType == toggleDeviceType}) {
                            newVideoDevice = device
                        } else if let device = devices.first(where: {$0.position == togglePosition}) {
                            newVideoDevice = device
                        }
                        if let videoDevice = newVideoDevice {
                            
                            
                            do {
                                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                                
                                self.session.beginConfiguration()
                                self.session.removeInput(self.videoDeviceInput)
                                
                                if self.session.canAddInput(videoDeviceInput) {
                                    print("toggle can add new input")
                                    
                                    self.session.addInput(videoDeviceInput)
                                    self.videoDeviceInput = videoDeviceInput
                                } else {
                                    print("toggle can't add new input")
                                    self.session.addInput(self.videoDeviceInput)
                                }
                                
                                self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
                                self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
                                self.photoOutput.isPortraitEffectsMatteDeliveryEnabled = self.photoOutput.isPortraitEffectsMatteDeliverySupported
                                self.photoOutput.enabledSemanticSegmentationMatteTypes = self.photoOutput.availableSemanticSegmentationMatteTypes
                                
                                self.photoOutput.maxPhotoQualityPrioritization = .quality
                                
                                self.session.commitConfiguration()
                                
                            } catch {
                                print("Error occurred while creating video device input: \(error)")
                            }
                            
                            
                            
                        }
                        
                        DispatchQueue.main.async {
                            self.captureButton.isEnabled = true
                        }
                    }
                },
                completion: nil
            )
        }

        
        print("toggle finish")
    }
    
    @IBAction func cameraControl(_ sender: UISegmentedControl) {
        switchModeControl.isEnabled = false

        if sender.selectedSegmentIndex == 1 {
            print("toggle recording")
//            captureButton.isEnabled = false
            sessionQueue.async {
                let movieFileOutput = AVCaptureMovieFileOutput()
                
                if self.session.canAddOutput(movieFileOutput) {
                    self.session.beginConfiguration()
                    self.session.addOutput(movieFileOutput)
                    self.session.sessionPreset = .high
                    if let connection = movieFileOutput.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    self.session.commitConfiguration()
                    
                    DispatchQueue.main.async {
                        self.switchModeControl.isEnabled = true
                    }
                    
                    self.movieFileOutput = movieFileOutput
                    
                    DispatchQueue.main.async {
                        self.captureButton.isEnabled = true
                        
                    }
                }
            }
            
        } else {
            print("toggle capturing")
            
            
            sessionQueue.async {
                // Remove the AVCaptureMovieFileOutput from the session because it doesn't support capture of Live Photos.
                self.session.beginConfiguration()
                self.session.removeOutput(self.movieFileOutput!)
                self.session.sessionPreset = .photo
                
                DispatchQueue.main.async {
                    self.switchModeControl.isEnabled = true
                }
                
                self.movieFileOutput = nil
                
                if self.photoOutput.isLivePhotoCaptureSupported {
                    self.photoOutput.isLivePhotoCaptureEnabled = true
                    
                   
                }
                if self.photoOutput.isDepthDataDeliverySupported {
                    self.photoOutput.isDepthDataDeliveryEnabled = true
                }
                
                if self.photoOutput.isPortraitEffectsMatteDeliverySupported {
                    self.photoOutput.isPortraitEffectsMatteDeliveryEnabled = true
                    
                }
               
                self.session.commitConfiguration()
            }
        }
    }
    
    @IBOutlet weak var switchModeControl: UISegmentedControl!
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?

    
    var stillData: Data?
    
    
    

}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("start recoding")
        
        DispatchQueue.main.async {
            self.captureButton.tintColor = .red
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        print("finish recoding")
        // Note: Because we use a unique file path for each recording, a new recording won't overwrite a recording mid-save.
        func cleanup() {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }

            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid

                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
        }

        var success = true

        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }

        if success {
            // Check the authorization status.
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // Save the movie file to the photo library and cleanup.
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
                    }, completionHandler: { success, error in
                        if !success {
                            print("AVCam couldn't save the movie to your photo library: \(String(describing: error))")
                        }
                        cleanup()
                    }
                    )
                } else {
                    cleanup()
                }
            }
        } else {
            cleanup()
        }

        // Enable the Camera and Record buttons to let the user switch camera and start another recording.
        DispatchQueue.main.async {
            // Only enable the ability to change camera if the device has more than one camera.
            self.switchModeControl.isEnabled = true
            self.captureButton.tintColor = .yellow
        }
    }
    
    
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    
    
    // 开始快门
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        preview.backgroundColor = .green
        
        UIView.animate(withDuration: 2, delay: 0, options: .curveLinear, animations: {
            self.preview.backgroundColor = .black
        }, completion: {state in
            print("shutter is start")
        })
    }
    // 结束快门
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("shutter is finish")
        DispatchQueue.main.async {
            self.lastImageLoading.isHidden = false
            self.lastImageLoading.startAnimating()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            print("didFinishProcessingPhoto error: \(String(describing: error)) ")
        }
        PHPhotoLibrary.requestAuthorization {state in
            if state != .authorized {
                return
            }
            PHPhotoLibrary.shared().performChanges({
                       
                let creationRequest = PHAssetCreationRequest.forAsset()
                self.stillData = photo.fileDataRepresentation()
                creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
            }, completionHandler: {(success, error) in
                if error != nil {
                    print("save ocurred some error")
                    return
                }
                if success {
                    if let image = UIImage(data: photo.fileDataRepresentation()!) {
                        DispatchQueue.main.async {
                            self.lastImageLoading.isHidden = true
                            self.lastImageLoading.stopAnimating()
                            self.lastImageView.image = image
                        }
                    }
                }
            })
        }
        print("didFinishProcessingPhoto output: \(output)")
        
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        print("live photo")
        if let error = error {
            print("error: \(error)")
        } else {
            print("live url: \(outputFileURL)")
            if let stillData = stillData {
                saveLivePhotoToPhotosLibrary(stillImageData: stillData, livePhotoMovieURL: outputFileURL)

            }
            
        }
    }
    
    func saveLivePhotoToPhotosLibrary(stillImageData: Data, livePhotoMovieURL: URL) {    PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                // Add the captured photo's file data as the main resource for the Photos asset.
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: stillImageData, options: nil)
                
                // Add the movie file URL as the Live Photo's paired video resource.
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoMovieURL, options: options)
            }) { success, error in
                // Handle completion.
            }
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("")
        if let input = videoDeviceInput {
            let device = input.device
            print("current iso: \(device.iso)")
            DispatchQueue.main.async {
                self.isoButton.setTitle("iso: \(device.iso)", for: .normal)
            }
            
        }
//        print("sampleBuffer.imageBuffer: \(sampleBuffer.imageBuffer)")
        
        
    }
}

extension AVCapturePhoto {
    func displayPhotoInfo() {
        print("photo info: \ncount: \(photoCount)\ntimeStamp: \(timestamp)\n isRawPhoto: \(isRawPhoto)\nhasDepthData: \(depthData != nil)")
    }
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
    
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        
        var uniqueDevicePositions = [AVCaptureDevice.Position]()
        
        for device in devices where !uniqueDevicePositions.contains(device.position) {
            uniqueDevicePositions.append(device.position)
        }
        
        return uniqueDevicePositions.count
    }
}

