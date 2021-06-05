//
//  KCSession.swift
//  CAMRA-KIT
//
//  Created by 梁斌 on 2021/4/17.
//

import Foundation
import AVFoundation

class KCSession: NSObject {
    
    private var session: AVCaptureSession
    private var previewView: KCPreviewView?
    
    override init() {
        self.session = AVCaptureSession()
    }
    
    //MARK: Manage Session 
    deinit {
        self.session.stopRunning()
    }
    
    func startSession() {
        self.session.startRunning()
    }
    
    func stopSession() {
        self.session.stopRunning()
    }
    
    
    
    
    
}
