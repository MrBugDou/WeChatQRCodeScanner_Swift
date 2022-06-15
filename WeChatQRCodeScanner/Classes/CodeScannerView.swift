//
//  CodeScannerView.swift
//  WeChatQRCodeScanner
//
//  Created by DouDou on 2022/6/11.
//

import opencv2
import Foundation
import AVFoundation

public protocol CodeScannerViewDelegate: NSObjectProtocol {
    func scannerView(_ view: CodeScannerView, scanComplete result: [CodeScannerResult], elapsedTime: TimeInterval) -> Bool
}

open class CodeScannerView: UIView {
    
    //输入输出中间桥梁(会话)
    private lazy var session = AVCaptureSession()
    
    var stoped: Bool = false
    
    public weak var delegate: CodeScannerViewDelegate?
    
    open func startScanner() throws {
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        try? device.lockForConfiguration()
//        if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
//            device.focusMode = .autoFocus
//        }
        device.activeVideoMaxFrameDuration = .init(value: 1, timescale: 25)
        device.unlockForConfiguration()
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else { return }

        // let session = AVCaptureSession()
        // session.sessionPreset = .hd1280x720
        
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
        
        let metadataOutput = AVCaptureVideoDataOutput()
        let key = kCVPixelBufferPixelFormatTypeKey as String
        metadataOutput.videoSettings = [key: kCVPixelFormatType_32BGRA]
        metadataOutput.alwaysDiscardsLateVideoFrames = true
        metadataOutput.setSampleBufferDelegate(self, queue: .main)
        
        var videoConnection: AVCaptureConnection?
        for connection in metadataOutput.connections {
            for port in connection.inputPorts {
                if port.mediaType == .video {
                    videoConnection = connection
                    break
                }
            }
            if videoConnection != nil {
                break
            }
        }
        
        videoConnection?.videoOrientation = .portrait
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
        }
            
        let previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer.insertSublayer(previewLayer, at: 0)
        
        if !session.isRunning {
            stoped = false
            session.startRunning()
        }
    }
    
    open func stopScanner() {
        if session.isRunning {
            stoped = true
            session.stopRunning()
        }
    }
    
    open func changeTorchMode(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch, device.isTorchAvailable else {
                  return
              }
        
        try? device.lockForConfiguration()
        
        device.torchMode = on ? .on : .off
        
        device.unlockForConfiguration()
    }

}

extension CodeScannerView: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if stoped {
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        guard let imgBufAddr = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
//        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
//        let image = UIImage(ciImage: ciImage)
        let imgData = Data(bytes: imgBufAddr, count: (bytesPerRow * height))
        
        let mat = Mat(rows: Int32(height), cols: Int32(width), type: CvType.CV_8UC4, data: imgData, step: 0)
        
        let transMat = Mat()
        Core.transpose(src: mat, dst: transMat)
        
        let flipMat = Mat()
        Core.flip(src: transMat, dst: flipMat, flipCode: 1)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        var points: [Mat] = []
        let start = CACurrentMediaTime()
        let ret = CodeImageScanner.shared.scanner.detectAndDecode(img: flipMat, points: &points)
        let elapsedTime = CACurrentMediaTime() - start
        
        if stoped {
            return
        }
        
        var result: [CodeScannerResult] = []
        for idx in 0 ..< ret.count  {
            let point = points[idx]
            let left = (point.get(row: 0, col: 0).first ?? 0)
            let top = (point.get(row: 0, col: 1).first ?? 0)
            let right = (point.get(row: 1, col: 0).first ?? 0)
            let bottom = (point.get(row: 2, col: 1).first ?? 0)
            let rectOfImage = CGRect(x: left, y: top, width: right - left, height: bottom - top)
            
            let sx = bounds.width / CGFloat(height)
            let sy = bounds.height / CGFloat(width)
            let transform = CGAffineTransform.identity.scaledBy(x: sx, y: sy)
            let rectOfView = rectOfImage.applying(transform)
            result.append(.init(content: ret[idx], rectOfImage: rectOfImage, rectOfView: rectOfView))
        }
        stoped = delegate?.scannerView(self, scanComplete: result, elapsedTime: elapsedTime as TimeInterval) ?? false
    }
}

