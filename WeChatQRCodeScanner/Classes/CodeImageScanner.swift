//
// CodeImageScanner.swift
//
// Copyright (c) 2024 DouDou
//
// Created by DouDou on 2024/1/15.
//

import Foundation
import opencv2
import UIKit
import Vision

public struct CodeImageScanner {
    public static let shared = CodeImageScanner()

    let scanner: WeChatQRCode

    init() {
        let bundle: Bundle = .codeScanner
        guard let detectPrototxt = bundle.path(forResource: "detect", ofType: "prototxt"),
              let detectCaffemodel = bundle.path(forResource: "detect", ofType: "caffemodel"),
              let srPrototxt = bundle.path(forResource: "sr", ofType: "prototxt"),
              let srCaffemodel = bundle.path(forResource: "sr", ofType: "caffemodel") else {
            scanner = .init()
            return
        }
        scanner = .init(detector_prototxt_path: detectPrototxt,
                        detector_caffe_model_path: detectCaffemodel,
                        super_resolution_prototxt_path: srPrototxt,
                        super_resolution_caffe_model_path: srCaffemodel)
    }

    public func scan(with image: UIImage) -> [CodeScannerResult] {
//        scan(with: image.mat())
        detect(with: image)
    }

    private func scan(with image: Mat) -> [CodeScannerResult] {
        let points = NSMutableArray()
        let ret: [String] = scanner.detectAndDecode(img: image, points: points)
        var result: [CodeScannerResult] = []
        for idx in 0..<ret.count {
            guard let point = points[idx] as? Mat else {
                continue
            }
            result.append(.init(content: ret[idx], rectOfImage: point.rectOfImage, type: .qr))
        }
        return result
    }

    public func detect(with image: UIImage?) -> [CodeScannerResult] {
        var detectedBarcodes: [CodeScannerResult] = []
        guard let cgimg = image?.cgImage else {
            return detectedBarcodes
        }

        let request = VNDetectBarcodesRequest { req, err in
            if let error = err {
                Log.error("parseBarCode error: \(error)")
                return
            }
            guard let results = req.results, !results.isEmpty else {
                return
            }
            for result in results {
                Log.debug("result: \(result)")
                if let barcode = result as? VNBarcodeObservation, let value = barcode.payloadStringValue {
                    let rectOfImage = convertRect(barcode.boundingBox, image)
                    if barcode.symbology == .qr { // 二维码
                        detectedBarcodes.append(.init(content: value, rectOfImage: rectOfImage, type: .qr))
                        Log.debug("qrcode: \(value) rectOfImage: \(rectOfImage)")
                    } else { // 条形码
                        detectedBarcodes.append(.init(content: value, rectOfImage: rectOfImage, type: barcode.symbology))
                        Log.debug("barcode: \(value), rectOfImage: \(rectOfImage), \(barcode.symbology.rawValue)")
                    }
                    break
                }
            }
        }
        let handler = VNImageRequestHandler(cgImage: cgimg)
        do {
            try handler.perform([request])
        } catch {
            Log.error("parseBarCode error: \(error)")
        }
        return detectedBarcodes
    }

    /// image坐标转换
    private func convertRect(_ rectangleRect: CGRect, _ image: UIImage?) -> CGRect {
        guard let image = image else { return .zero }
        // 此处是将Image的实际尺寸转化成imageView的尺寸
        let imageSize = image.size
        let w = rectangleRect.width * imageSize.width
        let h = rectangleRect.height * imageSize.height
        let x = rectangleRect.minX * imageSize.width
        // 该Y坐标与UIView的Y坐标是相反的
        let y = (1 - rectangleRect.minY) * imageSize.height - h
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
