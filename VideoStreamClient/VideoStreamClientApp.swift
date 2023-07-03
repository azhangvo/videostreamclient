//
//  VideoStreamClientApp.swift
//  VideoStreamClient
//
//  Created by Arthur Zhang on 2/4/23.
//

import SwiftUI
import SwiftyZeroMQ5
import AVFoundation
import VideoToolbox

var count = 0;
var buf = NSMutableData()

@main
class VideoStreamClientApp: NSObject, App, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let videoQueue = DispatchQueue(label: "videoQueue")
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var captureSession: AVCaptureSession?
    var compressionSession: VTCompressionSession?
    var context: SwiftyZeroMQ.Context?
    var pusher: SwiftyZeroMQ.Socket?
    
    var lastInputPTS: CMTime = CMTime.zero
    
    var wifiAddress: String? = getWifiAddress()
    
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized camera access.
            var isAuthorized = status == .authorized
            
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    required override init() {
        captureSession = AVCaptureSession()
        
        var compressionSessionOrNil: VTCompressionSession? = nil
        let compressionSessionErr = VTCompressionSessionCreate(allocator: kCFAllocatorDefault, width: 960, height: 540, codecType: kCMVideoCodecType_H264, encoderSpecification: nil, imageBufferAttributes: nil, compressedDataAllocator: kCFAllocatorDefault, outputCallback: videoCompressionOutputCallback, refcon: nil, compressionSessionOut: &compressionSessionOrNil)
        
        if(compressionSessionErr != noErr || (compressionSessionOrNil == nil)) {
            print("There was an error initializing")
        }
        
        let compressionSession = compressionSessionOrNil!
        
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue);
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_AverageBitRate, value: 32 as CFNumber)
        VTCompressionSessionPrepareToEncodeFrames(compressionSession)
        
        self.compressionSession = compressionSession
        
        
        do {
            self.context = try SwiftyZeroMQ.Context()
            self.pusher = try context!.socket(.push)

            let endpoint = "tcp://*:5555"
            try pusher!.bind(endpoint)

//            try pusher!.send(string: "Hello world!\n")
        } catch {
            print("Context creation failure: \(error)")
        }
    }
    
    func setUpCaptureSession() async {
        guard await isAuthorized else { return }
        // Set up the capture session.
        
        captureSession!.beginConfiguration()
        
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video, position: .unspecified)
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
            captureSession!.canAddInput(videoDeviceInput)
        else { return }
        captureSession!.addInput(videoDeviceInput)
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        guard captureSession!.canAddOutput(videoDataOutput) else { return }
        captureSession!.sessionPreset = .iFrame960x540
        captureSession!.addOutput(videoDataOutput)
        captureSession!.commitConfiguration()
        
        videoDataOutput.setSampleBufferDelegate(self, queue: self.videoQueue)
    }
    
    func startCaptureSession() async {
        await setUpCaptureSession()
        
        captureSession!.startRunning()
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // image buffer
        guard let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            assertionFailure()
            return
        }
        
        // pts
        let pts: CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        guard CMTIME_IS_VALID(pts) else {
            assertionFailure()
            return
        }
        
        // duration
        var duration: CMTime = CMSampleBufferGetDuration(sampleBuffer);
        if CMTIME_IS_INVALID(duration) && CMTIME_IS_VALID(self.lastInputPTS) {
            duration = CMTimeSubtract(pts, self.lastInputPTS)
        }
        
        //        index += 1
        self.lastInputPTS = pts
        //        print("[\(Date())]: pushVideoBuffer \(index)")
        
