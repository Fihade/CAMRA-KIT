//
//  KaChaCapturePhotoDelegate.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/5/4.
//

import Foundation
import AVFoundation
import Photos

class KaChaCapturePhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    private let willCapturePhotoAnimation: () -> Void
    private let photoProcessingHandler: (Bool) -> Void
    private let didFinishCaptureHandler: ((Data) -> Void)
    private let occuredErrorWhenCapturing: (Error?) -> Void
    private let completionHandler: (KaChaCapturePhotoDelegate) -> Void
    

    private var photoData: Data?
    private var rawFileURL: URL?
    
    init(
        with requestedPhotoSettings: AVCapturePhotoSettings,
        willCapturePhotoAnimation: @escaping () -> Void,
        photoProcessingHandler: @escaping (Bool) -> Void,
        didFinishCaptureHandler: @escaping (Data) -> Void,
        occuredErrorWhenCapturing: @escaping (Error?) -> Void,
        completionHandler: @escaping (KaChaCapturePhotoDelegate) -> Void
        ) {
        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.photoProcessingHandler = photoProcessingHandler
        self.didFinishCaptureHandler = didFinishCaptureHandler
        self.occuredErrorWhenCapturing = occuredErrorWhenCapturing
        self.completionHandler = completionHandler
    }
    
    
    var didFinish: (() -> Void)?
    
    // Will Capture
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
//        DispatchQueue.main.async {
//            self.previewView.videoPreviewLayer.opacity = 0
//            UIView.animate(withDuration: 0.25) {
//                self.previewView.videoPreviewLayer.opacity = 1
//            }
//            self.captureButton.isEnabled = false
//        }
        
        self.willCapturePhotoAnimation()
    }
    
    // Did Capture
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
//        self.imageView.startAnimate()
    }
    
    // Did finish Processed
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("didFinishProcessingPhoto")
        
        if let error = error {
            print("processing error: \(error)")
            occuredErrorWhenCapturing(error)
            return
        } else {
            self.photoProcessingHandler(true)
            
            guard let photoData = photo.fileDataRepresentation() else {
                print("No photo data to write.")
                return
            }
                  
            if photo.isRawPhoto {
                print("is raw photo")
                // Generate a unique URL to write the RAW file.
                rawFileURL = makeUniqueDNGFileURL()
                do {
                  // Write the RAW (DNG) file data to a URL.
                  try photoData.write(to: rawFileURL!)
                } catch {
                  fatalError("Couldn't write DNG file to the URL.")
                }
            } else {
              // Store compressed bitmap data.
                self.photoData = photoData
            }
        }

    }
    
    // Did Finish Capture
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
        print("finish capture")
//        didFinishCaptureHandler()
        
        if let error = error {
            print("did finish capture error: \(error)")
            self.occuredErrorWhenCapturing(error)
            self.completionHandler(self)
            return
        }
        
        guard let photoData = photoData else {
//            self.didFinishCaptureHandler()
            self.completionHandler(self)
            return
        }
        
        self.didFinishCaptureHandler(photoData)
        
        guard let rawFileURL = rawFileURL else {
            print("not raw file url")
            self.occuredErrorWhenCapturing(nil)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()

                    creationRequest.addResource(with: .photo, data: photoData, options: nil)
                
                    options.shouldMoveFile = true
                    creationRequest.addResource(with: .alternatePhoto, fileURL: rawFileURL, options: options)
//                    
                }, completionHandler: {success, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                    if success {
//                        self.didFinishCaptureHandler()
                        print("save successfully")
                    }
                })
            } else {
//                self.didFinishCaptureHandler()
                print("photo library is won't use")
            }
        }
        
        
        
    }
    
    private func makeUniqueDNGFileURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = ProcessInfo.processInfo.globallyUniqueString
        return tempDir.appendingPathComponent(fileName).appendingPathExtension("dng")
    }
}
