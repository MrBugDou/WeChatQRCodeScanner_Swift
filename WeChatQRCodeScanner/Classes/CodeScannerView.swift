//
// CodeScannerView.swift
//
// Copyright (c) 2024 DouDou
//
// Created by DouDou on 2024/1/15.
//

import AVFoundation
import UIKit
import Vision

public protocol CodeScannerViewDelegate: NSObjectProtocol {
    func scannerView(_ view: CodeScannerView, scanComplete result: [ScanResult], elapsedTime: TimeInterval) -> Bool
}

public class CodeScannerView: UIView {
    // MARK: Public

    public weak var delegate: CodeScannerViewDelegate?

    public weak var previewLayer: AVCaptureVideoPreviewLayer?

    override public func layoutSubviews() {
        super.layoutSubviews()
        previewBounds = bounds
        previewLayer?.frame = bounds
    }

    public func startScanner() throws {
        
        guard session == nil else {
            if session?.isRunning == false {
                stoped = false
                session?.startRunning()
            }
            return
        }
        
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

        var result: [ScanResult] = []

        for read in reads {
            guard let content = read.stringValue, !content.isEmpty else {
                Log.debug("未能识别到内容")
                break
            }

            Log.debug("code: \(content), type: \(read.type.rawValue) bounds: \(read.bounds)")

            result.append(.init(content: content, rectOfImage: read.bounds, type: read.type))
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

extension CodeScannerView: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        guard !stoped else {
            return
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let start = CACurrentMediaTime()
        let datas = DDCodeImageScanner.shared().scan(forImageBuf: pixelBuffer)

        guard !stoped, !datas.isEmpty else {
            return
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        var results: [ScanResult] = []
        for data in datas {
            guard !data.content.isEmpty else {
                continue
            }
            let sx = previewBounds.width / CGFloat(height)
            let sy = previewBounds.height / CGFloat(width)
            let transform = CGAffineTransform.identity.scaledBy(x: sx, y: sy)
            let rectOfView = data.rectOfImage.applying(transform)
            Log.debug("code: \(data.content), rectOfImage: \(data.rectOfImage)")
            results.append(.init(content: data.content, rectOfImage: rectOfView, type: .qr))
        }

        // 在这里处理扫描到的条形码
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        let elapsedTime = CACurrentMediaTime() - start

        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else {
                return
            }
            let stoped = self?.delegate?.scannerView(sSelf, scanComplete: results, elapsedTime: elapsedTime as TimeInterval) ?? false
            self?.stoped = stoped
            guard stoped else {
                return
            }
            self?.stopScanner()
        }
    }
}
