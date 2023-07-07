//
//  HostedViewController.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 7/3/23.
//

import Foundation
import SwiftUI
import AVFoundation
import Combine

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    private var ip_address: String = ""
    private var port: Int = 8001
    
    private var permissionGranted = false
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let videoDataOutputQueue = DispatchQueue(label: "videoDataOutputQueue")
    
    private let ciContext = CIContext()
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect : CGRect! = nil
    
    private var cancelable: AnyCancellable?
    private var cancelable2: AnyCancellable?
    
    override func viewDidLoad() {
        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
        
        cancelable = UserDefaults.standard.publisher(for: \.ipaddress)
            .sink(receiveValue: { [weak self] newValue in
                guard let self = self else { return }
                if newValue != self.ip_address { // avoid cycling !!
                    self.ip_address = newValue
                    print(self.ip_address)
                }
            })
        cancelable2 = UserDefaults.standard.publisher(for: \.port)
            .sink(receiveValue: { [weak self] newValue in
                guard let self = self else { return }
                if newValue != self.port { // avoid cycling !!
                    self.port = newValue
                    print(self.port)
                }
            })
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            break
        case .notDetermined:
            requestPermission()
            break
        default:
            permissionGranted = false
        }
    }
    
    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = permissionGranted
            self.sessionQueue.resume()
        }
    }
    
    func setupCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        guard captureSession.canAddOutput(output) else { return }
        captureSession.addOutput(output)
        
        screenRect = UIScreen.main.bounds
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        previewLayer.connection?.videoOrientation = .portrait
        
        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("output captured")
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage: CGImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage: UIImage = UIImage(cgImage: cgImage)
        guard let data: Data = uiImage.pngData() else { return }
        
        
    }
}

struct HostedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return ViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}

extension UserDefaults {
    @objc dynamic var ipaddress: String {
        get { string(forKey: "ipaddress") ?? "" }
        set { setValue(newValue, forKey: "ipaddress") }
    }
    
    @objc dynamic var port: Int {
        get { integer(forKey: "port") }
        set { setValue(newValue, forKey: "port") }
    }
}
