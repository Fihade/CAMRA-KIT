//
//  SPCapturePhotoCaptureDelegate.swift
//  CameraEngine
//
//  Created by Fihade on 2021/5/4.
//

import Foundation
import AVFoundation
import Photos
import UIKit

class SPCapturePhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    
    public var requestedPhotoSettings: AVCapturePhotoSettings!
    private let willCapture: () -> Void
    private let photoProcessing: (Bool) -> Void
    private let finishCapturing: (Data) -> Void
    private let completionHandler: (SPCapturePhotoCaptureDelegate) -> Void
    
    private var photoData: Data?
    private var rawFileURL: URL?
    
    private var feedbackGenerator : UISelectionFeedbackGenerator? = nil
    
    init(willCapture: @escaping () -> Void,
         photoProcessing: @escaping (Bool) -> Void,
         finishCapturing: @escaping (Data) -> Void,
         completionHandler: @escaping (SPCapturePhotoCaptureDelegate) -> Void) {
        
        self.willCapture = willCapture
        self.photoProcessing = photoProcessing
        self.finishCapturing = finishCapturing
        self.completionHandler = completionHandler
    }
    
    enum CaptureProcessError: String {
        case ProcessingError
        case CaptureFailed
        case NotFoundPhotoData
    }
    
    // Will Capture
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        willCapture()
        
        feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator?.prepare()
        feedbackGenerator?.selectionChanged()
    }
    
    // Did Capture
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        feedbackGenerator = nil
        
    }
    
    // Did finish Processed
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            return
        } else {
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
                self.photoData = photoData
            }
            finishCapturing(photoData)
            self.photoProcessing(true)
        }
        
        

    }
    
    // Did Finish Capture
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
        if let error = error {
            print("did finish capture error: \(error)")
            return
        }
        
        guard let photoData = photoData else {
            return
        }
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()

                    creationRequest.addResource(with: .photo, data: photoData, options: nil)
                    
                    if let rawFileURL = self.rawFileURL {
                        options.shouldMoveFile = true
                        creationRequest.addResource(with: .alternatePhoto, fileURL: rawFileURL, options: options)
                    }
                }, completionHandler: {success, error in
                    if error != nil {
                        return
                    }
                    if success {
                        self.completionHandler(self)
                    }
                })
            } else {
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
