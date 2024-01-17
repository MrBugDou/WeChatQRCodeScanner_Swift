//
// CodeScannerView.swift
//
// Copyright (c) 2024 DouDou
//
// Created by DouDou on 2024/1/15.
//

import AVFoundation
import opencv2
import UIKit
import Vision

public protocol CodeScannerViewDelegate: NSObjectProtocol {
    func scannerView(_ view: CodeScannerView, scanComplete result: [CodeScannerResult], elapsedTime: TimeInterval) -> Bool
}

public class CodeScannerView: UIView {
    // MARK: Public

    public weak var delegate: CodeScannerViewDelegate?

    public weak var previewLayer: AVCaptureVideoPreviewLayer?

    public override func layoutSubviews() {
        super.layoutSubviews()
        previewBounds = bounds
        previewLayer?.frame = bounds
    }
    
    public func startScanner() throws {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return
        }
        try? device.lockForConfiguration()
//        if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
//            device.focusMode = .autoFocus
//        }
        device.activeVideoMaxFrameDuration = .init(value: 1, timescale: 25)
        device.unlockForConfiguration()

        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        let session = AVCaptureSession()
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }

        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }

        // 设置输出以检测条形码
        let metadataOutput = AVCaptureMetadataOutput()

        // opencv
//        let metadataOutput = AVCaptureVideoDataOutput()

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
            // 设置输出以检测条形码
            metadataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
            metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .code128] // 可以根据需要添加其他类型
            metadataOutput.rectOfInterest = .init(x: 0, y: 0, width: 1, height: 1) // 全屏扫描
            // opencv
//            let key = kCVPixelBufferPixelFormatTypeKey as String
//            metadataOutput.videoSettings = [key: kCVPixelFormatType_32BGRA]
//            metadataOutput.alwaysDiscardsLateVideoFrames = true
//            metadataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer

        if !session.isRunning {
            stoped = false
            session.startRunning()
        }

        self.session = session
    }

    public func stopScanner() {
        guard let session = session else {
            stoped = true
            return
        }
        if session.isRunning {
            stoped = true
            session.stopRunning()
        }
    }

    public func changeTorchMode(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch, device.isTorchAvailable else {
            return
        }

        try? device.lockForConfiguration()

        device.torchMode = on ? .on : .off

        device.unlockForConfiguration()
    }
    
    // MARK: Internal

    var stoped: Bool = false

    // MARK: Private

    /// 输入输出中间桥梁(会话)
    private var session: AVCaptureSession?

    private var previewBounds: CGRect = .zero

    private let sessionQueue = DispatchQueue(label: "com.doudou.scanner.camera.sessionQueue", qos: .background)
}

extension CodeScannerView: AVCaptureMetadataOutputObjectsDelegate {
    /// 当检测到条形码时调用
    public func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        guard !stoped else {
            return
        }

        let objects = metadataObjects.map { [weak self] object in
            self?.previewLayer?.transformedMetadataObject(for: object)
        }

        let reads = objects.compactMap { $0 as? AVMetadataMachineReadableCodeObject }

        guard !stoped, !reads.isEmpty else {
            return
        }

        // 在这里处理扫描到的条形码
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        let start = CACurrentMediaTime()
        let elapsedTime = CACurrentMediaTime() - start

        var result: [CodeScannerResult] = []

        for read in reads {
            guard let content = read.stringValue, !content.isEmpty else {
                Log.debug("未能识别到内容")
                break
            }

            guard let type = convert(from: read.type) else {
                Log.debug("不支持的码类型: \(read.type.rawValue) - \(content)")
                break
            }

            Log.debug("code: \(content), type: \(type.rawValue) bounds: \(read.bounds)")

            result.append(.init(content: content, rectOfImage: read.bounds, type: type))
        }

        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else {
                return
            }
            let stoped = self?.delegate?.scannerView(sSelf, scanComplete: result, elapsedTime: elapsedTime as TimeInterval) ?? false
            self?.stoped = stoped
            guard stoped else {
                return
            }
            self?.stopScanner()
        }
    }

    func convert(from objectType: AVMetadataObject.ObjectType) -> VNBarcodeSymbology? {
        switch objectType {
        case .qr:
            return .qr
        case .ean8:
            return .ean8
        case .ean13:
            return .ean13
        case .code128:
            return .code128
        default:
            return nil
        }
    }
}

extension CodeScannerView: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        guard !stoped else {
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
        let imgData = Data(bytes: imgBufAddr, count: bytesPerRow * height)

        let mat = Mat(rows: Int32(height), cols: Int32(width), type: CV_8UC4, data: imgData, step: 0)

        let transMat = Mat()
        Core.transpose(src: mat, dst: transMat)

        let flipMat = Mat()
        Core.flip(src: transMat, dst: flipMat, flipCode: 1)

        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        let points = NSMutableArray()
        let ret: [String] = CodeImageScanner.shared.scanner.detectAndDecode(img: flipMat, points: points)

        guard !stoped, !ret.isEmpty else {
            return
        }

        // 在这里处理扫描到的条形码
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        let start = CACurrentMediaTime()
        var result: [CodeScannerResult] = []
        let elapsedTime = CACurrentMediaTime() - start
        for idx in 0..<ret.count {
            guard let point = points[idx] as? Mat else {
                continue
            }
            let sx = previewBounds.width / CGFloat(height)
            let sy = previewBounds.height / CGFloat(width)
            let transform = CGAffineTransform.identity.scaledBy(x: sx, y: sy)
            let rectOfView = point.rectOfImage.applying(transform)
            Log.debug("code: \(ret[idx]), rectOfImage: \(point.rectOfImage)")
            result.append(.init(content: ret[idx], rectOfImage: rectOfView, type: .qr))
        }

        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else {
                return
            }
            let stoped = self?.delegate?.scannerView(sSelf, scanComplete: result, elapsedTime: elapsedTime as TimeInterval) ?? false
            self?.stoped = stoped
            guard stoped else {
                return
            }
            self?.stopScanner()
        }
    }
}