//        let currentIndex = index
        
        guard let compressionSession = self.compressionSession else {
            return
        }
        VTCompressionSessionEncodeFrame(compressionSession, imageBuffer: imageBuffer, presentationTimeStamp: pts, duration: duration, frameProperties: nil, sourceFrameRefcon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), infoFlagsOut: nil)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    let videoCompressionOutputCallback: VTCompressionOutputCallback = { _,sourceFrameRefCon,status,_,sampleBuffer in
        guard status == noErr, let sampleBuffer = sampleBuffer else {
            return
        }
        
        let elementaryStream = NSMutableData()
        
        var isIFrame: Bool = false
        let attachmentsArray: CFArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)!
        if((CFArrayGetCount(attachmentsArray)) > 0) {
            let dict = CFArrayGetValueAtIndex(attachmentsArray, 0)
            let dictRef: CFDictionary = unsafeBitCast(dict, to: CFDictionary.self)
            
            let value = CFDictionaryGetValue(dictRef, unsafeBitCast(kCMSampleAttachmentKey_NotSync, to: UnsafeRawPointer.self))
            if value != nil {
                isIFrame = true
            }
        }
        
        let nStartCodeLength: size_t = 4
        let nStartCode: [UInt8] = [0x00, 0x00, 0x00, 0x01]
        
        if isIFrame == true {
            let description: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
            
            var numParams: size_t = 0
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: nil, parameterSetSizeOut: nil, parameterSetCountOut: &numParams, nalUnitHeaderLengthOut: nil)
            
            for i in 0..<numParams {
                var parameterSetPointer: UnsafePointer<UInt8>?
                var parameterSetLength: size_t = 0
                CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: i, parameterSetPointerOut: &parameterSetPointer, parameterSetSizeOut: &parameterSetLength, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
                elementaryStream.append(nStartCode, length: nStartCodeLength)
                elementaryStream.append(parameterSetPointer!, length: parameterSetLength)
            }
        }
        
        var blockBufferLength: size_t = 0
        var bufferDataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(CMSampleBufferGetDataBuffer(sampleBuffer)!, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &blockBufferLength, dataPointerOut: &bufferDataPointer)
        
        var bufferOffset: size_t = 0
        let AVCCHeaderLength: Int = 4
        while (bufferOffset < (blockBufferLength - AVCCHeaderLength)) {
            var NALUnitLength: UInt32 = 0
            memcpy(&NALUnitLength, bufferDataPointer! + bufferOffset, AVCCHeaderLength)
            NALUnitLength = CFSwapInt32(NALUnitLength)
            if(NALUnitLength > 0) {
                elementaryStream.append(nStartCode, length: nStartCodeLength)
                elementaryStream.append(bufferDataPointer! + bufferOffset + AVCCHeaderLength, length: Int(NALUnitLength))
                bufferOffset += AVCCHeaderLength + size_t(NALUnitLength)
            }
        }
        
        guard let sourceFrameRefCon = sourceFrameRefCon else {
            return
        }
        
        do {
            let aself = (Unmanaged<VideoStreamClientApp>.fromOpaque(sourceFrameRefCon).takeUnretainedValue())
            buf.append(Data(referencing: elementaryStream))
            print(count)
            try aself.pusher!.send(data: Data(referencing: elementaryStream));
            if count % 100 == 0 {
//                            try (Unmanaged<VideoStreamClientApp>.fromOpaque(sourceFrameRefCon).takeUnretainedValue()).pusher!.send(data: Data(referencing: elementaryStream));
                try aself.pusher!.send(data: Data(referencing: buf));
                buf.resetBytes(in: .init(location: 0, length: buf.length))
                buf = NSMutableData()
            }
            count += 1
        } catch {
            print("[INFO] Could not transfer frame to server: \(error)")
        }
        
        //debugPrint("[INFO]: outputCallback: sampleBuffer: \(sampleBuffer)")
    }
    
    
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("Test")
                VideoPreviewView(captureSession: captureSession!)
                    .task {
                        await self.startCaptureSession();
                }
                Text(wifiAddress != nil ? wifiAddress! + ":5555" : "No WiFi IP found")
                    .onReceive(timer) { input in
                        self.wifiAddress = getWifiAddress()
                    }
            }
        }
    }
}

