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
import SwiftyZeroMQ5

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    private var ip_address: String = ""
    private var port: Int = 8001
    
    private var permissionGranted = false
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let videoDataOutputQueue = DispatchQueue(label: "videoDataOutputQueue")
    private let transmitQueue = DispatchQueue(label: "transmitQueue")
    
    private let ciContext = CIContext()
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect : CGRect! = nil
    
    private var zmqContext: SwiftyZeroMQ.Context?
    private var zmqSocket: SwiftyZeroMQ.Socket?
    
    private var zmqThread: Thread?
    
    private var shouldTransmit: Bool = false
    
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
                    print(newValue)
                    self.ip_address = newValue
                    self.setupSocket()
                }
            })
        cancelable2 = UserDefaults.standard.publisher(for: \.port)
            .sink(receiveValue: { [weak self] newValue in
                guard let self = self else { return }
                if newValue != self.port { // avoid cycling !!
                    print(newValue)
                    self.port = newValue
                    self.setupSocket()
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
    
    func setupSocket() {
        if(zmqThread != nil) {
            try? zmqSocket?.close()
            zmqThread?.cancel()
        }
        
        zmqThread = Thread.init(target: self, selector: #selector(runSocket), object: nil)
        zmqThread?.start()
    }
    
    @objc
    func runSocket() {
        let urlOrIpRegex = /^(http(s?):\/\/)?(((www\.)?+[a-zA-Z0-9\.\-\_]+(\.[a-zA-Z]{2,3})+)|(\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b))(\/[a-zA-Z0-9\_\-\s\.\/\?\%\#\&\=]*)?$/
        
        if(!ip_address.contains(urlOrIpRegex)) {
            print("Invalid IP, not starting socket")
            return
        }
        
        if(port < 0 || port > 65535) {
            print("Invalid port, not starting socket")
            return
        }
        
        let uri = "tcp://\(ip_address):\(port)"
        print("Connecting to \(uri)")
        
        do {
            if(zmqContext == nil) {
                zmqContext = try SwiftyZeroMQ.Context()
            }
            zmqSocket = try zmqContext?.socket(.pair)
            
            try zmqSocket?.connect(uri)
            
            print("Requesting connection")
            try zmqSocket?.send(string: "Requesting connection")
            
            print("Message transmitted")
            
            let reply = try zmqSocket?.recv()
            print("Reply: \(reply ?? "Nothing")")
            
            while(true) {
                let reply2 = try zmqSocket?.recv()
                if(reply2 == "D") {
                    shouldTransmit = true
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if(!shouldTransmit) { return }
        shouldTransmit = false
        
        transmitQueue.async { [unowned self] in
            let ciImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
            guard let cgImage: CGImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
            let uiImage: UIImage = UIImage(cgImage: cgImage)
            guard let data: Data = uiImage.jpegData(compressionQuality: 0.02) else { return }
            
            try? self.zmqSocket?.send(data: data)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Dropped a frame!")
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
