//
//  VideoPreviewView.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 4/1/23.
//

import Foundation
import SwiftUI
import AVFoundation

class VideoPreviewViewController: UIViewController {
    var captureSession: AVCaptureSession;
    /// Convenience wrapper to get layer as its statically known type.
    var previewLayer: AVCaptureVideoPreviewLayer;
    
    init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.captureSession = AVCaptureSession();
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.previewLayer)
            self!.previewLayer.frame = self!.view.frame;
        }
//        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (time) in
//            print(self.captureSession.isRunning)
//            print("Preview", self.previewLayer.isPreviewing)
//        }
    }
}

struct VideoPreviewView: UIViewControllerRepresentable {
    var captureSession: AVCaptureSession;
    
    func makeUIViewController(context: Context) -> UIViewController {
        return VideoPreviewViewController(captureSession: captureSession)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

struct VideoPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPreviewView(captureSession: AVCaptureSession())
    }
}
